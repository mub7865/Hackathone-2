/**
 * useWebSocket hook for real-time task updates.
 *
 * This hook manages WebSocket connection to receive real-time updates
 * about task changes, reminders, and system messages.
 */

'use client';

import { useEffect, useRef, useState, useCallback } from 'react';

export interface TaskEvent {
  type: 'task_event';
  event: 'created' | 'updated' | 'deleted' | 'completed';
  task_id: string;
  data: any;
}

export interface ReminderEvent {
  type: 'reminder';
  task_id: string;
  data: any;
}

export interface SystemMessage {
  type: 'system';
  message: string;
}

export interface ConnectedMessage {
  type: 'connected';
  message: string;
  connection_id: string;
}

export interface PingMessage {
  type: 'ping';
}

export type WebSocketMessage =
  | TaskEvent
  | ReminderEvent
  | SystemMessage
  | ConnectedMessage
  | PingMessage;

export interface UseWebSocketOptions {
  url?: string;
  token?: string;
  autoConnect?: boolean;
  reconnectInterval?: number;
  maxReconnectAttempts?: number;
  onTaskEvent?: (event: TaskEvent) => void;
  onReminder?: (event: ReminderEvent) => void;
  onSystemMessage?: (message: SystemMessage) => void;
  onConnected?: (connectionId: string) => void;
  onDisconnected?: () => void;
  onError?: (error: Event) => void;
}

export interface UseWebSocketReturn {
  isConnected: boolean;
  connectionId: string | null;
  connect: () => void;
  disconnect: () => void;
  reconnect: () => void;
  sendMessage: (message: any) => void;
}

export default function useWebSocket({
  url = process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:8000/api/v1/ws',
  token,
  autoConnect = true,
  reconnectInterval = 5000,
  maxReconnectAttempts = 10,
  onTaskEvent,
  onReminder,
  onSystemMessage,
  onConnected,
  onDisconnected,
  onError,
}: UseWebSocketOptions = {}): UseWebSocketReturn {
  const [isConnected, setIsConnected] = useState(false);
  const [connectionId, setConnectionId] = useState<string | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectAttemptsRef = useRef(0);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const shouldReconnectRef = useRef(true);

  const connect = useCallback(() => {
    if (!token) {
      console.warn('WebSocket: No token provided, cannot connect');
      return;
    }

    if (wsRef.current?.readyState === WebSocket.OPEN) {
      console.log('WebSocket: Already connected');
      return;
    }

    try {
      // Build WebSocket URL with token
      const wsUrl = `${url}?token=${encodeURIComponent(token)}`;
      const ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        console.log('WebSocket: Connected');
        setIsConnected(true);
        reconnectAttemptsRef.current = 0;
      };

      ws.onmessage = (event) => {
        try {
          const message: WebSocketMessage = JSON.parse(event.data);

          switch (message.type) {
            case 'connected':
              setConnectionId(message.connection_id);
              onConnected?.(message.connection_id);
              break;

            case 'ping':
              // Respond to ping with pong
              ws.send(JSON.stringify({ type: 'pong' }));
              break;

            case 'task_event':
              onTaskEvent?.(message);
              break;

            case 'reminder':
              onReminder?.(message);
              break;

            case 'system':
              onSystemMessage?.(message);
              break;

            default:
              console.log('WebSocket: Unknown message type', message);
          }
        } catch (error) {
          console.error('WebSocket: Error parsing message', error);
        }
      };

      ws.onerror = (error) => {
        console.error('WebSocket: Error', error);
        onError?.(error);
      };

      ws.onclose = () => {
        console.log('WebSocket: Disconnected');
        setIsConnected(false);
        setConnectionId(null);
        onDisconnected?.();

        // Attempt reconnection if enabled
        if (
          shouldReconnectRef.current &&
          reconnectAttemptsRef.current < maxReconnectAttempts
        ) {
          reconnectAttemptsRef.current++;
          console.log(
            `WebSocket: Reconnecting (attempt ${reconnectAttemptsRef.current}/${maxReconnectAttempts})...`
          );

          reconnectTimeoutRef.current = setTimeout(() => {
            connect();
          }, reconnectInterval);
        } else if (reconnectAttemptsRef.current >= maxReconnectAttempts) {
          console.error('WebSocket: Max reconnection attempts reached');
        }
      };

      wsRef.current = ws;
    } catch (error) {
      console.error('WebSocket: Connection error', error);
    }
  }, [
    url,
    token,
    reconnectInterval,
    maxReconnectAttempts,
    onTaskEvent,
    onReminder,
    onSystemMessage,
    onConnected,
    onDisconnected,
    onError,
  ]);

  const disconnect = useCallback(() => {
    shouldReconnectRef.current = false;

    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
      reconnectTimeoutRef.current = null;
    }

    if (wsRef.current) {
      wsRef.current.close();
      wsRef.current = null;
    }

    setIsConnected(false);
    setConnectionId(null);
  }, []);

  const reconnect = useCallback(() => {
    disconnect();
    shouldReconnectRef.current = true;
    reconnectAttemptsRef.current = 0;
    setTimeout(() => connect(), 100);
  }, [connect, disconnect]);

  const sendMessage = useCallback((message: any) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(message));
    } else {
      console.warn('WebSocket: Cannot send message, not connected');
    }
  }, []);

  // Auto-connect on mount if enabled
  useEffect(() => {
    if (autoConnect && token) {
      connect();
    }

    // Cleanup on unmount
    return () => {
      shouldReconnectRef.current = false;
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, [autoConnect, token, connect]);

  return {
    isConnected,
    connectionId,
    connect,
    disconnect,
    reconnect,
    sendMessage,
  };
}

/**
 * useTaskUpdates hook for handling real-time task updates.
 *
 * This is a convenience hook that wraps useWebSocket and provides
 * task-specific event handlers.
 */
export function useTaskUpdates(
  token: string | undefined,
  onTaskUpdate: (event: TaskEvent) => void
) {
  return useWebSocket({
    token,
    autoConnect: !!token,
    onTaskEvent: onTaskUpdate,
    onReminder: (event) => {
      console.log('Reminder:', event);
      // Could show a notification here
    },
    onSystemMessage: (message) => {
      console.log('System message:', message.message);
      // Could show a toast notification here
    },
  });
}
