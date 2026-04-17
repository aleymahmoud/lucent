"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { BarChart3 } from "lucide-react";

interface Metrics {
  mae: number;
  rmse: number;
  mape: number;
}

interface CrossValidationResult {
  folds: number;
  method: string;
  metrics_per_fold: Metrics[];
  average_metrics: Metrics;
}

interface CrossValidationPanelProps {
  cvResults: CrossValidationResult;
}

function fmt(n: number | null | undefined, digits = 3): string {
  if (n === null || n === undefined || Number.isNaN(n) || !Number.isFinite(n)) return "—";
  return n.toLocaleString(undefined, { minimumFractionDigits: digits, maximumFractionDigits: digits });
}

/**
 * Cross-validation results panel (Results page).
 * Renders only when cv_results is populated in the forecast response.
 */
export function CrossValidationPanel({ cvResults }: CrossValidationPanelProps) {
  const { folds, method, metrics_per_fold, average_metrics } = cvResults;

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2 text-base">
              <BarChart3 className="h-4 w-4" />
              Out-of-Sample Accuracy (Cross-Validation)
            </CardTitle>
            <CardDescription>
              These metrics reflect how the model performs on unseen data —
              typically worse than in-sample fit. A large gap suggests overfitting.
            </CardDescription>
          </div>
          <div className="flex items-center gap-2">
            <Badge variant="secondary" className="capitalize">
              {method} window
            </Badge>
            <Badge variant="outline">{folds} folds</Badge>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Fold</TableHead>
              <TableHead className="text-right">MAE</TableHead>
              <TableHead className="text-right">RMSE</TableHead>
              <TableHead className="text-right">MAPE</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {metrics_per_fold.map((m, i) => (
              <TableRow key={i}>
                <TableCell>Fold {i + 1}</TableCell>
                <TableCell className="text-right tabular-nums">{fmt(m.mae)}</TableCell>
                <TableCell className="text-right tabular-nums">{fmt(m.rmse)}</TableCell>
                <TableCell className="text-right tabular-nums">{fmt(m.mape, 2)}%</TableCell>
              </TableRow>
            ))}
            <TableRow className="border-t-2 bg-muted/40 font-semibold">
              <TableCell>Average</TableCell>
              <TableCell className="text-right tabular-nums">{fmt(average_metrics.mae)}</TableCell>
              <TableCell className="text-right tabular-nums">{fmt(average_metrics.rmse)}</TableCell>
              <TableCell className="text-right tabular-nums">{fmt(average_metrics.mape, 2)}%</TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}
