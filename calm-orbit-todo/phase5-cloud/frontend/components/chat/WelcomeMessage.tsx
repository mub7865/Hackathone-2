'use client';

interface WelcomeMessageProps {
  onExampleClick?: (example: string) => void;
}

const EXAMPLE_COMMANDS = [
  {
    text: 'Add a task to buy groceries',
    description: 'Create a new task',
  },
  {
    text: 'Show my tasks',
    description: 'View all tasks',
  },
  {
    text: 'What do I need to do?',
    description: 'See pending tasks',
  },
  {
    text: 'Mark task as done',
    description: 'Complete a task',
  },
];

/**
 * WelcomeMessage component shown for new conversations
 * Feature: 007-ai-chatbot-phase3
 *
 * - Friendly greeting
 * - Clickable example commands
 */
export function WelcomeMessage({ onExampleClick }: WelcomeMessageProps) {
  return (
    <div className="flex flex-col items-center justify-center h-full max-w-2xl mx-auto px-3 sm:px-4 py-6 sm:py-8">
      {/* Icon */}
      <div className="w-14 h-14 sm:w-16 sm:h-16 mb-4 sm:mb-6 rounded-full bg-accent-primary/10 flex items-center justify-center">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="currentColor"
          className="w-7 h-7 sm:w-8 sm:h-8 text-accent-primary"
        >
          <path
            fillRule="evenodd"
            d="M4.848 2.771A49.144 49.144 0 0112 2.25c2.43 0 4.817.178 7.152.52 1.978.292 3.348 2.024 3.348 3.97v6.02c0 1.946-1.37 3.678-3.348 3.97a48.901 48.901 0 01-3.476.383.39.39 0 00-.297.17l-2.755 4.133a.75.75 0 01-1.248 0l-2.755-4.133a.39.39 0 00-.297-.17 48.9 48.9 0 01-3.476-.384c-1.978-.29-3.348-2.024-3.348-3.97V6.741c0-1.946 1.37-3.68 3.348-3.97z"
            clipRule="evenodd"
          />
        </svg>
      </div>

      {/* Greeting */}
      <h2 className="text-xl sm:text-heading-2 font-semibold text-text-primary mb-2 text-center">
        Hello! I'm your Todo Assistant
      </h2>
      <p className="text-sm sm:text-body-base text-text-secondary mb-6 sm:mb-8 text-center">
        I can help you manage your tasks through natural language. Try asking me to:
      </p>

      {/* Example commands */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 sm:gap-3 w-full max-w-xl">
        {EXAMPLE_COMMANDS.map((example) => (
          <button
            key={example.text}
            type="button"
            onClick={() => onExampleClick?.(example.text)}
            className={`
              text-left p-3 sm:p-4 rounded-xl
              bg-background-surface border border-border-subtle
              hover:border-accent-primary hover:bg-background-elevated
              transition-all duration-fast
              group
            `}
          >
            <p className="text-sm sm:text-body-sm font-medium text-text-primary group-hover:text-accent-primary transition-colors">
              "{example.text}"
            </p>
            <p className="text-xs sm:text-caption text-text-secondary mt-1">
              {example.description}
            </p>
          </button>
        ))}
      </div>

      {/* Help text */}
      <p className="text-xs sm:text-caption text-text-secondary mt-6 sm:mt-8 text-center">
        You can also ask me to delete, update, or mark tasks as complete!
      </p>
    </div>
  );
}
