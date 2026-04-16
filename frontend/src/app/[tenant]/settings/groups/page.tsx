"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { useTenant } from "@/contexts/TenantContext";
import { useRouter, useParams } from "next/navigation";
import {
  tenantAdminApi,
  type GroupResponse,
  type GroupDetailResponse,
  type TenantUserResponse,
  type DataSourceItem,
} from "@/lib/api/endpoints";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
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
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Users,
  Plus,
  Search,
  MoreHorizontal,
  Trash2,
  Pencil,
  X,
  AlertCircle,
  UserPlus,
  UserMinus,
  Shield,
  Eye,
  Loader2,
  Database,
} from "lucide-react";

export default function GroupsPage() {
  const { user } = useAuth();
  const { tenant } = useTenant();
  const router = useRouter();
  const params = useParams();
  const tenantSlug = params.tenant as string;

  const [groups, setGroups] = useState<GroupResponse[]>([]);
  const [allUsers, setAllUsers] = useState<TenantUserResponse[]>([]);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");

  // Modal states
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [isMembersOpen, setIsMembersOpen] = useState(false);
  const [selectedGroup, setSelectedGroup] = useState<GroupResponse | null>(null);
  const [groupDetail, setGroupDetail] = useState<GroupDetailResponse | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form states
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    rls_values: [] as string[],
  });
  const [rlsInput, setRlsInput] = useState("");

  // Data source + entity selection for RLS
  const [dataSources, setDataSources] = useState<DataSourceItem[]>([]);
  const [selectedDsId, setSelectedDsId] = useState<string>("");
  const [dsEntities, setDsEntities] = useState<string[]>([]);
  const [isLoadingEntities, setIsLoadingEntities] = useState(false);

  // Check if user is admin
  useEffect(() => {
    if (user && user.role !== "admin" ) {
      router.push(`/${tenantSlug}/dashboard`);
    }
  }, [user, router, tenantSlug]);

  useEffect(() => {
    loadData();
  }, [search]);

  const loadData = async () => {
    try {
      setIsLoading(true);
      setError(null);

      const params: any = { limit: 100 };
      if (search) params.search = search;

      const [groupsData, usersData, dsData] = await Promise.all([
        tenantAdminApi.listGroups(params),
        tenantAdminApi.listUsers({ limit: 100 }),
        tenantAdminApi.listDataSources(),
      ]);

      setGroups(groupsData.groups);
      setTotal(groupsData.total);
      setAllUsers(usersData.users);
      setDataSources(dsData.data_sources);
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to load groups");
    } finally {
      setIsLoading(false);
    }
  };

  const loadGroupDetail = async (groupId: string) => {
    try {
      const detail = await tenantAdminApi.getGroup(groupId);
      setGroupDetail(detail);
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to load group details");
    }
  };

  const handleCreate = async () => {
    try {
      setIsSubmitting(true);
      await tenantAdminApi.createGroup({
        name: formData.name,
        description: formData.description || undefined,
        rls_values: formData.rls_values,
      });
      setIsCreateOpen(false);
      setFormData({ name: "", description: "", rls_values: [] });
      setRlsInput("");
      loadData();
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to create group");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleUpdate = async () => {
    if (!selectedGroup) return;
    try {
      setIsSubmitting(true);
      await tenantAdminApi.updateGroup(selectedGroup.id, {
        name: formData.name,
        description: formData.description || undefined,
        rls_values: formData.rls_values,
      });
      setIsEditOpen(false);
      setSelectedGroup(null);
      loadData();
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to update group");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedGroup) return;
    try {
      setIsSubmitting(true);
      await tenantAdminApi.deleteGroup(selectedGroup.id);
      setIsDeleteOpen(false);
      setSelectedGroup(null);
      loadData();
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to delete group");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleAddMember = async (userId: string) => {
    if (!selectedGroup) return;
    try {
      await tenantAdminApi.addGroupMember(selectedGroup.id, userId);
      loadGroupDetail(selectedGroup.id);
      loadData();
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to add member");
    }
  };

  const handleRemoveMember = async (userId: string) => {
    if (!selectedGroup) return;
    try {
      await tenantAdminApi.removeGroupMember(selectedGroup.id, userId);
      loadGroupDetail(selectedGroup.id);
      loadData();
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to remove member");
    }
  };

  const openEdit = (group: GroupResponse) => {
    setSelectedGroup(group);
    setFormData({
      name: group.name,
      description: group.description || "",
      rls_values: group.rls_values || [],
    });
    setRlsInput("");
    setSelectedDsId("");
    setDsEntities([]);
    setIsEditOpen(true);
  };

  const openDetail = async (group: GroupResponse) => {
    setSelectedGroup(group);
    await loadGroupDetail(group.id);
    setIsDetailOpen(true);
  };

  const openMembers = async (group: GroupResponse) => {
    setSelectedGroup(group);
    await loadGroupDetail(group.id);
    setIsMembersOpen(true);
  };

  const addRlsValue = () => {
    if (rlsInput.trim() && !formData.rls_values.includes(rlsInput.trim())) {
      setFormData({
        ...formData,
        rls_values: [...formData.rls_values, rlsInput.trim()],
      });
      setRlsInput("");
    }
  };

  const removeRlsValue = (value: string) => {
    setFormData({
      ...formData,
      rls_values: formData.rls_values.filter((v) => v !== value),
    });
  };

  const handleSelectDataSource = async (dsId: string) => {
    setSelectedDsId(dsId);
    if (!dsId) {
      setDsEntities([]);
      return;
    }
    try {
      setIsLoadingEntities(true);
      const entities = await tenantAdminApi.getDataSourceEntities(dsId);
      setDsEntities(entities.map((e: any) => e.id));
    } catch {
      setDsEntities([]);
    } finally {
      setIsLoadingEntities(false);
    }
  };

  const toggleEntitySelection = (entityId: string) => {
    const current = formData.rls_values;
    if (current.includes(entityId)) {
      setFormData({ ...formData, rls_values: current.filter((v) => v !== entityId) });
    } else {
      setFormData({ ...formData, rls_values: [...current, entityId] });
    }
  };

  const toggleAllEntities = () => {
    if (formData.rls_values.length === dsEntities.length) {
      setFormData({ ...formData, rls_values: [] });
    } else {
      setFormData({ ...formData, rls_values: [...dsEntities] });
    }
  };

  // Get users not in the current group
  const availableUsers = groupDetail
    ? allUsers.filter(
        (u) => !groupDetail.members.some((m) => m.id === u.id)
      )
    : allUsers;

  // Don't render if not admin
  if (user && user.role !== "admin" ) {
    return null;
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">User Groups</h2>
          <p className="text-muted-foreground">
            Manage user groups and RLS values for {tenant?.name || "your organization"}
          </p>
        </div>
        <Button
          onClick={() => {
            setFormData({ name: "", description: "", rls_values: [] });
            setRlsInput("");
            setSelectedDsId("");
            setDsEntities([]);
            setIsCreateOpen(true);
          }}
        >
          <Plus className="mr-2 h-4 w-4" />
          Create Group
        </Button>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 p-4 text-red-700">
          <AlertCircle className="h-4 w-4" />
          <span>{error}</span>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setError(null)}
            className="ml-auto"
          >
            <X className="h-4 w-4" />
          </Button>
        </div>
      )}

      {/* Search */}
      <Card>
        <CardHeader>
          <CardTitle>Search Groups</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="relative">
            <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search by name or description..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-10"
            />
          </div>
        </CardContent>
      </Card>

      {/* Groups Table */}
      <Card>
        <CardHeader>
          <CardTitle>Groups ({total})</CardTitle>
          <CardDescription>
            Groups define data access permissions through RLS values
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex items-center justify-center h-32">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : groups.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-32 text-muted-foreground">
              <Users className="h-8 w-8 mb-2" />
              <p>No groups found</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Description</TableHead>
                  <TableHead>Members</TableHead>
                  <TableHead>RLS Values</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="w-[50px]"></TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {groups.map((group) => (
                  <TableRow key={group.id}>
                    <TableCell className="font-medium">{group.name}</TableCell>
                    <TableCell className="text-muted-foreground max-w-xs truncate">
                      {group.description || "-"}
                    </TableCell>
                    <TableCell>{group.member_count}</TableCell>
                    <TableCell>
                      {group.rls_values.length > 0 ? (
                        <div className="flex flex-wrap gap-1">
                          {group.rls_values.slice(0, 3).map((value) => (
                            <span
                              key={value}
                              className="inline-flex items-center rounded-full bg-purple-100 px-2 py-0.5 text-xs font-medium text-purple-700"
                            >
                              {value}
                            </span>
                          ))}
                          {group.rls_values.length > 3 && (
                            <span className="text-xs text-muted-foreground">
                              +{group.rls_values.length - 3} more
                            </span>
                          )}
                        </div>
                      ) : (
                        <span className="text-muted-foreground text-sm">
                          No values
                        </span>
                      )}
                    </TableCell>
                    <TableCell>
                      {group.is_active ? (
                        <span className="inline-flex items-center rounded-full bg-green-100 px-2 py-1 text-xs font-medium text-green-700">
                          Active
                        </span>
                      ) : (
                        <span className="inline-flex items-center rounded-full bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700">
                          Inactive
                        </span>
                      )}
                    </TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="icon">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem onClick={() => openDetail(group)}>
                            <Eye className="mr-2 h-4 w-4" />
                            View Details
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => openEdit(group)}>
                            <Pencil className="mr-2 h-4 w-4" />
                            Edit
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => openMembers(group)}>
                            <Users className="mr-2 h-4 w-4" />
                            Manage Members
                          </DropdownMenuItem>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem
                            onClick={() => {
                              setSelectedGroup(group);
                              setIsDeleteOpen(true);
                            }}
                            className="text-red-600"
                          >
                            <Trash2 className="mr-2 h-4 w-4" />
                            Delete
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Create Group Dialog */}
      <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Create New Group</DialogTitle>
            <DialogDescription>
              Create a group with RLS values for data access control
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="name">Group Name</Label>
              <Input
                id="name"
                placeholder="e.g., Store A Team"
                value={formData.name}
                onChange={(e) =>
                  setFormData({ ...formData, name: e.target.value })
                }
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="description">Description</Label>
              <Input
                id="description"
                placeholder="Optional description"
                value={formData.description}
                onChange={(e) =>
                  setFormData({ ...formData, description: e.target.value })
                }
              />
            </div>
            <div className="space-y-3">
              <Label>Assign Entities (RLS)</Label>
              <p className="text-xs text-muted-foreground">
                Select a data source and choose which entities this group can access
              </p>

              {dataSources.length > 0 ? (
                <>
                  <Select value={selectedDsId} onValueChange={handleSelectDataSource}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select a data source" />
                    </SelectTrigger>
                    <SelectContent>
                      {dataSources.map((ds) => (
                        <SelectItem key={ds.id} value={ds.id}>
                          <div className="flex items-center gap-2">
                            <Database className="h-3.5 w-3.5 text-muted-foreground" />
                            <span>{ds.name}</span>
                            <span className="text-xs text-muted-foreground">
                              ({ds.entity_count} entities)
                            </span>
                          </div>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>

                  {isLoadingEntities && (
                    <div className="flex items-center gap-2 py-4 justify-center text-sm text-muted-foreground">
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Loading entities...
                    </div>
                  )}

                  {!isLoadingEntities && dsEntities.length > 0 && (
                    <div className="border rounded-md">
                      <div className="flex items-center justify-between px-3 py-2 border-b bg-muted/30">
                        <Button variant="ghost" size="sm" className="h-7 text-xs" onClick={toggleAllEntities}>
                          {formData.rls_values.length === dsEntities.length ? "Deselect All" : "Select All"}
                        </Button>
                        <span className="text-xs text-muted-foreground">
                          {formData.rls_values.length} / {dsEntities.length} selected
                        </span>
                      </div>
                      <div className="max-h-48 overflow-y-auto p-1">
                        {dsEntities.map((entityId) => (
                          <label
                            key={entityId}
                            className="flex items-center gap-3 rounded px-3 py-1.5 hover:bg-muted/50 cursor-pointer text-sm"
                          >
                            <Checkbox
                              checked={formData.rls_values.includes(entityId)}
                              onCheckedChange={() => toggleEntitySelection(entityId)}
                            />
                            <span className="font-mono text-xs">{entityId}</span>
                          </label>
                        ))}
                      </div>
                    </div>
                  )}
                </>
              ) : (
                <p className="text-sm text-muted-foreground italic py-2">
                  No data sources configured yet. Run the Setup Wizard on a connector first.
                </p>
              )}
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleCreate}
              disabled={!formData.name || isSubmitting}
            >
              {isSubmitting ? "Creating..." : "Create Group"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit Group Dialog */}
      <Dialog open={isEditOpen} onOpenChange={setIsEditOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Edit Group</DialogTitle>
            <DialogDescription>
              Update group information and RLS values
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="edit-name">Group Name</Label>
              <Input
                id="edit-name"
                value={formData.name}
                onChange={(e) =>
                  setFormData({ ...formData, name: e.target.value })
                }
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-description">Description</Label>
              <Input
                id="edit-description"
                value={formData.description}
                onChange={(e) =>
                  setFormData({ ...formData, description: e.target.value })
                }
              />
            </div>
            <div className="space-y-3">
              <Label>Assigned Entities (RLS)</Label>
              <p className="text-xs text-muted-foreground">
                Select a data source and choose which entities this group can access
              </p>

              {dataSources.length > 0 ? (
                <>
                  <Select value={selectedDsId} onValueChange={handleSelectDataSource}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select a data source" />
                    </SelectTrigger>
                    <SelectContent>
                      {dataSources.map((ds) => (
                        <SelectItem key={ds.id} value={ds.id}>
                          <div className="flex items-center gap-2">
                            <Database className="h-3.5 w-3.5 text-muted-foreground" />
                            <span>{ds.name}</span>
                            <span className="text-xs text-muted-foreground">
                              ({ds.entity_count} entities)
                            </span>
                          </div>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>

                  {isLoadingEntities && (
                    <div className="flex items-center gap-2 py-4 justify-center text-sm text-muted-foreground">
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Loading entities...
                    </div>
                  )}

                  {!isLoadingEntities && dsEntities.length > 0 && (
                    <div className="border rounded-md">
                      <div className="flex items-center justify-between px-3 py-2 border-b bg-muted/30">
                        <Button variant="ghost" size="sm" className="h-7 text-xs" onClick={toggleAllEntities}>
                          {formData.rls_values.length === dsEntities.length ? "Deselect All" : "Select All"}
                        </Button>
                        <span className="text-xs text-muted-foreground">
                          {formData.rls_values.length} / {dsEntities.length} selected
                        </span>
                      </div>
                      <div className="max-h-48 overflow-y-auto p-1">
                        {dsEntities.map((entityId) => (
                          <label
                            key={entityId}
                            className="flex items-center gap-3 rounded px-3 py-1.5 hover:bg-muted/50 cursor-pointer text-sm"
                          >
                            <Checkbox
                              checked={formData.rls_values.includes(entityId)}
                              onCheckedChange={() => toggleEntitySelection(entityId)}
                            />
                            <span className="font-mono text-xs">{entityId}</span>
                          </label>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Show currently assigned values not in the entity list */}
                  {!isLoadingEntities && formData.rls_values.length > 0 && dsEntities.length === 0 && !selectedDsId && (
                    <div className="flex flex-wrap gap-1 mt-1">
                      {formData.rls_values.map((val) => (
                        <span key={val} className="inline-flex items-center gap-1 rounded-full bg-purple-100 px-2 py-0.5 text-xs font-medium text-purple-700">
                          <Shield className="h-3 w-3" />
                          {val}
                          <button type="button" onClick={() => removeRlsValue(val)} className="ml-1 text-purple-500 hover:text-purple-700">
                            <X className="h-3 w-3" />
                          </button>
                        </span>
                      ))}
                    </div>
                  )}
                </>
              ) : (
                <p className="text-sm text-muted-foreground italic py-2">
                  No data sources configured yet. Run the Setup Wizard on a connector first.
                </p>
              )}
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsEditOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleUpdate}
              disabled={!formData.name || isSubmitting}
            >
              {isSubmitting ? "Saving..." : "Save Changes"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Group Detail Dialog */}
      <Dialog open={isDetailOpen} onOpenChange={setIsDetailOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{groupDetail?.name}</DialogTitle>
            <DialogDescription>
              {groupDetail?.description || "No description"}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div>
              <Label className="text-sm font-medium">RLS Values</Label>
              {groupDetail?.rls_values && groupDetail.rls_values.length > 0 ? (
                <div className="flex flex-wrap gap-2 mt-2">
                  {groupDetail.rls_values.map((value) => (
                    <span
                      key={value}
                      className="inline-flex items-center gap-1 rounded-full bg-purple-100 px-3 py-1 text-sm font-medium text-purple-700"
                    >
                      <Shield className="h-3 w-3" />
                      {value}
                    </span>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-muted-foreground mt-1">
                  No RLS values assigned
                </p>
              )}
            </div>
            <div>
              <Label className="text-sm font-medium">
                Members ({groupDetail?.members.length || 0})
              </Label>
              {groupDetail?.members && groupDetail.members.length > 0 ? (
                <div className="mt-2 space-y-2 max-h-48 overflow-y-auto">
                  {groupDetail.members.map((member) => (
                    <div
                      key={member.id}
                      className="flex items-center justify-between p-2 rounded-lg bg-muted/50"
                    >
                      <div>
                        <p className="font-medium text-sm">
                          {member.full_name || member.email}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {member.email}
                        </p>
                      </div>
                      <span className="text-xs text-muted-foreground capitalize">
                        {member.role}
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-muted-foreground mt-1">
                  No members in this group
                </p>
              )}
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDetailOpen(false)}>
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Manage Members Dialog */}
      <Dialog open={isMembersOpen} onOpenChange={setIsMembersOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Manage Members - {selectedGroup?.name}</DialogTitle>
            <DialogDescription>
              Add or remove users from this group
            </DialogDescription>
          </DialogHeader>
          <div className="grid grid-cols-2 gap-4 py-4">
            {/* Current Members */}
            <div>
              <Label className="text-sm font-medium">
                Current Members ({groupDetail?.members.length || 0})
              </Label>
              <div className="mt-2 space-y-2 max-h-64 overflow-y-auto border rounded-lg p-2">
                {groupDetail?.members && groupDetail.members.length > 0 ? (
                  groupDetail.members.map((member) => (
                    <div
                      key={member.id}
                      className="flex items-center justify-between p-2 rounded-lg bg-muted/50"
                    >
                      <div className="overflow-hidden">
                        <p className="font-medium text-sm truncate">
                          {member.full_name || member.email}
                        </p>
                        <p className="text-xs text-muted-foreground truncate">
                          {member.email}
                        </p>
                      </div>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleRemoveMember(member.id)}
                        className="text-red-600 hover:text-red-700 hover:bg-red-50"
                      >
                        <UserMinus className="h-4 w-4" />
                      </Button>
                    </div>
                  ))
                ) : (
                  <p className="text-sm text-muted-foreground p-2">
                    No members yet
                  </p>
                )}
              </div>
            </div>

            {/* Available Users */}
            <div>
              <Label className="text-sm font-medium">
                Available Users ({availableUsers.length})
              </Label>
              <div className="mt-2 space-y-2 max-h-64 overflow-y-auto border rounded-lg p-2">
                {availableUsers.length > 0 ? (
                  availableUsers.map((u) => (
                    <div
                      key={u.id}
                      className="flex items-center justify-between p-2 rounded-lg hover:bg-muted/50"
                    >
                      <div className="overflow-hidden">
                        <p className="font-medium text-sm truncate">
                          {u.full_name || u.email}
                        </p>
                        <p className="text-xs text-muted-foreground truncate">
                          {u.email}
                        </p>
                      </div>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleAddMember(u.id)}
                        className="text-green-600 hover:text-green-700 hover:bg-green-50"
                      >
                        <UserPlus className="h-4 w-4" />
                      </Button>
                    </div>
                  ))
                ) : (
                  <p className="text-sm text-muted-foreground p-2">
                    All users are already members
                  </p>
                )}
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsMembersOpen(false)}>
              Done
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Group Dialog */}
      <Dialog open={isDeleteOpen} onOpenChange={setIsDeleteOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Group</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &quot;{selectedGroup?.name}&quot;? This
              will remove all member associations.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDeleteOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleDelete}
              disabled={isSubmitting}
              variant="destructive"
            >
              {isSubmitting ? "Deleting..." : "Delete Group"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
