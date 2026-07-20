import { useState } from "react"
import { Button } from "../ui/button"
import { Input } from "../ui/input"
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card"
import toast from "react-hot-toast"

interface CoachNote {
  id: string
  coachName: string
  text: string
  createdAt: string
  shotNumber: number | null // null = session-level note
}

interface CoachNotesProps {
  sessionId: string
  shotNumber: number | null
  existingNotes: CoachNote[]
}

export function CoachNotes({ shotNumber, existingNotes }: CoachNotesProps) {
  const [note, setNote] = useState("")
  const [isSubmitting, setIsSubmitting] = useState(false)

  const filteredNotes = existingNotes.filter(
    (n) => n.shotNumber === shotNumber || n.shotNumber === null
  )

  const handleSave = async () => {
    if (!note.trim()) return
    setIsSubmitting(true)

    // TODO: Replace with actual API call: POST /coach-notes
    setTimeout(() => {
      setIsSubmitting(false)
      setNote("")
      toast.success("Note saved!")
    }, 500)
  }

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm">
          {shotNumber ? `Coach Notes — Shot #${shotNumber}` : "Session Notes"}
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="flex gap-2">
          <Input
            placeholder="Add a note for this player..."
            value={note}
            onChange={(e) => setNote(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault()
                handleSave()
              }
            }}
          />
          <Button
            size="sm"
            onClick={handleSave}
            disabled={isSubmitting || !note.trim()}
          >
            {isSubmitting ? "..." : "Save"}
          </Button>
        </div>

        {filteredNotes.length > 0 && (
          <div className="space-y-2 pt-2 border-t">
            {filteredNotes.slice(0, 3).map((n) => (
              <div key={n.id} className="text-sm">
                <p className="text-foreground">{n.text}</p>
                <p className="text-xs text-muted-foreground mt-0.5">
                  — {n.coachName}, {n.createdAt}
                </p>
              </div>
            ))}
            {filteredNotes.length > 3 && (
              <button className="text-xs text-primary hover:underline">
                View all {filteredNotes.length} notes
              </button>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  )
}

export type { CoachNote }
