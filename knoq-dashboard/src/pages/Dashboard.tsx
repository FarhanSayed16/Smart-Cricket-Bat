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
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDashboard = async () => {
      try {
        const res = await api.get("/dashboard/overview");
        const { stats: apiStats, chartData: apiChartData } = res.data.data;
        
        setStats({
          totalPlayers: apiStats.totalPlayers || 0,
          totalCoaches: apiStats.totalCoaches || 0,
          sessionsThisMonth: apiStats.totalSessionsThisMonth || 0,
          lifetimeShots: apiStats.totalHitsThisMonth || 0,
          activeBats: apiStats.activeDevices || 0,
        });
        
        setChartData(apiChartData || []);
      } catch (error) {
        toast.error("Failed to load dashboard data");
        console.error(error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboard();
  }, []);

  const mockAtRisk: AtRiskPlayer[] = [
    { id: "1", name: "Rahul Dravid", lastSessionDate: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString() },
    { id: "2", name: "Sachin T", lastSessionDate: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000).toISOString() },
  ];

  if (loading) {
    return <div className="flex items-center justify-center h-[calc(100vh-8rem)]">Loading dashboard...</div>;
  }

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500 ease-in-out">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Overview</h1>
          <p className="text-muted-foreground">Welcome back, {dbUser?.name || "Admin"}. Here is your academy's status.</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm">
            <UserPlus className="mr-2 h-4 w-4" /> Invite Player
          </Button>
          <Button size="sm">
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
            <AtRiskPlayers players={mockAtRisk} />
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
