"use client";

import { createContext, useContext, useState, useEffect, ReactNode } from "react";
import { useParams, useRouter } from "next/navigation";
import { tenantsPublicApi } from "@/lib/api/endpoints";

interface TenantInfo {
  id: string;
  slug: string;
  name: string;
  is_active: boolean;
}

interface TenantContextType {
  tenant: TenantInfo | null;
  isLoading: boolean;
  isValid: boolean;
  error: string | null;
}

const TenantContext = createContext<TenantContextType | undefined>(undefined);

interface TenantProviderProps {
  children: ReactNode;
  tenantSlug: string;
}

export function TenantProvider({ children, tenantSlug }: TenantProviderProps) {
  const [tenant, setTenant] = useState<TenantInfo | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    const validateTenant = async () => {
      if (!tenantSlug) {
        setError("No tenant specified");
        setIsLoading(false);
        return;
      }

      try {
        const tenantData = await tenantsPublicApi.getBySlug(tenantSlug);
        setTenant(tenantData);
        setError(null);
      } catch (err: any) {
        console.error("Failed to validate tenant:", err);
        setTenant(null);
        setError("Tenant not found");
      } finally {
        setIsLoading(false);
      }
    };

    validateTenant();
  }, [tenantSlug]);

  const isValid = tenant !== null && !error;

  return (
    <TenantContext.Provider
      value={{
        tenant,
        isLoading,
        isValid,
        error,
      }}
    >
      {children}
    </TenantContext.Provider>
  );
}

export function useTenant() {
  const context = useContext(TenantContext);
  if (context === undefined) {
    throw new Error("useTenant must be used within a TenantProvider");
  }
  return context;
}
