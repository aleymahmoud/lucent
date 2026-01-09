'use client';

import Link from 'next/link';
import { usePathname, useParams } from 'next/navigation';
import { cn } from '@/lib/utils';
import { useAuth } from '@/contexts/AuthContext';
import {
  BarChart3,
  Database,
  FileText,
  Home,
  LineChart,
  Settings,
  TrendingUp,
  Users,
  Activity,
  Shield,
  UsersRound,
  Link2,
} from 'lucide-react';

// Navigation items (paths will be prefixed with tenant slug)
const navigationItems = [
  { name: 'Dashboard', path: '/dashboard', icon: Home },
  { name: 'Data', path: '/data', icon: Database },
  { name: 'Preprocessing', path: '/preprocessing', icon: FileText },
  { name: 'Forecast', path: '/forecast', icon: TrendingUp },
  { name: 'Results', path: '/results', icon: LineChart },
  { name: 'Diagnostics', path: '/diagnostics', icon: Activity },
  { name: 'Settings', path: '/settings', icon: Settings },
];

const adminNavigationItems = [
  { name: 'Users', path: '/settings/users', icon: Users },
  { name: 'Groups', path: '/settings/groups', icon: UsersRound },
  { name: 'Connectors', path: '/settings/connectors', icon: Link2 },
];

export function Sidebar() {
  const pathname = usePathname();
  const params = useParams();
  const { user } = useAuth();

  // Get tenant slug from URL params or user data
  const tenantSlug = (params?.tenant as string) || user?.tenant_slug || '';

  // Build tenant-prefixed href
  const buildHref = (path: string) => `/${tenantSlug}${path}`;

  // Check if a path is active
  const isPathActive = (path: string) => {
    const fullPath = buildHref(path);
    return pathname === fullPath || pathname?.startsWith(`${fullPath}/`);
  };

  return (
    <div className="flex h-full w-64 flex-col border-r bg-background">
      {/* Logo */}
      <div className="flex h-16 items-center border-b px-6">
        <BarChart3 className="h-6 w-6 text-primary" />
        <span className="ml-2 text-xl font-bold">LUCENT</span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 space-y-1 px-3 py-4">
        {navigationItems.map((item) => {
          const isActive = isPathActive(item.path);
          const Icon = item.icon;

          return (
            <Link
              key={item.name}
              href={buildHref(item.path)}
              className={cn(
                'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                isActive
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
              )}
            >
              <Icon className="h-5 w-5" />
              {item.name}
            </Link>
          );
        })}

        {/* Tenant Admin Links */}
        {(user?.role === 'admin' || user?.is_super_admin) && (
          <>
            <div className="my-4 border-t" />
            <p className="px-3 text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2">
              Admin
            </p>
            {adminNavigationItems.map((item) => {
              const isActive = isPathActive(item.path);
              const Icon = item.icon;

              return (
                <Link
                  key={item.name}
                  href={buildHref(item.path)}
                  className={cn(
                    'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                    isActive
                      ? 'bg-primary text-primary-foreground'
                      : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                  )}
                >
                  <Icon className="h-5 w-5" />
                  {item.name}
                </Link>
              );
            })}
          </>
        )}

        {/* Super Admin Link */}
        {user?.is_super_admin && (
          <>
            <div className="my-4 border-t" />
            <Link
              href="/admin"
              className={cn(
                'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                'bg-red-50 text-red-700 hover:bg-red-100'
              )}
            >
              <Shield className="h-5 w-5" />
              Super Admin
            </Link>
          </>
        )}
      </nav>

      {/* Footer */}
      <div className="border-t p-4">
        <div className="flex items-center gap-3">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-sm font-medium text-primary-foreground">
            {user?.full_name?.[0]?.toUpperCase() || user?.email?.[0]?.toUpperCase() || 'U'}
          </div>
          <div className="flex-1 overflow-hidden">
            <p className="truncate text-sm font-medium">{user?.full_name || user?.email || 'User'}</p>
            <p className="truncate text-xs text-muted-foreground capitalize">{user?.role || 'User'}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
