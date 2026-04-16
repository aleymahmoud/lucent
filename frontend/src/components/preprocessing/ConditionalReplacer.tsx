"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Loader2, Info, AlertTriangle } from "lucide-react";
import { api } from "@/lib/api/client";
import { toast } from "sonner";

type Condition = "less_than" | "greater_than" | "equal_to" | "between";
type ReplacementMethod = "specific_value" | "weekday_mean" | "weekday_median";

interface ConditionalReplacerProps {
  datasetId: string;
  entityId: string | null;
  entityColumn: string | null;
  columns?: string[];
  onProcessingComplete?: () => void;
}

interface PreviewResult {
  affected_count: number;
  condition_text: string;
  replacement_text: string;
  weekday_breakdown?: Record<string, number>;
  warnings: string[];
}

const conditionOptions: { value: Condition; label: string }[] = [
  { value: "less_than", label: "Less than" },
  { value: "greater_than", label: "Greater than" },
  { value: "between", label: "Between" },
  { value: "equal_to", label: "Equal to" },
];

const methodOptions: { value: ReplacementMethod; label: string; description: string }[] = [
  { value: "specific_value", label: "Specific Value", description: "Replace with a fixed number" },
  { value: "weekday_mean", label: "Mean of Same Weekday", description: "Replace with average of same weekday (per entity)" },
  { value: "weekday_median", label: "Median of Same Weekday", description: "Replace with median of same weekday (per entity)" },
];

export function ConditionalReplacer({
  datasetId,
  entityId,
  entityColumn,
  columns: availableColumns,
  onProcessingComplete,
}: ConditionalReplacerProps) {
  const [column, setColumn] = useState<string>("");
  const [condition, setCondition] = useState<Condition>("less_than");
  const [threshold1, setThreshold1] = useState<string>("0");
  const [threshold2, setThreshold2] = useState<string>("10");
  const [method, setMethod] = useState<ReplacementMethod>("specific_value");
  const [replacementValue, setReplacementValue] = useState<string>("0");
  const [preview, setPreview] = useState<PreviewResult | null>(null);
  const [previewing, setPreviewing] = useState(false);
  const [processing, setProcessing] = useState(false);

  const buildRequestBody = () => {
    const body: Record<string, unknown> = {
      column,
      condition,
      threshold1: parseFloat(threshold1) || 0,
      replacement_method: method,
    };
    if (condition === "between") {
      body.threshold2 = parseFloat(threshold2) || 0;
    }
    if (method === "specific_value") {
      body.replacement_value = parseFloat(replacementValue) || 0;
    }
    return body;
  };

  useEffect(() => {
    if (!column) {
      setPreview(null);
      return;
    }
    const timer = setTimeout(async () => {
      setPreviewing(true);
      try {
        const params = new URLSearchParams();
        if (entityId) params.append("entity_id", entityId);
        if (entityColumn) params.append("entity_column", entityColumn);

        const result = await api.post<PreviewResult>(
          `/preprocessing/${datasetId}/replace-conditional/preview${params.toString() ? `?${params}` : ""}`,
          buildRequestBody()
        );
        setPreview(result);
      } catch {
        setPreview(null);
      } finally {
        setPreviewing(false);
      }
    }, 400);
    return () => clearTimeout(timer);
  }, [datasetId, entityId, entityColumn, column, condition, threshold1, threshold2, method, replacementValue]);

  const handleApply = async () => {
    if (!column) {
      toast.error("Please select a column");
      return;
    }
    if (method === "specific_value" && replacementValue === "") {
      toast.error("Please enter a replacement value");
      return;
    }

    setProcessing(true);
    try {
      const params = new URLSearchParams();
      if (entityId) params.append("entity_id", entityId);
      if (entityColumn) params.append("entity_column", entityColumn);

      const result = await api.post<{
        rows_affected: number;
        message: string;
      }>(
        `/preprocessing/${datasetId}/replace-conditional${params.toString() ? `?${params}` : ""}`,
        buildRequestBody()
      );

      toast.success(`${result.rows_affected} value${result.rows_affected !== 1 ? "s" : ""} replaced`);
      onProcessingComplete?.();
    } catch (err: any) {
      toast.error(err.response?.data?.detail || "Failed to replace values");
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div className="space-y-4 p-4 border rounded-md bg-muted/30">
      {/* Column */}
      <div className="space-y-2">
        <Label>Column</Label>
        <Select value={column} onValueChange={setColumn}>
          <SelectTrigger>
            <SelectValue placeholder="Select numeric column" />
          </SelectTrigger>
          <SelectContent>
            {availableColumns?.map((c) => (
              <SelectItem key={c} value={c}>
                {c}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Condition + Thresholds */}
      <div className="grid grid-cols-3 gap-4">
        <div className="space-y-2">
          <Label>Condition</Label>
          <Select value={condition} onValueChange={(v) => setCondition(v as Condition)}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {conditionOptions.map((o) => (
                <SelectItem key={o.value} value={o.value}>
                  {o.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>Value {condition === "between" ? "1" : ""}</Label>
          <Input
            type="number"
            step="any"
            value={threshold1}
            onChange={(e) => setThreshold1(e.target.value)}
          />
        </div>
        {condition === "between" && (
          <div className="space-y-2">
            <Label>Value 2</Label>
            <Input
              type="number"
              step="any"
              value={threshold2}
              onChange={(e) => setThreshold2(e.target.value)}
            />
          </div>
        )}
      </div>

      {/* Replacement */}
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label>Replace with</Label>
          <Select value={method} onValueChange={(v) => setMethod(v as ReplacementMethod)}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {methodOptions.map((o) => (
                <SelectItem key={o.value} value={o.value}>
                  <div>
                    <div className="font-medium">{o.label}</div>
                    <div className="text-xs text-muted-foreground">{o.description}</div>
                  </div>
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        {method === "specific_value" && (
          <div className="space-y-2">
            <Label>Value</Label>
            <Input
              type="number"
              step="any"
              value={replacementValue}
              onChange={(e) => setReplacementValue(e.target.value)}
            />
          </div>
        )}
      </div>

      {/* Preview */}
      {previewing && (
        <div className="flex items-center gap-2 p-3 bg-muted rounded-md text-sm text-muted-foreground">
          <Loader2 className="h-4 w-4 animate-spin" />
          Calculating preview...
        </div>
      )}

      {!previewing && preview && (
        <div className={`p-3 rounded-md text-sm border ${preview.affected_count > 0 ? "bg-orange-50 border-orange-200 dark:bg-orange-950/20" : "bg-muted"}`}>
          <div className="flex items-start gap-2">
            {preview.affected_count > 0 ? (
              <AlertTriangle className="h-4 w-4 text-orange-600 mt-0.5 shrink-0" />
            ) : (
              <Info className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
            )}
            <div className="flex-1">
              <p>
                {preview.condition_text} will replace{" "}
                <span className="font-semibold">{preview.affected_count}</span> record
                {preview.affected_count !== 1 ? "s" : ""} {preview.replacement_text}.
              </p>
              {preview.weekday_breakdown && Object.keys(preview.weekday_breakdown).length > 0 && (
                <div className="flex flex-wrap gap-1 mt-2">
                  {Object.entries(preview.weekday_breakdown).map(([day, count]) => (
                    <Badge key={day} variant="secondary" className="text-xs">
                      {day}: {count}
                    </Badge>
                  ))}
                </div>
              )}
              {preview.warnings.map((w, i) => (
                <p key={i} className="text-xs text-orange-700 dark:text-orange-400 mt-1">
                  ⚠ {w}
                </p>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Apply */}
      <Button
        onClick={handleApply}
        disabled={processing || !column || !preview || preview.affected_count === 0}
        className="w-full"
      >
        {processing ? (
          <>
            <Loader2 className="h-4 w-4 mr-2 animate-spin" />
            Applying...
          </>
        ) : (
          "Apply Conditional Replacement"
        )}
      </Button>
    </div>
  );
}
