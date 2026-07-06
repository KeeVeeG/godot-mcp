/**
 * WebSocket bridge for communicating with Godot EditorPlugin
 *
 * Godot connects as a WebSocket CLIENT to this server.
 * Uses JSON-RPC 2.0 for message format.
 */

import { WebSocketServer, WebSocket } from 'ws';
import { randomUUID } from 'node:crypto';
import { WS_BASE_PORT, MAX_SESSIONS, REQUEST_TIMEOUT_MS, PING_INTERVAL_MS, PING_TIMEOUT_MS, MAX_MESSAGE_SIZE, JSONRPC_VERSION } from './config.js';
import type { JsonRpcRequest, JsonRpcResponse, JsonRpcNotification, JsonRpcErrorResponse, PendingRequest, ConnectionState } from './types.js';
import { isSuccessResponse, isErrorResponse } from './types.js';

/** Logger helper */
function log(level: 'info' | 'warn' | 'error' | 'debug', message: string, ...args: unknown[]): void {
  const timestamp = new Date().toISOString();
  const prefix = `[GodotBridge ${timestamp}]`;
  switch (level) {
    case 'error':
      console.error(prefix, message, ...args);
      break;
    case 'warn':
      console.warn(prefix, message, ...args);
      break;
    case 'debug':
      // Only log debug in development
      if (process.env.GODOT_MCP_DEBUG) {
        console.error(prefix, message, ...args);
      }
      break;
    default:
      console.error(prefix, message, ...args);
  }
}

/**
 * WebSocket bridge that manages communication with Godot EditorPlugin.
 *
 * The bridge starts a WebSocket server that Godot connects to.
 * Each tool request is forwarded as a JSON-RPC 2.0 call.
 */
export class GodotBridge {
  private wss: WebSocketServer | null = null;
  private client: WebSocket | null = null;
  private port: number;
  private state: ConnectionState = 'disconnected';
  private pendingRequests: Map<string | number, PendingRequest> = new Map();
  private pingInterval: ReturnType<typeof setInterval> | null = null;
  private lastPongTime: number = 0;
  private requestIdCounter: number = 0;

  constructor(port: number = WS_BASE_PORT) {
    this.port = port;
  }

  /**
   * Start the WebSocket server, trying ports 6505-6514 if busy.
   */
  async start(): Promise<number> {
    for (let portOffset = 0; portOffset < MAX_SESSIONS; portOffset++) {
      const tryPort = this.port + portOffset;
      const success = await this.tryListen(tryPort);
      if (success) {
        this.port = tryPort;
        log('info', `Listening on port ${tryPort}`);
        return tryPort;
      }
    }
    throw new Error(`Failed to bind to any port in range ${WS_BASE_PORT}-${WS_BASE_PORT + MAX_SESSIONS - 1}`);
  }

  /**
   * Try to listen on a specific port.
   */
  private tryListen(port: number): Promise<boolean> {
    return new Promise((resolve) => {
      const wss = new WebSocketServer({
        port,
        maxPayload: MAX_MESSAGE_SIZE,
      });

      wss.on('listening', () => {
        this.wss = wss;
        this.setupServer(wss);
        resolve(true);
      });

      wss.on('error', (err: NodeJS.ErrnoException) => {
        if (err.code === 'EADDRINUSE') {
          log('debug', `Port ${port} is busy`);
          resolve(false);
        } else {
          log('error', `Server error on port ${port}:`, err.message);
          resolve(false);
        }
      });
    });
  }

  /**
   * Set up the WebSocket server event handlers.
   */
  private setupServer(wss: WebSocketServer): void {
    wss.on('connection', (ws: WebSocket) => {
      // Only allow one client at a time
      if (this.client && this.client.readyState === WebSocket.OPEN) {
        log('warn', 'Rejecting new client - one client already connected');
        ws.close(1013, 'Another client is already connected');
        return;
      }

      this.client = ws;
      this.state = 'connected';
      this.lastPongTime = Date.now();
      log('info', 'Godot editor connected');

      this.setupClientHandlers(ws);
      this.startPingInterval(ws);
    });

    wss.on('error', (err: Error) => {
      log('error', 'WebSocket server error:', err.message);
    });
  }

  /**
   * Set up event handlers for a connected client.
   */
  private setupClientHandlers(ws: WebSocket): void {
    ws.on('message', (data: Buffer) => {
      this.handleMessage(data);
    });

    ws.on('close', (code: number, reason: Buffer) => {
      log('info', `Godot editor disconnected (code: ${code}, reason: ${reason.toString()})`);
      this.cleanup();
    });

    ws.on('error', (err: Error) => {
      log('error', 'Client WebSocket error:', err.message);
    });

    ws.on('pong', () => {
      this.lastPongTime = Date.now();
    });
  }

  /**
   * Start the ping/pong keepalive interval.
   */
  private startPingInterval(ws: WebSocket): void {
    this.stopPingInterval();

    this.pingInterval = setInterval(() => {
      if (ws.readyState !== WebSocket.OPEN) {
        this.stopPingInterval();
        return;
      }

      // Check if last pong was too long ago
      const timeSinceLastPong = Date.now() - this.lastPongTime;
      if (timeSinceLastPong > PING_INTERVAL_MS + PING_TIMEOUT_MS) {
        log('warn', 'No pong received, closing connection');
        ws.terminate();
        return;
      }

      ws.ping();
    }, PING_INTERVAL_MS);
  }

  /**
   * Stop the ping interval.
   */
  private stopPingInterval(): void {
    if (this.pingInterval) {
      clearInterval(this.pingInterval);
      this.pingInterval = null;
    }
  }

  /**
   * Handle an incoming WebSocket message.
   */
  private handleMessage(data: Buffer): void {
    let message: JsonRpcResponse | JsonRpcNotification;
    try {
      message = JSON.parse(data.toString()) as JsonRpcResponse | JsonRpcNotification;
    } catch {
      log('error', 'Failed to parse message as JSON');
      return;
    }

    // Check if this is a response to a pending request
    if ('id' in message && message.id !== undefined && message.id !== null) {
      const pending = this.pendingRequests.get(message.id as string | number);
      if (pending) {
        this.pendingRequests.delete(message.id as string | number);
        clearTimeout(pending.timer);

        const response = message as JsonRpcResponse;
        if (isSuccessResponse(response)) {
          log('debug', `Response for ${pending.method}: success`);
          pending.resolve(response.result);
        } else if (isErrorResponse(response)) {
          const err = response as JsonRpcErrorResponse;
          const error = new Error(err.error.message);
          (error as Error & { code?: number; data?: unknown }).code = err.error.code;
          (error as Error & { code?: number; data?: unknown }).data = err.error.data;
          log('debug', `Response for ${pending.method}: error - ${err.error.message}`);
          pending.reject(error);
        }
        return;
      }
    }

    // Otherwise it might be a notification from Godot (e.g., scene_changed)
    log('debug', 'Received notification:', message);
  }

  /**
   * Send a JSON-RPC 2.0 request to Godot and wait for a response.
   */
  async sendRequest(method: string, params: Record<string, unknown> = {}): Promise<unknown> {
    if (!this.client || this.client.readyState !== WebSocket.OPEN) {
      throw new Error('Godot editor is not connected');
    }

    const id = `mcp_${++this.requestIdCounter}_${randomUUID().slice(0, 8)}`;

    const request: JsonRpcRequest = {
      jsonrpc: JSONRPC_VERSION,
      id,
      method,
      params,
    };

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pendingRequests.delete(id);
        reject(new Error(`Request ${method} timed out after ${REQUEST_TIMEOUT_MS}ms`));
      }, REQUEST_TIMEOUT_MS);

      this.pendingRequests.set(id, {
        id,
        method,
        resolve,
        reject,
        timer,
      });

      const message = JSON.stringify(request);
      log('debug', `Sending request: ${method} (id: ${id})`);

      this.client!.send(message, (err) => {
        if (err) {
          this.pendingRequests.delete(id);
          clearTimeout(timer);
          reject(new Error(`Failed to send request: ${err.message}`));
        }
      });
    });
  }

  /**
   * Send a JSON-RPC 2.0 notification (no response expected).
   */
  sendNotification(method: string, params: Record<string, unknown> = {}): void {
    if (!this.client || this.client.readyState !== WebSocket.OPEN) {
      log('warn', `Cannot send notification ${method}: Godot not connected`);
      return;
    }

    const notification: JsonRpcNotification = {
      jsonrpc: JSONRPC_VERSION,
      method,
      params,
    };

    this.client.send(JSON.stringify(notification));
  }

  /**
   * Clean up connection state.
   */
  private cleanup(): void {
    this.state = 'disconnected';
    this.client = null;
    this.stopPingInterval();

    // Reject all pending requests
    for (const [, pending] of this.pendingRequests) {
      clearTimeout(pending.timer);
      pending.reject(new Error('Connection closed'));
    }
    this.pendingRequests.clear();
  }

  /**
   * Get the current connection state.
   */
  getState(): ConnectionState {
    return this.state;
  }

  /**
   * Check if a Godot client is connected.
   */
  isConnected(): boolean {
    return this.client !== null && this.client.readyState === WebSocket.OPEN;
  }

  /**
   * Get the port the server is listening on.
   */
  getPort(): number {
    return this.port;
  }

  /**
   * Shut down the bridge and close all connections.
   */
  async shutdown(): Promise<void> {
    log('info', 'Shutting down bridge...');
    this.cleanup();

    if (this.wss) {
      await new Promise<void>((resolve) => {
        this.wss!.close(() => {
          this.wss = null;
          resolve();
        });
      });
    }
  }
}
