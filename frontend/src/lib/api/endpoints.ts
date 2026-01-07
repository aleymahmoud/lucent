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

export const authApi = {
  login: (email: string, password: string) =>
    api.post<{ access_token: string; token_type: string; user: User }>('/auth/login', { email, password }),

  register: (data: { email: string; password: string; fullName: string; tenantName: string }) =>
    api.post<{ access_token: string; token_type: string; user: User }>('/auth/register', {
      email: data.email,
      password: data.password,
      full_name: data.fullName,
      tenant_name: data.tenantName,
    }),

  logout: () =>
    api.post('/auth/logout'),

  me: () =>
    api.get<User>('/auth/me'),
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
