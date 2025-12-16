'use client';

import { useState, useCallback, Suspense } from 'react';
import { useTasks, useTaskMutations, useToast, useTaskQuery, useAllTaskStats } from '@/hooks';
import {
  TaskFilterTabs,
  TaskList,
  TaskModal,
  DeleteConfirmModal,
  TaskSearchInput,
  TaskSortDropdown,
} from '@/components/tasks';
import type { TaskFormData } from '@/components/tasks';
import { Button, ToastContainer, TaskListSkeleton } from '@/components/ui';
import { FocusSummaryPanel } from '@/components/layout/FocusSummaryPanel';
import { ReflectionPanel } from '@/components/layout/ReflectionPanel';
import type { Task, ModalType, TaskFilter, SortField, SortOrder } from '@/types/task';

/**
 * Tasks page with Wow Layer panels
 * Feature: 006-ui-theme-motion (FR-044, FR-047, FR-049)
 *
 * - Focus Summary Panel with task stats (from ALL tasks, not filtered)
 * - Reflection Panel with motivational text
 * - Responsive: panels beside list on lg+, stacked below on <lg
 */
function TasksPageContent() {
  // URL-synced query state - this is the source of truth
  const { query, setStatus, setSearch, setSortAndOrder } = useTaskQuery();

  // Refresh trigger for stats - increments when tasks are mutated
  const [statsRefreshTrigger, setStatsRefreshTrigger] = useState(0);

  // Task list state - controlled by URL query values (single source of truth)
  const {
    tasks,
    isLoading,
    isLoadingMore,
    error,
    hasMore,
    highlightedTaskId,
    filter,
    search,
    sort,
    order,
    loadMore,
    refresh,
    addTask,
    updateTaskInList,
    removeTask,
    highlightTask,
  } = useTasks({
    // Controlled mode - URL is the source of truth
    filter: query.status,
    search: query.search,
    sort: query.sort,
    order: query.order,
  });

  // Handle filter change - update URL only
  const handleFilterChange = useCallback((newFilter: TaskFilter) => {
    setStatus(newFilter);
  }, [setStatus]);

  // Handle search change - update URL only
  const handleSearchChange = useCallback((newSearch: string) => {
    setSearch(newSearch);
  }, [setSearch]);

  // Handle sort change - update URL only
  const handleSortChange = useCallback((newSort: SortField, newOrder: SortOrder) => {
    setSortAndOrder(newSort, newOrder);
  }, [setSortAndOrder]);

  // Task mutations
  const {
    isCreating,
    createErrors,
    handleCreate,
    clearCreateErrors,
    isUpdating,
    updateErrors,
    handleUpdate,
    clearUpdateErrors,
    isDeleting,
    deleteError,
    handleDelete,
    clearDeleteError,
    togglingTaskId,
    handleToggleStatus,
  } = useTaskMutations();

  // Toast notifications
  const { toasts, removeToast, success, error: showError } = useToast();

  // Modal state
  const [modalType, setModalType] = useState<ModalType>(null);
  const [selectedTask, setSelectedTask] = useState<Task | null>(null);

  // Open create modal
  const openCreateModal = useCallback(() => {
    clearCreateErrors();
    setSelectedTask(null);
    setModalType('create');
  }, [clearCreateErrors]);

  // Open edit modal
  const openEditModal = useCallback(
    (task: Task) => {
      clearUpdateErrors();
      setSelectedTask(task);
      setModalType('edit');
    },
    [clearUpdateErrors]
  );

  // Open delete modal
  const openDeleteModal = useCallback(
    (task: Task) => {
      clearDeleteError();
      setSelectedTask(task);
      setModalType('delete');
    },
    [clearDeleteError]
  );

  // Close modal
  const closeModal = useCallback(() => {
    setModalType(null);
    setSelectedTask(null);
  }, []);

  // Trigger stats refresh
  const refreshStats = useCallback(() => {
    setStatsRefreshTrigger(prev => prev + 1);
  }, []);

  // Handle create task submission
  const handleCreateSubmit = useCallback(
    async (data: TaskFormData) => {
      const task = await handleCreate({
        title: data.title,
        description: data.description || undefined,
      });

      if (task) {
        addTask(task);
        highlightTask(task.id);
        closeModal();
        success('Task created successfully');
        refreshStats(); // Refresh stats after create
      }
    },
    [handleCreate, addTask, highlightTask, closeModal, success, refreshStats]
  );

  // Handle edit task submission
  const handleEditSubmit = useCallback(
    async (data: TaskFormData) => {
      if (!selectedTask) return;

      const task = await handleUpdate(selectedTask.id, {
        title: data.title,
        description: data.description || null,
        status: data.status,
      });

      if (task) {
        updateTaskInList(task);
        closeModal();
        success('Task updated successfully');
        refreshStats(); // Refresh stats after update
      }
    },
    [selectedTask, handleUpdate, updateTaskInList, closeModal, success, refreshStats]
  );

  // Handle delete confirmation
  const handleDeleteConfirm = useCallback(async () => {
    if (!selectedTask) return;

    const deleted = await handleDelete(selectedTask.id);

    if (deleted) {
      removeTask(selectedTask.id);
      closeModal();
      success('Task deleted successfully');
      refreshStats(); // Refresh stats after delete
    }
  }, [selectedTask, handleDelete, removeTask, closeModal, success, refreshStats]);

  // Handle status toggle
  const handleStatusToggle = useCallback(
    async (task: Task) => {
      const updatedTask = await handleToggleStatus(task);

      if (updatedTask) {
        updateTaskInList(updatedTask);
        const message =
          updatedTask.status === 'completed'
            ? 'Task marked as completed'
            : 'Task marked as pending';
        success(message);
        refreshStats(); // Refresh stats after toggle
      } else {
        showError('Failed to update task status');
      }
    },
    [handleToggleStatus, updateTaskInList, success, showError, refreshStats]
  );

  // Fetch ALL tasks stats (not filtered) - refreshes when tasks are mutated
  const allStats = useAllTaskStats(statsRefreshTrigger);

  // Convert to TaskStats format for panels
  const stats = {
    pending: allStats.pending,
    completed: allStats.completed,
    total: allStats.total,
    percentage: allStats.percentage,
  };

  return (
    <div className="max-w-7xl mx-auto p-6">
      {/* Responsive grid: single column on mobile, 2 columns on lg+ */}
      <div className="grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6">
        {/* Main content column */}
        <div>
          {/* Header with title and add button */}
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-heading-lg font-semibold text-text-primary">
              My Tasks
            </h2>
            <Button onClick={openCreateModal}>
              <svg
                className="w-4 h-4 mr-2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                aria-hidden="true"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 4v16m8-8H4"
                />
              </svg>
              Add Task
            </Button>
          </div>

          {/* Filter tabs */}
          <TaskFilterTabs
            activeFilter={filter}
            onFilterChange={handleFilterChange}
            className="mb-4"
          />

          {/* Search and sort controls */}
          <div className="flex flex-col sm:flex-row gap-3 mb-6">
            <TaskSearchInput
              value={search}
              onChange={handleSearchChange}
              className="flex-1"
            />
            <TaskSortDropdown
              sort={sort}
              order={order}
              onSortChange={handleSortChange}
              className="w-full sm:w-48"
            />
          </div>

          {/* Task list */}
          <TaskList
            tasks={tasks}
            filter={filter}
            isLoading={isLoading}
            isLoadingMore={isLoadingMore}
            error={error}
            hasMore={hasMore}
            highlightedTaskId={highlightedTaskId}
            togglingTaskId={togglingTaskId}
            onToggleStatus={handleStatusToggle}
            onEdit={openEditModal}
            onDelete={openDeleteModal}
            onLoadMore={loadMore}
            onRetry={refresh}
            onCreateTask={openCreateModal}
          />
        </div>

        {/* Sidebar panels - shown on right on lg+, stacked below on mobile */}
        <div className="space-y-4 lg:sticky lg:top-6 lg:self-start">
          <FocusSummaryPanel stats={stats} />
          <ReflectionPanel stats={stats} />
        </div>
      </div>

      {/* Create/Edit Modal */}
      <TaskModal
        isOpen={modalType === 'create' || modalType === 'edit'}
        mode={modalType === 'edit' ? 'edit' : 'create'}
        task={selectedTask}
        isSubmitting={modalType === 'edit' ? isUpdating : isCreating}
        errors={modalType === 'edit' ? updateErrors : createErrors}
        onSubmit={modalType === 'edit' ? handleEditSubmit : handleCreateSubmit}
        onClose={closeModal}
      />

      {/* Delete Confirmation Modal */}
      <DeleteConfirmModal
        isOpen={modalType === 'delete'}
        task={selectedTask}
        isDeleting={isDeleting}
        error={deleteError}
        onConfirm={handleDeleteConfirm}
        onCancel={closeModal}
      />

      {/* Toast notifications */}
      <ToastContainer toasts={toasts} onDismiss={removeToast} />
    </div>
  );
}

/**
 * Tasks page - main task list view with CRUD operations
 */
export default function TasksPage() {
  return (
    <Suspense
      fallback={
        <div className="max-w-7xl mx-auto p-6">
          <div className="grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6">
            {/* Main content skeleton */}
            <div>
              {/* Header skeleton */}
              <div className="flex items-center justify-between mb-6">
                <div className="h-8 w-32 bg-background-surface rounded animate-pulse" />
                <div className="h-10 w-28 bg-background-surface rounded animate-pulse" />
              </div>
              {/* Tabs skeleton */}
              <div className="h-10 w-64 bg-background-surface rounded animate-pulse mb-6" />
              {/* Task list skeleton */}
              <div className="bg-background-elevated rounded-lg border border-border-subtle overflow-hidden">
                <TaskListSkeleton count={5} />
              </div>
            </div>
            {/* Sidebar skeleton */}
            <div className="space-y-4">
              <div className="bg-background-elevated border border-border-subtle rounded-lg p-4 h-48 animate-pulse" />
              <div className="bg-background-elevated border border-border-subtle rounded-lg p-4 h-24 animate-pulse" />
            </div>
          </div>
        </div>
      }
    >
      <TasksPageContent />
    </Suspense>
  );
}
