"""
ChatKit Server Implementation
Feature: 007-ai-chatbot-phase3 (ChatKit integration)

Implements OpenAI ChatKit server with:
- ChatKitServer for handling user messages
- Store implementation using SQLModel database
- Integration with OpenAI Agents SDK
"""

from typing import AsyncIterator
from dataclasses import dataclass
from chatkit.server import ChatKitServer
from chatkit.types import (
    ThreadMetadata,
    UserMessageItem,
    ThreadStreamEvent,
    ThreadItem,
)
from chatkit.agents import simple_to_agent_input, stream_agent_response
from chatkit.store import Store
from agents import Agent, Runner
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.models.conversation import Conversation
from app.models.message import Message
from app.database import get_session


@dataclass
class ChatKitRequestContext:
    """Context for each ChatKit request"""
    user_id: str
    session: AsyncSession


class SQLModelChatKitStore(Store):
    """
    ChatKit Store implementation using SQLModel database
    Maps ChatKit threads to Conversation model
    Maps ChatKit items to Message model
    """

    def __init__(self, session: AsyncSession, user_id: str):
        self.session = session
        self.user_id = user_id

    async def load_thread(self, thread_id: str) -> ThreadMetadata | None:
        """Load thread metadata by ID"""
        result = await self.session.execute(
            select(Conversation).where(
                Conversation.id == int(thread_id),
                Conversation.user_id == self.user_id
            )
        )
        conversation = result.scalar_one_or_none()

        if not conversation:
            return None

        return ThreadMetadata(
            id=str(conversation.id),
            title=conversation.title or "New Chat",
            created_at=conversation.created_at.isoformat(),
            updated_at=conversation.updated_at.isoformat(),
        )

    async def save_thread(self, thread: ThreadMetadata) -> None:
        """Save or update thread metadata"""
        if thread.id:
            # Update existing conversation
            result = await self.session.execute(
                select(Conversation).where(
                    Conversation.id == int(thread.id),
                    Conversation.user_id == self.user_id
                )
            )
            conversation = result.scalar_one_or_none()
            if conversation:
                conversation.title = thread.title
                self.session.add(conversation)
        else:
            # Create new conversation
            conversation = Conversation(
                user_id=self.user_id,
                title=thread.title or "New Chat"
            )
            self.session.add(conversation)

        await self.session.commit()

    async def load_threads(
        self,
        limit: int = 20,
        cursor: str | None = None
    ) -> tuple[list[ThreadMetadata], str | None]:
        """Load list of threads with pagination"""
        query = select(Conversation).where(
            Conversation.user_id == self.user_id
        ).order_by(Conversation.updated_at.desc()).limit(limit)

        if cursor:
            query = query.where(Conversation.id < int(cursor))

        result = await self.session.execute(query)
        conversations = result.scalars().all()

        threads = [
            ThreadMetadata(
                id=str(conv.id),
                title=conv.title or "New Chat",
                created_at=conv.created_at.isoformat(),
                updated_at=conv.updated_at.isoformat(),
            )
            for conv in conversations
        ]

        next_cursor = str(conversations[-1].id) if conversations else None
        return threads, next_cursor

    async def load_thread_items(
        self,
        thread_id: str,
        limit: int = 50,
        cursor: str | None = None
    ) -> tuple[list[ThreadItem], str | None]:
        """Load messages in a thread"""
        query = select(Message).where(
            Message.conversation_id == int(thread_id)
        ).order_by(Message.created_at.asc()).limit(limit)

        if cursor:
            query = query.where(Message.id > int(cursor))

        result = await self.session.execute(query)
        messages = result.scalars().all()

        items = [
            {
                "id": str(msg.id),
                "type": "user_message" if msg.role == "user" else "assistant_message",
                "content": msg.content,
                "created_at": msg.created_at.isoformat(),
            }
            for msg in messages
        ]

        next_cursor = str(messages[-1].id) if messages else None
        return items, next_cursor

    async def add_thread_item(self, thread_id: str, item: ThreadItem) -> str:
        """Add a new message to thread"""
        message = Message(
            conversation_id=int(thread_id),
            role="user" if item.get("type") == "user_message" else "assistant",
            content=item.get("content", ""),
        )
        self.session.add(message)
        await self.session.commit()
        await self.session.refresh(message)
        return str(message.id)

    async def save_item(self, thread_id: str, item: ThreadItem) -> None:
        """Update an existing message"""
        if item.get("id"):
            result = await self.session.execute(
                select(Message).where(Message.id == int(item["id"]))
            )
            message = result.scalar_one_or_none()
            if message:
                message.content = item.get("content", message.content)
                self.session.add(message)
                await self.session.commit()

    async def delete_thread(self, thread_id: str) -> None:
        """Delete a thread and all its messages"""
        # Delete messages first
        await self.session.execute(
            select(Message).where(Message.conversation_id == int(thread_id))
        )

        # Delete conversation
        result = await self.session.execute(
            select(Conversation).where(
                Conversation.id == int(thread_id),
                Conversation.user_id == self.user_id
            )
        )
        conversation = result.scalar_one_or_none()
        if conversation:
            await self.session.delete(conversation)
            await self.session.commit()

    async def delete_thread_item(self, thread_id: str, item_id: str) -> None:
        """Delete a specific message"""
        result = await self.session.execute(
            select(Message).where(Message.id == int(item_id))
        )
        message = result.scalar_one_or_none()
        if message:
            await self.session.delete(message)
            await self.session.commit()


class TodoChatKitServer(ChatKitServer[ChatKitRequestContext]):
    """
    ChatKit server for Todo application
    Handles user messages and generates AI responses
    """

    def __init__(self):
        # Initialize OpenAI Agent
        self.agent = Agent(
            name="todo-assistant",
            instructions="""You are a helpful task management assistant.
            Help users manage their tasks through natural language.
            You can help them:
            - Add new tasks
            - List existing tasks
            - Mark tasks as complete
            - Update task details
            - Delete tasks
            - Set due dates and reminders

            Be friendly, concise, and helpful.""",
            model="gpt-4o-mini",
        )

    async def respond(
        self,
        thread: ThreadMetadata,
        input_user_message: UserMessageItem | None,
        context: ChatKitRequestContext,
    ) -> AsyncIterator[ThreadStreamEvent]:
        """
        Generate response to user message
        Called once per user turn
        """
        # Create store for this request
        store = SQLModelChatKitStore(context.session, context.user_id)

        # Load recent thread history
        items, _ = await store.load_thread_items(thread.id, limit=20)

        # Convert to agent input
        agent_input = simple_to_agent_input(items)

        # Run agent and stream response
        runner = Runner(agent=self.agent)
        async for event in stream_agent_response(
            runner.run_stream(agent_input),
            context.context
        ):
            yield event


# Global ChatKit server instance
chatkit_server = TodoChatKitServer()
