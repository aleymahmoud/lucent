"use client";

import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Plus, Trash2, Play, Loader2, Trophy } from "lucide-react";
import { toast } from "sonner";

import { api } from "@/lib/api/client";

interface ModelComparisonPanelProps {
  /** Pre-seed the panel with this forecast ID. */
  currentForecastId?: string;
}

interface ComparisonModel {
  forecast_id: string;
  method: string;
  entity_id: string;
  metrics: { mae: number; rmse: number; mape: number };
  quality: { accuracy: number; stability: number; reliability: number; coverage: number };
  composite_score?: number;
}

interface ComparisonResponse {
  models: ComparisonModel[];
  best_model: string;
}

export function ModelComparisonPanel({ currentForecastId }: ModelComparisonPanelProps) {
  const [ids, setIds] = useState<string[]>(() =>
    currentForecastId ? [currentForecastId, ""] : ["", ""]
  );
  const [running, setRunning] = useState(false);
  const [response, setResponse] = useState<ComparisonResponse | null>(null);

  const setAt = (i: number, value: string) =>
    setIds((prev) => prev.map((v, idx) => (idx === i ? value : v)));

  const addRow = () => {
    if (ids.length >= 5) return;
    setIds((prev) => [...prev, ""]);
  };

  const removeAt = (i: number) => {
    if (ids.length <= 2) return;
    setIds((prev) => prev.filter((_, idx) => idx !== i));
  };

  const runComparison = async () => {
    const cleaned = ids.map((s) => s.trim()).filter(Boolean);
    if (cleaned.length < 2) {
      toast.error("Enter at least 2 forecast IDs to compare");
      return;
    }
    setRunning(true);
    setResponse(null);
    try {
      const res = await api.post<ComparisonResponse>("/diagnostics/compare", {
        forecast_ids: cleaned,
      });
      setResponse(res);
      toast.success(`Compared ${res.models.length} models`);
    } catch (err: any) {
      toast.error(err.response?.data?.detail || "Comparison failed");
    } finally {
      setRunning(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Compare Models</CardTitle>
        <CardDescription>
          Enter 2–5 forecast IDs to compare their accuracy, stability, reliability, and coverage side-by-side.
          The best model is ranked by composite score.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <Label>Forecast IDs</Label>
          {ids.map((id, i) => (
            <div key={i} className="flex items-center gap-2">
              <Input
                placeholder="Paste a forecast ID (UUID)"
                value={id}
                onChange={(e) => setAt(i, e.target.value)}
                disabled={running}
                className="font-mono text-xs"
              />
              <Button
                variant="ghost"
                size="icon"
                onClick={() => removeAt(i)}
                disabled={running || ids.length <= 2}
                aria-label="Remove"
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </div>
          ))}
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={addRow}
              disabled={running || ids.length >= 5}
            >
              <Plus className="h-4 w-4 mr-1" />
              Add another
            </Button>
            <Button onClick={runComparison} disabled={running}>
              {running ? (
                <>
                  <Loader2 className="h-4 w-4 mr-1 animate-spin" />
                  Comparing...
                </>
              ) : (
                <>
                  <Play className="h-4 w-4 mr-1" />
                  Run Comparison
                </>
              )}
            </Button>
          </div>
        </div>

        {response && response.models.length > 0 && (
          <div className="space-y-2">
            <Label>Results</Label>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Method</TableHead>
                  <TableHead className="text-right">MAE</TableHead>
                  <TableHead className="text-right">RMSE</TableHead>
                  <TableHead className="text-right">MAPE</TableHead>
                  <TableHead className="text-right">Composite</TableHead>
                  <TableHead className="w-10"></TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {response.models.map((m) => {
                  const isBest = m.forecast_id === response.best_model;
                  return (
                    <TableRow
                      key={m.forecast_id}
                      className={isBest ? "bg-green-50 dark:bg-green-950/20" : ""}
                    >
                      <TableCell>
                        <div className="flex flex-col">
                          <span className="font-medium uppercase">{m.method}</span>
                          <span className="font-mono text-[10px] text-muted-foreground">
                            {m.forecast_id.slice(0, 8)}…
                          </span>
                        </div>
                      </TableCell>
                      <TableCell className="text-right tabular-nums">
                        {m.metrics.mae?.toFixed(3) ?? "—"}
                      </TableCell>
                      <TableCell className="text-right tabular-nums">
                        {m.metrics.rmse?.toFixed(3) ?? "—"}
                      </TableCell>
                      <TableCell className="text-right tabular-nums">
                        {m.metrics.mape?.toFixed(2) ?? "—"}%
                      </TableCell>
                      <TableCell className="text-right tabular-nums font-semibold">
                        {m.composite_score?.toFixed(1) ?? "—"}
                      </TableCell>
                      <TableCell>
                        {isBest && (
                          <Badge variant="default" className="gap-1">
                            <Trophy className="h-3 w-3" />
                            Best
                          </Badge>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
