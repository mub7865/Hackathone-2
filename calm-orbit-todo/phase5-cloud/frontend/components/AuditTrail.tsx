/**
 * AuditTrail component for viewing audit logs.
 *
 * This component displays a paginated list of audit logs with filtering
 * and detailed change tracking.
 */

'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

export type AuditAction = 'created' | 'updated' | 'deleted' | 'completed' | 'viewed';

export interface AuditLog {
  id: string;
  user_id: string;
  action: AuditAction;
  resource_type: string;
  resource_id: string;
  changes?: Record<string, { before: any; after: any }>;
  ip_address?: string;
  user_agent?: string;
  created_at: string;
}

export interface AuditLogListResponse {
  items: AuditLog[];
  total: number;
  offset: number;
  limit: number;
}

export interface AuditStatistics {
  total_actions: number;
  actions_by_type: Record<string, number>;
  actions_by_resource: Record<string, number>;
  period_days: number;
}

export interface AuditTrailProps {
  apiUrl?: string;
  token?: string;
  resourceType?: string;
  resourceId?: string;
}

const ACTION_CONFIG = {
  created: { label: 'Created', color: 'bg-green-100 text-green-700 border-green-300', icon: '➕' },
  updated: { label: 'Updated', color: 'bg-blue-100 text-blue-700 border-blue-300', icon: '✏️' },
  deleted: { label: 'Deleted', color: 'bg-red-100 text-red-700 border-red-300', icon: '🗑️' },
  completed: { label: 'Completed', color: 'bg-purple-100 text-purple-700 border-purple-300', icon: '✅' },
  viewed: { label: 'Viewed', color: 'bg-gray-100 text-gray-700 border-gray-300', icon: '👁️' },
};

export default function AuditTrail({
  apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  token,
  resourceType,
  resourceId,
}: AuditTrailProps) {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [statistics, setStatistics] = useState<AuditStatistics | null>(null);
  const [total, setTotal] = useState(0);
  const [offset, setOffset] = useState(0);
  const [limit] = useState(20);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showStatistics, setShowStatistics] = useState(false);

  // Filters
  const [filterAction, setFilterAction] = useState<AuditAction | ''>('');
  const [filterResourceType, setFilterResourceType] = useState<string>(resourceType || '');
  const [startDate, setStartDate] = useState<string>('');
  const [endDate, setEndDate] = useState<string>('');

  // Expanded log details
  const [expandedLogId, setExpandedLogId] = useState<string | null>(null);

  useEffect(() => {
    if (token) {
      fetchLogs();
      fetchStatistics();
    }
  }, [token, offset, filterAction, filterResourceType, startDate, endDate]);

  const fetchLogs = async () => {
    if (!token) return;

    setLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        offset: offset.toString(),
        limit: limit.toString(),
      });

      if (filterAction) params.append('action', filterAction);
      if (filterResourceType) params.append('resource_type', filterResourceType);
      if (resourceId) params.append('resource_id', resourceId);
      if (startDate) params.append('start_date', new Date(startDate).toISOString());
      if (endDate) params.append('end_date', new Date(endDate).toISOString());

      const response = await fetch(`${apiUrl}/api/v1/audit?${params}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch audit logs');
      }

      const data: AuditLogListResponse = await response.json();
      setLogs(data.items);
      setTotal(data.total);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const fetchStatistics = async () => {
    if (!token) return;

    try {
      const response = await fetch(`${apiUrl}/api/v1/audit/statistics?days=30`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data: AuditStatistics = await response.json();
        setStatistics(data);
      }
    } catch (err) {
      console.error('Failed to fetch statistics:', err);
    }
  };

  const handlePreviousPage = () => {
    if (offset > 0) {
      setOffset(Math.max(0, offset - limit));
    }
  };

  const handleNextPage = () => {
    if (offset + limit < total) {
      setOffset(offset + limit);
    }
  };

  const handleClearFilters = () => {
    setFilterAction('');
    setFilterResourceType(resourceType || '');
    setStartDate('');
    setEndDate('');
    setOffset(0);
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const formatValue = (value: any): string => {
    if (value === null || value === undefined) return 'null';
    if (typeof value === 'boolean') return value ? 'true' : 'false';
    if (Array.isArray(value)) return `[${value.join(', ')}]`;
    if (typeof value === 'object') return JSON.stringify(value);
    return String(value);
  };

  if (!token) {
    return (
      <div className="p-4 text-center text-gray-500">
        Please log in to view audit trail
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900">Audit Trail</h2>
        <button
          onClick={() => setShowStatistics(!showStatistics)}
          className="px-4 py-2 text-sm font-medium text-blue-600 hover:text-blue-700 border border-blue-300 rounded-lg hover:bg-blue-50 transition-colors"
        >
          {showStatistics ? 'Hide' : 'Show'} Statistics
        </button>
      </div>

      {/* Statistics Panel */}
      <AnimatePresence>
        {showStatistics && statistics && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="bg-white border border-gray-200 rounded-lg p-6 shadow-sm"
          >
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Last {statistics.period_days} Days
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Total Actions */}
              <div>
                <p className="text-sm text-gray-500 mb-2">Total Actions</p>
                <p className="text-3xl font-bold text-gray-900">
                  {statistics.total_actions}
                </p>
              </div>

              {/* Actions by Type */}
              <div>
                <p className="text-sm text-gray-500 mb-2">Actions by Type</p>
                <div className="space-y-1">
                  {Object.entries(statistics.actions_by_type).map(([action, count]) => (
                    <div key={action} className="flex items-center justify-between text-sm">
                      <span className="text-gray-700 capitalize">{action}</span>
                      <span className="font-semibold text-gray-900">{count}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Actions by Resource */}
              <div>
                <p className="text-sm text-gray-500 mb-2">Actions by Resource</p>
                <div className="space-y-1">
                  {Object.entries(statistics.actions_by_resource).map(([resource, count]) => (
                    <div key={resource} className="flex items-center justify-between text-sm">
                      <span className="text-gray-700 capitalize">{resource}</span>
                      <span className="font-semibold text-gray-900">{count}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Filters */}
      <div className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {/* Action Filter */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Action
            </label>
            <select
              value={filterAction}
              onChange={(e) => {
                setFilterAction(e.target.value as AuditAction | '');
                setOffset(0);
              }}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Actions</option>
              <option value="created">Created</option>
              <option value="updated">Updated</option>
              <option value="deleted">Deleted</option>
              <option value="completed">Completed</option>
              <option value="viewed">Viewed</option>
            </select>
          </div>

          {/* Resource Type Filter */}
          {!resourceType && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Resource Type
              </label>
              <select
                value={filterResourceType}
                onChange={(e) => {
                  setFilterResourceType(e.target.value);
                  setOffset(0);
                }}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">All Resources</option>
                <option value="task">Task</option>
                <option value="saved_filter">Saved Filter</option>
              </select>
            </div>
          )}

          {/* Start Date Filter */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Start Date
            </label>
            <input
              type="date"
              value={startDate}
              onChange={(e) => {
                setStartDate(e.target.value);
                setOffset(0);
              }}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* End Date Filter */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              End Date
            </label>
            <input
              type="date"
              value={endDate}
              onChange={(e) => {
                setEndDate(e.target.value);
                setOffset(0);
              }}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Clear Filters Button */}
        {(filterAction || filterResourceType || startDate || endDate) && (
          <div className="mt-4">
            <button
              onClick={handleClearFilters}
              className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
            >
              Clear Filters
            </button>
          </div>
        )}
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          {error}
        </div>
      )}

      {/* Loading State */}
      {loading && (
        <div className="text-center py-8 text-gray-500">
          Loading audit logs...
        </div>
      )}

      {/* Audit Logs List */}
      {!loading && logs.length === 0 && (
        <div className="text-center py-8 text-gray-500">
          No audit logs found
        </div>
      )}

      {!loading && logs.length > 0 && (
        <div className="space-y-3">
          <AnimatePresence>
            {logs.map((log) => {
              const config = ACTION_CONFIG[log.action];
              const isExpanded = expandedLogId === log.id;

              return (
                <motion.div
                  key={log.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -20 }}
                  className="bg-white border border-gray-200 rounded-lg shadow-sm hover:shadow-md transition-shadow"
                >
                  <div
                    className="p-4 cursor-pointer"
                    onClick={() => setExpandedLogId(isExpanded ? null : log.id)}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex items-start space-x-3 flex-1">
                        {/* Action Badge */}
                        <span
                          className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border ${config.color}`}
                        >
                          <span className="mr-1">{config.icon}</span>
                          {config.label}
                        </span>

                        {/* Log Details */}
                        <div className="flex-1">
                          <div className="flex items-center space-x-2 text-sm">
                            <span className="font-medium text-gray-900 capitalize">
                              {log.resource_type}
                            </span>
                            <span className="text-gray-400">•</span>
                            <span className="text-gray-600 font-mono text-xs">
                              {log.resource_id.substring(0, 8)}...
                            </span>
                          </div>
                          <div className="mt-1 text-xs text-gray-500">
                            {formatDate(log.created_at)}
                            {log.ip_address && (
                              <>
                                <span className="mx-2">•</span>
                                <span className="font-mono">{log.ip_address}</span>
                              </>
                            )}
                          </div>
                        </div>
                      </div>

                      {/* Expand Icon */}
                      {log.changes && Object.keys(log.changes).length > 0 && (
                        <motion.div
                          animate={{ rotate: isExpanded ? 180 : 0 }}
                          transition={{ duration: 0.2 }}
                          className="text-gray-400"
                        >
                          ▼
                        </motion.div>
                      )}
                    </div>

                    {/* Expanded Details */}
                    <AnimatePresence>
                      {isExpanded && log.changes && (
                        <motion.div
                          initial={{ opacity: 0, height: 0 }}
                          animate={{ opacity: 1, height: 'auto' }}
                          exit={{ opacity: 0, height: 0 }}
                          className="mt-4 pt-4 border-t border-gray-200"
                        >
                          <h4 className="text-sm font-semibold text-gray-900 mb-2">
                            Changes:
                          </h4>
                          <div className="space-y-2">
                            {Object.entries(log.changes).map(([field, change]) => (
                              <div
                                key={field}
                                className="bg-gray-50 rounded-lg p-3 text-sm"
                              >
                                <div className="font-medium text-gray-700 mb-1 capitalize">
                                  {field}
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                  <div>
                                    <span className="text-xs text-gray-500">Before:</span>
                                    <div className="mt-1 font-mono text-xs text-red-600 bg-red-50 px-2 py-1 rounded">
                                      {formatValue(change.before)}
                                    </div>
                                  </div>
                                  <div>
                                    <span className="text-xs text-gray-500">After:</span>
                                    <div className="mt-1 font-mono text-xs text-green-600 bg-green-50 px-2 py-1 rounded">
                                      {formatValue(change.after)}
                                    </div>
                                  </div>
                                </div>
                              </div>
                            ))}
                          </div>

                          {/* Additional Metadata */}
                          {log.user_agent && (
                            <div className="mt-3 text-xs text-gray-500">
                              <span className="font-medium">User Agent:</span>{' '}
                              <span className="font-mono">{log.user_agent}</span>
                            </div>
                          )}
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>
                </motion.div>
              );
            })}
          </AnimatePresence>
        </div>
      )}

      {/* Pagination */}
      {!loading && total > 0 && (
        <div className="flex items-center justify-between bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
          <div className="text-sm text-gray-600">
            Showing {offset + 1} to {Math.min(offset + limit, total)} of {total} logs
          </div>
          <div className="flex items-center space-x-2">
            <button
              onClick={handlePreviousPage}
              disabled={offset === 0}
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              Previous
            </button>
            <button
              onClick={handleNextPage}
              disabled={offset + limit >= total}
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
