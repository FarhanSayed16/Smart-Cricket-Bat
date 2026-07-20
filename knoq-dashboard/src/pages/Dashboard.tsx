import { useState, useEffect } from "react";
import { useAuth } from "../auth/AuthContext";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { StatCards } from "../components/dashboard/StatCards";
import { SessionsChart } from "../components/dashboard/SessionsChart";
import { AtRiskPlayers } from "../components/dashboard/AtRiskPlayers";
import type { AtRiskPlayer } from "../components/dashboard/AtRiskPlayers";
import { Button } from "../components/ui/button";
import { UserPlus, PlusCircle } from "lucide-react";
import api from "../lib/axios";
import toast from "react-hot-toast";

export default function Dashboard() {
  const { dbUser } = useAuth();
  
  const [stats, setStats] = useState({
    totalPlayers: 0,
    totalCoaches: 0,
    sessionsThisMonth: 0,
    lifetimeShots: 0,
    activeBats: 0,
  });
  const [chartData, setChartData] = useState<any[]>([]);
  const [atRiskPlayers, setAtRiskPlayers] = useState<AtRiskPlayer[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDashboard = async () => {
      try {
        const [overviewRes, playersRes] = await Promise.all([
          api.get("/dashboard/overview"),
          api.get("/dashboard/players")
        ]);

        const { stats: apiStats, chartData: apiChartData } = overviewRes.data.data;
        
        setStats({
          totalPlayers: apiStats.totalPlayers || 0,
          totalCoaches: apiStats.totalCoaches || 0,
          sessionsThisMonth: apiStats.totalSessionsThisMonth || 0,
          lifetimeShots: apiStats.totalHitsThisMonth || 0,
          activeBats: apiStats.activeDevices || 0,
        });
        
        setChartData(apiChartData || []);

        // Filter players who haven't had a session in over 7 days
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        
        const players = playersRes.data.data || [];
        const atRisk = players
          .filter((p: any) => {
            if (!p.last_session_date) return true; // Never had a session
            return new Date(p.last_session_date) < sevenDaysAgo;
          })
          .map((p: any) => ({
            id: p.id,
            name: p.name,
            lastSessionDate: p.last_session_date || null
          }))
          .slice(0, 5); // Take top 5 at risk
          
        setAtRiskPlayers(atRisk);

      } catch (error) {
        toast.error("Failed to load dashboard data");
        console.error(error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboard();
  }, []);

  if (loading) {
    return <div className="flex items-center justify-center h-[calc(100vh-8rem)]">Loading dashboard...</div>;
  }

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500 ease-in-out">
      {/* Professional Structural Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4 pb-6 border-b">
        <div className="space-y-1">
          <h1 className="text-3xl font-bold tracking-tight text-foreground">
            Overview
          </h1>
          <p className="text-muted-foreground text-sm">
            Welcome back, <span className="font-medium text-foreground">{dbUser?.name || "Admin"}</span>. Here is your academy's status.
          </p>
        </div>
        <div className="flex gap-2 shrink-0">
          <Button variant="outline" size="sm" className="h-9">
            <UserPlus className="mr-2 h-4 w-4" /> Invite Player
          </Button>
          <Button size="sm" className="h-9">
            <PlusCircle className="mr-2 h-4 w-4" /> Register Bat
          </Button>
        </div>
      </div>

      <StatCards stats={stats} />

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <Card className="col-span-4 lg:col-span-5">
          <CardHeader>
            <CardTitle>Sessions Overview (Last 30 Days)</CardTitle>
          </CardHeader>
          <CardContent className="pl-0">
            <SessionsChart data={chartData} />
          </CardContent>
        </Card>
        <Card className="col-span-3 lg:col-span-2">
          <CardHeader>
            <CardTitle>At-Risk Players</CardTitle>
          </CardHeader>
          <CardContent>
            <AtRiskPlayers players={atRiskPlayers} />
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
