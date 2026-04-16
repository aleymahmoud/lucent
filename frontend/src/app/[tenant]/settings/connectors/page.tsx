"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { useTenant } from "@/contexts/TenantContext";
import { useRouter, useParams } from "next/navigation";
import {
  tenantAdminApi,
  type DataSourceItem,
  type GroupResponse,
} from "@/lib/api/endpoints";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Switch } from "@/components/ui/switch";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Database,
  Shield,
  Users,
  AlertCircle,
  X,
  Loader2,
  Check,
  Settings,
  Table2,
  Trash2,
} from "lucide-react";

// -------------------------------------------------------
// Connector type labels
// -------------------------------------------------------

const connectorTypeLabels: Record<string, string> = {
  postgres: "PostgreSQL",
  mysql: "MySQL",
  sqlserver: "SQL Server",
  s3: "Amazon S3",
  azure_blob: "Azure Blob",
  gcs: "Google Cloud Storage",
  bigquery: "BigQuery",
  snowflake: "Snowflake",
  api: "REST API",
};

// -------------------------------------------------------
// Page
// -------------------------------------------------------

export default function ConnectorsRlsPage() {
  const { user } = useAuth();
  const { tenant } = useTenant();
  const router = useRouter();
  const params = useParams();
  const tenantSlug = params.tenant as string;

  const [dataSources, setDataSources] = useState<DataSourceItem[]>([]);
  const [groups, setGroups] = useState<GroupResponse[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Entity assignment dialog
  const [assignDialogOpen, setAssignDialogOpen] = useState(false);
  const [selectedDs, setSelectedDs] = useState<DataSourceItem | null>(null);
  const [selectedGroupId, setSelectedGroupId] = useState<string | null>(null);
  const [entityIds, setEntityIds] = useState<string[]>([]);
  const [selectedEntities, setSelectedEntities] = useState<Set<string>>(new Set());
  const [isLoadingEntities, setIsLoadingEntities] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  // Delete confirmation
  const [deleteTarget, setDeleteTarget] = useState<{ type: "connector" | "data-source"; id: string; name: string } | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    if (user && user.role !== "admin") {
      router.push(`/${tenantSlug}/dashboard`);
    }
  }, [user, router, tenantSlug]);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const [dsData, groupsData] = await Promise.all([
        tenantAdminApi.listDataSources(),
        tenantAdminApi.listGroups({ limit: 100 }),
      ]);
      setDataSources(dsData.data_sources);
      setGroups(groupsData.groups);
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to load data");
    } finally {
      setIsLoading(false);
    }
  };

  const handleToggleRls = async (ds: DataSourceItem) => {
    try {
      await tenantAdminApi.toggleConnectorRLS(ds.connector_id);
      loadData();
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to toggle RLS");
    }
  };

  const openAssignDialog = async (ds: DataSourceItem, groupId: string) => {
    setSelectedDs(ds);
    setSelectedGroupId(groupId);
    setAssignDialogOpen(true);
    setIsLoadingEntities(true);

    try {
      // Load entities from the wizard data via the data-sources entities endpoint
      const res = await tenantAdminApi.getDataSourceEntities(ds.id);
      const ids: string[] = res.map((e: any) => e.id);
      setEntityIds(ids);

      // Pre-select entities already assigned to this group
      const group = groups.find((g) => g.id === groupId);
      const existing = new Set(group?.rls_values ?? []);
      setSelectedEntities(existing);
    } catch {
      // Fallback: use selected_entity_ids if entities endpoint unavailable
      setEntityIds([]);
    } finally {
      setIsLoadingEntities(false);
    }
  };

  const handleSaveEntities = async () => {
    if (!selectedGroupId) return;
    try {
      setIsSaving(true);
      await tenantAdminApi.updateGroup(selectedGroupId, {
        rls_values: Array.from(selectedEntities),
      });
      setAssignDialogOpen(false);
      loadData();
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to save entity assignments");
    } finally {
      setIsSaving(false);
    }
  };

  const toggleEntity = (entityId: string) => {
    setSelectedEntities((prev) => {
      const next = new Set(prev);
      if (next.has(entityId)) {
        next.delete(entityId);
      } else {
        next.add(entityId);
      }
      return next;
    });
  };

  const toggleAll = () => {
    if (selectedEntities.size === entityIds.length) {
      setSelectedEntities(new Set());
    } else {
      setSelectedEntities(new Set(entityIds));
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      setIsDeleting(true);
      if (deleteTarget.type === "data-source") {
        await tenantAdminApi.deleteDataSource(deleteTarget.id);
      } else {
        await tenantAdminApi.deleteConnector(deleteTarget.id);
      }
      setDeleteTarget(null);
      loadData();
    } catch (err: any) {
      setError(err.response?.data?.detail || `Failed to delete ${deleteTarget.type}`);
    } finally {
      setIsDeleting(false);
    }
  };

  // Collect all RLS values across groups
  const allRlsValues = Array.from(new Set(groups.flatMap((g) => g.rls_values)));

  if (user && user.role !== "admin") {
    return null;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Data Source RLS</h2>
          <p className="text-muted-foreground">
            Assign entities from your data sources to user groups for {tenant?.name || "your organization"}
          </p>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 p-4 text-red-700">
          <AlertCircle className="h-4 w-4" />
          <span>{error}</span>
          <Button variant="ghost" size="sm" onClick={() => setError(null)} className="ml-auto">
            <X className="h-4 w-4" />
          </Button>
        </div>
      )}

      {/* How RLS Works */}
      <Card className="border-blue-200 bg-blue-50">
        <CardHeader className="pb-2">
          <CardTitle className="text-blue-800 flex items-center gap-2 text-base">
            <Shield className="h-4 w-4" />
            How RLS Works
          </CardTitle>
        </CardHeader>
        <CardContent className="text-blue-700 text-sm space-y-2">
          <p>
            The wizard extracts entities (e.g. stores, branches) from your data source.
            Assign entities to user groups so each group only sees their own data.
          </p>
          <div>
            <strong>Steps:</strong>
            <ol className="list-decimal ml-5 mt-1 space-y-0.5">
              <li>Select a data source below</li>
              <li>Choose a user group</li>
              <li>Pick which entities that group can access</li>
            </ol>
          </div>
        </CardContent>
      </Card>

      {/* Data Sources Table */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="h-5 w-5" />
            Data Sources ({dataSources.length})
          </CardTitle>
          <CardDescription>
            Data sources created via the Setup Wizard. Select a group to assign entities.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex items-center justify-center h-32">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
          ) : dataSources.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-32 text-muted-foreground">
              <Database className="h-8 w-8 mb-2" />
              <p className="font-medium">No data sources configured</p>
              <p className="text-sm">
                Go to Data Connectors and run the Setup Wizard to create a data source
              </p>
            </div>
          ) : (
            <div className="space-y-6">
              {dataSources.map((ds) => (
                <Card key={ds.id} className="border">
                  <CardHeader className="pb-3">
                    <div className="flex items-center justify-between">
                      <div className="space-y-1">
                        <CardTitle className="text-base flex items-center gap-2">
                          <Table2 className="h-4 w-4 text-muted-foreground" />
                          {ds.name}
                        </CardTitle>
                        <CardDescription className="text-xs space-x-3">
                          <span>
                            Connector: <span className="font-medium">{ds.connector_name}</span>
                          </span>
                          <span className="inline-flex items-center rounded-md bg-gray-100 px-1.5 py-0.5 text-xs font-medium text-gray-700">
                            {connectorTypeLabels[ds.connector_type] || ds.connector_type}
                          </span>
                          <span>
                            Table: <span className="font-mono">{ds.source_table}</span>
                          </span>
                        </CardDescription>
                      </div>

                      <div className="flex items-center gap-3">
                        {/* Entity count badge */}
                        <span className="inline-flex items-center gap-1 rounded-full bg-purple-100 px-2.5 py-1 text-xs font-medium text-purple-700">
                          <Users className="h-3 w-3" />
                          {ds.entity_count} entities
                        </span>

                        {/* RLS column badge */}
                        {ds.rls_column && (
                          <span className="inline-flex items-center gap-1 rounded-full bg-blue-100 px-2.5 py-1 text-xs font-medium text-blue-700">
                            <Shield className="h-3 w-3" />
                            {ds.rls_column}
                          </span>
                        )}

                        {/* RLS toggle */}
                        <div className="flex items-center gap-2">
                          <Switch
                            checked={ds.rls_enabled}
                            onCheckedChange={() => handleToggleRls(ds)}
                          />
                          <span className="text-xs">
                            {ds.rls_enabled ? (
                              <span className="text-green-600">RLS On</span>
                            ) : (
                              <span className="text-gray-500">RLS Off</span>
                            )}
                          </span>
                        </div>

                        {/* Delete data source */}
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-muted-foreground hover:text-destructive"
                          onClick={() => setDeleteTarget({ type: "data-source", id: ds.id, name: ds.name })}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  </CardHeader>

                  <CardContent className="pt-0">
                    {/* Column mapping summary */}
                    <div className="flex gap-4 mb-4 text-xs text-muted-foreground">
                      {Object.entries(ds.column_map).map(([role, col]) => (
                        <span key={role}>
                          <span className="capitalize">{role.replace('_', ' ')}:</span>{" "}
                          <span className="font-mono text-foreground">{col}</span>
                        </span>
                      ))}
                    </div>

                    {/* Groups assignment table */}
                    {groups.length > 0 ? (
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>Group</TableHead>
                            <TableHead>Assigned Entities</TableHead>
                            <TableHead className="w-[120px]">Action</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {groups.map((group) => {
                            const assignedCount = group.rls_values.length;
                            return (
                              <TableRow key={group.id}>
                                <TableCell className="font-medium">
                                  <div className="flex items-center gap-2">
                                    <Users className="h-3.5 w-3.5 text-muted-foreground" />
                                    {group.name}
                                    <span className="text-xs text-muted-foreground">
                                      ({group.member_count} members)
                                    </span>
                                  </div>
                                </TableCell>
                                <TableCell>
                                  {assignedCount > 0 ? (
                                    <div className="flex flex-wrap gap-1">
                                      {group.rls_values.slice(0, 5).map((val) => (
                                        <span
                                          key={val}
                                          className="inline-flex items-center rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700"
                                        >
                                          {val}
                                        </span>
                                      ))}
                                      {assignedCount > 5 && (
                                        <span className="text-xs text-muted-foreground">
                                          +{assignedCount - 5} more
                                        </span>
                                      )}
                                    </div>
                                  ) : (
                                    <span className="text-sm text-muted-foreground italic">
                                      No entities assigned
                                    </span>
                                  )}
                                </TableCell>
                                <TableCell>
                                  <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => openAssignDialog(ds, group.id)}
                                  >
                                    <Settings className="h-3.5 w-3.5 mr-1" />
                                    Assign
                                  </Button>
                                </TableCell>
                              </TableRow>
                            );
                          })}
                        </TableBody>
                      </Table>
                    ) : (
                      <p className="text-sm text-muted-foreground italic py-4">
                        No user groups created yet. Create groups in Settings &gt; Groups first.
                      </p>
                    )}
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Delete Confirmation Dialog */}
      <Dialog open={!!deleteTarget} onOpenChange={(v) => !v && setDeleteTarget(null)}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-destructive">
              <Trash2 className="h-5 w-5" />
              Delete {deleteTarget?.type === "connector" ? "Connector" : "Data Source"}
            </DialogTitle>
            <DialogDescription>
              Are you sure you want to delete{" "}
              <span className="font-semibold text-foreground">{deleteTarget?.name}</span>?
              {deleteTarget?.type === "connector" && " This will also delete all associated data sources."}
              {" "}This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteTarget(null)} disabled={isDeleting}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDelete} disabled={isDeleting}>
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

      {/* Entity Assignment Dialog */}
      <Dialog open={assignDialogOpen} onOpenChange={setAssignDialogOpen}>
        <DialogContent className="max-w-lg max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Users className="h-5 w-5" />
              Assign Entities to {groups.find((g) => g.id === selectedGroupId)?.name}
            </DialogTitle>
            <DialogDescription>
              Select which entities this group can access from{" "}
              <span className="font-medium">{selectedDs?.name}</span>
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2">
            {/* Select all toggle */}
            <div className="flex items-center justify-between border-b pb-2">
              <Button variant="ghost" size="sm" onClick={toggleAll}>
                {selectedEntities.size === entityIds.length ? "Deselect All" : "Select All"}
              </Button>
              <span className="text-xs text-muted-foreground">
                {selectedEntities.size} of {entityIds.length} selected
              </span>
            </div>

            {isLoadingEntities ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-6 w-6 animate-spin" />
              </div>
            ) : entityIds.length === 0 ? (
              <p className="text-sm text-muted-foreground py-4 text-center">
                No entities found for this data source
              </p>
            ) : (
              <div className="space-y-1 max-h-64 overflow-y-auto">
                {entityIds.map((entityId) => (
                  <label
                    key={entityId}
                    className="flex items-center gap-3 rounded-md px-3 py-2 hover:bg-muted/50 cursor-pointer"
                  >
                    <Checkbox
                      checked={selectedEntities.has(entityId)}
                      onCheckedChange={() => toggleEntity(entityId)}
                    />
                    <span className="text-sm font-mono">{entityId}</span>
                    {selectedEntities.has(entityId) && (
                      <Check className="h-3.5 w-3.5 text-green-600 ml-auto" />
                    )}
                  </label>
                ))}
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setAssignDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSaveEntities} disabled={isSaving}>
              {isSaving ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Saving...
                </>
              ) : (
                `Save (${selectedEntities.size} entities)`
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
