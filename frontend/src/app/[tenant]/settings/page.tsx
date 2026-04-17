"use client";

import { useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useAuth } from "@/contexts/AuthContext";
import { userApi } from "@/lib/api/endpoints";
import { Users, UsersRound, Link2, Palette, Settings, KeyRound, Loader2, CheckCircle2, AlertCircle, ScrollText, Gauge } from "lucide-react";
import { toast } from "sonner";

const settingsItems = [
  {
    name: "Users",
    description: "Manage users in your organization",
    href: "/settings/users",
    icon: Users,
    adminOnly: true,
  },
  {
    name: "Groups",
    description: "Manage user groups and permissions",
    href: "/settings/groups",
    icon: UsersRound,
    adminOnly: true,
  },
  {
    name: "Connectors",
    description: "Configure data connectors and RLS",
    href: "/settings/connectors",
    icon: Link2,
    adminOnly: true,
  },
  {
    name: "Branding",
    description: "Customize your organization's appearance",
    href: "/settings/branding",
    icon: Palette,
    adminOnly: true,
  },
  {
    name: "Audit Log",
    description: "Review security-relevant actions across your tenant",
    href: "/settings/audit",
    icon: ScrollText,
    adminOnly: true,
  },
  {
    name: "Usage & Limits",
    description: "See current consumption vs your plan limits",
    href: "/settings/usage",
    icon: Gauge,
    adminOnly: true,
  },
];

function ChangePasswordForm() {
  const [oldPassword, setOldPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isValid = oldPassword && newPassword.length >= 6 && newPassword === confirmPassword;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isValid) return;
    setError(null);
    try {
      setIsSubmitting(true);
      await userApi.changePassword(oldPassword, newPassword);
      toast.success("Password changed successfully");
      setOldPassword("");
      setNewPassword("");
      setConfirmPassword("");
    } catch (err: any) {
      const msg = err.response?.data?.detail || "Failed to change password";
      setError(typeof msg === "string" ? msg : msg.message || "Failed to change password");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <KeyRound className="h-5 w-5 text-primary" />
          Change Password
        </CardTitle>
        <CardDescription>Update your account password</CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4 max-w-sm">
          {error && (
            <div className="flex items-center gap-2 rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700">
              <AlertCircle className="h-4 w-4 shrink-0" />
              {error}
            </div>
          )}
          <div className="space-y-1.5">
            <Label htmlFor="old-pw">Current Password</Label>
            <Input
              id="old-pw"
              type="password"
              value={oldPassword}
              onChange={(e) => setOldPassword(e.target.value)}
              placeholder="Enter current password"
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="new-pw">New Password</Label>
            <Input
              id="new-pw"
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="At least 6 characters"
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="confirm-pw">Confirm New Password</Label>
            <Input
              id="confirm-pw"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Repeat new password"
            />
            {confirmPassword && newPassword !== confirmPassword && (
              <p className="text-xs text-destructive">Passwords do not match</p>
            )}
          </div>
          <Button type="submit" disabled={!isValid || isSubmitting}>
            {isSubmitting ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Changing...
              </>
            ) : (
              "Change Password"
            )}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

export default function SettingsPage() {
  const params = useParams();
  const tenantSlug = params?.tenant as string;
  const { user } = useAuth();

  const isAdmin = user?.role === "admin";

  // Filter items based on user role
  const visibleItems = settingsItems.filter(
    (item) => !item.adminOnly || isAdmin
  );

  return (
    <div className="container mx-auto py-6 space-y-6">
      <div>
        <h1 className="text-3xl font-bold flex items-center gap-2">
          <Settings className="h-8 w-8" />
          Settings
        </h1>
        <p className="text-muted-foreground mt-1">
          Manage your organization's settings and preferences
        </p>
      </div>

      {visibleItems.length === 0 ? (
        <Card>
          <CardContent className="py-8 text-center">
            <p className="text-muted-foreground">
              No settings available for your role.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {visibleItems.map((item) => {
            const Icon = item.icon;
            return (
              <Link key={item.name} href={`/${tenantSlug}${item.href}`}>
                <Card className="h-full hover:bg-muted/50 transition-colors cursor-pointer">
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <Icon className="h-5 w-5 text-primary" />
                      {item.name}
                    </CardTitle>
                    <CardDescription>{item.description}</CardDescription>
                  </CardHeader>
                </Card>
              </Link>
            );
          })}
        </div>
      )}

      {/* Change Password — visible to all users */}
      <ChangePasswordForm />
    </div>
  );
}
