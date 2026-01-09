// ============================================
// API Endpoints - Type-safe API calls
// ============================================

import { api } from './client';
import type {
  User,
  Tenant,
  Dataset,
  DataSummary,
  PreprocessConfig,
  EntityStats,
  ForecastConfig,
  ForecastResult,
  DiagnosticsData,
  DataConnector,
  PaginatedResponse,
} from '@/types';

// ============================================
// Authentication
// ============================================

// User type for API responses (snake_case from backend)
interface ApiUser {
  id: string;
  email: string;
  full_name: string | null;
  role: string;
  tenant_id: string;
  tenant_slug: string | null;
  is_active: boolean;
  is_approved: boolean;
  is_super_admin: boolean;
  created_at: string;
  last_login: string | null;
}

// Public tenant info (for URL validation)
interface TenantPublicInfo {
  id: string;
  slug: string;
  name: string;
  is_active: boolean;
}

// ============================================
// Super Admin Types
// ============================================

interface AdminTenant {
  id: string;
  name: string;
  slug: string;
  settings: Record<string, any>;
  limits: Record<string, any>;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  user_count: number;
}

interface AdminTenantListResponse {
  tenants: AdminTenant[];
  total: number;
}

interface AdminUserResponse {
  id: string;
  email: string;
  full_name: string | null;
  role: string;
  tenant_id: string;
  tenant_name: string | null;
  is_active: boolean;
  is_approved: boolean;
  is_super_admin: boolean;
  created_at: string;
  last_login: string | null;
}

interface AdminUserListResponse {
  users: AdminUserResponse[];
  total: number;
}

interface PlatformStats {
  total_tenants: number;
  active_tenants: number;
  total_users: number;
  active_users: number;
  pending_approvals: number;
}

export const authApi = {
  login: (email: string, password: string) =>
    api.post<{ access_token: string; token_type: string; user: ApiUser }>('/auth/login', { email, password }),

  register: (data: { email: string; password: string; fullName: string; tenantName: string }) =>
    api.post<{ access_token: string; token_type: string; user: ApiUser }>('/auth/register', {
      email: data.email,
      password: data.password,
      full_name: data.fullName,
      tenant_name: data.tenantName,
    }),

  logout: () =>
    api.post('/auth/logout'),

  me: () =>
    api.get<ApiUser>('/auth/me'),

  // Admin user management
  getPendingUsers: () =>
    api.get<ApiUser[]>('/auth/pending-users'),

  approveUser: (userId: string) =>
    api.post<ApiUser>(`/auth/approve-user/${userId}`),

  rejectUser: (userId: string) =>
    api.post<{ message: string }>(`/auth/reject-user/${userId}`),

  // Get all users in tenant (admin only)
  getAllUsers: () =>
    api.get<ApiUser[]>('/users'),
};

// ============================================
// Datasets
// ============================================

export const datasetApi = {
  upload: (file: File, onProgress?: (progress: number) => void) =>
    api.upload<Dataset>('/datasets/upload', file, onProgress),

  loadSample: () =>
    api.post<Dataset>('/datasets/sample'),

  list: () =>
    api.get<Dataset[]>('/datasets'),

  get: (id: string) =>
    api.get<Dataset>(`/datasets/${id}`),

  preview: (id: string, page: number = 1, pageSize: number = 100) =>
    api.get<PaginatedResponse<any>>(`/datasets/${id}/preview?page=${page}&pageSize=${pageSize}`),

  summary: (id: string) =>
    api.get<DataSummary>(`/datasets/${id}/summary`),

  structure: (id: string) =>
    api.get<any>(`/datasets/${id}/structure`),

  missing: (id: string) =>
    api.get<any>(`/datasets/${id}/missing`),

  delete: (id: string) =>
    api.delete(`/datasets/${id}`),

  downloadTemplate: () =>
    api.download('/templates/download', 'lucent-template.csv'),
};

// ============================================
// Preprocessing
// ============================================

export const preprocessingApi = {
  getEntities: (datasetId: string) =>
    api.get<string[]>(`/preprocessing/${datasetId}/entities`),

  getEntityStats: (datasetId: string, entityId: string) =>
    api.get<EntityStats>(`/preprocessing/${datasetId}/${entityId}/stats`),

  getEntityData: (datasetId: string, entityId: string) =>
    api.get<any[]>(`/preprocessing/${datasetId}/${entityId}/data`),

  handleMissing: (datasetId: string, entityId: string, config: any) =>
    api.post(`/preprocessing/${datasetId}/${entityId}/missing`, config),

  handleDuplicates: (datasetId: string, entityId: string, config: any) =>
    api.post(`/preprocessing/${datasetId}/${entityId}/duplicates`, config),

  handleOutliers: (datasetId: string, entityId: string, config: any) =>
    api.post(`/preprocessing/${datasetId}/${entityId}/outliers`, config),

  replaceValues: (datasetId: string, entityId: string, config: any) =>
    api.post(`/preprocessing/${datasetId}/${entityId}/replace`, config),

  aggregate: (datasetId: string, entityId: string, config: any) =>
    api.post(`/preprocessing/${datasetId}/${entityId}/aggregate`, config),

  apply: (datasetId: string, entityId: string) =>
    api.post(`/preprocessing/${datasetId}/${entityId}/apply`),

  reset: (datasetId: string, entityId: string) =>
    api.post(`/preprocessing/${datasetId}/${entityId}/reset`),

  download: (datasetId: string, entityId: string) =>
    api.download(`/preprocessing/${datasetId}/${entityId}/download`, `processed-${entityId}.csv`),

  saveConfig: (datasetId: string, config: PreprocessConfig, name: string) =>
    api.post(`/preprocessing/${datasetId}/configs`, { config, name }),

  getConfigs: (datasetId: string) =>
    api.get<any[]>(`/preprocessing/${datasetId}/configs`),
};

// ============================================
// Forecasting
// ============================================

export const forecastApi = {
  run: (config: ForecastConfig & { datasetId: string; entityId: string }) =>
    api.post<ForecastResult>('/forecast/run', config),

  runBatch: (config: ForecastConfig & { datasetId: string; entityIds: string[] }) =>
    api.post<{ batchId: string }>('/forecast/batch', config),

  getStatus: (forecastId: string) =>
    api.get<ForecastResult>(`/forecast/status/${forecastId}`),

  preview: (config: ForecastConfig & { datasetId: string; entityId: string }) =>
    api.post<any>('/forecast/preview', config),

  getMethods: () =>
    api.get<string[]>('/forecast/methods'),

  autoParams: (method: string, datasetId: string, entityId: string) =>
    api.post<any>(`/forecast/auto-params/${method}`, { datasetId, entityId }),
};

// ============================================
// Results
// ============================================

export const resultsApi = {
  get: (forecastId: string) =>
    api.get<ForecastResult>(`/results/${forecastId}`),

  getData: (forecastId: string, page: number = 1, pageSize: number = 100) =>
    api.get<PaginatedResponse<any>>(`/results/${forecastId}/data?page=${page}&pageSize=${pageSize}`),

  getMetrics: (forecastId: string) =>
    api.get<any>(`/results/${forecastId}/metrics`),

  getSummary: (forecastId: string) =>
    api.get<any>(`/results/${forecastId}/summary`),

  getCrossValidation: (forecastId: string) =>
    api.get<any>(`/results/${forecastId}/cv`),

  getByEntity: (datasetId: string, entityId: string) =>
    api.get<ForecastResult[]>(`/results/entity/${datasetId}/${entityId}`),

  download: (forecastId: string, format: 'csv' | 'excel') =>
    api.download(`/results/download/${forecastId}?format=${format}`, `forecast-results.${format}`),

  export: (forecastId: string, options: any) =>
    api.post(`/results/export/${forecastId}`, options),
};

// ============================================
// Diagnostics
// ============================================

export const diagnosticsApi = {
  get: (forecastId: string) =>
    api.get<DiagnosticsData>(`/diagnostics/${forecastId}`),

  getResiduals: (forecastId: string) =>
    api.get<any>(`/diagnostics/${forecastId}/residuals`),

  getParameters: (forecastId: string) =>
    api.get<any>(`/diagnostics/${forecastId}/parameters`),

  getSeasonality: (forecastId: string) =>
    api.get<any>(`/diagnostics/${forecastId}/seasonality`),

  getEvaluation: (forecastId: string) =>
    api.get<any>(`/diagnostics/${forecastId}/evaluation`),

  getQuality: (forecastId: string) =>
    api.get<any>(`/diagnostics/${forecastId}/quality`),

  compare: (forecastIds: string[]) =>
    api.post<any>('/diagnostics/compare', { forecastIds }),

  export: (forecastId: string, format: 'pdf' | 'html' | 'docx') =>
    api.post(`/diagnostics/export/${forecastId}`, { format }),
};

// ============================================
// Users & Team
// ============================================

export const userApi = {
  me: () =>
    api.get<User>('/users/me'),

  updateProfile: (data: Partial<User>) =>
    api.put<User>('/users/me', data),

  changePassword: (oldPassword: string, newPassword: string) =>
    api.put('/users/me/password', { oldPassword, newPassword }),

  // Admin only
  list: () =>
    api.get<User[]>('/users'),

  create: (data: any) =>
    api.post<User>('/users', data),

  update: (id: string, data: Partial<User>) =>
    api.put<User>(`/users/${id}`, data),

  delete: (id: string) =>
    api.delete(`/users/${id}`),

  changeRole: (id: string, role: string) =>
    api.put(`/users/${id}/role`, { role }),
};

// ============================================
// Data Connectors
// ============================================

export const connectorApi = {
  list: () =>
    api.get<DataConnector[]>('/connectors'),

  create: (data: any) =>
    api.post<DataConnector>('/connectors', data),

  update: (id: string, data: Partial<DataConnector>) =>
    api.put<DataConnector>(`/connectors/${id}`, data),

  delete: (id: string) =>
    api.delete(`/connectors/${id}`),

  test: (id: string) =>
    api.post<{ success: boolean; message: string }>(`/connectors/${id}/test`),

  fetch: (id: string, query?: string) =>
    api.post<Dataset>(`/connectors/${id}/fetch`, { query }),
};

// ============================================
// Tenant
// ============================================

export const tenantApi = {
  get: () =>
    api.get<Tenant>('/tenant'),

  update: (data: Partial<Tenant>) =>
    api.put<Tenant>('/tenant', data),

  getLimits: () =>
    api.get<any>('/tenant/limits'),

  getUsage: () =>
    api.get<any>('/tenant/usage'),
};

// ============================================
// Audit Logs
// ============================================

export const auditApi = {
  list: (page: number = 1, pageSize: number = 50) =>
    api.get<PaginatedResponse<any>>(`/audit?page=${page}&pageSize=${pageSize}`),
};

// ============================================
// Super Admin API (Platform-wide management)
// ============================================

export const superAdminApi = {
  // Platform Stats
  getStats: () =>
    api.get<PlatformStats>('/admin/stats'),

  // Tenant Management
  listTenants: (params?: { skip?: number; limit?: number; search?: string; is_active?: boolean }) => {
    const query = new URLSearchParams();
    if (params?.skip !== undefined) query.append('skip', params.skip.toString());
    if (params?.limit !== undefined) query.append('limit', params.limit.toString());
    if (params?.search) query.append('search', params.search);
    if (params?.is_active !== undefined) query.append('is_active', params.is_active.toString());
    return api.get<AdminTenantListResponse>(`/admin/tenants?${query.toString()}`);
  },

  getTenant: (id: string) =>
    api.get<AdminTenant>(`/admin/tenants/${id}`),

  createTenant: (data: { name: string; slug: string; settings?: Record<string, any>; limits?: Record<string, any> }) =>
    api.post<AdminTenant>('/admin/tenants', data),

  updateTenant: (id: string, data: { name?: string; slug?: string; settings?: Record<string, any>; limits?: Record<string, any>; is_active?: boolean }) =>
    api.put<AdminTenant>(`/admin/tenants/${id}`, data),

  deleteTenant: (id: string) =>
    api.delete(`/admin/tenants/${id}`),

  // Create admin user for a tenant
  createTenantAdmin: (tenantId: string, data: { email: string; password: string; full_name: string; role?: string }) =>
    api.post<AdminUserResponse>(`/admin/tenants/${tenantId}/admin`, data),

  // User Management (all tenants)
  listUsers: (params?: { skip?: number; limit?: number; tenant_id?: string; search?: string; is_active?: boolean; is_approved?: boolean; role?: string }) => {
    const query = new URLSearchParams();
    if (params?.skip !== undefined) query.append('skip', params.skip.toString());
    if (params?.limit !== undefined) query.append('limit', params.limit.toString());
    if (params?.tenant_id) query.append('tenant_id', params.tenant_id);
    if (params?.search) query.append('search', params.search);
    if (params?.is_active !== undefined) query.append('is_active', params.is_active.toString());
    if (params?.is_approved !== undefined) query.append('is_approved', params.is_approved.toString());
    if (params?.role) query.append('role', params.role);
    return api.get<AdminUserListResponse>(`/admin/users?${query.toString()}`);
  },

  approveUser: (userId: string) =>
    api.put<AdminUserResponse>(`/admin/users/${userId}/approve`),

  toggleUserActive: (userId: string) =>
    api.put<AdminUserResponse>(`/admin/users/${userId}/toggle-active`),

  deleteUser: (userId: string) =>
    api.delete(`/admin/users/${userId}`),
};

// ============================================
// Tenant Admin Types
// ============================================

interface TenantUserResponse {
  id: string;
  email: string;
  full_name: string | null;
  role: string;
  is_active: boolean;
  is_approved: boolean;
  created_at: string;
  last_login: string | null;
  groups: { id: string; name: string }[];
}

interface TenantUserListResponse {
  users: TenantUserResponse[];
  total: number;
}

interface TenantStats {
  total_users: number;
  active_users: number;
  pending_approvals: number;
  total_groups: number;
  total_connectors: number;
}

interface GroupResponse {
  id: string;
  name: string;
  description: string | null;
  rls_values: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
  member_count: number;
}

interface GroupDetailResponse {
  id: string;
  name: string;
  description: string | null;
  rls_values: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
  members: { id: string; email: string; full_name: string | null; role: string }[];
}

interface GroupListResponse {
  groups: GroupResponse[];
  total: number;
}

interface ConnectorRLSResponse {
  id: string;
  connector_id: string;
  rls_column: string;
  is_enabled: boolean;
  created_at: string;
  updated_at: string;
}

interface ConnectorWithRLS {
  id: string;
  name: string;
  type: string;
  is_active: boolean;
  created_at: string;
  rls_config: ConnectorRLSResponse | null;
}

interface ConnectorListResponse {
  connectors: ConnectorWithRLS[];
  total: number;
}

// ============================================
// Tenant Admin API (Tenant-scoped management)
// ============================================

export const tenantAdminApi = {
  // Tenant Stats
  getStats: () =>
    api.get<TenantStats>('/users/stats'),

  // User Management (within tenant)
  listUsers: (params?: { skip?: number; limit?: number; search?: string; is_active?: boolean; is_approved?: boolean; role?: string }) => {
    const query = new URLSearchParams();
    if (params?.skip !== undefined) query.append('skip', params.skip.toString());
    if (params?.limit !== undefined) query.append('limit', params.limit.toString());
    if (params?.search) query.append('search', params.search);
    if (params?.is_active !== undefined) query.append('is_active', params.is_active.toString());
    if (params?.is_approved !== undefined) query.append('is_approved', params.is_approved.toString());
    if (params?.role) query.append('role', params.role);
    return api.get<TenantUserListResponse>(`/users?${query.toString()}`);
  },

  getUser: (userId: string) =>
    api.get<TenantUserResponse>(`/users/${userId}`),

  createUser: (data: { email: string; password: string; full_name: string; role?: string }) =>
    api.post<TenantUserResponse>('/users', data),

  updateUser: (userId: string, data: { full_name?: string; role?: string; is_active?: boolean; is_approved?: boolean }) =>
    api.put<TenantUserResponse>(`/users/${userId}`, data),

  deleteUser: (userId: string) =>
    api.delete(`/users/${userId}`),

  approveUser: (userId: string) =>
    api.put<TenantUserResponse>(`/users/${userId}/approve`),

  toggleUserActive: (userId: string) =>
    api.put<TenantUserResponse>(`/users/${userId}/toggle-active`),

  // Group Management
  listGroups: (params?: { skip?: number; limit?: number; search?: string; is_active?: boolean }) => {
    const query = new URLSearchParams();
    if (params?.skip !== undefined) query.append('skip', params.skip.toString());
    if (params?.limit !== undefined) query.append('limit', params.limit.toString());
    if (params?.search) query.append('search', params.search);
    if (params?.is_active !== undefined) query.append('is_active', params.is_active.toString());
    return api.get<GroupListResponse>(`/groups?${query.toString()}`);
  },

  getGroup: (groupId: string) =>
    api.get<GroupDetailResponse>(`/groups/${groupId}`),

  createGroup: (data: { name: string; description?: string; rls_values?: string[] }) =>
    api.post<GroupResponse>('/groups', data),

  updateGroup: (groupId: string, data: { name?: string; description?: string; rls_values?: string[]; is_active?: boolean }) =>
    api.put<GroupResponse>(`/groups/${groupId}`, data),

  deleteGroup: (groupId: string) =>
    api.delete(`/groups/${groupId}`),

  // Group Membership
  addGroupMember: (groupId: string, userId: string) =>
    api.post<{ message: string; group_id: string; added_count: number }>(`/groups/${groupId}/members`, { user_id: userId }),

  addGroupMembersBulk: (groupId: string, userIds: string[]) =>
    api.post<{ message: string; group_id: string; added_count: number }>(`/groups/${groupId}/members/bulk`, { user_ids: userIds }),

  removeGroupMember: (groupId: string, userId: string) =>
    api.delete<{ message: string; group_id: string; removed_count: number }>(`/groups/${groupId}/members/${userId}`),

  removeAllGroupMembers: (groupId: string) =>
    api.delete<{ message: string; group_id: string; removed_count: number }>(`/groups/${groupId}/members`),

  // Connector RLS Management
  listConnectors: (params?: { skip?: number; limit?: number; search?: string; is_active?: boolean }) => {
    const query = new URLSearchParams();
    if (params?.skip !== undefined) query.append('skip', params.skip.toString());
    if (params?.limit !== undefined) query.append('limit', params.limit.toString());
    if (params?.search) query.append('search', params.search);
    if (params?.is_active !== undefined) query.append('is_active', params.is_active.toString());
    return api.get<ConnectorListResponse>(`/connectors?${query.toString()}`);
  },

  getConnector: (connectorId: string) =>
    api.get<ConnectorWithRLS>(`/connectors/${connectorId}`),

  getConnectorRLS: (connectorId: string) =>
    api.get<ConnectorRLSResponse>(`/connectors/${connectorId}/rls`),

  createConnectorRLS: (connectorId: string, data: { rls_column: string; is_enabled?: boolean }) =>
    api.post<ConnectorRLSResponse>(`/connectors/${connectorId}/rls`, data),

  updateConnectorRLS: (connectorId: string, data: { rls_column?: string; is_enabled?: boolean }) =>
    api.put<ConnectorRLSResponse>(`/connectors/${connectorId}/rls`, data),

  deleteConnectorRLS: (connectorId: string) =>
    api.delete(`/connectors/${connectorId}/rls`),

  toggleConnectorRLS: (connectorId: string) =>
    api.put<ConnectorRLSResponse>(`/connectors/${connectorId}/rls/toggle`),

  // Get connector columns (for RLS column selector)
  getConnectorColumns: (connectorId: string) =>
    api.get<{ columns: string[] }>(`/connectors/${connectorId}/columns`),
};

// ============================================
// Public Tenants API (for URL validation)
// ============================================

export const tenantsPublicApi = {
  getBySlug: (slug: string) =>
    api.get<TenantPublicInfo>(`/tenants/${slug}`),
};

// Export types for use in components
export type { ApiUser, TenantPublicInfo };
export type { AdminTenant, AdminTenantListResponse, AdminUserResponse, AdminUserListResponse, PlatformStats };
export type { TenantUserResponse, TenantUserListResponse, TenantStats, GroupResponse, GroupDetailResponse, GroupListResponse, ConnectorRLSResponse, ConnectorWithRLS, ConnectorListResponse };
