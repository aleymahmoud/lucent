"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { BarChart3, Database, TrendingUp, FileText, Activity, Users, Loader2, Link2 } from "lucide-react";
import { useTenant } from "@/contexts/TenantContext";
import { useAuth } from "@/contexts/AuthContext";
import { api } from "@/lib/api/client";

interface DashboardData {
  datasets: number;
  connectors: number;
  users: number;
  groups: number;
  recentDatasets: { id: string; name: string; row_count: number | null; uploaded_at: string }[];
}

export default function DashboardPage() {
  const { tenant } = useTenant();
  const { user } = useAuth();
  const router = useRouter();
  const params = useParams();
  const tenantSlug = params.tenant as string;

  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const [datasetsRes, statsRes] = await Promise.all([
          api.get<{ datasets: any[]; total: number }>("/datasets"),
          api.get<{ total_users: number; active_users: number; total_groups: number; total_connectors: number }>("/users/stats").catch(() => null),
        ]);

        const datasets = datasetsRes.datasets || [];

        setData({
          datasets: datasetsRes.total || datasets.length,
          connectors: statsRes?.total_connectors ?? 0,
          users: statsRes?.total_users ?? 0,
          groups: statsRes?.total_groups ?? 0,
          recentDatasets: datasets.slice(0, 5).map((d: any) => ({
            id: d.id,
            name: d.name,
            row_count: d.row_count,
            uploaded_at: d.uploaded_at || d.created_at || "",
          })),
        });
      } catch {
        setData({ datasets: 0, connectors: 0, users: 0, groups: 0, recentDatasets: [] });
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const isAdmin = user?.role === "admin";

  function timeAgo(dateStr: string): string {
    if (!dateStr) return "";
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `${mins}m ago`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  const stats = [
    {
      title: "Datasets",
      value: String(data?.datasets ?? 0),
      subtitle: data?.recentDatasets?.length ? `Latest: ${data.recentDatasets[0]?.name}` : "No datasets yet",
      icon: Database,
      color: "text-blue-600",
    },
    {
      title: "Data Connectors",
      value: String(data?.connectors ?? 0),
      subtitle: isAdmin ? "Manage in Settings" : "Contact admin to add",
      icon: Link2,
      color: "text-green-600",
    },
    {
      title: "Team Members",
      value: String(data?.users ?? 0),
      subtitle: isAdmin ? "Manage in Settings" : "",
      icon: Users,
      color: "text-orange-600",
    },
    {
      title: "User Groups",
      value: String(data?.groups ?? 0),
      subtitle: isAdmin ? "Manage RLS access" : "",
      icon: BarChart3,
      color: "text-purple-600",
    },
  ];

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-3xl font-bold">Dashboard</h1>
        <p className="text-muted-foreground">
          Welcome{user?.full_name ? `, ${user.full_name}` : ""}! Here's an overview of {tenant?.name || "your organization"}.
        </p>
      </div>

      {/* Stats grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <Card key={stat.title}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">{stat.title}</CardTitle>
                <Icon className={`h-4 w-4 ${stat.color}`} />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stat.value}</div>
                {stat.subtitle && (
                  <p className="text-xs text-muted-foreground truncate">{stat.subtitle}</p>
                )}
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Recent activity + Quick actions */}
      <div className="grid gap-6 md:grid-cols-2">
        {/* Recent datasets */}
        <Card>
          <CardHeader>
            <CardTitle>Recent Datasets</CardTitle>
            <CardDescription>Your latest imported data</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {data?.recentDatasets && data.recentDatasets.length > 0 ? (
              data.recentDatasets.map((ds) => (
                <div key={ds.id} className="flex items-center justify-between">
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-sm truncate">{ds.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {ds.row_count?.toLocaleString() ?? "?"} rows
                      {ds.uploaded_at && ` · ${timeAgo(ds.uploaded_at)}`}
                    </p>
                  </div>
                  <button
                    onClick={() => router.push(`/${tenantSlug}/preprocessing?dataset=${ds.id}`)}
                    className="text-xs text-primary hover:underline shrink-0 ml-2"
                  >
                    Preprocess
                  </button>
                </div>
              ))
            ) : (
              <p className="text-sm text-muted-foreground py-4 text-center">
                No datasets yet. Import data from a connector or upload a file.
              </p>
            )}
          </CardContent>
        </Card>

        {/* Quick actions */}
        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
            <CardDescription>Start your next task</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            <button
              onClick={() => router.push(`/${tenantSlug}/connectors`)}
              className="flex w-full items-center gap-3 rounded-lg border p-4 text-left transition-colors hover:bg-accent"
            >
              <Link2 className="h-8 w-8 text-blue-600 shrink-0" />
              <div>
                <p className="font-medium">{isAdmin ? "Manage Connectors" : "Import from Data Source"}</p>
                <p className="text-sm text-muted-foreground">
                  {isAdmin ? "Set up connectors and data sources" : "Select a data source and import data"}
                </p>
              </div>
            </button>
            <button
              onClick={() => router.push(`/${tenantSlug}/data`)}
              className="flex w-full items-center gap-3 rounded-lg border p-4 text-left transition-colors hover:bg-accent"
            >
              <Database className="h-8 w-8 text-green-600 shrink-0" />
              <div>
                <p className="font-medium">Upload Dataset</p>
                <p className="text-sm text-muted-foreground">Import CSV or Excel files</p>
              </div>
            </button>
            <button
              onClick={() => router.push(`/${tenantSlug}/forecast`)}
              className="flex w-full items-center gap-3 rounded-lg border p-4 text-left transition-colors hover:bg-accent"
            >
              <TrendingUp className="h-8 w-8 text-purple-600 shrink-0" />
              <div>
                <p className="font-medium">Run Forecast</p>
                <p className="text-sm text-muted-foreground">Create a new forecast model</p>
              </div>
            </button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
