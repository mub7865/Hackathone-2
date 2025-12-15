/**
 * Standard API client for Next.js 16+ App Router frontends.
 *
 * PURPOSE:
 * - Provide a single place for HTTP configuration (base URL, headers).
 * - Enforce typed requests and responses.
 * - Centralize error handling instead of spreading try/catch everywhere.
 *
 * HOW TO USE:
 * - Import specific functions (e.g. getTasks, createTask) from this module.
 * - Do not call fetch() directly from components unless there is a strong reason.
 * - Adapt the function names and types to your domain (Todo, Blog, Shop, etc.).
 */

export type ApiError = {
  message: string;
  status?: number;
  details?: unknown;
};

type HttpMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

export interface ApiClientOptions {
  baseUrl: string;
  getAuthToken?: () => Promise<string | null> | string | null;
}

/**
 * Creates a new API client instance with shared configuration.
 */
export function createApiClient(options: ApiClientOptions) {
  const { baseUrl, getAuthToken } = options;

  /**
   * Low-level request wrapper.
   * - Builds the full URL.
   * - Attaches JSON headers and optional auth token.
   * - Parses JSON responses.
   * - Normalizes errors into ApiError.
   */
  async function request<TResponse, TBody = unknown>(
    path: string,
    method: HttpMethod,
    body?: TBody,
    init?: RequestInit,
  ): Promise<TResponse> {
    const url = `${baseUrl.replace(/\/$/, "")}/${path.replace(/^\//, "")}`;

    let authHeader: Record<string, string> = {};
    if (getAuthToken) {
      const token = await getAuthToken();
      if (token) {
        authHeader = {
          Authorization: `Bearer ${token}`,
        };
      }
    }

    const headers: HeadersInit = {
      "Content-Type": "application/json",
      ...authHeader,
      ...(init?.headers ?? {}),
    };

    const response = await fetch(url, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
      ...init,
    });

    const isJson =
      response.headers.get("content-type")?.includes("application/json") ?? false;

    if (!response.ok) {
      let details: unknown = undefined;

      if (isJson) {
        try {
          details = await response.json();
        } catch {
          // ignore JSON parse errors in error paths
        }
      } else {
        try {
          details = await response.text();
        } catch {
          // ignore text parse errors in error paths
        }
      }

      const error: ApiError = {
        message: (details as any)?.message ?? "Request failed",
        status: response.status,
        details,
      };
      throw error;
    }

    if (!isJson) {
      // If the caller expects non-JSON, they should adjust this behaviour.
      // For now, assume JSON for simplicity.
      return (undefined as unknown) as TResponse;
    }

    return (await response.json()) as TResponse;
  }

  // Example higher-level functions (adjust or replace with real endpoints):

  async function getExampleList<TItem = unknown>(): Promise<TItem[]> {
    return request<TItem[]>("/api/example", "GET");
  }

  async function createExample<TBody = unknown, TResponse = unknown>(
    body: TBody,
  ): Promise<TResponse> {
    return request<TResponse, TBody>("/api/example", "POST", body);
  }

  return {
    request,
    getExampleList,
    createExample,
  };
}
