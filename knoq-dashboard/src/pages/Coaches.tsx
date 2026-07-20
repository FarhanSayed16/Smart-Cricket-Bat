import { useState, useEffect } from "react"
import { CoachesTable } from "../components/coaches/CoachesTable"
import type { CoachData } from "../components/coaches/CoachesTable"
import { InviteCoachModal } from "../components/coaches/InviteCoachModal"
import api from "../lib/axios"
import toast from "react-hot-toast"

export default function Coaches() {
  const [coaches, setCoaches] = useState<CoachData[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchCoaches = async () => {
      try {
        const res = await api.get("/dashboard/coaches")
        const mappedCoaches: CoachData[] = res.data.data.map((c: any) => ({
          id: c.id,
          name: c.name,
          email: c.email,
          playersAssigned: c.assigned_players || 0,
          sessionsReviewed: Math.floor(Math.random() * 50), // Mock until backend supports it
          notesThisMonth: Math.floor(Math.random() * 20), // Mock until backend supports it
          joinedDate: c.last_active ? new Date(c.last_active).toLocaleDateString() : "Unknown",
          status: c.status as "active" | "inactive" | "invited",
        }))
        setCoaches(mappedCoaches)
      } catch (error) {
        console.error("Failed to fetch coaches", error)
        toast.error("Failed to load coaches")
      } finally {
        setLoading(false)
      }
    }
    fetchCoaches()
  }, [])

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Coaches</h1>
          <p className="text-muted-foreground">
            Manage your coaching staff, assign players, and track coaching
            activity.
          </p>
        </div>
        <InviteCoachModal />
      </div>

      {loading ? (
        <div className="flex justify-center py-12">Loading coaches...</div>
      ) : (
        <CoachesTable data={coaches} />
      )}
    </div>
  )
}
