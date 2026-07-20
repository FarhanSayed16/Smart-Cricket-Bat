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
import { Smartphone } from "lucide-react"
import toast from "react-hot-toast"

export function RegisterBatModal() {
  const [open, setOpen] = useState(false)
  const [macAddress, setMacAddress] = useState("")
  const [name, setName] = useState("")
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)

    // TODO: Replace with actual API call: POST /devices/register { macAddress, name }
    setTimeout(() => {
      setIsSubmitting(false)
      setOpen(false)
      setMacAddress("")
      setName("")
      toast.success(`Device "${name}" registered successfully!`)
    }, 1000)
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>
          <Smartphone className="mr-2 h-4 w-4" />
          Register New Bat
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Register New Bat</DialogTitle>
          <DialogDescription>
            Add a new KnoQ smart bat to your academy. You'll find the MAC
            address printed on the inside of the bat handle grip.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleRegister} className="grid gap-4 py-4">
          <div className="flex flex-col gap-2">
            <label htmlFor="bat-name" className="text-sm font-medium">
              Device Name
            </label>
            <Input
              id="bat-name"
              type="text"
              placeholder='e.g. "Bat #3 — Net 2"'
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>
          <div className="flex flex-col gap-2">
            <label htmlFor="bat-mac" className="text-sm font-medium">
              MAC Address
            </label>
            <Input
              id="bat-mac"
              type="text"
              placeholder="AA:BB:CC:DD:EE:FF"
              value={macAddress}
              onChange={(e) => setMacAddress(e.target.value.toUpperCase())}
              pattern="^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$"
              title="Enter a valid MAC address (e.g., AA:BB:CC:DD:EE:FF)"
              required
            />
            <p className="text-xs text-muted-foreground">
              Format: AA:BB:CC:DD:EE:FF
            </p>
          </div>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => setOpen(false)}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={isSubmitting || !macAddress || !name}
            >
              {isSubmitting ? "Registering..." : "Register Bat"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
