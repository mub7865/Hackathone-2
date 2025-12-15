/**
 * Standard Express error-handling middleware using Problem Details (RFC 7807).
 *
 * PURPOSE:
 * - Provide a centralized, consistent JSON error format for all Express REST APIs.
 * - Follow the (err, req, res, next) signature required by Express for error middleware.
 * - Emit `application/problem+json` responses with RFC 7807-style fields.
 *
 * HOW TO USE:
 * 1. Save as something like: src/middleware/problemDetailsErrorHandler.js
 * 2. Register AFTER all routes in your Express app, e.g. in app.js / server.js:
 *
 *    const express = require("express");
 *    const problemDetailsErrorHandler = require("./middleware/problemDetailsErrorHandler");
 *
 *    const app = express();
 *    // ... all routes, other middleware ...
 *    app.use(problemDetailsErrorHandler); // must be last
 *
 * 3. In routes/middleware, throw errors or call next(err).
 *    - You can attach `statusCode` or `status` and `type` to errors
 *      to customize the response.
 */

function buildProblemDetails(options) {
  const {
    statusCode,
    title,
    detail,
    instance,
    typeUri = "https://example.com/errors/generic-error",
    errors,
  } = options;

  const problem = {
    type: typeUri,
    title,
    status: statusCode,
    detail,
    instance,
  };

  if (Array.isArray(errors) && errors.length > 0) {
    problem.errors = errors;
  }

  return problem;
}

/**
 * Express global error-handling middleware (must have 4 args).
 * Place this AFTER all other routes and middleware.
 */
function problemDetailsErrorHandler(err, req, res, next) {
  // In case some other middleware already started sending a response
  if (res.headersSent) {
    return next(err);
  }

  // Derive HTTP status
  const statusCode =
    err.statusCode ||
    err.status ||
    (err.name === "ValidationError" ? 422 : 500);

  // Generic titles per status
  const title = titleForStatus(statusCode);

  // Prefer explicit message/detail when available
  const detail =
    typeof err.detail === "string"
      ? err.detail
      : typeof err.message === "string"
      ? err.message
      : "An unexpected error occurred.";

  const instance = req.originalUrl || req.url || "";

  // Optional: field-level validation errors if attached to error
  // e.g. err.errors = [{ field: "title", message: "Title is required." }]
  const fieldErrors = Array.isArray(err.errors) ? err.errors : undefined;

  const typeUri = err.type || typeUriForStatus(statusCode);

  const problem = buildProblemDetails({
    statusCode,
    title,
    detail,
    instance,
    typeUri,
    errors: fieldErrors,
  });

  res
    .status(statusCode)
    .type("application/problem+json")
    .json(problem);
}

/**
 * Map common HTTP status codes to human-readable titles.
 */
function titleForStatus(statusCode) {
  const mapping = {
    400: "Bad Request",
    401: "Unauthorized",
    403: "Forbidden",
    404: "Not Found",
    409: "Conflict",
    422: "Unprocessable Entity",
    500: "Internal Server Error",
  };
  return mapping[statusCode] || "Error";
}

/**
 * Map status codes to default type URIs.
 * Projects can override per-error by setting err.type.
 */
function typeUriForStatus(statusCode) {
  const base = "https://example.com/errors";
  const mapping = {
    400: `${base}/bad-request`,
    401: `${base}/unauthorized`,
    403: `${base}/forbidden`,
    404: `${base}/not-found`,
    409: `${base}/conflict`,
    422: `${base}/validation-error`,
    500: `${base}/internal-server-error`,
  };
  return mapping[statusCode] || `${base}/generic-error`;
}

module.exports = problemDetailsErrorHandler;
