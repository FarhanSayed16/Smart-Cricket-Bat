import { Card, CardContent, CardHeader, CardTitle } from "../ui/card"
import { Badge } from "../ui/badge"

interface ShotData {
  shotNumber: number
  zone: string
  power: number
  sweetSpot: boolean
  techniqueScore: number
  swingSpeed: number | null
  aiFeedback: string
}

interface ShotDataPanelProps {
  shot: ShotData
  totalShots: number
}

function ZoneDiagram({ zone }: { zone: string }) {
  // Simplified bat face zone diagram
  const zones: Record<string, { x: number; y: number; label: string }> = {
    sweet: { x: 50, y: 40, label: "Sweet Spot" },
    toe: { x: 20, y: 60, label: "Toe" },
    edge: { x: 80, y: 30, label: "Edge" },
    middle: { x: 50, y: 50, label: "Middle" },
    top: { x: 50, y: 20, label: "Top" },
    bottom: { x: 50, y: 75, label: "Bottom" },
  }

  const activeZone = zones[zone] || zones.middle

  return (
    <div className="relative w-full max-w-[120px] mx-auto">
      <svg viewBox="0 0 100 100" className="w-full">
        {/* Bat face outline */}
        <rect
          x="15"
          y="5"
          width="70"
          height="90"
          rx="10"
          fill="none"
          stroke="hsl(var(--border))"
          strokeWidth="2"
        />
        {/* Zone lines */}
        <line x1="15" y1="35" x2="85" y2="35" stroke="hsl(var(--border))" strokeWidth="0.5" />
        <line x1="15" y1="65" x2="85" y2="65" stroke="hsl(var(--border))" strokeWidth="0.5" />
        <line x1="50" y1="5" x2="50" y2="95" stroke="hsl(var(--border))" strokeWidth="0.5" />
        {/* Active zone dot */}
        <circle
          cx={activeZone.x}
          cy={activeZone.y}
          r="8"
          fill="hsl(var(--primary))"
          opacity="0.8"
        />
        <circle
          cx={activeZone.x}
          cy={activeZone.y}
          r="4"
          fill="hsl(var(--primary-foreground))"
        />
      </svg>
      <p className="text-xs text-center text-muted-foreground mt-1">{activeZone.label}</p>
    </div>
  )
}

function PowerArc({ power }: { power: number }) {
  const normalized = Math.min(Math.max(power, 0), 100)
  const angle = (normalized / 100) * 180
  const radians = (angle * Math.PI) / 180
  const endX = 50 + 40 * Math.cos(Math.PI - radians)
  const endY = 50 - 40 * Math.sin(Math.PI - radians)
  const largeArc = angle > 90 ? 1 : 0

  let color = "hsl(var(--destructive))"
  if (normalized > 70) color = "hsl(var(--chart-2))"
  else if (normalized > 40) color = "hsl(var(--chart-4))"

  return (
    <div className="relative w-full max-w-[120px] mx-auto">
      <svg viewBox="0 0 100 55" className="w-full">
        {/* Background arc */}
        <path
          d="M 10 50 A 40 40 0 0 1 90 50"
          fill="none"
          stroke="hsl(var(--border))"
          strokeWidth="6"
          strokeLinecap="round"
        />
        {/* Power arc */}
        <path
          d={`M 10 50 A 40 40 0 ${largeArc} 1 ${endX} ${endY}`}
          fill="none"
          stroke={color}
          strokeWidth="6"
          strokeLinecap="round"
        />
      </svg>
      <p className="text-center text-lg font-bold -mt-2">{normalized}%</p>
      <p className="text-xs text-center text-muted-foreground">Power</p>
    </div>
  )
}

export function ShotDataPanel({ shot, totalShots }: ShotDataPanelProps) {
  return (
    <div className="space-y-4">
      <div className="text-center">
        <p className="text-lg font-semibold">
          Shot {shot.shotNumber} of {totalShots}
        </p>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <ZoneDiagram zone={shot.zone} />
        <PowerArc power={shot.power} />
      </div>

      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm">Technique Score</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2">
            <span className="text-2xl font-bold">{shot.techniqueScore}</span>
            <span className="text-muted-foreground text-sm">/100</span>
            <Badge
              variant={
                shot.techniqueScore >= 70
                  ? "default"
                  : shot.techniqueScore >= 40
                    ? "outline"
                    : "destructive"
              }
              className="ml-auto"
            >
              {shot.techniqueScore >= 70
                ? "Good"
                : shot.techniqueScore >= 40
                  ? "Fair"
                  : "Needs Work"}
            </Badge>
          </div>
          {shot.swingSpeed && (
            <p className="text-sm text-muted-foreground mt-1">
              Swing Speed: {shot.swingSpeed} m/s
            </p>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm">AI Feedback</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm">{shot.aiFeedback}</p>
        </CardContent>
      </Card>
    </div>
  )
}

export type { ShotData }
