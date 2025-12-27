/**
 * Base API client with JWT injection and error handling
 * Provides typed fetch wrapper for backend API calls
 */




import { ApiError, isValidationError, type ProblemDetail, type RequestOptions } from '@/types/api';
import { getAccessToken } from '@/lib/auth/client';

// API base URL from environment
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

/**
 * Make an authenticated API request
 */
export async function apiRequest<T>(
  endpoint: string,
  options: RequestOptions = {}
): Promise<T> {
  const { method = 'GET', body, headers = {} } = options;

  // Get auth token
  const token = await getAccessToken();

  // Build request headers
  const requestHeaders: Record<string, string> = {
    'Content-Type': 'application/json',
    ...headers,
  };

  // Add Authorization header if token exists
  if (token) {
    requestHeaders['Authorization'] = `Bearer ${token}`;
  }

  // Build fetch options
  const fetchOptions: RequestInit = {
    method,
    headers: requestHeaders,
  };

  // Add body for non-GET requests
  if (body && method !== 'GET') {
    fetchOptions.body = JSON.stringify(body);
  }

  // Make the request
  const response = await fetch(`${API_BASE_URL}${endpoint}`, fetchOptions);

  // Handle 204 No Content (e.g., DELETE success)
  if (response.status === 204) {
    return undefined as T;
  }

  // Parse response body
  const responseBody = await response.text();
  let data: unknown;

  try {
    data = responseBody ? JSON.parse(responseBody) : null;
  } catch {
    // If response isn't JSON, treat as generic error
    if (!response.ok) {
      throw new ApiError({
        type: 'about:blank',
        title: 'Request Failed',
        status: response.status,
        detail: responseBody || 'An unexpected error occurred',
      });
    }
    return responseBody as T;
  }

  // Handle error responses
  if (!response.ok) {
    // Check if response follows RFC 7807 Problem Details
    const problemDetail = data as ProblemDetail;
    if (problemDetail && typeof problemDetail.status === 'number') {
      throw new ApiError(problemDetail);
    }

    // Fallback for non-standard error responses
    throw new ApiError({
      type: 'about:blank',
      title: 'Request Failed',
      status: response.status,
      detail: typeof data === 'object' && data !== null && 'message' in data
        ? String((data as { message: unknown }).message)
        : 'An unexpected error occurred',
    });
  }

  return data as T;
}

/**
 * Extract field errors from validation error
 */
export function extractFieldErrors(error: ApiError): Record<string, string> {
  const errors: Record<string, string> = {};

  if (isValidationError(error.problemDetail)) {
    for (const item of error.problemDetail.errors) {
      // Get the field name from the location path
      const field = item.loc[item.loc.length - 1];
      if (typeof field === 'string') {
        errors[field] = item.msg;
      }
    }
  }

  return errors;
}

/**
 * Get user-friendly error message
 */
export function getErrorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    return error.problemDetail.detail || error.problemDetail.title;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return 'An unexpected error occurred';
}

/**
 * Check if error is an authentication error (401)
 */
export function isAuthError(error: unknown): boolean {
  return error instanceof ApiError && error.status === 401;
}

/**
 * Check if error is a not found error (404)
 */
export function isNotFoundError(error: unknown): boolean {
  return error instanceof ApiError && error.status === 404;
}

/**
 * Check if error is a validation error (422)
 */
export function isValidationApiError(error: unknown): boolean {
  return error instanceof ApiError && error.status === 422;
}
