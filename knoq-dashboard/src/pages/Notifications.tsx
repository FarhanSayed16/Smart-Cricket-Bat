import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../components/ui/card"
import { Button } from "../components/ui/button"
import { Textarea } from "../components/ui/textarea"
import { Label } from "../components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select"
import { Switch } from "../components/ui/switch"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table"
import { Send, Smartphone, Clock, Settings2 } from "lucide-react"
import toast from "react-hot-toast"

const SENT_HISTORY = [
  { id: 1, message: "Practice moved to indoor nets due to rain.", target: "Entire Academy", sent: "Today 9:00 AM", delivered: 45, opened: 41 },
  { id: 2, message: "New session feedback available from Coach Dravid.", target: "Specific Player", sent: "Yesterday 4:30 PM", delivered: 1, opened: 1 },
  { id: 3, message: "Reminder: Firmware update required for all bats.", target: "All Coaches", sent: "Oct 24, 2023", delivered: 5, opened: 5 },
]

export default function Notifications() {
  const [message, setMessage] = useState("")
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleSend = () => {
    if (!message) return
    setIsSubmitting(true)
    setTimeout(() => {
      setIsSubmitting(false)
      setMessage("")
      toast.success("Notification queued for delivery!")
    }, 800)
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Notification Centre</h1>
        <p className="text-muted-foreground">
          Send push notifications directly to players and coaches.
        </p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Compose Form */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2 mb-1">
              <div className="p-1.5 bg-primary/10 text-primary rounded-md">
                <Send className="h-5 w-5" />
              </div>
              <CardTitle>Compose Notification</CardTitle>
            </div>
            <CardDescription>Target specific groups or individuals.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Target Audience</Label>
              <Select defaultValue="all">
                <SelectTrigger>
                  <SelectValue placeholder="Select target" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Entire Academy (All Users)</SelectItem>
                  <SelectItem value="all_players">All Players</SelectItem>
                  <SelectItem value="all_coaches">All Coaches</SelectItem>
                  <SelectItem value="specific_player">Specific Player...</SelectItem>
                  <SelectItem value="specific_coach">Specific Coach...</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>Notification Type</Label>
              <Select defaultValue="announcement">
                <SelectTrigger>
                  <SelectValue placeholder="Select type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="announcement">General Announcement</SelectItem>
                  <SelectItem value="reminder">Practice Reminder</SelectItem>
                  <SelectItem value="feedback">Session Feedback</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <div className="flex justify-between">
                <Label>Message</Label>
                <span className="text-xs text-muted-foreground">{message.length}/200</span>
              </div>
              <Textarea 
                placeholder="Enter notification message..." 
                value={message}
                onChange={(e) => setMessage(e.target.value.substring(0, 200))}
                rows={3}
                className="resize-none"
              />
            </div>

            <div className="space-y-2">
              <Label>Schedule</Label>
              <div className="flex gap-2">
                <Select defaultValue="now">
                  <SelectTrigger className="flex-1">
                    <SelectValue placeholder="Send time" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="now">Send Now</SelectItem>
                    <SelectItem value="schedule">Schedule for Later...</SelectItem>
                  </SelectContent>
                </Select>
                <Button onClick={handleSend} disabled={isSubmitting || !message} className="flex-1">
                  <Send className="mr-2 h-4 w-4" />
                  {isSubmitting ? "Sending..." : "Send Notification"}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Preview & Automation */}
        <div className="space-y-6">
          <Card>
            <CardHeader className="pb-4">
              <CardTitle className="text-sm">Mobile Preview</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="mx-auto w-[280px] h-[160px] border-[6px] border-black rounded-3xl bg-muted/30 relative overflow-hidden flex flex-col p-4 shadow-xl">
                <div className="absolute top-2 left-1/2 -translate-x-1/2 w-20 h-4 bg-black rounded-b-xl" />
                <div className="mt-8 bg-background/80 backdrop-blur-md rounded-xl p-3 shadow-sm border text-sm animate-in slide-in-from-top-4">
                  <div className="flex items-center gap-2 mb-1">
                    <Smartphone className="h-4 w-4 text-primary" />
                    <span className="font-semibold text-xs">KnoQ App</span>
                    <span className="text-[10px] text-muted-foreground ml-auto">now</span>
                  </div>
                  <p className="font-medium text-xs">New Notification</p>
                  <p className="text-[11px] text-muted-foreground leading-tight mt-0.5 line-clamp-2">
                    {message || "Your message will appear here..."}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-4">
              <div className="flex items-center gap-2">
                <Settings2 className="h-4 w-4 text-muted-foreground" />
                <CardTitle className="text-sm">Automated Rules</CardTitle>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>New Coach Note</Label>
                  <p className="text-xs text-muted-foreground">Notify player when a coach adds feedback</p>
                </div>
                <Switch defaultChecked />
              </div>
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Weekly Summary</Label>
                  <p className="text-xs text-muted-foreground">Send automated report to all players on Sundays</p>
                </div>
                <Switch defaultChecked />
              </div>
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Inactive Player Alert</Label>
                  <p className="text-xs text-muted-foreground">Notify admin when a player hasn't practiced in 7 days</p>
                </div>
                <Switch defaultChecked />
              </div>
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Session Complete</Label>
                  <p className="text-xs text-muted-foreground">Notify coach when assigned player completes a session</p>
                </div>
                <Switch />
              </div>
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Low Battery Alert</Label>
                  <p className="text-xs text-muted-foreground">Notify coaches if a bat drops below 15%</p>
                </div>
                <Switch />
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* History Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Clock className="h-4 w-4 text-muted-foreground" />
            <CardTitle>Sent History</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Message</TableHead>
                <TableHead>Target</TableHead>
                <TableHead>Sent Time</TableHead>
                <TableHead className="text-right">Delivered / Opened</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {SENT_HISTORY.map((item) => (
                <TableRow key={item.id}>
                  <TableCell className="font-medium max-w-[300px] truncate" title={item.message}>
                    {item.message}
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">{item.target}</TableCell>
                  <TableCell className="text-sm text-muted-foreground">{item.sent}</TableCell>
                  <TableCell className="text-right">
                    <span className="font-medium text-green-600">{item.opened}</span>
                    <span className="text-muted-foreground"> / {item.delivered}</span>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
