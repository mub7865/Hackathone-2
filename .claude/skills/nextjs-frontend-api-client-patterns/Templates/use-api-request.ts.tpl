/**
 * Generic React hook for calling the shared API client from client components.
 *
 * PURPOSE:
 * - Provide a standard pattern for loading / error / data state.
 * - Keep components thin by delegating networking concerns to this hook.
 *
 * HOW TO USE:
 * - Import the `api` instance (created via createApiClient) into this module.
 * - Export domain-specific hooks (e.g. useTasks, useUserProfile) that
 *   internally call `call`.
 *
 * NOTE:
 * - This template assumes a React environment (Next.js client components).
 * - Mark the file or the consuming components with `"use client"` as needed.
 */

"use client";

import { useCallback, useState } from "react";
import type { ApiError } from "./api-client"; // adjust path as needed

type AsyncFn<TArgs extends any[], TResult> = (...args: TArgs) => Promise<TResult>;

export interface UseApiRequestState<TResult> {
  loading: boolean;
  error: ApiError | null;
  data: TResult | null;
}

export interface UseApiRequestReturn<TArgs extends any[], TResult> {
  state: UseApiRequestState<TResult>;
  call: AsyncFn<TArgs, TResult>;
  reset: () => void;
}

/**
 * Generic hook to wrap any async API function with loading/error/data state.
 */
export function useApiRequest<TArgs extends any[], TResult>(
  fn: AsyncFn<TArgs, TResult>,
): UseApiRequestReturn<TArgs, TResult> {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [data, setData] = useState<TResult | null>(null);

  const call: AsyncFn<TArgs, TResult> = useCallback(
    async (...args: TArgs) => {
      setLoading(true);
      setError(null);

      try {
        const result = await fn(...args);
        setData(result);
        return result;
      } catch (err: any) {
        const apiError: ApiError = {
          message: err?.message ?? "Request failed",
          status: err?.status,
          details: err?.details,
        };
        setError(apiError);
        throw apiError;
      } finally {
        setLoading(false);
      }
    },
    [fn],
  );

  const reset = useCallback(() => {
    setLoading(false);
    setError(null);
    setData(null);
  }, []);

  return {
    state: { loading, error, data },
    call,
    reset,
  };
}

/**
 * EXAMPLE: Domain-specific hook (adjust to your project)
 *
 * import { api } from "@/lib/api";
 *
 * export function useTasks() {
 *   const { state, call, reset } = useApiRequest(api.getTasks);
 *   return { ...state, getTasks: call, reset };
 * }
 */
