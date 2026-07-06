/**
 * TypeScript types for Godot MCP Server
 *
 * Shared Zod schemas and tool-result helpers live in tools/shared-types.ts.
 * This file re-exports them for backward compatibility.
 */

// Re-export shared tool types so existing consumers keep working
export type { ToolContent, ToolResult } from './tools/shared-types.js';
export { toolResult, errorResult } from './tools/shared-types.js';

// Backward-compat aliases for functions that existed here previously
import type { ToolResult } from './tools/shared-types.js';

/** @deprecated Use toolResult() from tools/shared-types.ts */
export function createToolResult(text: string): ToolResult {
  return {
    content: [{ type: 'text', text }],
  };
}

/** @deprecated Use errorResult() from tools/shared-types.ts */
export function createErrorResult(message: string): ToolResult {
  return {
    content: [{ type: 'text', text: message }],
    isError: true,
  };
}

// ────────────────────────────────────────────────────────────
// JSON-RPC types (not shared with tool modules)
// ────────────────────────────────────────────────────────────

/** JSON-RPC 2.0 Request */
export interface JsonRpcRequest {
  jsonrpc: '2.0';
  id: string | number;
  method: string;
  params?: Record<string, unknown>;
}

/** JSON-RPC 2.0 Success Response */
export interface JsonRpcSuccessResponse {
  jsonrpc: '2.0';
  id: string | number;
  result: unknown;
}

/** JSON-RPC 2.0 Error Response */
export interface JsonRpcErrorResponse {
  jsonrpc: '2.0';
  id: string | number | null;
  error: JsonRpcError;
}

/** JSON-RPC 2.0 Error object */
export interface JsonRpcError {
  code: number;
  message: string;
  data?: unknown;
}

/** JSON-RPC 2.0 Response (union) */
export type JsonRpcResponse = JsonRpcSuccessResponse | JsonRpcErrorResponse;

/** JSON-RPC 2.0 Notification (no id) */
export interface JsonRpcNotification {
  jsonrpc: '2.0';
  method: string;
  params?: Record<string, unknown>;
}

/** Any JSON-RPC message */
export type JsonRpcMessage = JsonRpcRequest | JsonRpcResponse | JsonRpcNotification;

/** Pending request tracking */
export interface PendingRequest {
  id: string | number;
  method: string;
  resolve: (value: unknown) => void;
  reject: (reason: Error) => void;
  timer: ReturnType<typeof setTimeout>;
}

/** Godot bridge connection state */
export type ConnectionState = 'disconnected' | 'connecting' | 'connected';

/** Bridge event types */
export interface BridgeEvents {
  connected: () => void;
  disconnected: () => void;
  error: (error: Error) => void;
}

/** Standard error codes for JSON-RPC */
export const JsonRpcErrorCode = {
  PARSE_ERROR: -32700,
  INVALID_REQUEST: -32600,
  METHOD_NOT_FOUND: -32601,
  INVALID_PARAMS: -32602,
  INTERNAL_ERROR: -32603,
} as const;

/** Type guard for JSON-RPC success response */
export function isSuccessResponse(response: JsonRpcResponse): response is JsonRpcSuccessResponse {
  return 'result' in response;
}

/** Type guard for JSON-RPC error response */
export function isErrorResponse(response: JsonRpcResponse): response is JsonRpcErrorResponse {
  return 'error' in response;
}
