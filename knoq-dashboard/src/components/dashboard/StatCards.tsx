import { Users, UserSquare2, Activity, BatteryCharging, Trophy } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card";

interface StatCardsProps {
  stats: {
    totalPlayers: number;
    totalCoaches: number;
    sessionsThisMonth: number;
    lifetimeShots: number;
    activeBats: number;
  };
}

export function StatCards({ stats }: StatCardsProps) {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-5">
      <Card className="shadow-sm border transition-colors hover:border-foreground/20">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Total Players</CardTitle>
          <Users className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-foreground">{stats.totalPlayers}</div>
        </CardContent>
      </Card>
      
      <Card className="shadow-sm border transition-colors hover:border-foreground/20">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Total Coaches</CardTitle>
          <UserSquare2 className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-foreground">{stats.totalCoaches}</div>
        </CardContent>
      </Card>
      
      <Card className="shadow-sm border transition-colors hover:border-foreground/20">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Sessions (Month)</CardTitle>
          <Activity className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-foreground">{stats.sessionsThisMonth}</div>
        </CardContent>
      </Card>
      
      <Card className="shadow-sm border transition-colors hover:border-foreground/20">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Lifetime Shots</CardTitle>
          <Trophy className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-foreground">{stats.lifetimeShots.toLocaleString()}</div>
        </CardContent>
      </Card>
      
      <Card className="shadow-sm border transition-colors hover:border-foreground/20">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Active Bats</CardTitle>
          <BatteryCharging className="h-4 w-4 text-green-500" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-foreground">{stats.activeBats}</div>
          <div className="flex items-center gap-1.5 mt-1">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
            </span>
            <p className="text-xs text-muted-foreground">
              Online right now
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
