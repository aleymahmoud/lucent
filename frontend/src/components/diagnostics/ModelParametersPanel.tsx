"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

// -------------------------------------------------------
// Types
// -------------------------------------------------------

interface ModelCoefficient {
  name: string;
  estimate: number;
  std_error?: number;
  z_stat?: number;
  p_value?: number;
  significant?: boolean;
}

interface ModelParametersPanelProps {
  method: string;
  parameters: Record<string, unknown>;
  coefficients?: Record<string, number> | ModelCoefficient[] | null;
  standardErrors?: Record<string, number> | null;
  aic?: number | null;
  bic?: number | null;
}

// Normalize either legacy Dict<str, float> or new ModelCoefficient[] into the new shape.
function normaliseCoefficients(
  coeffs: Record<string, number> | ModelCoefficient[] | null | undefined,
  standardErrors?: Record<string, number> | null,
): ModelCoefficient[] {
  if (!coeffs) return [];
  if (Array.isArray(coeffs)) return coeffs;
  return Object.entries(coeffs).map(([name, estimate]) => ({
    name,
    estimate,
    std_error: standardErrors?.[name],
  }));
}

// -------------------------------------------------------
// Helpers
// -------------------------------------------------------

function methodLabel(method: string): string {
  switch (method.toLowerCase()) {
    case "arima":
      return "ARIMA -- AutoRegressive Integrated Moving Average";
    case "ets":
      return "ETS -- Error, Trend, Seasonality (Exponential Smoothing)";
    case "prophet":
      return "Prophet -- Additive Regression Model by Meta";
    default:
      return method;
  }
}

function formatParamValue(value: unknown): string {
  if (value === null || value === undefined) return "--";
  if (Array.isArray(value)) return `[${value.join(", ")}]`;
  if (typeof value === "boolean") return value ? "true" : "false";
  if (typeof value === "number") {
    return Number.isInteger(value) ? String(value) : value.toFixed(4);
  }
  return String(value);
}

// -------------------------------------------------------
// Component
// -------------------------------------------------------

export function ModelParametersPanel({
  method,
  parameters,
  coefficients,
  standardErrors,
  aic,
  bic,
}: ModelParametersPanelProps) {
  const paramEntries = Object.entries(parameters ?? {});
  const coeffs = normaliseCoefficients(coefficients, standardErrors);
  const hasCoefficients = coeffs.length > 0;
  const hasStdErrors = coeffs.some((c) => c.std_error != null);
  const hasZStats = coeffs.some((c) => c.z_stat != null);
  const hasPValues = coeffs.some((c) => c.p_value != null);
  const isProphet = method.toLowerCase() === "prophet";

  return (
    <Card>
      <CardHeader>
        <CardTitle>Model Parameters</CardTitle>
        <CardDescription>{methodLabel(method)}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Method badge row + information criteria */}
        <div className="flex flex-wrap items-center gap-2">
          <Badge className="uppercase">{method}</Badge>
          {aic != null && (
            <Badge variant="outline">AIC: {aic.toFixed(2)}</Badge>
          )}
          {bic != null && (
            <Badge variant="outline">BIC: {bic.toFixed(2)}</Badge>
          )}
        </div>

        {/* Parameters key-value grid */}
        {paramEntries.length > 0 && (
          <div>
            <h4 className="mb-2 text-sm font-semibold">Parameters</h4>
            <div className="grid grid-cols-1 gap-1.5 sm:grid-cols-2">
              {paramEntries.map(([key, value]) => (
                <div
                  key={key}
                  className="flex items-center justify-between rounded-md bg-muted px-3 py-2 text-sm"
                >
                  <span className="text-muted-foreground capitalize">
                    {key.replace(/_/g, " ")}
                  </span>
                  <span className="font-mono text-foreground">
                    {formatParamValue(value)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Coefficients table (ARIMA/ETS only; Prophet uses hyperparameter grid above) */}
        {hasCoefficients && !isProphet && (
          <div>
            <h4 className="mb-2 text-sm font-semibold">Coefficients</h4>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead className="text-right">Estimate</TableHead>
                  {hasStdErrors && <TableHead className="text-right">Std. Error</TableHead>}
                  {hasZStats && <TableHead className="text-right">z-stat</TableHead>}
                  {hasPValues && <TableHead className="text-right">p-value</TableHead>}
                  {hasPValues && <TableHead className="text-right">Sig.</TableHead>}
                </TableRow>
              </TableHeader>
              <TableBody>
                {coeffs.map((c) => (
                  <TableRow key={c.name}>
                    <TableCell className="font-medium capitalize">
                      {c.name.replace(/_/g, " ")}
                    </TableCell>
                    <TableCell className="text-right font-mono tabular-nums">
                      {c.estimate.toFixed(4)}
                    </TableCell>
                    {hasStdErrors && (
                      <TableCell className="text-right font-mono tabular-nums text-muted-foreground">
                        {c.std_error != null ? c.std_error.toFixed(4) : "—"}
                      </TableCell>
                    )}
                    {hasZStats && (
                      <TableCell className="text-right font-mono tabular-nums text-muted-foreground">
                        {c.z_stat != null ? c.z_stat.toFixed(3) : "—"}
                      </TableCell>
                    )}
                    {hasPValues && (
                      <TableCell className="text-right font-mono tabular-nums">
                        {c.p_value != null ? c.p_value.toFixed(4) : "—"}
                      </TableCell>
                    )}
                    {hasPValues && (
                      <TableCell className="text-right">
                        {c.p_value == null ? (
                          <span className="text-xs text-muted-foreground">—</span>
                        ) : c.significant ? (
                          <Badge variant="default" className="text-[10px]">Sig.</Badge>
                        ) : (
                          <Badge variant="outline" className="text-[10px] text-muted-foreground">Not sig.</Badge>
                        )}
                      </TableCell>
                    )}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}

        {/* Empty state */}
        {paramEntries.length === 0 && !hasCoefficients && (
          <p className="text-sm text-muted-foreground">
            No detailed model parameter information available.
          </p>
        )}
      </CardContent>
    </Card>
  );
}
