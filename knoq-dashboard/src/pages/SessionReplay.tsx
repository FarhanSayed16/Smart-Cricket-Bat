import { useState } from "react"
import { useParams, Link } from "react-router-dom"
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card"
import { Button } from "../components/ui/button"
import { Badge } from "../components/ui/badge"
import { ShotDataPanel } from "../components/session-replay/ShotDataPanel"
import type { ShotData } from "../components/session-replay/ShotDataPanel"
import { ShotList } from "../components/session-replay/ShotList"
import { CoachNotes } from "../components/session-replay/CoachNotes"
import type { CoachNote } from "../components/session-replay/CoachNotes"
import {
  ChevronLeft,
  ChevronRight,
  ArrowLeft,
  Play,
  Pause,
  RotateCcw,
  FileDown,
} from "lucide-react"

// Mock data for session replay
const mockShots: ShotData[] = Array.from({ length: 30 }).map((_, i) => {
  const zones = ["sweet", "middle", "toe", "edge", "top", "bottom"]
  const feedbacks = [
    "Good weight transfer through the shot. Front elbow held high.",
    "Front foot not fully forward. Work on stride length.",
    "Excellent head position over the ball. Textbook cover drive.",
    "Bottom hand too dominant. Let the top hand guide the stroke.",
    "Late on the shot — bat speed needs improvement.",
    "Good shot selection for this delivery length.",
    "Front elbow dropped early. Maintain high elbow through contact.",
    "Weight on back foot — commit forward for full deliveries.",
  ]
  const zone = zones[Math.floor(Math.random() * zones.length)]
  return {
    shotNumber: i + 1,
    zone,
    power: Math.floor(Math.random() * 60) + 30,
    sweetSpot: zone === "sweet",
    techniqueScore: Math.floor(Math.random() * 60) + 30,
    swingSpeed: Math.random() > 0.3 ? +(Math.random() * 20 + 10).toFixed(1) : null,
    aiFeedback: feedbacks[Math.floor(Math.random() * feedbacks.length)],
  }
})

const mockCoachNotes: CoachNote[] = [
  {
    id: "n1",
    coachName: "Rahul Dravid",
    text: "Keep your head still and watch the ball till the end. Good session overall.",
    createdAt: "Today at 3:45 PM",
    shotNumber: null,
  },
  {
    id: "n2",
    coachName: "Rahul Dravid",
    text: "This shot — front foot needs to go further forward. You were reaching.",
    createdAt: "Today at 3:42 PM",
    shotNumber: 5,
  },
]

const FILTERS = [
  { label: "All", value: "all" },
  { label: "Sweet Spot", value: "sweet" },
  { label: "Poor Technique", value: "poor" },
  { label: "Edge/Toe", value: "edge" },
]

export default function SessionReplay() {
  const { id } = useParams<{ id: string }>()
  const [currentShotIndex, setCurrentShotIndex] = useState(0)
  const [isPlaying, setIsPlaying] = useState(false)
  const [playbackSpeed, setPlaybackSpeed] = useState(1)
  const [filter, setFilter] = useState("all")

  const currentShot = mockShots[currentShotIndex]

  const sessionMeta = {
    playerName: "Virat Kohli",
    date: "April 29, 2026 — 3:00 PM",
    duration: "42 min",
    totalHits: mockShots.length,
    sweetPercent: Math.round(
      (mockShots.filter((s) => s.sweetSpot).length / mockShots.length) * 100
    ),
    avgPower: Math.round(
      mockShots.reduce((sum, s) => sum + s.power, 0) / mockShots.length
    ),
  }

  const speeds = [0.25, 0.5, 1]

  return (
    <div className="space-y-4">
      {/* Back button + header */}
      <div className="flex items-center gap-4">
        <Link to="/players">
          <Button variant="ghost" size="sm">
            <ArrowLeft className="h-4 w-4 mr-1" />
            Back
          </Button>
        </Link>
        <div className="flex-1">
          <h1 className="text-2xl font-bold tracking-tight">
            Session Replay
            <span className="text-muted-foreground font-normal ml-2 text-base">
              #{id || "demo"}
            </span>
          </h1>
        </div>
        <Button variant="outline" size="sm">
          <FileDown className="h-4 w-4 mr-1" />
          Export PDF
        </Button>
      </div>

      {/* Session header stats */}
      <div className="flex flex-wrap gap-3 items-center text-sm">
        <Badge variant="outline" className="text-sm font-normal">
          {sessionMeta.playerName}
        </Badge>
        <span className="text-muted-foreground">{sessionMeta.date}</span>
        <span className="text-muted-foreground">·</span>
        <span className="text-muted-foreground">
          {sessionMeta.duration}
        </span>
        <span className="text-muted-foreground">·</span>
        <span>
          {sessionMeta.totalHits} shots
        </span>
        <span className="text-muted-foreground">·</span>
        <span className="font-medium">
          {sessionMeta.sweetPercent}% sweet spot
        </span>
        <span className="text-muted-foreground">·</span>
        <span>
          Avg power: {sessionMeta.avgPower}%
        </span>
      </div>

      {/* Main two-panel layout */}
      <div className="grid gap-4 lg:grid-cols-5">
        {/* Left panel — Video + controls */}
        <div className="lg:col-span-3 space-y-4">
          <Card>
            <CardContent className="pt-6">
              {/* Video player placeholder */}
              <div className="aspect-video bg-black rounded-lg flex items-center justify-center relative overflow-hidden">
                <div className="text-white/50 text-center">
                  <Play className="h-12 w-12 mx-auto mb-2 opacity-50" />
                  <p className="text-sm">
                    Shot #{currentShot.shotNumber} — 4s clip
                  </p>
                  <p className="text-xs opacity-50">
                    Video playback requires session recordings
                  </p>
                </div>
                {/* Playback speed badge */}
                <div className="absolute top-3 right-3">
                  <Badge variant="secondary" className="text-xs">
                    {playbackSpeed}x
                  </Badge>
                </div>
              </div>

              {/* Video controls */}
              <div className="flex items-center justify-center gap-2 mt-4">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() =>
                    setCurrentShotIndex(Math.max(0, currentShotIndex - 1))
                  }
                  disabled={currentShotIndex === 0}
                >
                  <ChevronLeft className="h-4 w-4" />
                  Prev
                </Button>
                <Button
                  variant={isPlaying ? "secondary" : "default"}
                  size="sm"
                  onClick={() => setIsPlaying(!isPlaying)}
                >
                  {isPlaying ? (
                    <Pause className="h-4 w-4" />
                  ) : (
                    <Play className="h-4 w-4" />
                  )}
                </Button>
                <Button variant="outline" size="sm">
                  <RotateCcw className="h-4 w-4" />
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() =>
                    setCurrentShotIndex(
                      Math.min(mockShots.length - 1, currentShotIndex + 1)
                    )
                  }
                  disabled={currentShotIndex === mockShots.length - 1}
                >
                  Next
                  <ChevronRight className="h-4 w-4" />
                </Button>

                <div className="ml-4 border-l pl-4 flex gap-1">
                  {speeds.map((s) => (
                    <Button
                      key={s}
                      variant={playbackSpeed === s ? "default" : "outline"}
                      size="sm"
                      className="px-2 text-xs"
                      onClick={() => setPlaybackSpeed(s)}
                    >
                      {s}x
                    </Button>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Timeline scrubber */}
          <Card>
            <CardContent className="pt-4 pb-4">
              <div className="flex gap-0.5">
                {mockShots.map((shot, i) => (
                  <button
                    key={i}
                    onClick={() => setCurrentShotIndex(i)}
                    className={`flex-1 h-6 rounded-sm transition-colors ${
                      i === currentShotIndex
                        ? "bg-primary"
                        : shot.sweetSpot
                          ? "bg-green-500/40 hover:bg-green-500/60"
                          : shot.techniqueScore < 40
                            ? "bg-red-500/30 hover:bg-red-500/50"
                            : "bg-muted hover:bg-muted-foreground/20"
                    }`}
                    title={`Shot #${i + 1} — ${shot.zone} · ${shot.power}%`}
                  />
                ))}
              </div>
              <p className="text-xs text-muted-foreground mt-1 text-center">
                Click any bar to jump to that shot ·{" "}
                <span className="text-green-600">Green = sweet spot</span> ·{" "}
                <span className="text-red-500">Red = poor technique</span>
              </p>
            </CardContent>
          </Card>

          {/* Session-level coach note */}
          <CoachNotes
            sessionId={id || "demo"}
            shotNumber={null}
            existingNotes={mockCoachNotes}
          />
        </div>

        {/* Right panel — Shot data + shot list */}
        <div className="lg:col-span-2 space-y-4">
          <ShotDataPanel shot={currentShot} totalShots={mockShots.length} />

          {/* Per-shot coach note */}
          <CoachNotes
            sessionId={id || "demo"}
            shotNumber={currentShot.shotNumber}
            existingNotes={mockCoachNotes}
          />

          {/* Shot list with filters */}
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm">All Shots</CardTitle>
              <div className="flex gap-1 flex-wrap">
                {FILTERS.map((f) => (
                  <Button
                    key={f.value}
                    variant={filter === f.value ? "default" : "outline"}
                    size="sm"
                    className="text-xs h-7"
                    onClick={() => setFilter(f.value)}
                  >
                    {f.label}
                  </Button>
                ))}
              </div>
            </CardHeader>
            <CardContent>
              <ShotList
                shots={mockShots}
                activeIndex={currentShotIndex}
                onSelect={setCurrentShotIndex}
                filter={filter}
              />
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
