"use client";

import { useState, useEffect, useRef, useMemo } from "react";
import {
  Activity,
  Bot,
  Clock,
  DollarSign,
  Hash,
  MessageSquare,
  RefreshCw,
  Terminal,
  Wrench,
  Zap,
  Brain,
  AlertCircle,
  ChevronDown,
  Pause,
  Play,
} from "lucide-react";
import type {
  ManagedSession,
  StoreEvent,
  StoreEventType,
  SessionCostReport,
  SessionInfo,
} from "@aurion/core/types/managed-agents";
import { Button } from "@aurion/ui/components/ui/button";
import { Badge } from "@aurion/ui/components/ui/badge";
import { cn } from "@aurion/ui/lib/utils";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface SessionViewProps {
  session: ManagedSession;
  workspaceSlug: string;
  onBack?: () => void;
  apiBaseUrl?: string;
}

// ---------------------------------------------------------------------------
// Event type config
// ---------------------------------------------------------------------------

const eventTypeConfig: Record<
  StoreEventType,
  { icon: typeof MessageSquare; color: string; label: string }
> = {
  user_message: { icon: MessageSquare, color: "text-blue-500", label: "User" },
  assistant_message: { icon: Bot, color: "text-purple-500", label: "Assistant" },
  tool_call: { icon: Wrench, color: "text-amber-500", label: "Tool Call" },
  tool_result: { icon: Terminal, color: "text-green-500", label: "Tool Result" },
  context_reset: { icon: RefreshCw, color: "text-red-500", label: "Context Reset" },
  system_event: { icon: Zap, color: "text-gray-500", label: "System" },
  cost_event: { icon: DollarSign, color: "text-emerald-500", label: "Cost" },
  thinking: { icon: Brain, color: "text-pink-500", label: "Thinking" },
};

// ---------------------------------------------------------------------------
// SessionView — Main component
// ---------------------------------------------------------------------------

export function SessionView({ session, workspaceSlug, onBack, apiBaseUrl }: SessionViewProps) {
  const [events, setEvents] = useState<StoreEvent[]>([]);
  const [costReport, setCostReport] = useState<SessionCostReport | null>(null);
  const [sessionInfo, setSessionInfo] = useState<SessionInfo | null>(null);
  const [autoScroll, setAutoScroll] = useState(true);
  const [filterType, setFilterType] = useState<StoreEventType | "all">("all");
  const [loading, setLoading] = useState(true);
  const eventsEndRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const baseUrl = apiBaseUrl || "";

  // Fetch initial events
  useEffect(() => {
    async function fetchEvents() {
      try {
        const res = await fetch(`${baseUrl}/api/v1/sessions/${session.id}/store/events`);
        if (res.ok) {
          const data = await res.json();
          setEvents(data.events || []);
        }
      } catch {
        // ignore
      } finally {
        setLoading(false);
      }
    }

    async function fetchCost() {
      try {
        const res = await fetch(`${baseUrl}/api/v1/sessions/${session.id}/store/cost`);
        if (res.ok) {
          setCostReport(await res.json());
        }
      } catch {
        // ignore
      }
    }

    fetchEvents();
    fetchCost();
  }, [session.id, baseUrl]);

  // SSE streaming for real-time events
  useEffect(() => {
    if (session.status !== "running") return;

    const es = new EventSource(`${baseUrl}/api/v1/sessions/${session.id}/stream`);

    es.onmessage = (e) => {
      try {
        const data = JSON.parse(e.data);
        if (data.type === "session.event") {
          setEvents((prev) => [...prev, data as StoreEvent]);
        }
      } catch {
        // skip non-JSON messages
      }
    };

    es.onerror = () => {
      es.close();
    };

    return () => es.close();
  }, [session.id, session.status, baseUrl]);

  // Auto-scroll to bottom
  useEffect(() => {
    if (autoScroll && eventsEndRef.current) {
      eventsEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [events, autoScroll]);

  // Filter events
  const filteredEvents = useMemo(() => {
    if (filterType === "all") return events;
    return events.filter((e) => e.type === filterType);
  }, [events, filterType]);

  // Status badge
  const statusColor = {
    running: "bg-green-500",
    idle: "bg-gray-400",
    terminated: "bg-red-500",
    rescheduling: "bg-yellow-500",
  }[session.status] || "bg-gray-400";

  return (
    <div className="flex h-full flex-col">
      {/* Header */}
      <div className="flex items-center justify-between border-b px-4 py-3">
        <div className="flex items-center gap-3">
          {onBack && (
            <Button variant="ghost" size="sm" onClick={onBack}>
              ← Back
            </Button>
          )}
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-lg font-semibold">
                {session.title || `Session ${session.id.slice(0, 8)}`}
              </h2>
              <Badge className={cn("text-white", statusColor)}>
                {session.status}
              </Badge>
              {session.wake_count && session.wake_count > 0 && (
                <Badge variant="outline" className="text-xs">
                  <RefreshCw className="mr-1 h-3 w-3" />
                  Woke {session.wake_count}×
                </Badge>
              )}
            </div>
            <div className="flex items-center gap-4 text-xs text-muted-foreground mt-1">
              <span className="flex items-center gap-1">
                <Hash className="h-3 w-3" />
                {events.length} events
              </span>
              <span className="flex items-center gap-1">
                <Clock className="h-3 w-3" />
                {new Date(session.created_at).toLocaleString()}
              </span>
              {costReport && (
                <span className="flex items-center gap-1">
                  <DollarSign className="h-3 w-3" />
                  ${costReport.total_cost_usd.toFixed(4)}
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="flex items-center gap-2">
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value as StoreEventType | "all")}
            className="rounded border bg-background px-2 py-1 text-xs"
          >
            <option value="all">All Events</option>
            <option value="user_message">User Messages</option>
            <option value="assistant_message">Assistant</option>
            <option value="tool_call">Tool Calls</option>
            <option value="tool_result">Tool Results</option>
            <option value="thinking">Thinking</option>
            <option value="context_reset">Context Resets</option>
            <option value="system_event">System</option>
          </select>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setAutoScroll(!autoScroll)}
          >
            {autoScroll ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
          </Button>
        </div>
      </div>

      {/* Event Timeline + Cost Sidebar */}
      <div className="flex flex-1 overflow-hidden">
        {/* Events */}
        <div ref={containerRef} className="flex-1 overflow-y-auto p-4 space-y-2">
          {loading ? (
            <div className="flex items-center justify-center h-32 text-muted-foreground">
              <Activity className="mr-2 h-4 w-4 animate-spin" />
              Loading events...
            </div>
          ) : filteredEvents.length === 0 ? (
            <div className="flex items-center justify-center h-32 text-muted-foreground">
              No events yet
            </div>
          ) : (
            filteredEvents.map((evt) => (
              <EventCard key={evt.id || evt.index} event={evt} />
            ))
          )}
          <div ref={eventsEndRef} />
        </div>

        {/* Cost Sidebar */}
        {costReport && costReport.total_cost_usd > 0 && (
          <div className="w-64 border-l p-4 overflow-y-auto">
            <h3 className="text-sm font-semibold mb-3 flex items-center gap-1">
              <DollarSign className="h-4 w-4" />
              Cost Breakdown
            </h3>

            <div className="space-y-3">
              <div className="rounded-lg bg-muted/50 p-3">
                <div className="text-2xl font-bold">
                  ${costReport.total_cost_usd.toFixed(4)}
                </div>
                <div className="text-xs text-muted-foreground mt-1">
                  {costReport.total_input_tokens.toLocaleString()} input ·{" "}
                  {costReport.total_output_tokens.toLocaleString()} output tokens
                </div>
              </div>

              {costReport.by_operation.length > 0 && (
                <div>
                  <h4 className="text-xs font-medium text-muted-foreground mb-1">
                    By Operation
                  </h4>
                  {costReport.by_operation.map((op) => (
                    <div key={op.operation} className="flex justify-between text-xs py-0.5">
                      <span>{op.operation}</span>
                      <span>${op.total_cost_usd.toFixed(4)}</span>
                    </div>
                  ))}
                </div>
              )}

              {costReport.by_tool.length > 0 && (
                <div>
                  <h4 className="text-xs font-medium text-muted-foreground mb-1">
                    By Tool
                  </h4>
                  {costReport.by_tool.map((tool) => (
                    <div key={tool.tool_name} className="flex justify-between text-xs py-0.5">
                      <span className="truncate mr-2">{tool.tool_name}</span>
                      <span>×{tool.call_count}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// EventCard — Single event in the timeline
// ---------------------------------------------------------------------------

function EventCard({ event }: { event: StoreEvent }) {
  const [expanded, setExpanded] = useState(false);
  const config = eventTypeConfig[event.type] || eventTypeConfig.system_event;
  const Icon = config.icon;

  return (
    <div
      className={cn(
        "group flex gap-3 rounded-lg border p-3 transition-colors hover:bg-muted/50",
        event.type === "context_reset" && "border-red-200 bg-red-50/50 dark:border-red-900 dark:bg-red-950/20",
      )}
    >
      {/* Index + Icon */}
      <div className="flex flex-col items-center gap-1">
        <span className="text-[10px] text-muted-foreground font-mono">
          #{event.index}
        </span>
        <Icon className={cn("h-4 w-4", config.color)} />
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-1">
          <span className={cn("text-xs font-medium", config.color)}>
            {config.label}
          </span>
          {event.data.tool_name && (
            <Badge variant="outline" className="text-[10px]">
              {event.data.tool_name}
            </Badge>
          )}
          {event.metadata?.cost_usd && event.metadata.cost_usd > 0 && (
            <span className="text-[10px] text-emerald-500">
              ${event.metadata.cost_usd.toFixed(6)}
            </span>
          )}
          <span className="text-[10px] text-muted-foreground ml-auto">
            {new Date(event.timestamp).toLocaleTimeString()}
          </span>
        </div>

        {/* Event content */}
        <EventContent event={event} expanded={expanded} />

        {/* Expand toggle for long content */}
        {hasLongContent(event) && (
          <button
            onClick={() => setExpanded(!expanded)}
            className="flex items-center gap-1 text-[10px] text-muted-foreground hover:text-foreground mt-1"
          >
            <ChevronDown className={cn("h-3 w-3 transition-transform", expanded && "rotate-180")} />
            {expanded ? "Collapse" : "Expand"}
          </button>
        )}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// EventContent — Renders event data based on type
// ---------------------------------------------------------------------------

function EventContent({ event, expanded }: { event: StoreEvent; expanded: boolean }) {
  const maxLen = expanded ? Infinity : 300;

  switch (event.type) {
    case "user_message":
    case "assistant_message":
      return (
        <div className="text-sm whitespace-pre-wrap break-words">
          {truncate(event.data.content || "", maxLen)}
        </div>
      );

    case "tool_call":
      return (
        <div className="space-y-1">
          <div className="flex items-center gap-2">
            <code className="text-xs bg-muted px-1.5 py-0.5 rounded">
              {event.data.tool_name}
            </code>
            <span className="text-[10px] text-muted-foreground font-mono">
              {event.data.call_id}
            </span>
          </div>
          {event.data.input && expanded && (
            <pre className="text-xs bg-muted rounded p-2 overflow-x-auto max-h-40">
              {JSON.stringify(event.data.input, null, 2)}
            </pre>
          )}
        </div>
      );

    case "tool_result":
      return (
        <div className="space-y-1">
          {event.data.is_error && (
            <div className="flex items-center gap-1 text-xs text-red-500">
              <AlertCircle className="h-3 w-3" />
              Error
            </div>
          )}
          <div className="text-xs font-mono bg-muted rounded p-2 overflow-x-auto">
            {truncate(event.data.output || "", maxLen)}
          </div>
        </div>
      );

    case "thinking":
      return (
        <div className="text-xs italic text-muted-foreground">
          {truncate(event.data.thinking || "", maxLen)}
        </div>
      );

    case "context_reset":
      return (
        <div className="space-y-1">
          <div className="text-xs text-red-500 font-medium">
            Compacted events {event.data.compacted_range?.[0]}–{event.data.compacted_range?.[1]}
          </div>
          {event.data.summary && (
            <div className="text-xs bg-muted rounded p-2">
              {truncate(event.data.summary, maxLen)}
            </div>
          )}
        </div>
      );

    case "system_event":
      return (
        <div className="text-xs text-muted-foreground">
          <strong>{event.data.event_name}</strong>
          {event.data.details && `: ${event.data.details}`}
        </div>
      );

    default:
      return null;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function truncate(s: string, maxLen: number): string {
  if (s.length <= maxLen) return s;
  return s.slice(0, maxLen) + "…";
}

function hasLongContent(event: StoreEvent): boolean {
  const content = event.data.content || event.data.output || event.data.thinking || event.data.summary || "";
  return content.length > 300 || !!event.data.input;
}
