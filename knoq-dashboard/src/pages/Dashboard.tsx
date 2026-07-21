import { useState, useEffect } from "react";
import { useAuth } from "../auth/AuthContext";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../components/ui/card";
import { StatCards } from "../components/dashboard/StatCards";
import { SessionsChart } from "../components/dashboard/SessionsChart";
import { AtRiskPlayers } from "../components/dashboard/AtRiskPlayers";
import type { AtRiskPlayer } from "../components/dashboard/AtRiskPlayers";
import { Button } from "../components/ui/button";
import { 
  UserPlus, PlusCircle, Activity, Target, TrendingUp, 
  TrendingDown, Clock, Zap, Award, ChevronRight, 
  CalendarDays, BarChart3, Users
} from "lucide-react";
import api from "../lib/axios";
import toast from "react-hot-toast";

// --- Sub-components for the enhanced dashboard ---

function SweetSpotGauge({ percentage }: { percentage: number }) {
  const circumference = 2 * Math.PI * 60;
  const strokeDashoffset = circumference - (percentage / 100) * circumference;
  const color = percentage >= 70 ? "text-green-500" : percentage >= 50 ? "text-yellow-500" : "text-red-500";

  return (
    <div className="flex flex-col items-center justify-center py-4">
      <div className="relative w-36 h-36">
        <svg className="w-36 h-36 -rotate-90" viewBox="0 0 128 128">
          <circle cx="64" cy="64" r="60" stroke="hsl(var(--border))" strokeWidth="8" fill="none" />
          <circle 
            cx="64" cy="64" r="60" 
            stroke="currentColor" 
            strokeWidth="8" 
            fill="none"
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            className={`${color} transition-all duration-1000 ease-out`}
          />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-3xl font-bold text-foreground">{percentage}%</span>
          <span className="text-xs text-muted-foreground">Sweet Spot</span>
        </div>
      </div>
      <p className="text-sm text-muted-foreground mt-3 text-center">Academy-wide average across all players this month</p>
    </div>
  );
}

interface RecentSession {
  id: string;
  playerName: string;
  date: string;
  totalHits: number;
  sweetSpotPct: number;
  peakPower: number;
}

function RecentSessionsTable({ sessions }: { sessions: RecentSession[] }) {
  return (
    <div className="space-y-3">
      {sessions.map((s) => (
        <div key={s.id} className="flex items-center justify-between p-3 border rounded-lg hover:bg-muted/50 transition-colors group">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
              <Activity className="h-4 w-4 text-primary" />
            </div>
            <div className="min-w-0">
              <p className="font-medium text-sm truncate">{s.playerName}</p>
              <p className="text-xs text-muted-foreground flex items-center gap-1">
                <Clock className="h-3 w-3" /> {s.date}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-4 shrink-0">
            <div className="text-right hidden sm:block">
              <p className="text-sm font-semibold">{s.totalHits} hits</p>
              <p className="text-xs text-muted-foreground">{s.sweetSpotPct}% sweet spot</p>
            </div>
            <ChevronRight className="h-4 w-4 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity" />
          </div>
        </div>
      ))}
    </div>
  );
}

interface TopPerformer {
  rank: number;
  name: string;
  avgSweetSpot: number;
  totalSessions: number;
  trend: "up" | "down" | "stable";
}

function TopPerformersBoard({ performers }: { performers: TopPerformer[] }) {
  return (
    <div className="space-y-3">
      {performers.map((p) => (
        <div key={p.rank} className="flex items-center gap-3 p-3 border rounded-lg hover:bg-muted/50 transition-colors">
          <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm shrink-0 ${
            p.rank === 1 ? "bg-amber-100 text-amber-600 dark:bg-amber-500/20 dark:text-amber-500" : 
            p.rank === 2 ? "bg-slate-100 text-slate-600 dark:bg-slate-500/20 dark:text-slate-400" : 
            p.rank === 3 ? "bg-orange-100 text-orange-600 dark:bg-orange-500/20 dark:text-orange-500" : 
            "bg-muted text-muted-foreground"
          }`}>
            {p.rank <= 3 ? <Award className="h-4 w-4" /> : p.rank}
          </div>
          <div className="flex-1 min-w-0">
            <p className="font-medium text-sm truncate">{p.name}</p>
            <p className="text-xs text-muted-foreground">{p.totalSessions} sessions</p>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <span className="text-sm font-bold">{p.avgSweetSpot}%</span>
            {p.trend === "up" ? (
              <TrendingUp className="h-4 w-4 text-green-500" />
            ) : p.trend === "down" ? (
              <TrendingDown className="h-4 w-4 text-red-500" />
            ) : null}
          </div>
        </div>
      ))}
    </div>
  );
}

function QuickInsightCard({ icon: Icon, label, value, subtext }: {
  icon: React.ElementType;
  label: string;
  value: string;
  subtext: string;
}) {
  return (
    <div className="flex items-start gap-3 p-4 border rounded-xl bg-background hover:border-foreground/20 transition-colors">
      <div className="p-2 rounded-lg bg-primary/10 text-primary">
        <Icon className="h-4 w-4" />
      </div>
      <div>
        <p className="text-xs text-muted-foreground font-medium">{label}</p>
        <p className="text-lg font-bold text-foreground">{value}</p>
        <p className="text-xs text-muted-foreground">{subtext}</p>
      </div>
    </div>
  );
}

// --- Main Dashboard ---

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
  const [avgSweetSpot, setAvgSweetSpot] = useState(68);

  // Enhanced dummy data for richer UI
  const recentSessions: RecentSession[] = [
    { id: "1", playerName: "Rahul Deshmukh", date: "Today, 4:17 AM", totalHits: 74, sweetSpotPct: 51, peakPower: 82 },
    { id: "2", playerName: "Arjun Mehta", date: "Today, 3:45 AM", totalHits: 198, sweetSpotPct: 65, peakPower: 91 },
    { id: "3", playerName: "Sneha Patil", date: "Yesterday, 6:30 PM", totalHits: 114, sweetSpotPct: 77, peakPower: 75 },
    { id: "4", playerName: "Vikram Singh", date: "Yesterday, 5:15 PM", totalHits: 89, sweetSpotPct: 42, peakPower: 88 },
    { id: "5", playerName: "Priya Sharma", date: "20 Jul, 4:17 AM", totalHits: 156, sweetSpotPct: 71, peakPower: 79 },
  ];

  const topPerformers: TopPerformer[] = [
    { rank: 1, name: "Sneha Patil", avgSweetSpot: 77, totalSessions: 32, trend: "up" },
    { rank: 2, name: "Priya Sharma", avgSweetSpot: 71, totalSessions: 28, trend: "up" },
    { rank: 3, name: "Arjun Mehta", avgSweetSpot: 65, totalSessions: 45, trend: "stable" },
    { rank: 4, name: "Rahul Deshmukh", avgSweetSpot: 51, totalSessions: 19, trend: "down" },
    { rank: 5, name: "Vikram Singh", avgSweetSpot: 42, totalSessions: 12, trend: "down" },
  ];

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

        setAvgSweetSpot(apiStats.avgSweetSpotPct || 68);
        
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
    return (
      <div className="flex flex-col items-center justify-center h-[calc(100vh-8rem)] gap-4">
        <div className="relative w-12 h-12">
          <div className="absolute inset-0 rounded-full border-4 border-muted"></div>
          <div className="absolute inset-0 rounded-full border-4 border-primary border-t-transparent animate-spin"></div>
        </div>
        <p className="text-sm text-muted-foreground font-medium">Loading dashboard...</p>
      </div>
    );
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

      {/* Stat Cards */}
      <StatCards stats={stats} />

      {/* Quick Insights Row */}
      <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
        <QuickInsightCard
          icon={Zap}
          label="Avg. Power (Month)"
          value="76.3"
          subtext="+4.2% from last month"
        />
        <QuickInsightCard
          icon={Target}
          label="Sweet Spot Accuracy"
          value={`${avgSweetSpot}%`}
          subtext="Academy-wide average"
        />
        <QuickInsightCard
          icon={CalendarDays}
          label="Avg. Sessions / Player"
          value="4.2"
          subtext="Per week this month"
        />
        <QuickInsightCard
          icon={BarChart3}
          label="Peak Bat Speed"
          value="142 km/h"
          subtext="Arjun Mehta — 19 Jul"
        />
      </div>

      {/* Sessions Chart + Sweet Spot Gauge */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <Card className="col-span-4 lg:col-span-5">
          <CardHeader>
            <CardTitle>Sessions Overview (Last 30 Days)</CardTitle>
            <CardDescription>Daily session count across all academy players</CardDescription>
          </CardHeader>
          <CardContent className="pl-0">
            <SessionsChart data={chartData} />
          </CardContent>
        </Card>
        <Card className="col-span-3 lg:col-span-2">
          <CardHeader>
            <CardTitle>Sweet Spot Score</CardTitle>
            <CardDescription>How well are your players hitting?</CardDescription>
          </CardHeader>
          <CardContent>
            <SweetSpotGauge percentage={avgSweetSpot} />
          </CardContent>
        </Card>
      </div>

      {/* Recent Sessions + Top Performers */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <Card className="col-span-4 lg:col-span-4">
          <CardHeader className="flex flex-row items-center justify-between">
            <div>
              <CardTitle>Recent Sessions</CardTitle>
              <CardDescription>Latest training sessions across the academy</CardDescription>
            </div>
            <Button variant="ghost" size="sm" className="text-xs text-muted-foreground">
              View All <ChevronRight className="ml-1 h-3 w-3" />
            </Button>
          </CardHeader>
          <CardContent>
            <RecentSessionsTable sessions={recentSessions} />
          </CardContent>
        </Card>
        <Card className="col-span-3 lg:col-span-3">
          <CardHeader className="flex flex-row items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <Users className="h-4 w-4 text-primary" /> Top Performers
              </CardTitle>
              <CardDescription>Ranked by sweet spot accuracy</CardDescription>
            </div>
          </CardHeader>
          <CardContent>
            <TopPerformersBoard performers={topPerformers} />
          </CardContent>
        </Card>
      </div>

      {/* At-Risk Players */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <Card className="col-span-4 lg:col-span-3">
          <CardHeader>
            <CardTitle>At-Risk Players</CardTitle>
            <CardDescription>Players who haven't trained in over 7 days</CardDescription>
          </CardHeader>
          <CardContent>
            <AtRiskPlayers players={atRiskPlayers} />
          </CardContent>
        </Card>
        <Card className="col-span-3 lg:col-span-4">
          <CardHeader>
            <CardTitle>Academy Health</CardTitle>
            <CardDescription>Key metrics at a glance</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <div className="p-4 rounded-xl border bg-card hover:bg-accent/50 transition-colors">
                <div className="flex items-center gap-2 mb-2">
                  <div className="p-1.5 rounded-md bg-green-500/10">
                    <TrendingUp className="h-4 w-4 text-green-600 dark:text-green-500" />
                  </div>
                  <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Improving</span>
                </div>
                <p className="text-2xl font-bold text-foreground">3</p>
                <p className="text-xs text-muted-foreground mt-1">Players trending up</p>
              </div>
              <div className="p-4 rounded-xl border bg-card hover:bg-accent/50 transition-colors">
                <div className="flex items-center gap-2 mb-2">
                  <div className="p-1.5 rounded-md bg-red-500/10">
                    <TrendingDown className="h-4 w-4 text-red-600 dark:text-red-500" />
                  </div>
                  <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Declining</span>
                </div>
                <p className="text-2xl font-bold text-foreground">2</p>
                <p className="text-xs text-muted-foreground mt-1">Players losing consistency</p>
              </div>
              <div className="p-4 rounded-xl border bg-card hover:bg-accent/50 transition-colors">
                <div className="flex items-center gap-2 mb-2">
                  <div className="p-1.5 rounded-md bg-blue-500/10">
                    <Activity className="h-4 w-4 text-blue-600 dark:text-blue-500" />
                  </div>
                  <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Active Today</span>
                </div>
                <p className="text-2xl font-bold text-foreground">4</p>
                <p className="text-xs text-muted-foreground mt-1">Players trained today</p>
              </div>
              <div className="p-4 rounded-xl border bg-card hover:bg-accent/50 transition-colors">
                <div className="flex items-center gap-2 mb-2">
                  <div className="p-1.5 rounded-md bg-purple-500/10">
                    <Award className="h-4 w-4 text-purple-600 dark:text-purple-500" />
                  </div>
                  <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Best Session</span>
                </div>
                <p className="text-2xl font-bold text-foreground">91%</p>
                <p className="text-xs text-muted-foreground mt-1">Sneha Patil — 19 Jul</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
