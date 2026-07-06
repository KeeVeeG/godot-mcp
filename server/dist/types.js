/**
 * TypeScript types for Godot MCP Server
 *
 * Shared Zod schemas and tool-result helpers live in tools/shared-types.ts.
 * This file re-exports them for backward compatibility.
 */
export { toolResult, errorResult } from './tools/shared-types.js';
/** @deprecated Use toolResult() from tools/shared-types.ts */
export function createToolResult(text) {
  return {
    content: [{ type: 'text', text }],
  };
}
/** @deprecated Use errorResult() from tools/shared-types.ts */
export function createErrorResult(message) {
  return {
    content: [{ type: 'text', text: message }],
    isError: true,
  };
}
/** Standard error codes for JSON-RPC */
export const JsonRpcErrorCode = {
  PARSE_ERROR: -32700,
  INVALID_REQUEST: -32600,
  METHOD_NOT_FOUND: -32601,
  INVALID_PARAMS: -32602,
  INTERNAL_ERROR: -32603,
};
/** Type guard for JSON-RPC success response */
export function isSuccessResponse(response) {
  return 'result' in response;
}
/** Type guard for JSON-RPC error response */
export function isErrorResponse(response) {
  return 'error' in response;
}
//# sourceMappingURL=types.js.map
