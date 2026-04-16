"use client";

import { useState, useEffect, useCallback } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import dynamic from "next/dynamic";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  ArrowLeft,
  ArrowRight,
  Database,
  AlertTriangle,
  TrendingUp,
  Calendar,
  Copy,
  RotateCcw,
  Download,
  Loader2,
  CheckCircle2,
  Replace,
  Users,
  ChevronLeft,
  ChevronRight,
  BarChart2,
} from "lucide-react";
import { toast } from "sonner";
import { api } from "@/lib/api/client";

import {
  MissingValuesHandler,
  OutlierHandler,
  TimeAggregator,
  DuplicateHandler,
  ValueReplacer,
} from "@/components/preprocessing";

const Plot = dynamic(() => import("react-plotly.js"), {
  ssr: false,
  loading: () => (
    <div className="flex h-[400px] items-center justify-center">
      <Loader2 className="h-8 w-8 animate-spin text-primary" />
    </div>
  ),
});

// ── Types ────────────────────────────────────────────────────────────────────

interface Dataset {
  id: string;
  name: string;
  filename: string;
  row_count: number | null;
  column_count: number | null;
  columns?: string[];
  entities: string[];
}

interface EntityInfo {
  name: string;
  row_count: number;
  date_range?: {
    start?: string;
    end?: string;
  };
}

interface EntityListResponse {
  entities: EntityInfo[];
  entity_column: string;
  total: number;
}

interface EntityDataResponse {
  columns: string[];
  data: Record<string, any>[];
  row_count: number;
}

// ── Page ─────────────────────────────────────────────────────────────────────

export default function PreprocessingPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const datasetIdParam = searchParams.get("dataset");

  // Dataset state
  const [datasets, setDatasets] = useState<Dataset[]>([]);
  const [selectedDatasetId, setSelectedDatasetId] = useState<string | null>(datasetIdParam);
  const [selectedDataset, setSelectedDataset] = useState<Dataset | null>(null);
  const [loading, setLoading] = useState(true);

  // Entity state (inlined from EntitySelector)
  const [entities, setEntities] = useState<EntityInfo[]>([]);
  const [entitiesLoading, setEntitiesLoading] = useState(false);
  const [entitiesError, setEntitiesError] = useState<string | null>(null);
  const [selectedEntity, setSelectedEntity] = useState<string | null>(null);
  const [entityColumn, setEntityColumn] = useState<string | null>(null);
  const [totalEntityRows, setTotalEntityRows] = useState<number>(0);

  // Chart state
  const [chartDates, setChartDates] = useState<string[]>([]);
  const [chartVolumes, setChartVolumes] = useState<number[]>([]);
  const [chartLoading, setChartLoading] = useState(false);

  // Action state
  const [resetting, setResetting] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [activeTab, setActiveTab] = useState("missing");
  const [refreshKey, setRefreshKey] = useState(0);

  // ── Fetch datasets on mount ─────────────────────────────────────────────────

  useEffect(() => {
    const fetchDatasets = async () => {
      try {
        const response = await api.get<{ datasets: Dataset[]; total: number }>("/datasets");
        setDatasets(response.datasets || []);

        if (datasetIdParam) {
          const dataset = response.datasets?.find((d: Dataset) => d.id === datasetIdParam);
          if (dataset) {
            setSelectedDataset(dataset);
          }
        }
      } catch {
        toast.error("Failed to load datasets");
      } finally {
        setLoading(false);
      }
    };

    fetchDatasets();
  }, [datasetIdParam]);

  // ── Fetch entities when dataset changes ────────────────────────────────────

  useEffect(() => {
    if (!selectedDatasetId) {
      setEntities([]);
      setSelectedEntity(null);
      setEntityColumn(null);
      return;
    }

    const fetchEntities = async () => {
      setEntitiesLoading(true);
      setEntitiesError(null);

      try {
        const response = await api.get<EntityListResponse>(
          `/preprocessing/${selectedDatasetId}/entities`
        );
        setEntities(response.entities || []);
        setEntityColumn(response.entity_column || null);
        setTotalEntityRows(response.total || 0);
      } catch (err: any) {
        setEntitiesError(err.response?.data?.detail || "Failed to load entities");
        setEntities([]);
      } finally {
        setEntitiesLoading(false);
      }
    };

    fetchEntities();
  }, [selectedDatasetId, refreshKey]);

  // ── Fetch chart data when entity or refreshKey changes ─────────────────────

  useEffect(() => {
    if (!selectedDatasetId || !selectedEntity) {
      setChartDates([]);
      setChartVolumes([]);
      return;
    }

    const fetchChartData = async () => {
      setChartLoading(true);
      setChartDates([]);
      setChartVolumes([]);
      try {
        const ecParam = entityColumn ? `&entity_column=${encodeURIComponent(entityColumn)}` : "";
        const response = await api.get<EntityDataResponse>(
          `/preprocessing/${selectedDatasetId}/entity/${encodeURIComponent(selectedEntity)}/data?page=1&page_size=1000${ecParam}`
        );

        const rows = response.data || [];

        if (rows.length === 0) {
          setChartDates([]);
          setChartVolumes([]);
          return;
        }

        // Find date and volume keys case-insensitively
        const firstRow = rows[0];
        const keys = Object.keys(firstRow);
        const dateKey = keys.find((k) => k.toLowerCase() === "date") || "date";
        const volumeKey = keys.find((k) => k.toLowerCase() === "volume") || "volume";

        // Aggregate by date (sum volume per day) and sort
        const dateMap = new Map<string, number>();
        for (const r of rows) {
          const raw = String(r[dateKey] ?? "");
          // Handle both ISO (2025-11-30T00:00:00) and long format (Sunday, November 30, 2025)
          let d = raw.split("T")[0];
          if (d.includes(",")) {
            // Parse long date format
            const parsed = new Date(d);
            if (!isNaN(parsed.getTime())) {
              d = parsed.toISOString().split("T")[0];
            }
          }
          if (!d) continue;
          dateMap.set(d, (dateMap.get(d) ?? 0) + Number(r[volumeKey] ?? 0));
        }
        const sorted = Array.from(dateMap.entries()).sort((a, b) => a[0].localeCompare(b[0]));
        setChartDates(sorted.map(([d]) => d));
        setChartVolumes(sorted.map(([, v]) => v));
      } catch {
        setChartDates([]);
        setChartVolumes([]);
      } finally {
        setChartLoading(false);
      }
    };

    fetchChartData();
  }, [selectedDatasetId, selectedEntity, refreshKey]);

  // ── Handlers ────────────────────────────────────────────────────────────────

  const handleDatasetChange = (datasetId: string) => {
    setSelectedDatasetId(datasetId);
    const dataset = datasets.find((d) => d.id === datasetId);
    setSelectedDataset(dataset || null);
    setSelectedEntity(null);
    setEntityColumn(null);

    const url = new URL(window.location.href);
    url.searchParams.set("dataset", datasetId);
    window.history.pushState({}, "", url.toString());
  };

  const handleEntitySelect = (value: string) => {
    setSelectedEntity(value === "all" ? null : value);
  };

  const currentEntityIndex = selectedEntity
    ? entities.findIndex((e) => e.name === selectedEntity)
    : -1;

  const handlePrevEntity = () => {
    if (entities.length === 0) return;
    const nextIndex =
      currentEntityIndex <= 0 ? entities.length - 1 : currentEntityIndex - 1;
    setSelectedEntity(entities[nextIndex].name);
  };

  const handleNextEntity = () => {
    if (entities.length === 0) return;
    const nextIndex =
      currentEntityIndex === -1 || currentEntityIndex === entities.length - 1
        ? 0
        : currentEntityIndex + 1;
    setSelectedEntity(entities[nextIndex].name);
  };

  const handleProcessingComplete = useCallback(() => {
    setRefreshKey((prev) => prev + 1);
  }, []);

  const handleReset = async () => {
    if (!selectedDatasetId) return;

    setResetting(true);
    try {
      const params = new URLSearchParams();
      if (selectedEntity) params.append("entity_id", selectedEntity);

      await api.post(
        `/preprocessing/${selectedDatasetId}/reset${params.toString() ? `?${params}` : ""}`
      );

      toast.success("Preprocessing reset to original data");
      setRefreshKey((prev) => prev + 1);
    } catch (err: any) {
      toast.error(err.response?.data?.detail || "Failed to reset preprocessing");
    } finally {
      setResetting(false);
    }
  };

  const handleDownload = async () => {
    if (!selectedDatasetId) return;

    setDownloading(true);
    try {
      const params = new URLSearchParams();
      params.append("format", "csv");
      if (selectedEntity) params.append("entity_id", selectedEntity);
      if (entityColumn) params.append("entity_column", entityColumn);

      const response = await api.get<Blob>(
        `/preprocessing/${selectedDatasetId}/download?${params}`,
        { responseType: "blob" }
      );

      const blob = new Blob([response], { type: "text/csv" });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `preprocessed_${selectedDataset?.name || selectedDatasetId}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);

      toast.success("Download started");
    } catch {
      toast.error("Failed to download data");
    } finally {
      setDownloading(false);
    }
  };

  const handleContinueToForecasting = () => {
    if (selectedDatasetId) {
      router.push(`forecast?dataset=${selectedDatasetId}`);
    }
  };

  const numericColumns =
    selectedDataset?.columns?.filter((col) => {
      const nonNumeric = [
        "date",
        "timestamp",
        "datetime",
        "name",
        "id",
        "entity",
        "category",
        "type",
      ];
      return !nonNumeric.some((n) => col.toLowerCase().includes(n));
    }) || [];

  // ── Loading gate ────────────────────────────────────────────────────────────

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-3">
        <Loader2 className="h-10 w-10 animate-spin text-primary" />
        <p className="text-sm text-muted-foreground">Loading...</p>
      </div>
    );
  }

  // ── Render ──────────────────────────────────────────────────────────────────

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Data Preprocessing</h1>
          <p className="text-muted-foreground">
            Clean and transform your data before forecasting
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleReset}
            disabled={!selectedDatasetId || resetting}
          >
            {resetting ? (
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
            ) : (
              <RotateCcw className="h-4 w-4 mr-2" />
            )}
            Reset
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={handleDownload}
            disabled={!selectedDatasetId || downloading}
          >
            {downloading ? (
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
            ) : (
              <Download className="h-4 w-4 mr-2" />
            )}
            Download
          </Button>
          <Button size="sm" onClick={handleContinueToForecasting} disabled={!selectedDatasetId}>
            Continue to Forecasting
            <ArrowRight className="h-4 w-4 ml-2" />
          </Button>
        </div>
      </div>

      {/* Combined Dataset + Entity Selection Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="h-5 w-5" />
            Dataset &amp; Entity Selection
          </CardTitle>
          <CardDescription>
            Choose a dataset and optionally filter by entity to preprocess
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-6">
            {/* Left: Dataset dropdown */}
            <div className="space-y-2">
              <Label>Dataset</Label>
              <Select value={selectedDatasetId || ""} onValueChange={handleDatasetChange}>
                <SelectTrigger>
                  <SelectValue placeholder="Select a dataset" />
                </SelectTrigger>
                <SelectContent>
                  {datasets.map((dataset) => (
                    <SelectItem key={dataset.id} value={dataset.id}>
                      <span className="flex items-center gap-2">
                        {dataset.name}
                        <Badge variant="secondary">
                          {dataset.row_count?.toLocaleString() || "?"} rows
                        </Badge>
                      </span>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {selectedDataset && (
                <p className="text-xs text-muted-foreground">
                  {selectedDataset.row_count?.toLocaleString() || "?"} rows,{" "}
                  {selectedDataset.column_count ??
                    selectedDataset.columns?.length ??
                    "?"}{" "}
                  columns
                  {selectedDataset.entities?.length > 0 &&
                    ` · ${selectedDataset.entities.length} entities`}
                </p>
              )}
            </div>

            {/* Right: Entity dropdown + Prev/Next navigation */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label>Entity / SKU</Label>
                {entityColumn && (
                  <Badge variant="outline" className="text-xs">
                    <Database className="h-3 w-3 mr-1" />
                    {entityColumn}
                  </Badge>
                )}
              </div>

              {entitiesLoading ? (
                <div className="flex items-center gap-2 h-10 text-muted-foreground text-sm">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Loading entities...
                </div>
              ) : entitiesError ? (
                <p className="text-sm text-destructive">{entitiesError}</p>
              ) : !selectedDatasetId ? (
                <div className="flex items-center h-10">
                  <p className="text-sm text-muted-foreground">Select a dataset first</p>
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <Button
                    variant="outline"
                    size="icon"
                    className="h-10 w-10 shrink-0"
                    onClick={handlePrevEntity}
                    disabled={entities.length === 0}
                    title="Previous entity"
                  >
                    <ChevronLeft className="h-4 w-4" />
                  </Button>

                  <Select value={selectedEntity || "all"} onValueChange={handleEntitySelect}>
                    <SelectTrigger className="flex-1">
                      <SelectValue placeholder="All Entities" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">
                        <span className="flex items-center gap-2">
                          All Entities
                          <Badge variant="secondary">
                            {totalEntityRows.toLocaleString()} rows
                          </Badge>
                        </span>
                      </SelectItem>
                      {entities.map((entity) => (
                        <SelectItem key={entity.name} value={entity.name}>
                          <span className="flex items-center gap-2">
                            {entity.name}
                            <Badge variant="secondary">
                              {(entity.row_count ?? 0).toLocaleString()} rows
                            </Badge>
                          </span>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>

                  <Button
                    variant="outline"
                    size="icon"
                    className="h-10 w-10 shrink-0"
                    onClick={handleNextEntity}
                    disabled={entities.length === 0}
                    title="Next entity"
                  >
                    <ChevronRight className="h-4 w-4" />
                  </Button>
                </div>
              )}

              {selectedEntity &&
                (() => {
                  const info = entities.find((e) => e.name === selectedEntity);
                  return info ? (
                    <p className="text-xs text-muted-foreground">
                      {(info.row_count ?? 0).toLocaleString()} rows
                      {info.date_range?.start && info.date_range?.end
                        ? ` · ${info.date_range.start} to ${info.date_range.end}`
                        : ""}
                      {entities.length > 0
                        ? ` · ${currentEntityIndex + 1} of ${entities.length}`
                        : ""}
                    </p>
                  ) : null;
                })()}
            </div>
          </div>
        </CardContent>
      </Card>

      {selectedDatasetId && (
        <>
          {/* Time Series Chart */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <BarChart2 className="h-5 w-5" />
                {selectedEntity ? `Time Series — ${selectedEntity}` : "Time Series Preview"}
              </CardTitle>
              <CardDescription>
                {selectedEntity
                  ? "Volume over time for the selected entity"
                  : "Select an entity to view its time series chart"}
              </CardDescription>
            </CardHeader>
            <CardContent>
              {!selectedEntity ? (
                <div className="flex h-[400px] items-center justify-center text-muted-foreground">
                  <div className="text-center space-y-2">
                    <Users className="h-10 w-10 mx-auto opacity-40" />
                    <p className="text-sm">Select an entity above to preview its time series data</p>
                  </div>
                </div>
              ) : chartLoading ? (
                <div className="flex h-[400px] items-center justify-center">
                  <Loader2 className="h-8 w-8 animate-spin text-primary" />
                </div>
              ) : chartDates.length === 0 ? (
                <div className="flex h-[400px] items-center justify-center text-muted-foreground text-sm">
                  No chart data available for this entity
                </div>
              ) : (
                <Plot
                  key={`chart-${selectedEntity}-${refreshKey}`}
                  data={[
                    {
                      type: "scatter",
                      mode: "lines+markers",
                      x: chartDates,
                      y: chartVolumes,
                      name: selectedEntity,
                      line: { color: "hsl(var(--primary))", width: 2 },
                      marker: { size: 4 },
                    },
                  ]}
                  layout={{
                    autosize: true,
                    height: 400,
                    margin: { t: 20, r: 20, b: 60, l: 60 },
                    xaxis: {
                      title: { text: "Date" },
                      type: "category",
                      showgrid: true,
                      gridcolor: "hsl(var(--border))",
                    },
                    yaxis: {
                      title: { text: "Volume" },
                      showgrid: true,
                      gridcolor: "hsl(var(--border))",
                    },
                    paper_bgcolor: "transparent",
                    plot_bgcolor: "transparent",
                    font: { color: "hsl(var(--foreground))", size: 12 },
                  }}
                  config={{ responsive: true, displayModeBar: false }}
                  style={{ width: "100%" }}
                  useResizeHandler
                />
              )}
            </CardContent>
          </Card>

          {/* Preprocessing Tools */}
          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList className="grid w-full grid-cols-5">
              <TabsTrigger value="missing" className="flex items-center gap-2">
                <AlertTriangle className="h-4 w-4" />
                Missing Values
              </TabsTrigger>
              <TabsTrigger value="duplicates" className="flex items-center gap-2">
                <Copy className="h-4 w-4" />
                Duplicates
              </TabsTrigger>
              <TabsTrigger value="outliers" className="flex items-center gap-2">
                <TrendingUp className="h-4 w-4" />
                Outliers
              </TabsTrigger>
              <TabsTrigger value="replace" className="flex items-center gap-2">
                <Replace className="h-4 w-4" />
                Replace Values
              </TabsTrigger>
              <TabsTrigger value="aggregation" className="flex items-center gap-2">
                <Calendar className="h-4 w-4" />
                Aggregation
              </TabsTrigger>
            </TabsList>

            <TabsContent value="missing" className="mt-6">
              <MissingValuesHandler
                key={`missing-${refreshKey}`}
                datasetId={selectedDatasetId}
                entityId={selectedEntity}
                entityColumn={entityColumn}
                onProcessingComplete={handleProcessingComplete}
              />
            </TabsContent>

            <TabsContent value="duplicates" className="mt-6">
              <DuplicateHandler
                key={`duplicates-${refreshKey}`}
                datasetId={selectedDatasetId}
                entityId={selectedEntity}
                entityColumn={entityColumn}
                columns={selectedDataset?.columns}
                onProcessingComplete={handleProcessingComplete}
              />
            </TabsContent>

            <TabsContent value="outliers" className="mt-6">
              <OutlierHandler
                key={`outliers-${refreshKey}`}
                datasetId={selectedDatasetId}
                entityId={selectedEntity}
                entityColumn={entityColumn}
                onProcessingComplete={handleProcessingComplete}
              />
            </TabsContent>

            <TabsContent value="replace" className="mt-6">
              <ValueReplacer
                key={`replace-${refreshKey}`}
                datasetId={selectedDatasetId}
                entityId={selectedEntity}
                entityColumn={entityColumn}
                columns={selectedDataset?.columns}
                onProcessingComplete={handleProcessingComplete}
              />
            </TabsContent>

            <TabsContent value="aggregation" className="mt-6">
              <TimeAggregator
                key={`aggregation-${refreshKey}`}
                datasetId={selectedDatasetId}
                entityId={selectedEntity}
                entityColumn={entityColumn}
                numericColumns={numericColumns}
                onProcessingComplete={handleProcessingComplete}
              />
            </TabsContent>
          </Tabs>

          {/* Processing Summary */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <CheckCircle2 className="h-5 w-5 text-green-600" />
                Ready for Forecasting
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">
                After preprocessing, your data will be ready for forecasting. You can:
              </p>
              <ul className="list-disc list-inside mt-2 text-muted-foreground space-y-1">
                <li>Download the preprocessed data for external use</li>
                <li>Reset to original data if needed</li>
                <li>Continue directly to forecasting</li>
              </ul>
              <div className="mt-4">
                <Button onClick={handleContinueToForecasting}>
                  Continue to Forecasting
                  <ArrowRight className="h-4 w-4 ml-2" />
                </Button>
              </div>
            </CardContent>
          </Card>
        </>
      )}

      {!selectedDatasetId && (
        <Card className="border-dashed">
          <CardContent className="flex flex-col items-center justify-center py-12">
            <Database className="h-12 w-12 text-muted-foreground mb-4" />
            <p className="text-muted-foreground text-center">
              Select a dataset above to start preprocessing.
              <br />
              <span className="text-sm">
                You can also{" "}
                <Button
                  variant="link"
                  className="p-0 h-auto"
                  onClick={() => router.push("data")}
                >
                  upload a new dataset
                </Button>{" "}
                first.
              </span>
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
