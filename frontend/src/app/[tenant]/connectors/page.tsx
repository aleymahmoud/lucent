"use client";

import { Suspense, useState, useCallback, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Loader2,
  Plug,
  Database,
  ArrowRight,
  Wand2,
  Table2,
  Calendar,
  Download,
  Users,
  Shield,
  CheckCircle2,
  AlertCircle,
  Trash2,
} from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { toast } from "sonner";
import { useAuth } from "@/contexts/AuthContext";
import {
  ConnectorList,
  ConnectorWizard,
  ResourceBrowser,
  DataPreview,
  type ConnectorCardData,
} from "@/components/connectors";
import { userDataSourceApi, tenantAdminApi, type DataSourceItem } from "@/lib/api/endpoints";

// -------------------------------------------------------
// QueryClient -- scoped to connectors page
// -------------------------------------------------------

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 2,
      retry: 2,
    },
  },
});

// -------------------------------------------------------
// User view — shows assigned data sources
// -------------------------------------------------------

function UserDataSourcesView() {
  const params = useParams();
  const router = useRouter();
  const tenantSlug = (params?.tenant as string) ?? '';
  const [dataSources, setDataSources] = useState<DataSourceItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Import state
  const [selectedDs, setSelectedDs] = useState<DataSourceItem | null>(null);
  const [dateStart, setDateStart] = useState("");
  const [dateEnd, setDateEnd] = useState("");
  const [isImporting, setIsImporting] = useState(false);
  const [importResult, setImportResult] = useState<{
    dataset_id: string;
    row_count: number;
    entity_count: number;
  } | null>(null);

  useEffect(() => {
    loadDataSources();
  }, []);

  const loadDataSources = async () => {
    try {
      setIsLoading(true);
      const data = await userDataSourceApi.list();
      setDataSources(data);
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to load data sources");
    } finally {
      setIsLoading(false);
    }
  };

  const handleImport = async () => {
    if (!selectedDs) return;
    try {
      setIsImporting(true);
      setImportResult(null);
      const result = await userDataSourceApi.importData(selectedDs.id, {
        date_range_start: dateStart || undefined,
        date_range_end: dateEnd || undefined,
      });
      setImportResult(result);
      toast.success("Data imported successfully", {
        description: `${result.row_count} rows, ${result.entity_count} entities. Redirecting to Data page...`,
      });
      // Navigate to data page after short delay
      setTimeout(() => {
        router.push(`/${tenantSlug}/data`);
      }, 2000);
    } catch (err: any) {
      toast.error("Import failed", {
        description: err.response?.data?.detail || "Could not import data",
      });
    } finally {
      setIsImporting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-3 text-muted-foreground">
        <AlertCircle className="h-8 w-8" />
        <p>{error}</p>
        <Button variant="outline" onClick={loadDataSources}>Retry</Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Data Sources</h1>
        <p className="text-muted-foreground">
          Select a data source, set a date range, and import data for forecasting
        </p>
      </div>

      {dataSources.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-16 text-muted-foreground">
            <Database className="h-10 w-10 mb-3" />
            <p className="font-medium">No data sources available</p>
            <p className="text-sm">Ask your admin to set up a data source and assign your group.</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          {/* Left — data source list */}
          <div className="lg:col-span-4 xl:col-span-3 space-y-2">
            {dataSources.map((ds) => (
              <button
                key={ds.id}
                onClick={() => { setSelectedDs(ds); setImportResult(null); }}
                className={`w-full text-left rounded-lg border p-4 transition-colors ${
                  selectedDs?.id === ds.id
                    ? "border-primary bg-primary/5"
                    : "hover:bg-muted/50"
                }`}
              >
                <div className="flex items-center gap-2 mb-1">
                  <Table2 className="h-4 w-4 text-muted-foreground shrink-0" />
                  <span className="font-medium text-sm truncate">{ds.name}</span>
                </div>
                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  <span>{ds.connector_name}</span>
                  <span className="text-muted-foreground/50">|</span>
                  <span className="flex items-center gap-1">
                    <Users className="h-3 w-3" />
                    {ds.entity_count} entities
                  </span>
                </div>
              </button>
            ))}
          </div>

          {/* Right — selected data source detail + import */}
          <div className="lg:col-span-8 xl:col-span-9">
            {selectedDs ? (
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Database className="h-5 w-5" />
                    {selectedDs.name}
                  </CardTitle>
                  <CardDescription className="space-x-3">
                    <span>Table: <span className="font-mono">{selectedDs.source_table}</span></span>
                    <span>Connector: {selectedDs.connector_name}</span>
                    {selectedDs.rls_enabled && (
                      <span className="inline-flex items-center gap-1 text-green-600">
                        <Shield className="h-3 w-3" /> RLS Active
                      </span>
                    )}
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  {/* Column mapping */}
                  <div>
                    <Label className="text-sm font-medium mb-2 block">Column Mapping</Label>
                    <div className="flex flex-wrap gap-3 text-sm">
                      {Object.entries(selectedDs.column_map).map(([role, col]) => (
                        <span key={role} className="inline-flex items-center gap-1 rounded-md bg-muted px-2.5 py-1 text-xs">
                          <span className="capitalize text-muted-foreground">{role.replace('_', ' ')}:</span>
                          <span className="font-mono font-medium">{col}</span>
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* Date range */}
                  <div>
                    <Label className="text-sm font-medium mb-2 flex items-center gap-1.5">
                      <Calendar className="h-4 w-4" />
                      Date Range (optional)
                    </Label>
                    <div className="flex gap-3">
                      <div className="flex-1">
                        <Label className="text-xs text-muted-foreground">From</Label>
                        <Input
                          type="date"
                          value={dateStart}
                          onChange={(e) => setDateStart(e.target.value)}
                        />
                      </div>
                      <div className="flex-1">
                        <Label className="text-xs text-muted-foreground">To</Label>
                        <Input
                          type="date"
                          value={dateEnd}
                          onChange={(e) => setDateEnd(e.target.value)}
                        />
                      </div>
                    </div>
                  </div>

                  {/* Import button */}
                  <Button
                    onClick={handleImport}
                    disabled={isImporting}
                    className="w-full"
                    size="lg"
                  >
                    {isImporting ? (
                      <>
                        <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                        Importing data...
                      </>
                    ) : (
                      <>
                        <Download className="h-4 w-4 mr-2" />
                        Import Data
                      </>
                    )}
                  </Button>

                  {/* Import result */}
                  {importResult && (
                    <div className="rounded-lg border border-green-200 bg-green-50 p-4 space-y-2">
                      <div className="flex items-center gap-2 text-green-800">
                        <CheckCircle2 className="h-5 w-5" />
                        <span className="font-medium">Import Complete</span>
                      </div>
                      <div className="text-sm text-green-700 space-y-1">
                        <p>Rows imported: <strong>{importResult.row_count.toLocaleString()}</strong></p>
                        <p>Entities: <strong>{importResult.entity_count}</strong></p>
                        <p>Dataset ID: <span className="font-mono text-xs">{importResult.dataset_id.slice(0, 8)}...</span></p>
                      </div>
                      <p className="text-xs text-green-600">
                        You can now use this data in the Preprocessing and Forecast modules.
                      </p>
                    </div>
                  )}
                </CardContent>
              </Card>
            ) : (
              <div className="flex flex-col items-center justify-center py-24 text-center">
                <Database className="h-12 w-12 text-muted-foreground mb-4" />
                <h2 className="text-xl font-semibold mb-2">Select a Data Source</h2>
                <p className="text-muted-foreground max-w-md text-sm">
                  Choose a data source from the list to set a date range and import data for forecasting.
                </p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// -------------------------------------------------------
// Admin view — original connector management + wizard
// -------------------------------------------------------

function AdminConnectorsView() {
  const params = useParams();
  const tenantSlug = (params?.tenant as string) ?? '';
  const [selectedConnector, setSelectedConnector] = useState<ConnectorCardData | null>(null);
  const [selectedResource, setSelectedResource] = useState<string | null>(null);
  const [wizardConnectorId, setWizardConnectorId] = useState<string | null>(null);
  const [deleteConnectorId, setDeleteConnectorId] = useState<{ id: string; name: string } | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  const handleDeleteConnector = useCallback(async () => {
    if (!deleteConnectorId) return;
    try {
      setIsDeleting(true);
      await tenantAdminApi.deleteConnector(deleteConnectorId.id);
      setSelectedConnector(null);
      setSelectedResource(null);
      setDeleteConnectorId(null);
      await queryClient.invalidateQueries({ queryKey: ["connectors"] });
      toast.success("Connector deleted");
    } catch (err: any) {
      toast.error(err.response?.data?.detail || "Failed to delete connector");
    } finally {
      setIsDeleting(false);
    }
  }, [deleteConnectorId]);

  const handleSelectConnector = useCallback((connector: ConnectorCardData) => {
    setSelectedConnector(connector);
    setSelectedResource(null);
  }, []);

  const handleBrowseResources = useCallback((connector: ConnectorCardData) => {
    setSelectedConnector(connector);
    setSelectedResource(null);
  }, []);

  const handlePreviewData = useCallback((connector: ConnectorCardData) => {
    setSelectedConnector(connector);
  }, []);

  const handleSelectResource = useCallback((resource: string) => {
    setSelectedResource(resource);
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Data Connectors</h1>
          <p className="text-muted-foreground">
            Connect to external data sources and preview their data
          </p>
        </div>
        {selectedConnector && (
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="icon"
              className="text-muted-foreground hover:text-destructive"
              onClick={() => setDeleteConnectorId({ id: selectedConnector.id, name: selectedConnector.name })}
            >
              <Trash2 className="h-4 w-4" />
            </Button>
            <Button
              onClick={() => setWizardConnectorId(selectedConnector.id)}
              className="gap-2"
            >
              <Wand2 className="h-4 w-4" />
              Setup Data Source
            </Button>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-4 xl:col-span-3">
          <ConnectorList
            selectedConnectorId={selectedConnector?.id ?? null}
            onSelectConnector={handleSelectConnector}
            onBrowseResources={handleBrowseResources}
            onPreviewData={handlePreviewData}
          />
        </div>

        <div className="lg:col-span-8 xl:col-span-9">
          {selectedConnector ? (
            <div className="space-y-4">
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-lg">{selectedConnector.name}</CardTitle>
                  <CardDescription className="text-xs">
                    Browse resources and preview data from this connector
                  </CardDescription>
                </CardHeader>
              </Card>
              <ResourceBrowser
                connectorId={selectedConnector.id}
                connectorName={selectedConnector.name}
                selectedResource={selectedResource}
                onSelectResource={handleSelectResource}
              />
              <DataPreview
                connectorId={selectedConnector.id}
                connectorName={selectedConnector.name}
                resource={selectedResource}
              />
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center py-24 text-center">
              <div className="flex h-16 w-16 items-center justify-center rounded-full bg-muted mb-4">
                <Plug className="h-8 w-8 text-muted-foreground" />
              </div>
              <h2 className="text-xl font-semibold mb-2">Select a Connector</h2>
              <p className="text-muted-foreground max-w-md text-sm">
                Choose a data connector from the list on the left to browse its resources and preview data.
              </p>
              <div className="flex items-center gap-2 mt-6 text-xs text-muted-foreground">
                <Database className="h-4 w-4" />
                <span>Select connector</span>
                <ArrowRight className="h-3 w-3" />
                <span>Browse resources</span>
                <ArrowRight className="h-3 w-3" />
                <span>Preview data</span>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Delete Connector Confirmation */}
      <Dialog open={!!deleteConnectorId} onOpenChange={(v) => !v && setDeleteConnectorId(null)}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-destructive">
              <Trash2 className="h-5 w-5" />
              Delete Connector
            </DialogTitle>
            <DialogDescription>
              Are you sure you want to delete{" "}
              <span className="font-semibold text-foreground">{deleteConnectorId?.name}</span>?
              This will also delete all associated data sources and RLS config. This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteConnectorId(null)} disabled={isDeleting}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDeleteConnector} disabled={isDeleting}>
              {isDeleting ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Deleting...
                </>
              ) : (
                "Delete"
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {wizardConnectorId && selectedConnector && (
        <ConnectorWizard
          connectorId={wizardConnectorId}
          connectorName={selectedConnector.name}
          tenantSlug={tenantSlug}
          open={true}
          onComplete={() => {
            setWizardConnectorId(null);
            toast.success("Data source configured successfully");
          }}
          onClose={() => setWizardConnectorId(null)}
        />
      )}
    </div>
  );
}

// -------------------------------------------------------
// Page content — switches between admin and user view
// -------------------------------------------------------

function ConnectorsPageContent() {
  const { user } = useAuth();
  const isAdmin = user?.role === "admin";

  return isAdmin ? <AdminConnectorsView /> : <UserDataSourcesView />;
}

// -------------------------------------------------------
// Default export
// -------------------------------------------------------

export default function ConnectorsPage() {
  return (
    <QueryClientProvider client={queryClient}>
      <Suspense
        fallback={
          <div className="flex flex-col h-64 items-center justify-center gap-3">
            <Loader2 className="h-10 w-10 animate-spin text-primary" />
            <p className="text-sm text-muted-foreground">Loading...</p>
          </div>
        }
      >
        <ConnectorsPageContent />
      </Suspense>
    </QueryClientProvider>
  );
}
