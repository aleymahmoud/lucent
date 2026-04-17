"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Sigma } from "lucide-react";

interface ForecastStatistics {
  mean: number;
  median: number;
  min: number;
  max: number;
  q25: number;
  q75: number;
  iqr: number;
  average_interval_width: number;
}

interface ForecastStatsPanelProps {
  stats: ForecastStatistics;
}

function fmt(n: number): string {
  if (!Number.isFinite(n)) return "—";
  const abs = Math.abs(n);
  if (abs >= 1e4 || (abs !== 0 && abs < 1e-2)) {
    return n.toLocaleString(undefined, { maximumFractionDigits: 2 });
  }
  return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function StatCell({ label, value, hint }: { label: string; value: string; hint?: string }) {
  return (
    <div className="rounded-md border bg-muted/30 p-3">
      <div className="text-xs uppercase tracking-wide text-muted-foreground">{label}</div>
      <div className="mt-1 text-lg font-semibold tabular-nums">{value}</div>
      {hint && <div className="mt-0.5 text-xs text-muted-foreground">{hint}</div>}
    </div>
  );
}

export function ForecastStatsPanel({ stats }: ForecastStatsPanelProps) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Sigma className="h-4 w-4" />
          Forecast Statistics
        </CardTitle>
        <CardDescription>
          Summary of the forecasted values — a quick sanity check against domain expectations.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
          <StatCell label="Mean" value={fmt(stats.mean)} />
          <StatCell label="Median" value={fmt(stats.median)} />
          <StatCell label="Min" value={fmt(stats.min)} />
          <StatCell label="Max" value={fmt(stats.max)} />
          <StatCell label="Q25" value={fmt(stats.q25)} />
          <StatCell label="Q75" value={fmt(stats.q75)} />
          <StatCell label="IQR" value={fmt(stats.iqr)} hint="Q75 − Q25" />
          <StatCell label="Avg interval" value={fmt(stats.average_interval_width)} hint="Upper − Lower" />
        </div>
      </CardContent>
    </Card>
  );
}
