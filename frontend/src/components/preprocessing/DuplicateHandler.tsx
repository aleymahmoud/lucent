"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import { Loader2, Copy, CheckCircle2 } from "lucide-react";
import { api } from "@/lib/api/client";
import { toast } from "sonner";

type DuplicateMethod = "keep_all" | "keep_first" | "keep_last" | "drop_all" | "aggregate_sum" | "aggregate_mean";

interface DuplicateHandlerProps {
  datasetId: string;
  entityId: string | null;
  entityColumn: string | null;
  columns?: string[];
  onProcessingComplete?: () => void;
}

const methodOptions: { value: DuplicateMethod; label: string; description: string }[] = [
  { value: "keep_all", label: "Keep All", description: "Retain all duplicate entries (no changes)" },
  { value: "keep_first", label: "Keep First", description: "Keep the first occurrence of duplicates" },
  { value: "keep_last", label: "Keep Last", description: "Keep the last occurrence of duplicates" },
  { value: "aggregate_sum", label: "Aggregate Sum", description: "Combine duplicates by summing values" },
  { value: "aggregate_mean", label: "Aggregate Mean", description: "Combine duplicates by averaging values" },
  { value: "drop_all", label: "Drop All", description: "Remove all rows involved in duplicates" },
];

export function DuplicateHandler({
  datasetId,
  entityId,
  entityColumn,
  columns: availableColumns,
  onProcessingComplete,
}: DuplicateHandlerProps) {
  const [analysis, setAnalysis] = useState<{
    total_rows: number;
    duplicate_rows: number;
    duplicate_percentage: number;
    duplicate_groups: number;
  } | null>(null);
  const [loading, setLoading] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [selectedMethod, setSelectedMethod] = useState<DuplicateMethod>("keep_first");
  const [subsetColumns, setSubsetColumns] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);

  const handleAnalyze = async () => {
    setLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams();
      if (entityId) params.append("entity_id", entityId);
      if (entityColumn) params.append("entity_column", entityColumn);
      if (subsetColumns.length > 0) params.append("subset", subsetColumns.join(","));

      const response = await api.get<{
        total_rows: number;
        duplicate_rows: number;
        duplicate_percentage: number;
        duplicate_groups: number;
      }>(
        `/preprocessing/${datasetId}/duplicates${params.toString() ? `?${params}` : ""}`
      );

      setAnalysis(response);
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to analyze duplicates");
    } finally {
      setLoading(false);
    }
  };

  const handleColumnToggle = (column: string) => {
    setSubsetColumns((prev) =>
      prev.includes(column) ? prev.filter((c) => c !== column) : [...prev, column]
    );
    // Reset analysis when columns change
    setAnalysis(null);
  };

  const handleApply = async () => {
    setProcessing(true);
    try {
      const params = new URLSearchParams();
      if (entityId) params.append("entity_id", entityId);
      if (entityColumn) params.append("entity_column", entityColumn);

      const result = await api.post<{
        success: boolean;
        message: string;
        rows_before: number;
        rows_after: number;
        rows_affected: number;
      }>(
        `/preprocessing/${datasetId}/duplicates${params.toString() ? `?${params}` : ""}`,
        {
          method: selectedMethod,
          subset: subsetColumns.length > 0 ? subsetColumns : undefined,
        }
      );

      const methodLabel = methodOptions.find((m) => m.value === selectedMethod)?.label || selectedMethod;
      if (selectedMethod === "keep_all") {
        toast.success("All rows kept — no duplicates removed");
      } else {
        toast.success(`${result.rows_affected} duplicate row${result.rows_affected !== 1 ? "s" : ""} handled using ${methodLabel}`);
      }
      if (onProcessingComplete) {
        onProcessingComplete();
      }
    } catch (err: any) {
      toast.error(err.response?.data?.detail || "Failed to handle duplicates");
    } finally {
      setProcessing(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Copy className="h-5 w-5" />
          Duplicate Detection
        </CardTitle>
        <CardDescription>Find and handle duplicate rows in your data</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Column Selection for Subset */}
        {availableColumns && availableColumns.length > 0 && (
          <div className="space-y-2">
            <Label>Check Duplicates Based On (Optional)</Label>
            <p className="text-xs text-muted-foreground mb-2">
              Select specific columns to check for duplicates. If none selected, Entity + Date columns are used automatically.
            </p>
            <div className="max-h-32 overflow-y-auto border rounded-md p-2 space-y-1">
              {availableColumns.map((col) => (
                <div key={col} className="flex items-center gap-2 p-1 hover:bg-muted rounded">
                  <Checkbox
                    checked={subsetColumns.includes(col)}
                    onCheckedChange={() => handleColumnToggle(col)}
                  />
                  <span className="text-sm">{col}</span>
                </div>
              ))}
            </div>
            {subsetColumns.length > 0 && (
              <div className="flex flex-wrap gap-1 mt-2">
                {subsetColumns.map((col) => (
                  <Badge key={col} variant="secondary">
                    {col}
                  </Badge>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Analyze Button */}
        <Button onClick={handleAnalyze} disabled={loading} variant="outline" className="w-full">
          {loading ? (
            <>
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              Analyzing...
            </>
          ) : (
            "Analyze Duplicates"
          )}
        </Button>

        {error && <div className="text-center py-4 text-destructive">{error}</div>}

        {analysis && analysis.duplicate_rows === 0 && (
          <div className="flex items-center justify-center py-8 text-green-600">
            <CheckCircle2 className="h-6 w-6 mr-2" />
            <span>No duplicates found in the dataset</span>
          </div>
        )}

        {analysis && analysis.duplicate_rows > 0 && (
          <>
            {/* Summary */}
            <div className="grid grid-cols-2 gap-4">
              <div className="p-3 bg-muted rounded-md">
                <div className="text-sm text-muted-foreground">Total Rows</div>
                <div className="text-xl font-semibold">{analysis.total_rows.toLocaleString()}</div>
              </div>
              <div className="p-3 bg-muted rounded-md">
                <div className="text-sm text-muted-foreground">Duplicate Rows</div>
                <div className="text-xl font-semibold text-orange-600">
                  {analysis.duplicate_rows.toLocaleString()}
                  <span className="text-sm font-normal text-muted-foreground ml-2">
                    ({analysis.duplicate_percentage.toFixed(1)}%)
                  </span>
                </div>
              </div>
            </div>

            {/* Method Selection */}
            <div className="space-y-2">
              <Label>Handling Method</Label>
              <Select value={selectedMethod} onValueChange={(v) => setSelectedMethod(v as DuplicateMethod)}>
                <SelectTrigger>
                  <SelectValue placeholder="Select method" />
                </SelectTrigger>
                <SelectContent>
                  {methodOptions.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      <div>
                        <div className="font-medium">{option.label}</div>
                        <div className="text-xs text-muted-foreground">{option.description}</div>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Preview of Impact */}
            <div className="p-3 bg-muted rounded-md text-sm">
              <p className="font-medium">Impact Preview:</p>
              <p className="text-muted-foreground mt-1">
                {selectedMethod === "keep_all" && "No rows will be removed"}
                {selectedMethod === "keep_first" && `Will remove ${analysis.duplicate_rows} rows, keeping first occurrence`}
                {selectedMethod === "keep_last" && `Will remove ${analysis.duplicate_rows} rows, keeping last occurrence`}
                {selectedMethod === "aggregate_sum" && `Will merge duplicate groups by summing numeric values`}
                {selectedMethod === "aggregate_mean" && `Will merge duplicate groups by averaging numeric values`}
                {selectedMethod === "drop_all" && `Will remove all rows involved in duplicates`}
              </p>
            </div>

            {/* Apply Button */}
            <Button onClick={handleApply} disabled={processing} className="w-full">
              {processing ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Processing...
                </>
              ) : (
                "Remove Duplicates"
              )}
            </Button>
          </>
        )}
      </CardContent>
    </Card>
  );
}
