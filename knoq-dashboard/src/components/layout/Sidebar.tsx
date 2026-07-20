import { Link, useLocation } from "react-router-dom";
import { LayoutDashboard, Users, UserSquare2, Smartphone, BarChart3, Database, FileText, Bell, Settings, ShieldAlert, Menu } from "lucide-react";
import { cn } from "../../lib/utils";
import { useAuth } from "../../auth/AuthContext";
import { useState } from "react";
import { Button } from "../ui/button";

export function Sidebar() {
  const { pathname } = useLocation();
  const { role } = useAuth();
  const [mobileOpen, setMobileOpen] = useState(false);

  const links = [
    { name: "Overview", href: "/dashboard", icon: LayoutDashboard },
    { name: "Players", href: "/players", icon: Users },
    { name: "Coaches", href: "/coaches", icon: UserSquare2 },
    { name: "Devices", href: "/devices", icon: Smartphone },
    { name: "Analytics", href: "/analytics", icon: BarChart3 },
    { name: "AI Lab", href: "/ai-lab", icon: Database },
    { name: "Reports", href: "/reports", icon: FileText },
    { name: "Notifications", href: "/notifications", icon: Bell },
    { name: "Settings", href: "/settings", icon: Settings },
  ];

  if (role === "super") {
    links.push({ name: "Super Admin", href: "/super-admin", icon: ShieldAlert });
  }

  const navContent = (
    <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
      {links.map((link) => {
        const Icon = link.icon;
        const isActive = pathname === link.href || pathname.startsWith(`${link.href}/`);
        return (
          <Link
            key={link.name}
            to={link.href}
            onClick={() => setMobileOpen(false)}
            className={cn(
              "flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors",
              isActive
                ? "bg-muted text-foreground font-semibold"
                : "text-muted-foreground hover:bg-muted/50 hover:text-foreground"
            )}
          >
            <Icon className="h-4 w-4" />
            {link.name}
          </Link>
        );
      })}
    </nav>
  );

  return (
    <>
      {/* Mobile hamburger button */}
      <Button
        variant="ghost"
        size="sm"
        className="md:hidden fixed top-4 left-4 z-50"
        onClick={() => setMobileOpen(!mobileOpen)}
      >
        <Menu className="h-5 w-5" />
      </Button>

      {/* Mobile overlay */}
      {mobileOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 md:hidden"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Mobile sidebar */}
      <aside className={cn(
        "fixed inset-y-0 left-0 z-40 w-64 border-r bg-card flex flex-col transition-transform duration-200 ease-in-out md:hidden",
        mobileOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        <div className="h-16 flex items-center px-6 border-b">
          <span className="font-bold text-2xl tracking-tight text-primary">KnoQ</span>
        </div>
        {navContent}
      </aside>

      {/* Desktop sidebar */}
      <aside className="hidden md:flex w-64 border-r bg-card flex-col h-full">
        <div className="h-16 flex items-center px-6 border-b">
          <span className="font-bold text-2xl tracking-tight text-primary">KnoQ</span>
        </div>
        {navContent}
      </aside>
    </>
  );
}
