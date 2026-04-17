"use client";

import { useState } from "react";
import {
  Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Send, Copy, Loader2, CheckCircle2 } from "lucide-react";
import { toast } from "sonner";
import { api } from "@/lib/api/client";

interface InviteUserDialogProps {
  onInvited?: () => void;
  /** Render a custom trigger button. If omitted, a default button is shown. */
  trigger?: React.ReactNode;
}

type Role = "admin" | "analyst" | "viewer";

interface InviteCreatedResponse {
  id: string;
  email: string;
  role: string;
  expires_at: string;
  invite_link: string | null;
}

export function InviteUserDialog({ onInvited, trigger }: InviteUserDialogProps) {
  const [open, setOpen] = useState(false);
  const [email, setEmail] = useState("");
  const [role, setRole] = useState<Role>("analyst");
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<InviteCreatedResponse | null>(null);

  const reset = () => {
    setEmail("");
    setRole("analyst");
    setResult(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const res = await api.post<InviteCreatedResponse>("/users/invite", { email, role });
      setResult(res);
      onInvited?.();
      if (!res.invite_link) {
        toast.success(`Invite email sent to ${res.email}`);
      } else {
        toast.info("SMTP not configured — copy the link and send it manually.");
      }
    } catch (err: any) {
      const detail = err.response?.data?.detail || err.message || "Failed to create invite";
      toast.error(typeof detail === "string" ? detail : JSON.stringify(detail));
    } finally {
      setSubmitting(false);
    }
  };

  const copyLink = async () => {
    if (!result?.invite_link) return;
    try {
      await navigator.clipboard.writeText(result.invite_link);
      toast.success("Link copied");
    } catch {
      toast.error("Copy failed — select and copy manually.");
    }
  };

  return (
    <Dialog open={open} onOpenChange={(o) => { setOpen(o); if (!o) reset(); }}>
      <DialogTrigger asChild>
        {trigger ?? (
          <Button variant="outline">
            <Send className="h-4 w-4 mr-2" />
            Invite User
          </Button>
        )}
      </DialogTrigger>
      <DialogContent>
        {result ? (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <CheckCircle2 className="h-5 w-5 text-green-600" />
                Invite created
              </DialogTitle>
              <DialogDescription>
                Invite for <strong>{result.email}</strong> as{" "}
                <Badge variant="outline">{result.role}</Badge>. Expires{" "}
                {new Date(result.expires_at).toLocaleDateString()}.
              </DialogDescription>
            </DialogHeader>
            {result.invite_link ? (
              <div className="space-y-2">
                <Label>Invite link (SMTP not configured — share manually)</Label>
                <div className="flex gap-2">
                  <Input readOnly value={result.invite_link} className="font-mono text-xs" />
                  <Button variant="outline" size="icon" onClick={copyLink} aria-label="Copy link">
                    <Copy className="h-4 w-4" />
                  </Button>
                </div>
                <p className="text-xs text-muted-foreground">
                  This link is shown only once. Copy it now and send it to the invitee.
                </p>
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">
                An invitation email has been sent. The invitee will receive a link to set their password.
              </p>
            )}
            <DialogFooter>
              <Button onClick={() => { setOpen(false); reset(); }}>Done</Button>
            </DialogFooter>
          </>
        ) : (
          <form onSubmit={handleSubmit}>
            <DialogHeader>
              <DialogTitle>Invite a new user</DialogTitle>
              <DialogDescription>
                An invitation link will be emailed to the address below. The invitee sets
                their own password.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="invite-email">Email</Label>
                <Input
                  id="invite-email"
                  type="email"
                  required
                  autoComplete="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="person@example.com"
                  disabled={submitting}
                />
              </div>
              <div className="space-y-2">
                <Label>Role</Label>
                <Select value={role} onValueChange={(v) => setRole(v as Role)} disabled={submitting}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="admin">Admin</SelectItem>
                    <SelectItem value="analyst">Analyst</SelectItem>
                    <SelectItem value="viewer">Viewer</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setOpen(false)} disabled={submitting}>
                Cancel
              </Button>
              <Button type="submit" disabled={submitting || !email}>
                {submitting ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : <Send className="h-4 w-4 mr-2" />}
                Send invite
              </Button>
            </DialogFooter>
          </form>
        )}
      </DialogContent>
    </Dialog>
  );
}
