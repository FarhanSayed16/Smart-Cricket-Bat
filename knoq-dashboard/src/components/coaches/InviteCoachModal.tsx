import { useState } from "react"
import { Button } from "../ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../ui/dialog"
import { Input } from "../ui/input"
import { UserSquare2 } from "lucide-react"
import toast from "react-hot-toast"

export function InviteCoachModal() {
  const [open, setOpen] = useState(false)
  const [email, setEmail] = useState("")
  const [name, setName] = useState("")
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleInvite = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)

    // TODO: Replace with actual API call: POST /academy/invite { email, name, role: 'coach' }
    setTimeout(() => {
      setIsSubmitting(false)
      setOpen(false)
      setEmail("")
      setName("")
      toast.success(`Coach invite sent to ${email}!`)
    }, 1000)
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>
          <UserSquare2 className="mr-2 h-4 w-4" />
          Invite Coach
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Invite Coach</DialogTitle>
          <DialogDescription>
            Send an email invitation to a coach. They will receive a secure link
            to join your academy with coach-level access.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleInvite} className="grid gap-4 py-4">
          <div className="flex flex-col gap-2">
            <label htmlFor="coach-name" className="text-sm font-medium">
              Full Name
            </label>
            <Input
              id="coach-name"
              type="text"
              placeholder="Coach name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>
          <div className="flex flex-col gap-2">
            <label htmlFor="coach-email" className="text-sm font-medium">
              Email address
            </label>
            <Input
              id="coach-email"
              type="email"
              placeholder="coach@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => setOpen(false)}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isSubmitting || !email || !name}>
              {isSubmitting ? "Sending..." : "Send Invite"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
