"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { FileDown, Loader2 } from "lucide-react";
import { toast } from "sonner";

interface DiagnosticsExportPanelProps {
  forecastId: string;
}

const API_BASE =
  typeof window !== "undefined"
    ? (process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1")
    : "http://localhost:8000/api/v1";

/**
 * Download a self-contained diagnostics HTML report.
 * PDF support is deferred — users can print-to-PDF from their browser.
 */
export function DiagnosticsExportPanel({ forecastId }: DiagnosticsExportPanelProps) {
  const [loading, setLoading] = useState(false);

  const handleExport = async () => {
    setLoading(true);
    try {
      const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
      const res = await fetch(
        `${API_BASE}/diagnostics/${forecastId}/export?format=html`,
        { headers: token ? { Authorization: `Bearer ${token}` } : {} }
      );
      if (!res.ok) throw new Error(`Server responded with ${res.status}`);
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `diagnostics-${forecastId}.html`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      toast.success("Report downloaded", {
        description: "Open the HTML file and use your browser's print function to save as PDF.",
      });
    } catch (err) {
      toast.error("Export failed", {
        description: err instanceof Error ? err.message : "Unknown error",
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Button variant="outline" size="sm" onClick={handleExport} disabled={loading}>
      {loading ? (
        <Loader2 className="h-4 w-4 mr-2 animate-spin" />
      ) : (
        <FileDown className="h-4 w-4 mr-2" />
      )}
      {loading ? "Exporting..." : "Export Report"}
    </Button>
  );
}
