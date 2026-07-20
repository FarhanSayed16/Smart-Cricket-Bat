import { Card, CardContent, CardHeader, CardTitle } from "../ui/card"
import { Progress } from "../ui/progress"
import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts"

const SHOT_TYPES = [
  { name: "Cover Drive", count: 142 },
  { name: "Straight Drive", count: 89 }, // < 100
  { name: "Pull", count: 120 },
  { name: "Hook", count: 45 }, // < 100
  { name: "Cut", count: 110 },
  { name: "Sweep", count: 60 }, // < 100
  { name: "Defend Front", count: 200 },
  { name: "Defend Back", count: 180 },
]

const DELIVERY_TYPES = [
  { name: "Good Length", count: 340 },
  { name: "Short", count: 210 },
  { name: "Full", count: 180 },
  { name: "Yorker", count: 90 },
  { name: "Bouncer", count: 126 },
]

export function DataCollectionOverview() {
  const totalClips = 1524
  const taggedClips = 946
  const untaggedClips = totalClips - taggedClips
  const taggedPercent = Math.round((taggedClips / totalClips) * 100)

  return (
    <div className="space-y-4">
      {/* Top Stats */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Clips</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalClips.toLocaleString()}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Tagged Clips</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <div className="text-2xl font-bold">{taggedClips.toLocaleString()}</div>
              <span className="text-sm text-green-500 font-medium">{taggedPercent}%</span>
            </div>
            <Progress value={taggedPercent} className="h-2 mt-2" />
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Untagged Clips</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-500">{untaggedClips.toLocaleString()}</div>
          </CardContent>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium">Clips per Shot Type</CardTitle>
          </CardHeader>
          <CardContent className="pl-0">
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={SHOT_TYPES} layout="vertical" margin={{ top: 0, right: 10, left: 20, bottom: 0 }}>
                <XAxis type="number" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis dataKey="name" type="category" fontSize={12} tickLine={false} axisLine={false} width={100} />
                <Tooltip
                  contentStyle={{ backgroundColor: 'hsl(var(--card))', borderColor: 'hsl(var(--border))', borderRadius: '8px' }}
                  cursor={{ fill: 'hsl(var(--muted))' }}
                />
                <Bar 
                  dataKey="count" 
                  radius={[0, 4, 4, 0]} 
                  fill="hsl(var(--primary))"
                  shape={(props: any) => {
                    const { x, y, width, height, payload } = props;
                    const fill = payload.count < 100 ? "hsl(var(--destructive))" : "hsl(var(--primary))";
                    return <rect x={x} y={y} width={width} height={height} fill={fill} rx={4} ry={4} />;
                  }}
                />
              </BarChart>
            </ResponsiveContainer>
            <p className="text-xs text-muted-foreground text-center mt-2">
              <span className="text-destructive font-semibold">Red</span> indicates &lt; 100 clips (not ready for model training).
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium">Clips per Delivery Type</CardTitle>
          </CardHeader>
          <CardContent className="pl-0">
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={DELIVERY_TYPES} layout="vertical" margin={{ top: 0, right: 10, left: 20, bottom: 0 }}>
                <XAxis type="number" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis dataKey="name" type="category" fontSize={12} tickLine={false} axisLine={false} width={80} />
                <Tooltip
                  contentStyle={{ backgroundColor: 'hsl(var(--card))', borderColor: 'hsl(var(--border))', borderRadius: '8px' }}
                  cursor={{ fill: 'hsl(var(--muted))' }}
                />
                <Bar dataKey="count" fill="hsl(var(--chart-2))" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardContent className="p-4 flex items-center justify-between bg-primary/5">
          <div>
            <h3 className="font-semibold text-primary">Model Readiness Estimate</h3>
            <p className="text-sm text-muted-foreground">Cover Drive and Pull Shot models have enough data for V1 training.</p>
          </div>
          <div className="text-right">
            <div className="text-sm font-medium">Overall Progress</div>
            <div className="text-2xl font-bold">2/8 Ready</div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
