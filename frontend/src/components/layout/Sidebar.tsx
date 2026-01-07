'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
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
} from 'lucide-react';

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: Home },
  { name: 'Data', href: '/dashboard/data', icon: Database },
  { name: 'Preprocessing', href: '/dashboard/preprocessing', icon: FileText },
  { name: 'Forecast', href: '/dashboard/forecast', icon: TrendingUp },
  { name: 'Results', href: '/dashboard/results', icon: LineChart },
  { name: 'Diagnostics', href: '/dashboard/diagnostics', icon: Activity },
  { name: 'Settings', href: '/dashboard/settings', icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <div className="flex h-full w-64 flex-col border-r bg-background">
      {/* Logo */}
      <div className="flex h-16 items-center border-b px-6">
        <BarChart3 className="h-6 w-6 text-primary" />
        <span className="ml-2 text-xl font-bold">LUCENT</span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 space-y-1 px-3 py-4">
        {navigation.map((item) => {
          const isActive = pathname === item.href || pathname?.startsWith(`${item.href}/`);
          const Icon = item.icon;

          return (
            <Link
              key={item.name}
              href={item.href}
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
      </nav>

      {/* Footer */}
      <div className="border-t p-4">
        <div className="flex items-center gap-3">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-sm font-medium text-primary-foreground">
            U
          </div>
          <div className="flex-1 overflow-hidden">
            <p className="truncate text-sm font-medium">User Name</p>
            <p className="truncate text-xs text-muted-foreground">Analyst</p>
          </div>
        </div>
      </div>
    </div>
  );
}
