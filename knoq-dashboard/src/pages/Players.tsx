import { useState, useEffect } from "react"
import { PlayersTable } from "../components/players/PlayersTable"
import type { PlayerData } from "../components/players/PlayersTable"
import { InvitePlayerModal } from "../components/players/InvitePlayerModal"
import api from "../lib/axios"
import toast from "react-hot-toast"

export default function Players() {
  const [players, setPlayers] = useState<PlayerData[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchPlayers = async () => {
      try {
        const res = await api.get("/dashboard/players")
        const mappedPlayers: PlayerData[] = res.data.data.map((p: any) => ({
          id: p.id,
          name: p.name,
          email: p.email,
          role: "Batter", // Defaulting role as backend doesn't have playing_role yet
          status: p.status,
          lastActive: p.last_session_date ? new Date(p.last_session_date).toLocaleDateString() : "Never",
        }))
        setPlayers(mappedPlayers)
      } catch (error) {
        console.error("Failed to fetch players", error)
        toast.error("Failed to load players")
      } finally {
        setLoading(false)
      }
    }
    fetchPlayers()
  }, [])

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500 ease-in-out">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Players</h1>
          <p className="text-muted-foreground">Manage your academy's roster, invite new players, and view their individual analytics.</p>
        </div>
        <InvitePlayerModal />
      </div>

      {loading ? (
        <div className="flex justify-center py-12">Loading players...</div>
      ) : (
        <PlayersTable data={players} />
      )}
    </div>
  )
}
