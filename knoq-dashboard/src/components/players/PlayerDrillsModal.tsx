import { useState, useEffect } from "react"
import { Button } from "../ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "../ui/dialog"
import api from "../../lib/axios"
import toast from "react-hot-toast"
import { Badge } from "../ui/badge"
import { Target, Activity } from "lucide-react"

interface PlayerDrillsModalProps {
  playerId: string
  playerName: string
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function PlayerDrillsModal({ playerId, playerName, open, onOpenChange }: PlayerDrillsModalProps) {
  const [drills, setDrills] = useState<any[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (open && playerId) {
      fetchDrills()
    }
  }, [open, playerId])

  const fetchDrills = async () => {
    setLoading(true)
    try {
      const res = await api.get(`/dashboard/drills/player/${playerId}`)
      setDrills(res.data.data)
    } catch (error) {
      console.error("Failed to fetch drills:", error)
      toast.error("Failed to load drills")
    } finally {
      setLoading(false)
    }
  }

  const handleCreateDrill = async () => {
    // Basic implementation for MVP, ideally this opens a form
    try {
      const payload = {
        player_id: playerId,
        title: "Target Practice: Sweet Spot",
        description: "Focus on hitting the sweet spot consistently.",
        target_zone: "sweet_spot",
        min_power: 40,
        target_shot_count: 50,
        deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() // 1 week
      }
      await api.post("/dashboard/drills", payload)
      toast.success("Drill assigned successfully!")
      fetchDrills()
    } catch (error) {
      console.error("Failed to assign drill:", error)
      toast.error("Failed to assign drill")
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px] max-h-[80vh] overflow-y-auto">
        <DialogHeader className="flex flex-row justify-between items-center pr-6">
          <div>
            <DialogTitle>{playerName}'s Drills</DialogTitle>
            <DialogDescription>
              Assign drills and track completion status.
            </DialogDescription>
          </div>
          <Button size="sm" onClick={handleCreateDrill}>
            Assign New Drill
          </Button>
        </DialogHeader>
        
        <div className="py-4 space-y-4">
          {loading ? (
            <div className="text-center py-4">Loading drills...</div>
          ) : drills.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No drills assigned to this player yet.
            </div>
          ) : (
            <>
              {/* Completion Rate Summary */}
              <div className="flex items-center gap-4 p-3 bg-muted/50 rounded-lg border mb-4">
                <div className="text-sm font-medium">
                  Completion Rate:
                </div>
                <div className="flex-1">
                  <div className="w-full bg-secondary rounded-full h-2.5">
                    <div
                      className="bg-primary h-2.5 rounded-full transition-all"
                      style={{
                        width: `${drills.length > 0 ? Math.round((drills.filter((d: any) => d.status === 'completed').length / drills.length) * 100) : 0}%`
                      }}
                    />
                  </div>
                </div>
                <div className="text-sm font-bold tabular-nums">
                  {drills.filter((d: any) => d.status === 'completed').length}/{drills.length}
                  <span className="text-muted-foreground font-normal ml-1">
                    ({drills.length > 0 ? Math.round((drills.filter((d: any) => d.status === 'completed').length / drills.length) * 100) : 0}%)
                  </span>
                </div>
              </div>
            <div className="grid gap-4">
              {drills.map((drill) => (
                <div key={drill.id} className="border rounded-lg p-4 bg-card">
                  <div className="flex justify-between items-start mb-2">
                    <h4 className="font-semibold">{drill.title}</h4>
                    <Badge variant={drill.status === 'completed' ? 'default' : drill.status === 'expired' ? 'destructive' : 'secondary'}>
                      {drill.status}
                    </Badge>
                  </div>
                  <p className="text-sm text-muted-foreground mb-4">{drill.description}</p>
                  
                  <div className="flex flex-wrap gap-4 text-xs">
                    <div className="flex items-center text-muted-foreground">
                      <Target className="w-4 h-4 mr-1" />
                      Zone: <span className="text-foreground ml-1 font-medium capitalize">{drill.target_zone ? drill.target_zone.replace('_', ' ') : 'Any'}</span>
                    </div>
                    <div className="flex items-center text-muted-foreground">
                      <Activity className="w-4 h-4 mr-1" />
                      Min Power: <span className="text-foreground ml-1 font-medium">{drill.min_power || 'Any'}</span>
                    </div>
                    <div className="flex items-center text-muted-foreground">
                      Target: <span className="text-foreground ml-1 font-medium">{drill.target_shot_count} shots</span>
                    </div>
                  </div>

                  <div className="mt-3 pt-3 border-t text-xs text-muted-foreground flex justify-between">
                    <span>Assigned: {new Date(drill.created_at).toLocaleDateString()}</span>
                    {drill.completed_at ? (
                      <span className="text-primary font-medium">Completed: {new Date(drill.completed_at).toLocaleDateString()}</span>
                    ) : (
                      <span>Due: {drill.deadline ? new Date(drill.deadline).toLocaleDateString() : 'No deadline'}</span>
                    )}
                  </div>
                </div>
              ))}
            </div>
            </>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
