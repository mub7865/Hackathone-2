/**
 * Task Executor
 *
 * Executes task operations based on parsed intents.
 * Uses the existing tasks API to perform CRUD operations.
 */

import { TaskIntent } from './taskIntentParser';
import { createTask, listTasks, updateTask, deleteTask } from '@/lib/api/tasks';
import type { Task, TaskCreateRequest, TaskUpdateRequest } from '@/types/task';

export interface TaskExecutionResult {
  success: boolean;
  message: string;
  tasks?: Task[];
  error?: string;
}

/**
 * Execute a task intent
 */
export async function executeTaskIntent(intent: TaskIntent): Promise<TaskExecutionResult> {
  try {
    switch (intent.action) {
      case 'create':
        return await executeCreate(intent);
      case 'list':
        return await executeList(intent);
      case 'complete':
        return await executeComplete(intent);
      case 'update':
        return await executeUpdate(intent);
      case 'delete':
        return await executeDelete(intent);
      case 'search':
        return await executeSearch(intent);
      default:
        return {
          success: false,
          message: "I couldn't understand what you want to do with tasks. Try asking me to create, list, complete, update, or delete tasks.",
        };
    }
  } catch (error) {
    console.error('Task execution error:', error);
    return {
      success: false,
      message: 'Sorry, something went wrong while processing your request. Please try again.',
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

/**
 * Execute CREATE task
 */
async function executeCreate(intent: TaskIntent): Promise<TaskExecutionResult> {
  const { title, description, priority, tags, due_date, remind_at } = intent.params;

  if (!title) {
    return {
      success: false,
      message: "I couldn't figure out what task you want to create. Please provide a task title.",
    };
  }

  const taskData: TaskCreateRequest = {
    title,
    description,
    priority,
    tags,
    due_date,
    remind_at,
    status: 'pending',
  };

  const task = await createTask(taskData);

  // Build response message
  let message = `✅ I've created the task "${task.title}"`;

  const details: string[] = [];
  if (task.priority) details.push(`Priority: ${task.priority}`);
  if (task.due_date) details.push(`Due: ${formatDate(task.due_date)}`);
  if (task.remind_at) details.push(`Reminder: ${formatDate(task.remind_at)}`);
  if (task.tags && task.tags.length > 0) details.push(`Tags: ${task.tags.join(', ')}`);

  if (details.length > 0) {
    message += ` with ${details.join(', ')}`;
  }

  return {
    success: true,
    message,
    tasks: [task],
  };
}

/**
 * Execute LIST tasks
 */
async function executeList(intent: TaskIntent): Promise<TaskExecutionResult> {
  const { priority, tags, status } = intent.params;

  const tasks = await listTasks({
    priority,
    tags,
    status: status || 'pending', // Default to pending tasks
  });

  if (tasks.length === 0) {
    let message = "You don't have any tasks";
    if (priority) message += ` with ${priority} priority`;
    if (tags && tags.length > 0) message += ` tagged with ${tags.join(', ')}`;
    message += '.';

    return {
      success: true,
      message,
      tasks: [],
    };
  }

  let message = `Here ${tasks.length === 1 ? 'is' : 'are'} your ${tasks.length} task${tasks.length === 1 ? '' : 's'}`;
  if (priority) message += ` with ${priority} priority`;
  if (tags && tags.length > 0) message += ` tagged with ${tags.join(', ')}`;
  message += ':';

  return {
    success: true,
    message,
    tasks,
  };
}

/**
 * Execute COMPLETE task
 */
async function executeComplete(intent: TaskIntent): Promise<TaskExecutionResult> {
  const { search } = intent.params;

  if (!search) {
    return {
      success: false,
      message: "I couldn't figure out which task you want to complete. Please be more specific.",
    };
  }

  // Search for the task
  const tasks = await listTasks({ search, status: 'pending' });

  if (tasks.length === 0) {
    return {
      success: false,
      message: `I couldn't find any pending task matching "${search}".`,
    };
  }

  if (tasks.length > 1) {
    return {
      success: false,
      message: `I found ${tasks.length} tasks matching "${search}". Please be more specific about which one you want to complete.`,
      tasks,
    };
  }

  // Complete the task
  const task = tasks[0];
  const updatedTask = await updateTask(task.id, { status: 'completed' });

  return {
    success: true,
    message: `🎉 Great job! I've marked "${updatedTask.title}" as complete.`,
    tasks: [updatedTask],
  };
}

/**
 * Execute UPDATE task
 */
async function executeUpdate(intent: TaskIntent): Promise<TaskExecutionResult> {
  const { search, priority, due_date, tags } = intent.params;

  if (!search) {
    return {
      success: false,
      message: "I couldn't figure out which task you want to update. Please be more specific.",
    };
  }

  // Search for the task
  const tasks = await listTasks({ search });

  if (tasks.length === 0) {
    return {
      success: false,
      message: `I couldn't find any task matching "${search}".`,
    };
  }

  if (tasks.length > 1) {
    return {
      success: false,
      message: `I found ${tasks.length} tasks matching "${search}". Please be more specific about which one you want to update.`,
      tasks,
    };
  }

  // Update the task
  const task = tasks[0];
  const updateData: TaskUpdateRequest = {};
  if (priority) updateData.priority = priority;
  if (due_date) updateData.due_date = due_date;
  if (tags) updateData.tags = tags;

  const updatedTask = await updateTask(task.id, updateData);

  const changes: string[] = [];
  if (priority) changes.push(`priority to ${priority}`);
  if (due_date) changes.push(`due date to ${formatDate(due_date)}`);
  if (tags) changes.push(`tags to ${tags.join(', ')}`);

  return {
    success: true,
    message: `✅ I've updated "${updatedTask.title}" - changed ${changes.join(', ')}.`,
    tasks: [updatedTask],
  };
}

/**
 * Execute DELETE task
 */
async function executeDelete(intent: TaskIntent): Promise<TaskExecutionResult> {
  const { search } = intent.params;

  if (!search) {
    return {
      success: false,
      message: "I couldn't figure out which task you want to delete. Please be more specific.",
    };
  }

  // Search for the task
  const tasks = await listTasks({ search });

  if (tasks.length === 0) {
    return {
      success: false,
      message: `I couldn't find any task matching "${search}".`,
    };
  }

  if (tasks.length > 1) {
    return {
      success: false,
      message: `I found ${tasks.length} tasks matching "${search}". Please be more specific about which one you want to delete.`,
      tasks,
    };
  }

  // Delete the task
  const task = tasks[0];
  await deleteTask(task.id);

  return {
    success: true,
    message: `🗑️ I've deleted the task "${task.title}".`,
  };
}

/**
 * Execute SEARCH tasks
 */
async function executeSearch(intent: TaskIntent): Promise<TaskExecutionResult> {
  const { search } = intent.params;

  if (!search) {
    return {
      success: false,
      message: "Please tell me what you're looking for.",
    };
  }

  const tasks = await listTasks({ search });

  if (tasks.length === 0) {
    return {
      success: true,
      message: `I couldn't find any tasks matching "${search}".`,
      tasks: [],
    };
  }

  return {
    success: true,
    message: `I found ${tasks.length} task${tasks.length === 1 ? '' : 's'} matching "${search}":`,
    tasks,
  };
}

/**
 * Format date for display
 */
function formatDate(dateString: string): string {
  const date = new Date(dateString);
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  // Check if it's today
  if (date.toDateString() === today.toDateString()) {
    return 'today';
  }

  // Check if it's tomorrow
  if (date.toDateString() === tomorrow.toDateString()) {
    return 'tomorrow';
  }

  // Format as readable date
  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  });
}
