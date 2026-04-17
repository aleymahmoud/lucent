"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Gauge, Loader2, AlertTriangle } from "lucide-react";
import { toast } from "sonner";
import { api } from "@/lib/api/client";

interface UsageMetric {
  current: number;
  limit: number;
  pct: number;
  status: "ok" | "warn" | "exceeded";
}

interface UsageResponse {
  users: UsageMetric;
  forecasts_this_month: UsageMetric;
}

function UsageCard({
  label,
  metric,
  description,
}: {
  label: string;
  metric: UsageMetric;
  description: string;
}) {
  const color =
    metric.status === "exceeded"
      ? "text-destructive"
      : metric.status === "warn"
        ? "text-orange-600"
        : "text-green-600";
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-base">{label}</CardTitle>
        <CardDescription>{description}</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="flex items-baseline justify-between">
          <div className="text-3xl font-bold tabular-nums">
            {metric.current.toLocaleString()}
          </div>
          <div className="text-sm text-muted-foreground">
            of {metric.limit.toLocaleString()}
          </div>
        </div>
        <Progress value={Math.min(100, metric.pct)} className="mt-3 h-2" />
        <p className={`mt-2 text-sm font-medium ${color}`}>
          {metric.status === "exceeded"
            ? "Limit reached"
            : metric.status === "warn"
              ? `Approaching limit (${metric.pct.toFixed(1)}%)`
              : `${metric.pct.toFixed(1)}% used`}
        </p>
      </CardContent>
    </Card>
  );
}

export default function UsagePage() {
  const params = useParams();
  const tenant = params.tenant as string;
  const [data, setData] = useState<UsageResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const res = await api.get<UsageResponse>("/tenants/current/usage");
        setData(res);
      } catch (err: any) {
        toast.error("Failed to load usage", {
          description: err.response?.data?.detail || err.message,
        });
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <div className="container mx-auto py-6 max-w-5xl space-y-6">
      <div>
        <Link
          href={`/${tenant}/settings`}
          className="text-sm text-muted-foreground hover:text-foreground inline-flex items-center gap-1"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Settings
        </Link>
        <h1 className="mt-2 text-2xl font-bold flex items-center gap-2">
          <Gauge className="h-6 w-6" />
          Usage & Plan Limits
        </h1>
        <p className="text-muted-foreground">
          Current consumption vs your plan limits. Server-side enforcement prevents
          over-limit actions.
        </p>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      ) : !data ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center gap-2 py-12 text-muted-foreground">
            <AlertTriangle className="h-6 w-6" />
            <p>Usage data unavailable.</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          <UsageCard
            label="Users"
            metric={data.users}
            description="Active users in your tenant"
          />
          <UsageCard
            label="Forecasts this month"
            metric={data.forecasts_this_month}
            description="Runs since the 1st of the current month"
          />
        </div>
      )}
    </div>
  );
}
