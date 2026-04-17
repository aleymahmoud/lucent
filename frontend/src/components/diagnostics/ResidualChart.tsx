"use client";

import dynamic from "next/dynamic";
import { useMemo, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Loader2 } from "lucide-react";

const Plot = dynamic(() => import("react-plotly.js"), {
  ssr: false,
  loading: () => (
    <div className="flex h-[400px] items-center justify-center">
      <Loader2 className="h-8 w-8 animate-spin text-primary" />
    </div>
  ),
});

interface LjungBox {
  statistic: number;
  p_value: number;
}

interface JarqueBera {
  statistic: number;
  p_value: number;
}

type PlotType = "timeseries" | "histogram" | "qq";

interface ResidualChartProps {
  residuals: number[];
  ljungBox?: LjungBox;
  jarqueBera?: JarqueBera;
  isWhiteNoise?: boolean;
}

// ------------ Helpers ------------

function stats(xs: number[]) {
  const n = xs.length;
  const mean = xs.reduce((a, b) => a + b, 0) / n;
  const variance = xs.reduce((a, b) => a + (b - mean) ** 2, 0) / n;
  const std = Math.sqrt(variance);
  return { mean, std };
}

// Inverse standard normal CDF (approximation — Beasley-Springer)
function probit(p: number): number {
  if (p <= 0) return -Infinity;
  if (p >= 1) return Infinity;
  const a = [-39.6968302866538, 220.946098424521, -275.928510446969, 138.357751867269, -30.6647980661472, 2.50662827745924];
  const b = [-54.4760987982241, 161.585836858041, -155.698979859887, 66.8013118877197, -13.2806815528857];
  const c = [-7.78489400243029e-3, -0.322396458041136, -2.40075827716184, -2.54973253934373, 4.37466414146497, 2.93816398269878];
  const d = [7.78469570904146e-3, 0.32246712907004, 2.445134137143, 3.75440866190742];
  const pLow = 0.02425;
  const pHigh = 1 - pLow;
  let q: number, r: number;
  if (p < pLow) {
    q = Math.sqrt(-2 * Math.log(p));
    return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) /
           ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
  }
  if (p <= pHigh) {
    q = p - 0.5;
    r = q * q;
    return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * q /
           (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
  }
  q = Math.sqrt(-2 * Math.log(1 - p));
  return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) /
           ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
}

function normalPdf(x: number, mean: number, std: number): number {
  const z = (x - mean) / std;
  return Math.exp(-0.5 * z * z) / (std * Math.sqrt(2 * Math.PI));
}

// Simple Gaussian kernel density estimator
function kde(xs: number[], grid: number[], bandwidth: number): number[] {
  return grid.map((g) => {
    let sum = 0;
    for (const x of xs) {
      const z = (g - x) / bandwidth;
      sum += Math.exp(-0.5 * z * z);
    }
    return sum / (xs.length * bandwidth * Math.sqrt(2 * Math.PI));
  });
}

// ------------ Component ------------

export function ResidualChart({ residuals, ljungBox, jarqueBera, isWhiteNoise }: ResidualChartProps) {
  const [plotType, setPlotType] = useState<PlotType>("timeseries");

  const n = residuals?.length ?? 0;

  const data = useMemo<Plotly.Data[]>(() => {
    if (!residuals || residuals.length === 0) return [];

    if (plotType === "timeseries") {
      const { mean, std } = stats(residuals);
      const xs = residuals.map((_, i) => i);
      return [
        {
          x: xs, y: residuals,
          type: "scatter" as const, mode: "lines+markers" as const,
          name: "Residuals",
          line: { color: "#3b82f6", width: 1 },
          marker: { color: "#3b82f6", size: 4, opacity: 0.7 },
          hovertemplate: "Index %{x}: %{y:.4f}<extra></extra>",
        },
        {
          x: [0, n - 1], y: [mean, mean],
          type: "scatter" as const, mode: "lines" as const,
          name: `Mean (${mean.toFixed(3)})`,
          line: { color: "#6b7280", width: 1, dash: "solid" },
          hoverinfo: "skip" as const,
        },
        {
          x: [0, n - 1], y: [mean + std, mean + std],
          type: "scatter" as const, mode: "lines" as const,
          name: `+1σ (${(mean + std).toFixed(3)})`,
          line: { color: "#f59e0b", width: 1, dash: "dash" },
          hoverinfo: "skip" as const,
        },
        {
          x: [0, n - 1], y: [mean - std, mean - std],
          type: "scatter" as const, mode: "lines" as const,
          name: `-1σ (${(mean - std).toFixed(3)})`,
          line: { color: "#f59e0b", width: 1, dash: "dash" },
          showlegend: false,
          hoverinfo: "skip" as const,
        },
        {
          x: [0, n - 1], y: [mean + 2 * std, mean + 2 * std],
          type: "scatter" as const, mode: "lines" as const,
          name: `±2σ`,
          line: { color: "#ef4444", width: 1, dash: "dot" },
          hoverinfo: "skip" as const,
        },
        {
          x: [0, n - 1], y: [mean - 2 * std, mean - 2 * std],
          type: "scatter" as const, mode: "lines" as const,
          line: { color: "#ef4444", width: 1, dash: "dot" },
          showlegend: false,
          hoverinfo: "skip" as const,
        },
      ];
    }

    if (plotType === "histogram") {
      const { mean, std } = stats(residuals);
      const min = Math.min(...residuals);
      const max = Math.max(...residuals);
      const bins = Math.min(30, Math.max(10, Math.round(Math.sqrt(n))));
      const step = (max - min) / 200;
      const grid = Array.from({ length: 200 }, (_, i) => min + i * step);
      const bandwidth = 1.06 * std * Math.pow(n, -1 / 5); // Silverman
      const kdeY = kde(residuals, grid, bandwidth);
      const normalY = grid.map((g) => normalPdf(g, mean, std));
      return [
        {
          x: residuals,
          type: "histogram" as const,
          histnorm: "probability density" as const,
          name: "Histogram",
          marker: { color: "rgba(59, 130, 246, 0.45)", line: { color: "#3b82f6", width: 1 } },
          nbinsx: bins,
          hovertemplate: "%{y:.3f}<extra></extra>",
        },
        {
          x: grid, y: normalY,
          type: "scatter" as const, mode: "lines" as const,
          name: `Normal(${mean.toFixed(2)}, ${std.toFixed(2)})`,
          line: { color: "#2563eb", width: 2 },
          hoverinfo: "skip" as const,
        },
        {
          x: grid, y: kdeY,
          type: "scatter" as const, mode: "lines" as const,
          name: "KDE",
          line: { color: "#ef4444", width: 2, dash: "dash" },
          hoverinfo: "skip" as const,
        },
      ];
    }

    if (plotType === "qq") {
      const sorted = [...residuals].sort((a, b) => a - b);
      const { mean, std } = stats(sorted);
      const theoretical = sorted.map((_, i) => probit((i + 0.5) / n));
      const sample = sorted.map((v) => (v - mean) / std);
      const min = Math.min(...theoretical);
      const max = Math.max(...theoretical);
      return [
        {
          x: theoretical, y: sample,
          type: "scatter" as const, mode: "markers" as const,
          name: "Residuals (standardised)",
          marker: { color: "#3b82f6", size: 5, opacity: 0.7 },
          hovertemplate: "Theoretical: %{x:.3f}<br>Sample: %{y:.3f}<extra></extra>",
        },
        {
          x: [min, max], y: [min, max],
          type: "scatter" as const, mode: "lines" as const,
          name: "Reference (y = x)",
          line: { color: "#ef4444", width: 1.5, dash: "dash" },
          hoverinfo: "skip" as const,
        },
      ];
    }

    return [];
  }, [residuals, plotType, n]);

  const layout = useMemo<Partial<Plotly.Layout>>(() => {
    const common: Partial<Plotly.Layout> = {
      autosize: true,
      height: 420,
      margin: { l: 60, r: 20, t: 20, b: 70 },
      showlegend: true,
      legend: { orientation: "h", y: -0.28, x: 0.5, xanchor: "center", font: { size: 11 } },
      hovermode: "closest",
      plot_bgcolor: "rgba(0,0,0,0)",
      paper_bgcolor: "rgba(0,0,0,0)",
    };
    if (plotType === "timeseries") {
      return {
        ...common,
        xaxis: { title: { text: "Observation Index", standoff: 12 }, showgrid: true, gridcolor: "rgba(0,0,0,0.05)" },
        yaxis: { title: { text: "Residual", standoff: 8 }, showgrid: true, gridcolor: "rgba(0,0,0,0.05)" },
      };
    }
    if (plotType === "histogram") {
      return {
        ...common,
        xaxis: { title: { text: "Residual", standoff: 12 } },
        yaxis: { title: { text: "Density", standoff: 8 } },
      };
    }
    if (plotType === "qq") {
      return {
        ...common,
        xaxis: { title: { text: "Theoretical Quantile", standoff: 12 } },
        yaxis: { title: { text: "Sample Quantile (standardised)", standoff: 8 } },
      };
    }
    return common;
  }, [plotType]);

  const config: Partial<Plotly.Config> = {
    responsive: true,
    displayModeBar: true,
    displaylogo: false,
    modeBarButtonsToRemove: ["select2d", "lasso2d", "autoScale2d"],
  };

  if (!residuals || residuals.length === 0) {
    return (
      <Card>
        <CardContent className="flex h-[400px] items-center justify-center">
          <p className="text-muted-foreground">No residual data available.</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="pb-2">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <CardTitle>Residual Analysis</CardTitle>
            <CardDescription>
              {plotType === "timeseries" && "Residuals over time with mean and ±σ bands."}
              {plotType === "histogram" && "Residual distribution with normal curve + kernel density overlay."}
              {plotType === "qq" && "Quantile-quantile plot against the standard normal. Points on the line indicate normality."}
            </CardDescription>
          </div>
          <Select value={plotType} onValueChange={(v) => setPlotType(v as PlotType)}>
            <SelectTrigger className="w-[180px] h-9">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="timeseries">Time Series</SelectItem>
              <SelectItem value="histogram">Histogram</SelectItem>
              <SelectItem value="qq">Q-Q Plot</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <Plot
          data={data}
          layout={layout}
          config={config}
          style={{ width: "100%" }}
          useResizeHandler
        />

        <div className="flex flex-wrap items-center gap-2">
          {isWhiteNoise != null && (
            <Badge variant={isWhiteNoise ? "default" : "destructive"}>
              {isWhiteNoise ? "White Noise" : "Not White Noise"}
            </Badge>
          )}
          {ljungBox && (
            <Badge variant="outline">
              Ljung-Box: {ljungBox.statistic.toFixed(2)} (p={ljungBox.p_value.toFixed(4)})
            </Badge>
          )}
          {jarqueBera && (
            <Badge variant="outline">
              Jarque-Bera: {jarqueBera.statistic.toFixed(2)} (p={jarqueBera.p_value.toFixed(4)})
            </Badge>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
