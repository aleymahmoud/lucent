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
  ArrowLeft, ShieldCheck, ShieldOff, Copy, CheckCircle2, Loader2, AlertCircle,
} from "lucide-react";
import { toast } from "sonner";
import { api } from "@/lib/api/client";

interface EnrollResponse {
  secret: string;
  qr_uri: string;
  backup_codes: string[];
}

function QrFromUri({ uri }: { uri: string }) {
  // Use a public QR endpoint (no new dependency). The URI has the secret + issuer.
  const src = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(uri)}`;
  return (
    <img
      src={src}
      alt="TOTP QR code"
      width={200}
      height={200}
      className="border rounded-md bg-white p-2"
    />
  );
}

export default function SecurityPage() {
  const params = useParams();
  const tenant = params.tenant as string;

  const [mfaEnabled, setMfaEnabled] = useState<boolean | null>(null);
  const [enrolling, setEnrolling] = useState(false);
  const [enrolled, setEnrolled] = useState<EnrollResponse | null>(null);
  const [verifyCode, setVerifyCode] = useState("");
  const [verifying, setVerifying] = useState(false);
  const [disablePw, setDisablePw] = useState("");
  const [disabling, setDisabling] = useState(false);

  const loadMe = async () => {
    try {
      const me = await api.get<{ mfa_enabled?: boolean }>("/auth/me");
      setMfaEnabled(!!me.mfa_enabled);
    } catch {
      setMfaEnabled(false);
    }
  };

  useEffect(() => { loadMe(); }, []);

  const beginEnroll = async () => {
    setEnrolling(true);
    try {
      const res = await api.post<EnrollResponse>("/mfa/enroll", {});
      setEnrolled(res);
    } catch (err: any) {
      toast.error(err.response?.data?.detail || "Failed to start enrolment");
    } finally {
      setEnrolling(false);
    }
  };

  const submitVerify = async () => {
    if (!verifyCode) return;
    setVerifying(true);
    try {
      await api.post("/mfa/verify", { code: verifyCode });
      toast.success("MFA enabled");
      setEnrolled(null);
      setVerifyCode("");
      await loadMe();
    } catch (err: any) {
      toast.error(err.response?.data?.detail || "Invalid code");
    } finally {
      setVerifying(false);
    }
  };

  const disable = async () => {
    if (!disablePw) return;
    setDisabling(true);
    try {
      await api.post("/mfa/disable", { password: disablePw });
      toast.success("MFA disabled");
      setDisablePw("");
      await loadMe();
    } catch (err: any) {
      toast.error(err.response?.data?.detail || "Failed to disable");
    } finally {
      setDisabling(false);
    }
  };

  const copyCodes = async () => {
    if (!enrolled) return;
    try {
      await navigator.clipboard.writeText(enrolled.backup_codes.join("\n"));
      toast.success("Backup codes copied");
    } catch {
      toast.error("Copy failed — select manually.");
    }
  };

  return (
    <div className="container mx-auto py-6 max-w-3xl space-y-6">
      <div>
        <Link
          href={`/${tenant}/settings`}
          className="text-sm text-muted-foreground hover:text-foreground inline-flex items-center gap-1"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Settings
        </Link>
        <h1 className="mt-2 text-2xl font-bold flex items-center gap-2">
          <ShieldCheck className="h-6 w-6" />
          Security
        </h1>
        <p className="text-muted-foreground">
          Protect your account with two-factor authentication.
        </p>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2 text-base">
                Two-Factor Authentication (TOTP)
                {mfaEnabled === true && <Badge className="gap-1"><CheckCircle2 className="h-3 w-3" /> Enabled</Badge>}
                {mfaEnabled === false && <Badge variant="outline">Disabled</Badge>}
              </CardTitle>
              <CardDescription>
                Requires a 6-digit code from your authenticator app on every login.
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {mfaEnabled === null && (
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          )}

          {mfaEnabled === false && !enrolled && (
            <Button onClick={beginEnroll} disabled={enrolling}>
              {enrolling ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : <ShieldCheck className="h-4 w-4 mr-2" />}
              Enable 2FA
            </Button>
          )}

          {enrolled && (
            <div className="space-y-4">
              <div className="flex flex-col items-center gap-2 sm:flex-row sm:items-start">
                <QrFromUri uri={enrolled.qr_uri} />
                <div className="space-y-2 text-sm">
                  <p className="font-medium">1. Scan this QR with Google Authenticator, 1Password, Authy, etc.</p>
                  <p className="text-muted-foreground">
                    Can't scan? Enter this secret manually:
                    <code className="ml-1 rounded bg-muted px-2 py-0.5 font-mono text-xs">
                      {enrolled.secret}
                    </code>
                  </p>
                </div>
              </div>
              <div className="border-l-4 border-orange-400 bg-orange-50 p-3 dark:bg-orange-950/20">
                <p className="font-medium text-sm">2. Save these backup codes now</p>
                <p className="text-xs text-muted-foreground mb-2">
                  Each code works once if you lose your device. Shown only once.
                </p>
                <div className="grid grid-cols-2 gap-1 font-mono text-xs">
                  {enrolled.backup_codes.map((c) => (
                    <div key={c} className="rounded bg-white px-2 py-1 dark:bg-background">
                      {c}
                    </div>
                  ))}
                </div>
                <Button variant="outline" size="sm" className="mt-2" onClick={copyCodes}>
                  <Copy className="h-3 w-3 mr-1" />
                  Copy codes
                </Button>
              </div>
              <div className="space-y-2">
                <Label>3. Enter a 6-digit code from your authenticator</Label>
                <div className="flex gap-2">
                  <Input
                    value={verifyCode}
                    onChange={(e) => setVerifyCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
                    placeholder="123456"
                    maxLength={6}
                    className="font-mono max-w-[160px]"
                  />
                  <Button onClick={submitVerify} disabled={verifying || verifyCode.length !== 6}>
                    {verifying ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : null}
                    Verify & Enable
                  </Button>
                </div>
              </div>
            </div>
          )}

          {mfaEnabled === true && !enrolled && (
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">
                To disable 2FA, enter your current password:
              </p>
              <div className="flex gap-2 max-w-sm">
                <Input
                  type="password"
                  value={disablePw}
                  onChange={(e) => setDisablePw(e.target.value)}
                  placeholder="Current password"
                />
                <Button variant="destructive" onClick={disable} disabled={disabling || !disablePw}>
                  {disabling ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : <ShieldOff className="h-4 w-4 mr-2" />}
                  Disable
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
