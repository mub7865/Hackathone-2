/**
 * SavedFiltersPanel component for managing saved search filters.
 *
 * This component provides:
 * - List of saved filters
 * - Apply saved filter
 * - Set default filter
 * - Edit filter
 * - Delete filter
 * - Visual indicators for default filter
 */

'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import type { SearchFilters } from './AdvancedSearch';

export interface SavedFilter {
  id: string;
  user_id: string;
  name: string;
  description?: string | null;
  filter_config: SearchFilters;
  is_default: boolean;
  created_at: string;
  updated_at: string;
}

interface SavedFiltersPanelProps {
  filters: SavedFilter[];
  onApply: (filter: SavedFilter) => void;
  onSetDefault?: (filterId: string) => void;
  onDelete?: (filterId: string) => void;
  onEdit?: (filter: SavedFilter) => void;
  loading?: boolean;
}

export default function SavedFiltersPanel({
  filters,
  onApply,
  onSetDefault,
  onDelete,
  onEdit,
  loading = false,
}: SavedFiltersPanelProps) {
  const [expandedFilterId, setExpandedFilterId] = useState<string | null>(null);
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow-sm border-2 border-gray-200 p-6">
        <div className="animate-pulse space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-16 bg-gray-200 rounded"></div>
          ))}
        </div>
      </div>
    );
  }

  if (filters.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow-sm border-2 border-gray-200 p-6">
        <div className="text-center py-8">
          <svg
            className="w-16 h-16 mx-auto text-gray-300 mb-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"
            />
          </svg>
          <p className="text-gray-500 text-lg">No saved filters yet</p>
          <p className="text-gray-400 text-sm mt-2">
            Create a filter using the search panel above
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-sm border-2 border-gray-200 p-4">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Saved Filters</h3>

      <div className="space-y-3">
        <AnimatePresence>
          {filters.map((filter) => (
            <motion.div
              key={filter.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, x: -100 }}
              className={`
                border-2 rounded-lg p-4 transition-all
                ${filter.is_default ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'}
              `}
            >
              {/* Filter Header */}
              <div className="flex items-start justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <h4 className="font-semibold text-gray-900 truncate">
                      {filter.name}
                    </h4>
                    {filter.is_default && (
                      <span className="px-2 py-0.5 text-xs font-medium bg-blue-500 text-white rounded-full">
                        Default
                      </span>
                    )}
                  </div>
                  {filter.description && (
                    <p className="text-sm text-gray-600 line-clamp-2">
                      {filter.description}
                    </p>
                  )}

                  {/* Filter Details (Expandable) */}
                  {expandedFilterId === filter.id && (
                    <motion.div
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: 'auto' }}
                      exit={{ opacity: 0, height: 0 }}
                      className="mt-3 pt-3 border-t border-gray-200"
                    >
                      <div className="space-y-2 text-sm">
                        {filter.filter_config.status && (
                          <div className="flex items-center gap-2">
                            <span className="text-gray-500">Status:</span>
                            <span className="font-medium capitalize">
                              {filter.filter_config.status}
                            </span>
                          </div>
                        )}
                        {filter.filter_config.priority && (
                          <div className="flex items-center gap-2">
                            <span className="text-gray-500">Priority:</span>
                            <span className="font-medium capitalize">
                              {filter.filter_config.priority}
                            </span>
                          </div>
                        )}
                        {filter.filter_config.tags && filter.filter_config.tags.length > 0 && (
                          <div className="flex items-center gap-2">
                            <span className="text-gray-500">Tags:</span>
                            <div className="flex flex-wrap gap-1">
                              {filter.filter_config.tags.map((tag) => (
                                <span
                                  key={tag}
                                  className="px-2 py-0.5 bg-gray-200 text-gray-700 rounded-full text-xs"
                                >
                                  {tag}
                                </span>
                              ))}
                            </div>
                          </div>
                        )}
                        {filter.filter_config.search && (
                          <div className="flex items-center gap-2">
                            <span className="text-gray-500">Search:</span>
                            <span className="font-medium">
                              "{filter.filter_config.search}"
                            </span>
                          </div>
                        )}
                        {filter.filter_config.sort && (
                          <div className="flex items-center gap-2">
                            <span className="text-gray-500">Sort:</span>
                            <span className="font-medium">
                              {filter.filter_config.sort} ({filter.filter_config.order || 'desc'})
                            </span>
                          </div>
                        )}
                      </div>
                    </motion.div>
                  )}
                </div>

                {/* Action Buttons */}
                <div className="flex items-center gap-1">
                  <button
                    onClick={() =>
                      setExpandedFilterId(
                        expandedFilterId === filter.id ? null : filter.id
                      )
                    }
                    className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                    title="View details"
                  >
                    <svg
                      className={`w-4 h-4 transition-transform ${
                        expandedFilterId === filter.id ? 'rotate-180' : ''
                      }`}
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M19 9l-7 7-7-7"
                      />
                    </svg>
                  </button>
                </div>
              </div>

              {/* Action Bar */}
              <div className="flex items-center gap-2 mt-3 pt-3 border-t border-gray-200">
                <button
                  onClick={() => onApply(filter)}
                  className="flex-1 px-3 py-1.5 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors text-sm font-medium"
                >
                  Apply Filter
                </button>

                {onSetDefault && !filter.is_default && (
                  <button
                    onClick={() => onSetDefault(filter.id)}
                    className="p-1.5 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                    title="Set as default"
                  >
                    <svg
                      className="w-5 h-5"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"
                      />
                    </svg>
                  </button>
                )}

                {onEdit && (
                  <button
                    onClick={() => onEdit(filter)}
                    className="p-1.5 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                    title="Edit filter"
                  >
                    <svg
                      className="w-5 h-5"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                      />
                    </svg>
                  </button>
                )}

                {onDelete && (
                  <>
                    {confirmDeleteId === filter.id ? (
                      <div className="flex items-center gap-1">
                        <button
                          onClick={() => {
                            onDelete(filter.id);
                            setConfirmDeleteId(null);
                          }}
                          className="px-2 py-1 text-xs bg-red-500 text-white rounded hover:bg-red-600 transition-colors"
                        >
                          Confirm
                        </button>
                        <button
                          onClick={() => setConfirmDeleteId(null)}
                          className="px-2 py-1 text-xs bg-gray-200 text-gray-700 rounded hover:bg-gray-300 transition-colors"
                        >
                          Cancel
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => setConfirmDeleteId(filter.id)}
                        className="p-1.5 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                        title="Delete filter"
                      >
                        <svg
                          className="w-5 h-5"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth={2}
                            d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                          />
                        </svg>
                      </button>
                    )}
                  </>
                )}
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </div>
  );
}
