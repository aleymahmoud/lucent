"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Slider } from "@/components/ui/slider";
import { Sparkles } from "lucide-react";

interface ForecastConfig {
  method: "arima" | "ets" | "prophet";
  horizon: number;
  frequency: "daily" | "weekly" | "monthly" | "quarterly" | "yearly";
  frequencyAutoDetect?: boolean;
  confidenceLevel: number;
  methodSettings: Record<string, unknown>;
}

interface ForecastSettingsProps {
  config: ForecastConfig;
  onChange: (config: Partial<ForecastConfig>) => void;
  detectedFrequency?: string; // "D" | "W" | "M" | "Q" | "Y"
}

const FREQ_CODE_TO_LABEL: Record<string, string> = {
  D: "Daily",
  W: "Weekly",
  M: "Monthly",
  Q: "Quarterly",
  Y: "Yearly",
};

export function ForecastSettings({ config, onChange, detectedFrequency }: ForecastSettingsProps) {
  const autoDetect = config.frequencyAutoDetect !== false; // default true
  const detectedLabel = detectedFrequency ? FREQ_CODE_TO_LABEL[detectedFrequency] : undefined;

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-base">Forecast Settings</CardTitle>
        <CardDescription>Configure horizon, frequency, and confidence</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Horizon */}
        <div className="space-y-2">
          <Label htmlFor="horizon" className="text-sm">Forecast Horizon</Label>
          <Input
            id="horizon"
            type="number"
            min={1}
            max={365}
            value={config.horizon}
            onChange={(e) => onChange({ horizon: parseInt(e.target.value) || 30 })}
            className="h-9"
          />
          <p className="text-xs text-muted-foreground">
            Number of periods to forecast (1-365)
          </p>
        </div>

        {/* Frequency with auto-detect */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label className="text-sm">Data Frequency</Label>
            <div className="flex items-center gap-2">
              <Switch
                id="auto-detect-freq"
                checked={autoDetect}
                onCheckedChange={(checked) => onChange({ frequencyAutoDetect: checked })}
              />
              <Label htmlFor="auto-detect-freq" className="text-xs font-normal cursor-pointer">
                Auto-detect
              </Label>
            </div>
          </div>
          <Select
            value={config.frequency}
            disabled={autoDetect}
            onValueChange={(value: "daily" | "weekly" | "monthly" | "quarterly" | "yearly") =>
              onChange({ frequency: value })
            }
          >
            <SelectTrigger className="h-9">
              <SelectValue placeholder="Select frequency" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="daily">Daily</SelectItem>
              <SelectItem value="weekly">Weekly</SelectItem>
              <SelectItem value="monthly">Monthly</SelectItem>
              <SelectItem value="quarterly">Quarterly</SelectItem>
              <SelectItem value="yearly">Yearly</SelectItem>
            </SelectContent>
          </Select>
          {autoDetect && detectedLabel && (
            <p className="flex items-center gap-1 text-xs text-muted-foreground">
              <Sparkles className="h-3 w-3" />
              Detected: <span className="font-medium text-foreground">{detectedLabel}</span>
            </p>
          )}
          {autoDetect && !detectedLabel && (
            <p className="text-xs text-muted-foreground">Select an entity to detect frequency</p>
          )}
        </div>

        {/* Confidence Level */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label className="text-sm">Confidence Level</Label>
            <span className="text-sm font-medium">{Math.round(config.confidenceLevel * 100)}%</span>
          </div>
          <Slider
            value={[config.confidenceLevel * 100]}
            min={80}
            max={99}
            step={1}
            onValueChange={([value]) => onChange({ confidenceLevel: value / 100 })}
            className="py-2"
          />
          <p className="text-xs text-muted-foreground">
            Width of prediction intervals
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
