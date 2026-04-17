"use client";

import dynamic from "next/dynamic";
import { useMemo, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Loader2 } from "lucide-react";
import type { Prediction } from "@/types";

const Plot = dynamic(() => import("react-plotly.js"), {
  ssr: false,
  loading: () => (
    <div className="flex h-[400px] items-center justify-center">
      <Loader2 className="h-8 w-8 animate-spin text-primary" />
    </div>
  ),
});

type PlotType = "line" | "line-points" | "area";

interface ForecastChartProps {
  predictions: Prediction[];
  entityId?: string;
  method?: string;
}

export function ForecastChart({ predictions, entityId, method }: ForecastChartProps) {
  const [plotType, setPlotType] = useState<PlotType>("line");
  const [showIntervals, setShowIntervals] = useState(true);

  const n = predictions?.length ?? 0;

  const { data, layout, subtitle } = useMemo(() => {
    if (!predictions || predictions.length === 0) {
      return { data: [], layout: {}, subtitle: "" };
    }

    const dates = predictions.map((p) => p.date);
    const values = predictions.map((p) => p.value);
    const lower = predictions.map((p) => p.lowerBound);
    const upper = predictions.map((p) => p.upperBound);

    const ciX = [...dates, ...dates.slice().reverse()];
    const ciY = [...upper, ...lower.slice().reverse()];

    const traces: Plotly.Data[] = [];

    // Confidence interval band — only when toggle is on
    if (showIntervals) {
      traces.push({
        x: ciX, y: ciY,
        fill: "toself" as const,
        fillcolor: "rgba(59, 130, 246, 0.12)",
        line: { color: "transparent", width: 0 },
        name: "Confidence Interval",
        type: "scatter" as const, mode: "lines" as const,
        showlegend: true,
        hoverinfo: "skip" as const,
      });
    }

    // Forecast line — three rendering modes
    const baseLine: Partial<Plotly.Data> = {
      x: dates, y: values,
      type: "scatter" as const,
      name: "Forecast",
      line: { color: "#3b82f6", width: 2.5 },
      hovertemplate: "<b>%{x}</b><br>Value: %{y:.4f}<extra></extra>",
    } as any;

    if (plotType === "line") {
      traces.push({ ...(baseLine as any), mode: "lines" });
    } else if (plotType === "line-points") {
      traces.push({
        ...(baseLine as any),
        mode: "lines+markers",
        marker: { color: "#3b82f6", size: 5 },
      });
    } else {
      // Area — fill to zero
      traces.push({
        ...(baseLine as any),
        mode: "lines",
        fill: "tozeroy" as const,
        fillcolor: "rgba(59, 130, 246, 0.25)",
      });
    }

    if (showIntervals) {
      traces.push({
        x: dates, y: upper,
        type: "scatter" as const, mode: "lines" as const,
        name: "Upper Bound",
        line: { color: "#93c5fd", width: 1, dash: "dash" },
        hovertemplate: "<b>%{x}</b><br>Upper: %{y:.4f}<extra></extra>",
      });
      traces.push({
        x: dates, y: lower,
        type: "scatter" as const, mode: "lines" as const,
        name: "Lower Bound",
        line: { color: "#93c5fd", width: 1, dash: "dash" },
        hovertemplate: "<b>%{x}</b><br>Lower: %{y:.4f}<extra></extra>",
      });
    }

    const rangeSliderEnabled = n > 90;
    const lay: Partial<Plotly.Layout> = {
      autosize: true,
      height: 420,
      margin: { l: 60, r: 20, t: 20, b: rangeSliderEnabled ? 100 : 70 },
      xaxis: {
        title: { text: "Date", standoff: 12 },
        tickangle: -40,
        showgrid: true,
        gridcolor: "rgba(0,0,0,0.05)",
        tickfont: { size: 11 },
        rangeslider: rangeSliderEnabled ? { visible: true, thickness: 0.08 } : { visible: false },
      },
      yaxis: {
        title: { text: "Value", standoff: 8 },
        showgrid: true,
        gridcolor: "rgba(0,0,0,0.05)",
        tickfont: { size: 11 },
      },
      showlegend: true,
      legend: { orientation: "h", y: -0.28, x: 0.5, xanchor: "center", font: { size: 12 } },
      hovermode: "x unified",
      plot_bgcolor: "rgba(0,0,0,0)",
      paper_bgcolor: "rgba(0,0,0,0)",
    };

    const sub = [entityId, method?.toUpperCase()].filter(Boolean).join(" — ");
    return { data: traces, layout: lay, subtitle: sub };
  }, [predictions, plotType, showIntervals, entityId, method, n]);

  const config: Partial<Plotly.Config> = {
    responsive: true,
    displayModeBar: true,
    displaylogo: false,
    modeBarButtonsToRemove: ["select2d", "lasso2d", "autoScale2d"],
  };

  if (!predictions || predictions.length === 0) {
    return (
      <Card>
        <CardContent className="flex h-[400px] items-center justify-center">
          <p className="text-muted-foreground">No prediction data available.</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="pb-2">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <CardTitle>Forecast Chart</CardTitle>
            {subtitle && <CardDescription>{subtitle}</CardDescription>}
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Switch
                id="show-intervals"
                checked={showIntervals}
                onCheckedChange={setShowIntervals}
              />
              <Label htmlFor="show-intervals" className="text-xs font-normal cursor-pointer">
                Intervals
              </Label>
            </div>
            <Select value={plotType} onValueChange={(v) => setPlotType(v as PlotType)}>
              <SelectTrigger className="w-[160px] h-9">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="line">Line</SelectItem>
                <SelectItem value="line-points">Line + Points</SelectItem>
                <SelectItem value="area">Area</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
      </CardHeader>
      <CardContent className="px-2 pb-2">
        <Plot
          data={data}
          layout={layout}
          config={config}
          style={{ width: "100%" }}
          useResizeHandler
        />
      </CardContent>
    </Card>
  );
}
