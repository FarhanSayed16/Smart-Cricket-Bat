import { cn } from "../../lib/utils"
import { Badge } from "../ui/badge"
import type { ShotData } from "./ShotDataPanel"

interface ShotListProps {
  shots: ShotData[]
  activeIndex: number
  onSelect: (index: number) => void
  filter: string
}

export function ShotList({ shots, activeIndex, onSelect, filter }: ShotListProps) {
  const filteredShots = shots.filter((shot) => {
    switch (filter) {
      case "sweet":
        return shot.sweetSpot
      case "poor":
        return shot.techniqueScore < 50
      case "edge":
        return shot.zone === "edge" || shot.zone === "toe"
      default:
        return true
    }
  })

  return (
    <div className="space-y-1 max-h-[400px] overflow-y-auto pr-1">
      {filteredShots.length === 0 ? (
        <p className="text-sm text-muted-foreground text-center py-4">
          No shots match this filter.
        </p>
      ) : (
        filteredShots.map((shot) => (
          <button
            key={shot.shotNumber}
            onClick={() => onSelect(shot.shotNumber - 1)}
            className={cn(
              "w-full text-left px-3 py-2 rounded-md text-sm transition-colors flex items-center justify-between",
              activeIndex === shot.shotNumber - 1
                ? "bg-primary text-primary-foreground"
                : "hover:bg-muted"
            )}
          >
            <span className="font-medium">Shot #{shot.shotNumber}</span>
            <div className="flex items-center gap-2">
              {shot.sweetSpot && (
                <Badge
                  variant={
                    activeIndex === shot.shotNumber - 1 ? "secondary" : "default"
                  }
                  className="text-[10px] px-1.5 py-0"
                >
                  Sweet
                </Badge>
              )}
              <span
                className={cn(
                  "text-xs",
                  activeIndex === shot.shotNumber - 1
                    ? "text-primary-foreground/80"
                    : "text-muted-foreground"
                )}
              >
                {shot.power}% · {shot.techniqueScore}/100
              </span>
            </div>
          </button>
        ))
      )}
    </div>
  )
}
