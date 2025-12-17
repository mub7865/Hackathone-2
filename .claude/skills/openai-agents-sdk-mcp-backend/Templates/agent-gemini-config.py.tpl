"""
OpenAI Agents SDK - Gemini Model Configuration Template

PURPOSE:
- Configure the AI agent with Google Gemini as the LLM provider.
- Use OpenAI Agents SDK with non-OpenAI models.
- Provide alternative to OpenAI for cost or availability reasons.

HOW TO USE:
- Copy this template to your project (e.g. app/chat/agent.py).
- Set GEMINI_API_KEY environment variable.
- Import your MCP tools and add them to the tools list.
- Customize instructions for your specific use case.

REFERENCES:
- https://openai.github.io/openai-agents-python/
- https://ai.google.dev/gemini-api/docs/openai
"""

import os
from openai import AsyncOpenAI
from agents import Agent, OpenAIChatCompletionsModel, Runner, set_tracing_disabled

# Import your MCP tools
from app.chat.tools import (
    add_task,
    list_tasks,
    complete_task,
    delete_task,
    update_task,
)


# --- Gemini Client Configuration ---

# Get API key from environment
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY environment variable is required")

# Configure Gemini client using OpenAI-compatible API
# Reference: https://ai.google.dev/gemini-api/docs/openai
gemini_client = AsyncOpenAI(
    api_key=GEMINI_API_KEY,
    base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
)

# Disable tracing for non-OpenAI providers
# (OpenAI's tracing dashboard doesn't support other providers)
set_tracing_disabled(disabled=True)


# --- Model Selection ---

# Available Gemini models:
# - gemini-2.0-flash: Fast, 1M context, good for general use
# - gemini-1.5-pro: Most capable, 2M context, complex tasks
# - gemini-1.5-flash: Fast, 1M context, balance of speed/quality

GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")


# --- Agent Instructions ---

AGENT_INSTRUCTIONS = """You are a helpful assistant that helps users manage their tasks.
You can communicate in English, Urdu, and Roman Urdu based on user's language preference.

## CAPABILITIES
You can help users with the following:
- Add new tasks with titles and optional descriptions
- List all tasks, or filter by status (pending/completed)
- Mark tasks as complete
- Delete tasks they no longer need
- Update task titles or descriptions

## BEHAVIOR GUIDELINES
1. Always confirm actions with a friendly, concise message
2. When listing tasks, format them clearly with task IDs
3. If a task is not found, explain politely and suggest alternatives
4. Ask for clarification if the user's request is ambiguous
5. Be proactive in suggesting related actions

## LANGUAGE SUPPORT
- If user writes in English, respond in English
- If user writes in Urdu or Roman Urdu, respond in Roman Urdu
- Examples of Roman Urdu responses:
  - "Maine 'Buy groceries' task add kar diya hai (Task #5)"
  - "Yeh hain aap ke pending tasks..."
  - "Task #3 complete ho gaya hai!"

## RESPONSE FORMAT
- Keep responses conversational but concise
- Use task IDs when referring to specific tasks
- Format task lists with clear structure

## EXAMPLE INTERACTIONS
User: "Add a task to buy groceries"
You: Use add_task tool, then respond: "Done! I've added 'Buy groceries' to your list (Task #5). Would you like to add any details?"

User: "Mujhe meri tasks dikhao"
You: Use list_tasks tool, then respond: "Yeh hain aap ki tasks:
- Task #1: Buy groceries (pending)
- Task #2: Call mom (completed)
Koi aur kaam hai?"

User: "Task 3 done"
You: Use complete_task tool, then respond: "Task #3 complete ho gaya! Well done!"
"""


# --- Agent Creation ---

def create_gemini_agent() -> Agent:
    """
    Create and configure the todo assistant agent with Gemini model.

    Returns:
        Configured Agent instance using Gemini as the LLM provider.
    """
    agent = Agent(
        name="Todo Assistant",
        instructions=AGENT_INSTRUCTIONS,
        model=OpenAIChatCompletionsModel(
            model=GEMINI_MODEL,
            openai_client=gemini_client,
        ),
        tools=[
            add_task,
            list_tasks,
            complete_task,
            delete_task,
            update_task,
        ],
    )
    return agent


# Create singleton agent instance
agent = create_gemini_agent()


# --- Helper function to run agent ---

async def run_agent(user_message: str, context: dict = None) -> str:
    """
    Run the agent with a user message.

    Args:
        user_message: The user's input message.
        context: Optional context dictionary (e.g., user_id, history).

    Returns:
        The agent's response as a string.
    """
    result = await Runner.run(
        agent,
        input=user_message,
        context=context or {},
    )
    return result.final_output


# --- Example usage ---

if __name__ == "__main__":
    import asyncio

    async def main():
        # Test the agent
        response = await run_agent("Add a task to buy groceries")
        print(response)

        response = await run_agent("Meri tasks dikhao")
        print(response)

    asyncio.run(main())
