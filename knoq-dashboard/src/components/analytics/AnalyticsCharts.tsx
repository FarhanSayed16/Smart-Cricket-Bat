import { Bar, BarChart, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis, PieChart, Pie, Cell } from "recharts"
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card"

const mockSessionsPerDay = Array.from({ length: 14 }).map((_, i) => {
  const d = new Date()
  d.setDate(d.getDate() - (13 - i))
  return {
    date: d.toISOString().split("T")[0].substring(5),
    sessions: Math.floor(Math.random() * 20) + 5,
  }
})

const mockSweetTrend = Array.from({ length: 14 }).map((_, i) => {
  const d = new Date()
  d.setDate(d.getDate() - (13 - i))
  return {
    date: d.toISOString().split("T")[0].substring(5),
    sweetPercent: 40 + Math.floor(Math.random() * 20) + i, // Trending slightly up
    powerAvg: 50 + Math.floor(Math.random() * 15) + Math.floor(i * 0.5),
  }
})

const mockZoneDistribution = [
  { name: "Sweet Spot", value: 45, color: "hsl(var(--chart-1))" },
  { name: "Middle", value: 25, color: "hsl(var(--chart-2))" },
  { name: "Toe", value: 15, color: "hsl(var(--chart-3))" },
  { name: "Edge", value: 10, color: "hsl(var(--chart-4))" },
  { name: "Top/Bottom", value: 5, color: "hsl(var(--chart-5))" },
]

export function AnalyticsCharts() {
  return (
    <div className="space-y-4">
      {/* Aggregate Metrics */}
      <div className="grid gap-4 sm:grid-cols-2 md:grid-cols-5">
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xs text-muted-foreground uppercase tracking-wide">Total Sessions</p>
            <p className="text-2xl font-bold mt-1">1,248</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xs text-muted-foreground uppercase tracking-wide">Total Hits</p>
            <p className="text-2xl font-bold mt-1">24,560</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xs text-muted-foreground uppercase tracking-wide">Avg Sweet Spot</p>
            <p className="text-2xl font-bold mt-1 text-green-600">54%</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xs text-muted-foreground uppercase tracking-wide">Avg Power</p>
            <p className="text-2xl font-bold mt-1">62%</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xs text-muted-foreground uppercase tracking-wide">Avg Consistency</p>
            <p className="text-2xl font-bold mt-1">78</p>
          </CardContent>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium">Sessions per Day</CardTitle>
          </CardHeader>
          <CardContent className="pl-0">
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={mockSessionsPerDay} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <XAxis dataKey="date" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis fontSize={12} tickLine={false} axisLine={false} />
                <Tooltip
                  contentStyle={{ backgroundColor: 'hsl(var(--card))', borderColor: 'hsl(var(--border))', borderRadius: '8px' }}
                  cursor={{ fill: 'hsl(var(--muted))' }}
                />
                <Bar dataKey="sessions" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium">Sweet Spot % & Power Trend</CardTitle>
          </CardHeader>
          <CardContent className="pl-0">
            <ResponsiveContainer width="100%" height={250}>
              <LineChart data={mockSweetTrend} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <XAxis dataKey="date" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis fontSize={12} tickLine={false} axisLine={false} domain={[0, 100]} />
                <Tooltip
                  contentStyle={{ backgroundColor: 'hsl(var(--card))', borderColor: 'hsl(var(--border))', borderRadius: '8px' }}
                />
                <Line
                  type="monotone"
                  dataKey="sweetPercent"
                  name="Sweet Spot %"
                  stroke="hsl(var(--chart-2))"
                  strokeWidth={3}
                  dot={false}
                  activeDot={{ r: 6, fill: "hsl(var(--chart-2))" }}
                />
                <Line
                  type="monotone"
                  dataKey="powerAvg"
                  name="Power Avg %"
                  stroke="hsl(var(--chart-4))"
                  strokeWidth={2}
                  strokeDasharray="5 5"
                  dot={false}
                  activeDot={{ r: 5, fill: "hsl(var(--chart-4))" }}
                />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium">Zone Distribution (Donut)</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[250px] flex flex-col md:flex-row items-center">
              <ResponsiveContainer width="100%" height="100%" className="flex-1">
                <PieChart>
                  <Pie
                    data={mockZoneDistribution}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={2}
                    dataKey="value"
                  >
                    {mockZoneDistribution.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{ backgroundColor: 'hsl(var(--card))', borderColor: 'hsl(var(--border))', borderRadius: '8px' }}
                  />
                </PieChart>
              </ResponsiveContainer>
              <div className="flex-1 flex flex-col gap-2 justify-center">
                {mockZoneDistribution.map((zone) => (
                  <div key={zone.name} className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full" style={{ backgroundColor: zone.color }} />
                    <span className="text-sm font-medium flex-1">{zone.name}</span>
                    <span className="text-sm text-muted-foreground">{zone.value}%</span>
                  </div>
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium">Fatigue Curve (Avg Power per Shot)</CardTitle>
          </CardHeader>
          <CardContent className="pl-0">
            <ResponsiveContainer width="100%" height={250}>
              <LineChart data={[
                { shot: 1, power: 85 }, { shot: 10, power: 88 }, { shot: 20, power: 82 }, 
                { shot: 30, power: 75 }, { shot: 40, power: 70 }, { shot: 50, power: 65 }
              ]} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <XAxis dataKey="shot" fontSize={12} tickLine={false} axisLine={false} label={{ value: 'Shot Number', position: 'insideBottom', offset: -5 }} />
                <YAxis fontSize={12} tickLine={false} axisLine={false} domain={[0, 100]} />
                <Tooltip
                  contentStyle={{ backgroundColor: 'hsl(var(--card))', borderColor: 'hsl(var(--border))', borderRadius: '8px' }}
                />
                <Line
                  type="monotone"
                  dataKey="power"
                  name="Power %"
                  stroke="hsl(var(--chart-1))"
                  strokeWidth={3}
                  dot={{ r: 4, fill: "hsl(var(--chart-1))" }}
                  activeDot={{ r: 6 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
