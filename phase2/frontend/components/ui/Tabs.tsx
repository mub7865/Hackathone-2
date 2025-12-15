'use client';

import { useId } from 'react';

export interface Tab {
  id: string;
  label: string;
  count?: number;
}

export interface TabsProps {
  tabs: Tab[];
  activeTab: string;
  onChange: (tabId: string) => void;
  className?: string;
}

/**
 * Tab navigation component with smooth indicator transitions
 * Feature: 006-ui-theme-motion (FR-017)
 *
 * - Uses semantic color tokens
 * - Smooth tab indicator transition (150ms)
 * - Clear active/inactive state distinction
 * - Respects reduced motion
 */
export function Tabs({ tabs, activeTab, onChange, className = '' }: TabsProps) {
  const tablistId = useId();

  return (
    <div className={`border-b border-border-subtle ${className}`}>
      <nav
        className="flex -mb-px space-x-1"
        role="tablist"
        aria-label="Task filters"
      >
        {tabs.map((tab) => {
          const isActive = tab.id === activeTab;
          const tabId = `${tablistId}-tab-${tab.id}`;
          const panelId = `${tablistId}-panel-${tab.id}`;

          return (
            <button
              key={tab.id}
              id={tabId}
              role="tab"
              aria-selected={isActive}
              aria-controls={panelId}
              onClick={() => onChange(tab.id)}
              className={`
                px-4 py-2 text-body-sm font-medium
                border-b-2 rounded-t-md
                transition-all duration-fast
                motion-reduce:transition-none
                focus:outline-none focus:ring-2 focus:ring-accent-primary focus:ring-inset
                ${
                  isActive
                    ? 'border-accent-primary text-accent-primary bg-background-surface/50'
                    : 'border-transparent text-text-muted hover:text-text-secondary hover:border-border-subtle hover:bg-background-surface/30'
                }
              `.replace(/\s+/g, ' ').trim()}
            >
              {tab.label}
              {typeof tab.count === 'number' && (
                <span
                  className={`
                    ml-2 px-2 py-0.5 text-caption rounded-full
                    transition-colors duration-fast
                    motion-reduce:transition-none
                    ${
                      isActive
                        ? 'bg-accent-primary/20 text-accent-primary'
                        : 'bg-background-surface text-text-muted'
                    }
                  `.replace(/\s+/g, ' ').trim()}
                >
                  {tab.count}
                </span>
              )}
            </button>
          );
        })}
      </nav>
    </div>
  );
}
