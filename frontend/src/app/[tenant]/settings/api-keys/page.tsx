"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger,
} from "@/components/ui/dialog";
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from "@/components/ui/table";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { ArrowLeft, KeyRound, Copy, Plus, Trash2, Loader2, CheckCircle2 } from "lucide-react";
import { toast } from "sonner";
import { api } from "@/lib/api/client";

interface ApiKeyListItem {
  id: string;
  name: string;
  key_prefix: string;
  scopes: string[];
  last_used_at: string | null;
  revoked_at: string | null;
  created_at: string;
}

interface CreatedResponse {
  id: string;
  name: string;
  raw_key: string;
  key_prefix: string;
  scopes: string[];
  created_at: string;
}

export default function ApiKeysPage() {
  const params = useParams();
  const tenant = params.tenant as string;

  const [keys, setKeys] = useState<ApiKeyListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [createOpen, setCreateOpen] = useState(false);
  const [name, setName] = useState("");
  const [scope, setScope] = useState<"read" | "write">("read");
  const [submitting, setSubmitting] = useState(false);
  const [justCreated, setJustCreated] = useState<CreatedResponse | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await api.get<{ keys: ApiKeyListItem[] }>("/api-keys");
      setKeys(res.keys || []);
    } catch (err: any) {
      toast.error(err.response?.data?.detail || "Failed to load API keys");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const createKey = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const res = await api.post<CreatedResponse>("/api-keys", {
        name,
        scopes: scope === "write" ? ["read", "write"] : ["read"],
      });
      setJustCreated(res);
      setName("");
      setScope("read");
      await load();
    } catch (err: any) {
      toast.error(err.response?.data?.detail || "Failed to create key");
    } finally {
      setSubmitting(false);
    }
  };

  const revoke = async (id: string) => {
    if (!confirm("Revoke this API key? Any service using it will immediately fail.")) return;
    try {
      await api.delete(`/api-keys/${id}`);
      toast.success("Key revoked");
      await load();
    } catch (err: any) {
      toast.error(err.response?.data?.detail || "Revoke failed");
    }
  };

  const copyRaw = async () => {
    if (!justCreated) return;
    try {
      await navigator.clipboard.writeText(justCreated.raw_key);
      toast.success("Key copied to clipboard");
    } catch {
      toast.error("Copy failed");
    }
  };

  return (
    <div className="container mx-auto py-6 max-w-5xl space-y-6">
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
            <KeyRound className="h-6 w-6" />
            API Keys
          </h1>
          <p className="text-muted-foreground">
            Personal bearer tokens for programmatic access.
          </p>
        </div>
        <Dialog open={createOpen} onOpenChange={(o) => { setCreateOpen(o); if (!o) setJustCreated(null); }}>
          <DialogTrigger asChild>
            <Button>
              <Plus className="h-4 w-4 mr-2" />
              Create API Key
            </Button>
          </DialogTrigger>
          <DialogContent>
            {justCreated ? (
              <>
                <DialogHeader>
                  <DialogTitle className="flex items-center gap-2">
                    <CheckCircle2 className="h-5 w-5 text-green-600" />
                    Key created
                  </DialogTitle>
                  <DialogDescription>
                    Copy this key now — it will not be shown again.
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-3">
                  <div className="rounded-md border bg-muted p-3">
                    <code className="break-all font-mono text-sm">{justCreated.raw_key}</code>
                  </div>
                  <Button variant="outline" size="sm" onClick={copyRaw}>
                    <Copy className="h-4 w-4 mr-2" />
                    Copy key
                  </Button>
                  <p className="text-xs text-muted-foreground">
                    Use this value as the <code>Authorization: Bearer &lt;key&gt;</code> header.
                  </p>
                </div>
                <DialogFooter>
                  <Button onClick={() => { setCreateOpen(false); setJustCreated(null); }}>Done</Button>
                </DialogFooter>
              </>
            ) : (
              <form onSubmit={createKey}>
                <DialogHeader>
                  <DialogTitle>Create a new API Key</DialogTitle>
                  <DialogDescription>
                    The key is bound to your user and tenant.
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4 py-4">
                  <div className="space-y-2">
                    <Label>Name</Label>
                    <Input
                      required
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="e.g. Production deploy bot"
                      maxLength={128}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Scope</Label>
                    <Select value={scope} onValueChange={(v) => setScope(v as any)}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="read">Read-only</SelectItem>
                        <SelectItem value="write">Read + Write</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
                <DialogFooter>
                  <Button type="button" variant="outline" onClick={() => setCreateOpen(false)}>
                    Cancel
                  </Button>
                  <Button type="submit" disabled={submitting || !name}>
                    {submitting ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : null}
                    Create
                  </Button>
                </DialogFooter>
              </form>
            )}
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Prefix</TableHead>
                <TableHead>Scopes</TableHead>
                <TableHead>Last used</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="w-10"></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading && (
                <TableRow>
                  <TableCell colSpan={6} className="py-10 text-center">
                    <Loader2 className="inline h-5 w-5 animate-spin text-muted-foreground" />
                  </TableCell>
                </TableRow>
              )}
              {!loading && keys.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} className="py-12 text-center text-muted-foreground">
                    No API keys yet.
                  </TableCell>
                </TableRow>
              )}
              {!loading && keys.map((k) => (
                <TableRow key={k.id}>
                  <TableCell className="font-medium">{k.name}</TableCell>
                  <TableCell className="font-mono text-xs">{k.key_prefix}…</TableCell>
                  <TableCell>
                    {k.scopes.map((s) => (
                      <Badge key={s} variant="outline" className="mr-1 text-[10px]">{s}</Badge>
                    ))}
                  </TableCell>
                  <TableCell className="text-xs text-muted-foreground">
                    {k.last_used_at ? new Date(k.last_used_at).toLocaleString() : "Never"}
                  </TableCell>
                  <TableCell>
                    {k.revoked_at ? (
                      <Badge variant="destructive">Revoked</Badge>
                    ) : (
                      <Badge variant="default">Active</Badge>
                    )}
                  </TableCell>
                  <TableCell>
                    {!k.revoked_at && (
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => revoke(k.id)}
                        aria-label="Revoke"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
