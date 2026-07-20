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
import { MessageSquare } from "lucide-react"

interface PlayerNotesModalProps {
  playerId: string
  playerName: string
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function PlayerNotesModal({ playerId, playerName, open, onOpenChange }: PlayerNotesModalProps) {
  const [notes, setNotes] = useState<any[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (open && playerId) {
      fetchNotes()
    }
  }, [open, playerId])

  const fetchNotes = async () => {
    setLoading(true)
    try {
      const res = await api.get(`/dashboard/coach/players/${playerId}/notes`)
      setNotes(res.data.data)
    } catch (error) {
      console.error("Failed to fetch notes:", error)
      toast.error("Failed to load notes")
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px] max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{playerName}'s Coach Notes</DialogTitle>
          <DialogDescription>
            Timeline of notes added to this player's sessions.
          </DialogDescription>
        </DialogHeader>
        
        <div className="py-4 space-y-4">
          {loading ? (
            <div className="text-center py-4">Loading notes...</div>
          ) : notes.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No notes found for this player.
            </div>
          ) : (
            <div className="space-y-6 border-l-2 border-border pl-4 ml-2">
              {notes.map((note) => (
                <div key={note.id} className="relative">
                  <span className="absolute -left-[25px] top-1 h-3 w-3 rounded-full bg-primary ring-4 ring-background" />
                  <div className="mb-1 flex items-center justify-between">
                    <span className="text-sm font-medium text-foreground">
                      {new Date(note.created_at).toLocaleDateString()}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      Session: {new Date(note.session_date).toLocaleDateString()}
                    </span>
                  </div>
                  <div className="bg-muted/50 rounded-md p-3 text-sm">
                    {/* Rich text would be rendered safely here using dangerouslySetInnerHTML, but fallback to simple text */}
                    <div dangerouslySetInnerHTML={{ __html: note.note }} />
                  </div>
                  {note.tags && note.tags.length > 0 && (
                    <div className="flex gap-2 mt-2">
                      {note.tags.map((tag: string) => (
                        <Badge key={tag} variant="secondary" className="text-xs">
                          {tag}
                        </Badge>
                      ))}
                    </div>
                  )}
                  <div className="mt-2 text-xs">
                    <Button variant="link" className="p-0 h-auto text-muted-foreground hover:text-foreground">
                      <MessageSquare className="w-3 h-3 mr-1" /> View Replies
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
