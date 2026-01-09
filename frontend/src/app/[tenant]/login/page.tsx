"use client";

import { useState, useEffect } from "react";
import { useRouter, useParams } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { BarChart3 } from "lucide-react";
import { api } from "@/lib/api/client";
import { tenantsPublicApi } from "@/lib/api/endpoints";

interface TenantInfo {
  id: string;
  slug: string;
  name: string;
  is_active: boolean;
}

interface UserResponse {
  id: string;
  email: string;
  full_name: string | null;
  role: string;
  tenant_id: string;
  tenant_slug: string | null;
  is_active: boolean;
  is_approved: boolean;
  created_at: string;
  last_login: string | null;
}

interface AuthResponse {
  access_token: string;
  token_type: string;
  user: UserResponse;
}

export default function TenantLoginPage() {
  const router = useRouter();
  const params = useParams();
  const tenantSlug = params?.tenant as string;

  const [tenant, setTenant] = useState<TenantInfo | null>(null);
  const [tenantLoading, setTenantLoading] = useState(true);
  const [tenantError, setTenantError] = useState<string | null>(null);

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  // Validate tenant exists
  useEffect(() => {
    async function validateTenant() {
      if (!tenantSlug) return;

      try {
        const tenantInfo = await tenantsPublicApi.getBySlug(tenantSlug);
        if (!tenantInfo.is_active) {
          setTenantError("This organization is currently inactive.");
        } else {
          setTenant(tenantInfo);
        }
      } catch (err) {
        setTenantError("Organization not found.");
      } finally {
        setTenantLoading(false);
      }
    }

    validateTenant();
  }, [tenantSlug]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      // Tenant user login endpoint
      const response = await api.post<AuthResponse>("/auth/login", {
        email,
        password,
      });

      // Verify user belongs to this tenant
      if (response.user.tenant_slug !== tenantSlug) {
        setError("Your account is not associated with this organization.");
        setLoading(false);
        return;
      }

      // Store user token and info
      localStorage.setItem("token", response.access_token);
      localStorage.setItem("user", JSON.stringify(response.user));

      // Redirect to tenant dashboard
      router.push(`/${tenantSlug}/dashboard`);
    } catch (err: any) {
      const detail = err.response?.data?.detail;
      if (detail?.includes("pending approval")) {
        setError("Your account is pending approval. Please contact your administrator.");
      } else {
        setError(detail || "Invalid credentials. Please try again.");
      }
    } finally {
      setLoading(false);
    }
  };

  // Loading state
  if (tenantLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  // Tenant error state
  if (tenantError) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
        <Card className="w-full max-w-md">
          <CardHeader className="text-center">
            <CardTitle className="text-red-600">Organization Not Found</CardTitle>
            <CardDescription>{tenantError}</CardDescription>
          </CardHeader>
          <CardFooter className="justify-center">
            <p className="text-sm text-gray-500">
              Please check the URL or contact your administrator.
            </p>
          </CardFooter>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1 text-center">
          <div className="flex justify-center mb-4">
            <div className="p-3 bg-blue-600/10 rounded-full">
              <BarChart3 className="h-8 w-8 text-blue-600" />
            </div>
          </div>
          <CardTitle className="text-2xl font-bold">{tenant?.name}</CardTitle>
          <CardDescription>
            Sign in to access your organization's dashboard
          </CardDescription>
        </CardHeader>
        <form onSubmit={handleSubmit}>
          <CardContent className="space-y-4">
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded text-sm">
                {error}
              </div>
            )}

            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="you@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                disabled={loading}
              />
            </div>
          </CardContent>

          <CardFooter className="flex flex-col space-y-4">
            <Button
              type="submit"
              className="w-full"
              disabled={loading}
            >
              {loading ? "Signing in..." : "Sign in"}
            </Button>

            <div className="text-sm text-center text-gray-600">
              Don't have an account?{" "}
              <Link href={`/${tenantSlug}/register`} className="text-blue-600 hover:underline">
                Request access
              </Link>
            </div>
          </CardFooter>
        </form>
      </Card>
    </div>
  );
}
