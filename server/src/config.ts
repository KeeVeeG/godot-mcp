/**
 * Godot MCP Server Configuration
 */

/** Base port for WebSocket connections */
export const WS_BASE_PORT = 6505;

/** Maximum number of concurrent AI sessions (ports 6505-6514) */
export const MAX_SESSIONS = 10;

/** Request timeout in milliseconds */
export const REQUEST_TIMEOUT_MS = 30_000;

/** Ping interval for WebSocket keepalive in milliseconds */
export const PING_INTERVAL_MS = 30_000;

/** Ping timeout - disconnect if no pong received within this time */
export const PING_TIMEOUT_MS = 15_000;

/** Maximum message size in bytes (10MB) */
export const MAX_MESSAGE_SIZE = 10 * 1024 * 1024;

/** Server version */
export const SERVER_VERSION = '1.0.17';

/** Server name for MCP identification */
export const SERVER_NAME = 'godot-mcp';

/** JSON-RPC version used for communication */
export const JSONRPC_VERSION = '2.0' as const;

/** Reconnect delay in milliseconds */
export const RECONNECT_DELAY_MS = 1_000;

/** Maximum reconnection attempts */
export const MAX_RECONNECT_ATTEMPTS = 5;

/** Log level configuration */
export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

/** Current log level */
export const LOG_LEVEL: LogLevel = 'info';

/** Godot project detection */
import { existsSync } from 'fs';
import { resolve } from 'path';

/**
 * Check if the current working directory is a Godot project root.
 * A Godot project is identified by the presence of a `project.godot` file.
 */
export function isGodotProject(): boolean {
  return existsSync(resolve(process.cwd(), 'project.godot'));
}
