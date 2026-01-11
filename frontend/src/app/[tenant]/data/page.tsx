"use client";

import { useState, useCallback } from "react";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  FileUploader,
  DataPreviewTable,
  DataSummary,
  SampleDataLoader,
  DatasetList,
} from "@/components/data";
import { ArrowLeft, Download, Settings } from "lucide-react";
import { toast } from "sonner";

interface Dataset {
  id: string;
  name: string;
  filename: string;
  file_size: number;
  file_type: string;
  row_count: number | null;
  column_count: number | null;
  columns?: string[];
  entities: string[];
  uploaded_at: string;
  is_processed: boolean;
}

export default function DataPage() {
  const [selectedDataset, setSelectedDataset] = useState<Dataset | null>(null);
  const [refreshTrigger, setRefreshTrigger] = useState(0);
  const [activeTab, setActiveTab] = useState("preview");

  const handleUploadComplete = useCallback((result: any) => {
    toast.success("File uploaded successfully!", {
      description: `${result.name} - ${result.row_count.toLocaleString()} rows`,
    });
    // Refresh the dataset list
    setRefreshTrigger((prev) => prev + 1);
    // Auto-select the newly uploaded dataset
    setSelectedDataset(result);
  }, []);

  const handleUploadError = useCallback((error: string) => {
    toast.error("Upload failed", {
      description: error,
    });
  }, []);

  const handleSampleLoadComplete = useCallback((result: any) => {
    toast.success("Sample data loaded!", {
      description: `${result.name} - ${result.row_count.toLocaleString()} rows`,
    });
    setRefreshTrigger((prev) => prev + 1);
    setSelectedDataset(result);
  }, []);

  const handleSampleLoadError = useCallback((error: string) => {
    toast.error("Failed to load sample data", {
      description: error,
    });
  }, []);

  const handleSelectDataset = useCallback((dataset: Dataset) => {
    setSelectedDataset(dataset);
    setActiveTab("preview");
  }, []);

  const handleBackToList = useCallback(() => {
    setSelectedDataset(null);
  }, []);

  const handleDownloadTemplate = async (type: string) => {
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";
      const response = await fetch(`${apiUrl}/datasets/templates/download?template_type=${type}`, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
      });

      if (!response.ok) throw new Error("Download failed");

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `lucent_${type}_template.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);

      toast.success("Template downloaded!");
    } catch (err) {
      toast.error("Failed to download template");
    }
  };

  // Dataset detail view
  if (selectedDataset) {
    return (
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button variant="ghost" size="icon" onClick={handleBackToList}>
              <ArrowLeft className="h-5 w-5" />
            </Button>
            <div>
              <h1 className="text-2xl font-bold">{selectedDataset.name}</h1>
              <p className="text-sm text-muted-foreground">
                {selectedDataset.filename} -{" "}
                {selectedDataset.row_count?.toLocaleString() || "?"} rows,{" "}
                {selectedDataset.column_count || "?"} columns
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm">
              <Settings className="h-4 w-4 mr-2" />
              Configure Columns
            </Button>
            <Button size="sm">Continue to Preprocessing</Button>
          </div>
        </div>

        {/* Tabs */}
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList>
            <TabsTrigger value="preview">Data Preview</TabsTrigger>
            <TabsTrigger value="summary">Summary Statistics</TabsTrigger>
          </TabsList>

          <TabsContent value="preview" className="mt-6">
            <DataPreviewTable
              datasetId={selectedDataset.id}
              initialColumns={selectedDataset.columns}
            />
          </TabsContent>

          <TabsContent value="summary" className="mt-6">
            <DataSummary datasetId={selectedDataset.id} />
          </TabsContent>
        </Tabs>
      </div>
    );
  }

  // Main data page view
  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Data</h1>
          <p className="text-muted-foreground">
            Upload and manage your datasets for forecasting
          </p>
        </div>
        <div className="flex items-center gap-2">
          <SampleDataLoader
            onLoadComplete={handleSampleLoadComplete}
            onLoadError={handleSampleLoadError}
          />
          <Button variant="outline" onClick={() => handleDownloadTemplate("multi_entity")}>
            <Download className="h-4 w-4 mr-2" />
            Download Template
          </Button>
        </div>
      </div>

      {/* Upload Section */}
      <FileUploader onUploadComplete={handleUploadComplete} onUploadError={handleUploadError} />

      {/* Dataset List */}
      <DatasetList onSelectDataset={handleSelectDataset} refreshTrigger={refreshTrigger} />
    </div>
  );
}
