import { useState } from "react"
import { AnalyticsCharts } from "../components/analytics/AnalyticsCharts"
import { Leaderboards } from "../components/analytics/Leaderboards"
import { Button } from "../components/ui/button"
import { Download } from "lucide-react"

const TIME_RANGES = [
  { label: "7 Days", value: "7d" },
  { label: "30 Days", value: "30d" },
  { label: "90 Days", value: "90d" },
  { label: "All Time", value: "all" },
]

export default function Analytics() {
  const [timeRange, setTimeRange] = useState("30d")

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Analytics</h1>
          <p className="text-muted-foreground">
            Academy-wide performance trends, leaderboards, and shot distribution.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex bg-muted p-1 rounded-md">
            {TIME_RANGES.map((range) => (
              <button
                key={range.value}
                onClick={() => setTimeRange(range.value)}
                className={`px-3 py-1.5 text-sm font-medium rounded-sm transition-colors ${
                  timeRange === range.value
                    ? "bg-background text-foreground shadow-sm"
                    : "text-muted-foreground hover:text-foreground"
                }`}
              >
                {range.label}
              </button>
            ))}
          </div>
          <Button variant="outline" size="sm" className="hidden sm:flex">
            <Download className="mr-2 h-4 w-4" />
            Download Report
          </Button>
        </div>
      </div>

      <AnalyticsCharts />
      
      <div className="pt-4">
        <h2 className="text-xl font-semibold mb-4">Player Leaderboards</h2>
        <Leaderboards />
      </div>
    </div>
  )
}
