"use client";

import { useEffect, useMemo, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from "@/components/ui/table";
import {
  Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle,
} from "@/components/ui/dialog";
import {
  ArrowLeft, ChevronLeft, ChevronRight, Download, Filter, Loader2, RefreshCw, ScrollText,
} from "lucide-react";
import { toast } from "sonner";

import { api } from "@/lib/api/client";
import type { AuditEvent, AuditListResponse } from "@/types";

const PAGE_SIZE = 50;

function formatDate(iso: string): string {
  try {
    return new Intl.DateTimeFormat(undefined, {
      dateStyle: "short",
      timeStyle: "medium",
    }).format(new Date(iso));
  } catch {
    return iso;
  }
}

function ActionBadge({ action }: { action: string }) {
  const lower = action.toLowerCase();
  let variant: "default" | "secondary" | "destructive" | "outline" = "secondary";
  if (lower.includes("delete") || lower.includes("revoke") || lower.includes("fail")) {
    variant = "destructive";
  } else if (lower.includes("login") || lower.includes("logout")) {
    variant = "outline";
  }
  return <Badge variant={variant}>{action}</Badge>;
}

export default function AuditLogPage() {
  const params = useParams();
  const tenant = params.tenant as string;

  // filters
  const [action, setAction] = useState<string>("");
  const [resourceType, setResourceType] = useState<string>("");
  const [fromTs, setFromTs] = useState<string>("");
  const [toTs, setToTs] = useState<string>("");
  const [page, setPage] = useState(1);

  // data
  const [events, setEvents] = useState<AuditEvent[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [selected, setSelected] = useState<AuditEvent | null>(null);

  const totalPages = useMemo(() => Math.max(1, Math.ceil(total / PAGE_SIZE)), [total]);

  const load = async () => {
    setLoading(true);
    try {
      const qp = new URLSearchParams();
      qp.set("page", String(page));
      qp.set("page_size", String(PAGE_SIZE));
      if (action) qp.set("action", action);
      if (resourceType) qp.set("resource_type", resourceType);
      if (fromTs) qp.set("from", new Date(fromTs).toISOString());
      if (toTs) qp.set("to", new Date(toTs).toISOString());

      const res = await api.get<AuditListResponse>(`/audit?${qp.toString()}`);
      setEvents(res.events || []);
      setTotal(res.total || 0);
    } catch (err: any) {
      toast.error("Failed to load audit log", {
        description: err.response?.data?.detail || err.message,
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page]);

  const applyFilters = () => {
    setPage(1);
    load();
  };

  const resetFilters = () => {
    setAction("");
    setResourceType("");
    setFromTs("");
    setToTs("");
    setPage(1);
    // trigger load via effect on page (page already 1; manually call)
    load();
  };

  const handleExport = async () => {
    try {
      const qp = new URLSearchParams();
      if (action) qp.set("action", action);
      if (resourceType) qp.set("resource_type", resourceType);
      if (fromTs) qp.set("from", new Date(fromTs).toISOString());
      if (toTs) qp.set("to", new Date(toTs).toISOString());

      const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";
      const token = localStorage.getItem("token");
      const res = await fetch(`${API_BASE}/audit/export?${qp.toString()}`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `audit_log_${new Date().toISOString().replace(/[:.]/g, "-")}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      toast.success("CSV downloaded");
    } catch (err: any) {
      toast.error("Export failed", { description: err.message });
    }
  };

  return (
    <div className="container mx-auto py-6 max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <Link
            href={`/${tenant}/settings`}
            className="text-sm text-muted-foreground hover:text-foreground inline-flex items-center gap-1"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Settings
          </Link>
          <h1 className="mt-2 text-2xl font-bold flex items-center gap-2">
            <ScrollText className="h-6 w-6" />
            Audit Log
          </h1>
          <p className="text-muted-foreground">
            Security-relevant actions across your tenant. Retained for one year.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={load} disabled={loading}>
            <RefreshCw className={`h-4 w-4 mr-1 ${loading ? "animate-spin" : ""}`} />
            Refresh
          </Button>
          <Button variant="outline" size="sm" onClick={handleExport} disabled={loading}>
            <Download className="h-4 w-4 mr-1" />
            Export CSV
          </Button>
        </div>
      </div>

      {/* Filters */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <Filter className="h-4 w-4" />
            Filters
          </CardTitle>
          <CardDescription>
            Narrow events by action, resource type, or time range. Filters combine with AND.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 gap-3 md:grid-cols-5">
            <div>
              <Label className="text-xs">Action</Label>
              <Select value={action || "any"} onValueChange={(v) => setAction(v === "any" ? "" : v)}>
                <SelectTrigger className="h-9">
                  <SelectValue placeholder="Any" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="any">Any action</SelectItem>
                  <SelectItem value="login">login</SelectItem>
                  <SelectItem value="logout">logout</SelectItem>
                  <SelectItem value="user.create">user.create</SelectItem>
                  <SelectItem value="user.update">user.update</SelectItem>
                  <SelectItem value="user.delete">user.delete</SelectItem>
                  <SelectItem value="user.approve">user.approve</SelectItem>
                  <SelectItem value="user.deactivate">user.deactivate</SelectItem>
                  <SelectItem value="password.change">password.change</SelectItem>
                  <SelectItem value="connector.create">connector.create</SelectItem>
                  <SelectItem value="connector.delete">connector.delete</SelectItem>
                  <SelectItem value="forecast.run">forecast.run</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label className="text-xs">Resource type</Label>
              <Input
                value={resourceType}
                onChange={(e) => setResourceType(e.target.value)}
                placeholder="e.g. user, forecast"
                className="h-9"
              />
            </div>
            <div>
              <Label className="text-xs">From</Label>
              <Input
                type="datetime-local"
                value={fromTs}
                onChange={(e) => setFromTs(e.target.value)}
                className="h-9"
              />
            </div>
            <div>
              <Label className="text-xs">To</Label>
              <Input
                type="datetime-local"
                value={toTs}
                onChange={(e) => setToTs(e.target.value)}
                className="h-9"
              />
            </div>
            <div className="flex items-end gap-2">
              <Button onClick={applyFilters} disabled={loading} size="sm">
                Apply
              </Button>
              <Button variant="ghost" onClick={resetFilters} disabled={loading} size="sm">
                Reset
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Table */}
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[180px]">Time</TableHead>
                <TableHead className="w-[140px]">Action</TableHead>
                <TableHead>User</TableHead>
                <TableHead>Resource</TableHead>
                <TableHead className="w-[130px]">IP</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading && (
                <TableRow>
                  <TableCell colSpan={5} className="py-10 text-center">
                    <Loader2 className="inline h-5 w-5 animate-spin text-muted-foreground" />
                  </TableCell>
                </TableRow>
              )}
              {!loading && events.length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} className="py-12 text-center text-muted-foreground">
                    No audit events match the current filters.
                  </TableCell>
                </TableRow>
              )}
              {!loading && events.map((e) => (
                <TableRow
                  key={e.id}
                  className="cursor-pointer hover:bg-muted/50"
                  onClick={() => setSelected(e)}
                >
                  <TableCell className="font-mono text-xs text-muted-foreground">
                    {formatDate(e.created_at)}
                  </TableCell>
                  <TableCell><ActionBadge action={e.action} /></TableCell>
                  <TableCell className="text-sm">
                    {e.user_email || <span className="text-muted-foreground">—</span>}
                  </TableCell>
                  <TableCell className="text-sm">
                    {e.resource_type && e.resource_id ? (
                      <>
                        <span className="text-muted-foreground">{e.resource_type}</span>
                        <span className="ml-1 font-mono text-xs">{e.resource_id.slice(0, 8)}…</span>
                      </>
                    ) : e.resource_type || <span className="text-muted-foreground">—</span>}
                  </TableCell>
                  <TableCell className="font-mono text-xs text-muted-foreground">
                    {e.ip_address || "—"}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between border-t px-4 py-3">
              <p className="text-sm text-muted-foreground">
                Page {page} of {totalPages} · {total.toLocaleString()} events
              </p>
              <div className="flex items-center gap-1">
                <Button variant="outline" size="icon" className="h-8 w-8"
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1 || loading}>
                  <ChevronLeft className="h-4 w-4" />
                </Button>
                <Button variant="outline" size="icon" className="h-8 w-8"
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages || loading}>
                  <ChevronRight className="h-4 w-4" />
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Detail dialog */}
      <Dialog open={!!selected} onOpenChange={(o) => !o && setSelected(null)}>
        <DialogContent className="max-w-2xl max-h-[85vh] overflow-y-auto">
          {selected && (
            <>
              <DialogHeader>
                <DialogTitle className="flex items-center gap-2">
                  <ActionBadge action={selected.action} />
                </DialogTitle>
                <DialogDescription>{formatDate(selected.created_at)}</DialogDescription>
              </DialogHeader>
              <div className="mt-4 space-y-4">
                <div>
                  <Label className="text-xs text-muted-foreground">User</Label>
                  <p className="text-sm">{selected.user_email || "(system)"}</p>
                  {selected.user_id && (
                    <p className="font-mono text-xs text-muted-foreground">{selected.user_id}</p>
                  )}
                </div>
                {selected.resource_type && (
                  <div>
                    <Label className="text-xs text-muted-foreground">Resource</Label>
                    <p className="text-sm">{selected.resource_type}</p>
                    {selected.resource_id && (
                      <p className="font-mono text-xs text-muted-foreground">{selected.resource_id}</p>
                    )}
                  </div>
                )}
                <div>
                  <Label className="text-xs text-muted-foreground">Request</Label>
                  <p className="text-sm font-mono">{selected.ip_address || "—"}</p>
                  <p className="text-xs text-muted-foreground break-all">{selected.user_agent || ""}</p>
                </div>
                {selected.details && (
                  <div>
                    <Label className="text-xs text-muted-foreground">Details</Label>
                    <pre className="mt-1 max-h-96 overflow-auto rounded-md bg-muted p-3 text-xs">
                      {JSON.stringify(selected.details, null, 2)}
                    </pre>
                  </div>
                )}
              </div>
            </>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
