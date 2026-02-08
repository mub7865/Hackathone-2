/**
 * Task Intent Parser
 *
 * Parses natural language messages to detect task-related intents
 * and extract parameters for task operations.
 *
 * Supports:
 * - Create tasks with title, priority, tags, due dates, reminders
 * - List/search tasks with filters
 * - Complete tasks
 * - Update tasks
 * - Delete tasks
 */

import { TaskPriority, TaskStatus } from '@/types/task';

export interface TaskIntent {
  action: 'create' | 'list' | 'update' | 'complete' | 'delete' | 'search' | null;
  params: {
    title?: string;
    description?: string;
    priority?: TaskPriority;
    tags?: string[];
    due_date?: string;
    remind_at?: string;
    status?: TaskStatus;
    search?: string;
    taskId?: string;
  };
  confidence: number; // 0-1, how confident we are in the parsing
}

/**
 * Parse a natural language message to detect task intent
 */
export function parseTaskIntent(message: string): TaskIntent | null {
  const lowerMessage = message.toLowerCase().trim();

  // Try to match each action type
  const createIntent = parseCreateIntent(lowerMessage, message);
  if (createIntent) return createIntent;

  const listIntent = parseListIntent(lowerMessage);
  if (listIntent) return listIntent;

  const completeIntent = parseCompleteIntent(lowerMessage);
  if (completeIntent) return completeIntent;

  const deleteIntent = parseDeleteIntent(lowerMessage);
  if (deleteIntent) return deleteIntent;

  const updateIntent = parseUpdateIntent(lowerMessage, message);
  if (updateIntent) return updateIntent;

  const searchIntent = parseSearchIntent(lowerMessage, message);
  if (searchIntent) return searchIntent;

  return null;
}

/**
 * Parse CREATE task intent
 * Examples:
 * - "Create a task to buy groceries"
 * - "Add task: finish report by tomorrow"
 * - "New task with high priority: call client"
 * - "Remind me to exercise at 6pm"
 */
function parseCreateIntent(lowerMessage: string, originalMessage: string): TaskIntent | null {
  const createPatterns = [
    /(?:create|add|new)\s+(?:a\s+)?task\s+(?:to\s+)?(.+)/i,
    /(?:remind\s+me\s+to|remember\s+to)\s+(.+)/i,
    /(?:i\s+need\s+to|i\s+should|i\s+have\s+to)\s+(.+)/i,
  ];

  for (const pattern of createPatterns) {
    const match = originalMessage.match(pattern);
    if (match) {
      const taskText = match[1].trim();

      // Extract priority
      const priority = extractPriority(taskText);

      // Extract tags
      const tags = extractTags(taskText);

      // Extract due date
      const due_date = extractDueDate(taskText);

      // Extract reminder time
      const remind_at = extractReminderTime(taskText);

      // Clean title by removing extracted metadata
      let title = taskText
        .replace(/\b(high|medium|low)\s+priority\b/gi, '')
        .replace(/\btag(?:ged)?\s+(?:with|as)\s+[\w\s,]+/gi, '')
        .replace(/\b(?:by|due|on)\s+(?:tomorrow|today|monday|tuesday|wednesday|thursday|friday|saturday|sunday|\d{4}-\d{2}-\d{2})/gi, '')
        .replace(/\bat\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)?/gi, '')
        .trim();

      return {
        action: 'create',
        params: {
          title,
          priority,
          tags,
          due_date,
          remind_at,
        },
        confidence: 0.9,
      };
    }
  }

  return null;
}

/**
 * Parse LIST task intent
 * Examples:
 * - "Show me all tasks"
 * - "List high priority tasks"
 * - "What are my tasks for today?"
 * - "Show tasks tagged with work"
 */
function parseListIntent(lowerMessage: string): TaskIntent | null {
  const listPatterns = [
    /(?:show|list|get|display|what\s+are)\s+(?:me\s+)?(?:all\s+)?(?:my\s+)?tasks?/i,
    /(?:what\s+tasks?\s+do\s+i\s+have)/i,
  ];

  for (const pattern of listPatterns) {
    if (pattern.test(lowerMessage)) {
      const priority = extractPriority(lowerMessage);
      const tags = extractTags(lowerMessage);
      const status = extractStatus(lowerMessage);

      return {
        action: 'list',
        params: {
          priority,
          tags,
          status,
        },
        confidence: 0.85,
      };
    }
  }

  return null;
}

/**
 * Parse COMPLETE task intent
 * Examples:
 * - "Complete the grocery task"
 * - "Mark buy milk as done"
 * - "Finish the report task"
 */
function parseCompleteIntent(lowerMessage: string): TaskIntent | null {
  const completePatterns = [
    /(?:complete|finish|done\s+with|mark\s+as\s+done)\s+(?:the\s+)?(.+)/i,
  ];

  for (const pattern of completePatterns) {
    const match = lowerMessage.match(pattern);
    if (match) {
      const taskIdentifier = match[1].trim();

      return {
        action: 'complete',
        params: {
          search: taskIdentifier,
        },
        confidence: 0.8,
      };
    }
  }

  return null;
}

/**
 * Parse DELETE task intent
 * Examples:
 * - "Delete the meeting task"
 * - "Remove task about groceries"
 */
function parseDeleteIntent(lowerMessage: string): TaskIntent | null {
  const deletePatterns = [
    /(?:delete|remove)\s+(?:the\s+)?(?:task\s+)?(?:about\s+)?(.+)/i,
  ];

  for (const pattern of deletePatterns) {
    const match = lowerMessage.match(pattern);
    if (match) {
      const taskIdentifier = match[1].trim();

      return {
        action: 'delete',
        params: {
          search: taskIdentifier,
        },
        confidence: 0.8,
      };
    }
  }

  return null;
}

/**
 * Parse UPDATE task intent
 * Examples:
 * - "Update grocery task to high priority"
 * - "Change meeting task due date to tomorrow"
 */
function parseUpdateIntent(lowerMessage: string, originalMessage: string): TaskIntent | null {
  const updatePatterns = [
    /(?:update|change|modify)\s+(.+)/i,
  ];

  for (const pattern of updatePatterns) {
    const match = originalMessage.match(pattern);
    if (match) {
      const updateText = match[1].trim();

      const priority = extractPriority(updateText);
      const due_date = extractDueDate(updateText);
      const tags = extractTags(updateText);

      return {
        action: 'update',
        params: {
          search: updateText,
          priority,
          due_date,
          tags,
        },
        confidence: 0.7,
      };
    }
  }

  return null;
}

/**
 * Parse SEARCH task intent
 * Examples:
 * - "Find tasks about groceries"
 * - "Search for work tasks"
 */
function parseSearchIntent(lowerMessage: string, originalMessage: string): TaskIntent | null {
  const searchPatterns = [
    /(?:find|search\s+for)\s+(?:tasks?\s+)?(?:about\s+)?(.+)/i,
  ];

  for (const pattern of searchPatterns) {
    const match = originalMessage.match(pattern);
    if (match) {
      const searchQuery = match[1].trim();

      return {
        action: 'search',
        params: {
          search: searchQuery,
        },
        confidence: 0.75,
      };
    }
  }

  return null;
}

/**
 * Extract priority from text
 */
function extractPriority(text: string): TaskPriority | undefined {
  if (/\bhigh\s+priority\b/i.test(text)) return 'high';
  if (/\bmedium\s+priority\b/i.test(text)) return 'medium';
  if (/\blow\s+priority\b/i.test(text)) return 'low';
  return undefined;
}

/**
 * Extract tags from text
 */
function extractTags(text: string): string[] | undefined {
  const tagMatch = text.match(/\btag(?:ged)?\s+(?:with|as)\s+([\w\s,]+)/i);
  if (tagMatch) {
    return tagMatch[1].split(',').map(tag => tag.trim()).filter(Boolean);
  }
  return undefined;
}

/**
 * Extract status from text
 */
function extractStatus(text: string): TaskStatus | undefined {
  if (/\bcompleted?\b/i.test(text)) return 'completed';
  if (/\bpending\b/i.test(text)) return 'pending';
  return undefined;
}

/**
 * Extract due date from text
 * Supports: today, tomorrow, specific dates
 */
function extractDueDate(text: string): string | undefined {
  const today = new Date();

  if (/\btoday\b/i.test(text)) {
    return today.toISOString().split('T')[0];
  }

  if (/\btomorrow\b/i.test(text)) {
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return tomorrow.toISOString().split('T')[0];
  }

  // Match specific date format (YYYY-MM-DD)
  const dateMatch = text.match(/\b(\d{4}-\d{2}-\d{2})\b/);
  if (dateMatch) {
    return dateMatch[1];
  }

  // Match day of week
  const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  for (let i = 0; i < days.length; i++) {
    if (new RegExp(`\\b${days[i]}\\b`, 'i').test(text)) {
      const targetDay = i;
      const currentDay = today.getDay();
      const daysUntilTarget = (targetDay - currentDay + 7) % 7 || 7;
      const targetDate = new Date(today);
      targetDate.setDate(targetDate.getDate() + daysUntilTarget);
      return targetDate.toISOString().split('T')[0];
    }
  }

  return undefined;
}

/**
 * Extract reminder time from text
 * Supports: "at 5pm", "at 9:30am"
 */
function extractReminderTime(text: string): string | undefined {
  const timeMatch = text.match(/\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/i);
  if (timeMatch) {
    let hours = parseInt(timeMatch[1]);
    const minutes = timeMatch[2] ? parseInt(timeMatch[2]) : 0;
    const meridiem = timeMatch[3]?.toLowerCase();

    if (meridiem === 'pm' && hours < 12) hours += 12;
    if (meridiem === 'am' && hours === 12) hours = 0;

    const reminderDate = new Date();
    reminderDate.setHours(hours, minutes, 0, 0);

    return reminderDate.toISOString();
  }

  return undefined;
}
