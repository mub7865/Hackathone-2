/**
 * API response and error types
 * Based on RFC 7807 Problem Details
 */

import type { Task } from './task';

// RFC 7807 Problem Details base interface
export interface ProblemDetail {
  type: string;
  title: string;
  status: number;
  detail?: string;
  instance?: string;
}

// Validation error location
export interface ValidationErrorItem {
  loc: (string | number)[];
  msg: string;
  type: string;
}

// 422 Validation Error extension
export interface ValidationError extends ProblemDetail {
  errors: ValidationErrorItem[];
}

// Type guard for ValidationError
export function isValidationError(error: ProblemDetail): error is ValidationError {
  return 'errors' in error && Array.isArray((error as ValidationError).errors);
}

// API Response types
export type TaskListResponse = Task[];
export type TaskResponse = Task;

// Generic API error
export class ApiError extends Error {
  public readonly status: number;
  public readonly problemDetail: ProblemDetail;

  constructor(problemDetail: ProblemDetail) {
    super(problemDetail.detail || problemDetail.title);
    this.name = 'ApiError';
    this.status = problemDetail.status;
    this.problemDetail = problemDetail;
  }
}

// API client configuration
export interface ApiConfig {
  baseUrl: string;
  getToken: () => Promise<string | null>;
}

// Request options for API calls
export interface RequestOptions {
  method?: 'GET' | 'POST' | 'PATCH' | 'DELETE';
  body?: unknown;
  headers?: Record<string, string>;
}
