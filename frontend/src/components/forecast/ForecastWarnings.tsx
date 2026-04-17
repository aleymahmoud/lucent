"use client";

import { AlertTriangle, Info } from "lucide-react";
import { cn } from "@/lib/utils";

interface ForecastWarningsProps {
  warnings?: string[];
  variant?: "pre-run" | "post-run";
  className?: string;
}

/**
 * Displays a list of forecast warnings.
 *
 * - "pre-run" variant: shown before the user submits (informational)
 * - "post-run" variant: shown in the results tab (alert style)
 */
export function ForecastWarnings({
  warnings = [],
  variant = "pre-run",
  className,
}: ForecastWarningsProps) {
  if (!warnings || warnings.length === 0) {
    return null;
  }

  const isAlert = variant === "post-run";

  return (
    <div
      className={cn(
        "rounded-md border p-3 text-sm",
        isAlert
          ? "border-orange-200 bg-orange-50 dark:border-orange-800 dark:bg-orange-950/20"
          : "border-blue-200 bg-blue-50 dark:border-blue-800 dark:bg-blue-950/20",
        className
      )}
    >
      <div className="flex items-start gap-2">
        {isAlert ? (
          <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-orange-600 dark:text-orange-400" />
        ) : (
          <Info className="mt-0.5 h-4 w-4 shrink-0 text-blue-600 dark:text-blue-400" />
        )}
        <div className="flex-1 space-y-1">
          {warnings.length === 1 ? (
            <p className="text-foreground">{warnings[0]}</p>
          ) : (
            <ul className="list-disc space-y-1 pl-4">
              {warnings.map((w, i) => (
                <li key={i} className="text-foreground">
                  {w}
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </div>
  );
}
