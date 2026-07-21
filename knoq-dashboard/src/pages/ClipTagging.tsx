import { useState, useEffect, useCallback } from "react"
import { useParams, Link, useNavigate } from "react-router-dom"
import { Button } from "../components/ui/button"
import { Card, CardContent } from "../components/ui/card"
import { Textarea } from "../components/ui/textarea"
import { Label } from "../components/ui/label"
import { ArrowLeft, Play, FastForward, SkipForward, ActivitySquare } from "lucide-react"
import toast from "react-hot-toast"

const DELIVERY_TYPES = ["Yorker", "Full", "Good Length", "Short", "Bouncer"]
const BALL_LINES = ["Wide Off", "Off Stump", "Middle", "Leg", "Wide Leg"]
const SHOT_TYPES = ["Drive", "Pull", "Hook", "Defend", "Sweep", "Cut", "Flick", "Other"]
const SHOT_SELECTIONS = ["Perfect", "Good", "Risky", "Wrong"]

export default function ClipTagging() {
  const { clipId } = useParams()
  const navigate = useNavigate()
  
  const [deliveryType, setDeliveryType] = useState<string>("")
  const [ballLine, setBallLine] = useState<string>("")
  const [shotType, setShotType] = useState<string>("")
  const [shotSelection, setShotSelection] = useState<string>("")
  const [techniqueRating, setTechniqueRating] = useState<number>(0)
  const [notes, setNotes] = useState("")
  const [showPose, setShowPose] = useState(false)

  const handleSave = useCallback(() => {
    if (!deliveryType || !ballLine || !shotType || !shotSelection || !techniqueRating) {
      toast.error("Please complete all tagging fields")
      return
    }
    
    toast.success("Clip tagged successfully!")
    // Simulate moving to next clip
    setTimeout(() => {
      navigate("/ai-lab")
    }, 500)
  }, [deliveryType, ballLine, shotType, shotSelection, techniqueRating, navigate])

  // Keyboard shortcuts: Q-T for delivery, A-G for ball line, 1-5 for rating, Enter for save
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      // Don't trigger shortcuts when typing in a textarea or input
      const tag = (e.target as HTMLElement).tagName
      if (tag === "TEXTAREA" || tag === "INPUT") return

      const key = e.key.toLowerCase()

      // Delivery: Q=Yorker W=Full E=Good Length R=Short T=Bouncer
      const deliveryKeys: Record<string, string> = { q: "Yorker", w: "Full", e: "Good Length", r: "Short", t: "Bouncer" }
      if (deliveryKeys[key]) { setDeliveryType(deliveryKeys[key]); return }

      // Ball Line: A=Wide Off S=Off Stump D=Middle F=Leg G=Wide Leg
      const lineKeys: Record<string, string> = { a: "Wide Off", s: "Off Stump", d: "Middle", f: "Leg", g: "Wide Leg" }
      if (lineKeys[key]) { setBallLine(lineKeys[key]); return }

      // Technique Rating: 1-5
      if (["1", "2", "3", "4", "5"].includes(key)) { setTechniqueRating(Number(key)); return }

      // Enter → Save & Next
      if (key === "enter") { handleSave(); return }
    }

    window.addEventListener("keydown", handler)
    return () => window.removeEventListener("keydown", handler)
  }, [handleSave])

  return (
    <div className="space-y-4 h-[calc(100vh-6rem)] flex flex-col">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Link to="/ai-lab">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4 mr-1" />
              Back to AI Lab
            </Button>
          </Link>
          <h1 className="text-xl font-bold tracking-tight">Tagging Clip: {clipId}</h1>
          <span className="text-sm text-muted-foreground">Player: Rahul Deshmukh | Oct 24, 2023</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-sm text-muted-foreground mr-4">Progress: 47 / 100 tagged today</span>
          <Button variant="outline" onClick={() => navigate("/ai-lab")}>Skip</Button>
          <Button onClick={handleSave} className="bg-green-600 hover:bg-green-700">
            Save & Next <SkipForward className="ml-2 h-4 w-4" />
          </Button>
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-4 flex-1 min-h-0">
        {/* Left: Video Player */}
        <div className="flex flex-col gap-2 h-full">
          <Card className="flex-1 bg-black overflow-hidden relative rounded-lg flex items-center justify-center">
            <div className="text-white/50 text-center">
              <Play className="h-16 w-16 mx-auto mb-4 opacity-50" />
              <p>4-second extracted clip</p>
            </div>
            
            {showPose && (
              <div className="absolute inset-0 pointer-events-none flex items-center justify-center">
                <ActivitySquare className="h-32 w-32 text-primary opacity-50" />
                <span className="absolute text-primary text-xs font-mono top-4 left-4">POSE ESTIMATION ACTIVE</span>
              </div>
            )}
            
            {/* Video Controls Overlay */}
            <div className="absolute bottom-4 left-0 right-0 flex justify-center gap-2 px-4">
              <Button variant="secondary" size="sm" className="bg-black/50 text-white hover:bg-black/70 backdrop-blur-sm">
                <FastForward className="h-4 w-4 mr-1" /> 0.25x
              </Button>
              <Button variant="secondary" size="sm" className="bg-black/50 text-white hover:bg-black/70 backdrop-blur-sm" onClick={() => setShowPose(!showPose)}>
                {showPose ? "Hide Pose" : "Show Pose"}
              </Button>
            </div>
          </Card>
          
          <div className="bg-muted p-3 rounded-lg text-xs font-mono text-muted-foreground text-center">
            Keyboard Shortcuts: [Q-T] Delivery | [A-G] Line | [1-5] Rating | [Enter] Save
          </div>
        </div>

        {/* Right: Tagging Form */}
        <Card className="overflow-y-auto">
          <CardContent className="p-6 space-y-8">
            
            {/* Delivery Type */}
            <div className="space-y-3">
              <Label className="text-base font-semibold">1. Delivery Length</Label>
              <div className="flex flex-wrap gap-2">
                {DELIVERY_TYPES.map(type => (
                  <Button 
                    key={type} 
                    variant={deliveryType === type ? "default" : "outline"}
                    onClick={() => setDeliveryType(type)}
                    className="flex-1 min-w-[100px]"
                  >
                    {type}
                  </Button>
                ))}
              </div>
            </div>

            {/* Ball Line */}
            <div className="space-y-3">
              <Label className="text-base font-semibold">2. Ball Line</Label>
              <div className="flex flex-wrap gap-2">
                {BALL_LINES.map(line => (
                  <Button 
                    key={line} 
                    variant={ballLine === line ? "default" : "outline"}
                    onClick={() => setBallLine(line)}
                    className="flex-1 min-w-[100px]"
                  >
                    {line}
                  </Button>
                ))}
              </div>
            </div>

            {/* Shot Played */}
            <div className="space-y-3">
              <Label className="text-base font-semibold">3. Shot Played</Label>
              <div className="grid grid-cols-4 gap-2">
                {SHOT_TYPES.map(shot => (
                  <Button 
                    key={shot} 
                    variant={shotType === shot ? "default" : "outline"}
                    onClick={() => setShotType(shot)}
                  >
                    {shot}
                  </Button>
                ))}
              </div>
            </div>

            {/* Shot Selection */}
            <div className="space-y-3">
              <Label className="text-base font-semibold">4. Shot Selection (Decision)</Label>
              <div className="flex flex-wrap gap-2">
                {SHOT_SELECTIONS.map(sel => (
                  <Button 
                    key={sel} 
                    variant={shotSelection === sel ? "default" : "outline"}
                    onClick={() => setShotSelection(sel)}
                    className="flex-1"
                  >
                    {sel}
                  </Button>
                ))}
              </div>
            </div>

            {/* Technique Rating */}
            <div className="space-y-3">
              <Label className="text-base font-semibold flex justify-between">
                <span>5. Technique Quality</span>
                <span className="text-muted-foreground font-normal">{techniqueRating > 0 ? `${techniqueRating} Stars` : ""}</span>
              </Label>
              <div className="flex gap-2">
                {[1, 2, 3, 4, 5].map(star => (
                  <Button 
                    key={star} 
                    variant={techniqueRating >= star ? "default" : "outline"}
                    className={`flex-1 text-lg ${techniqueRating >= star ? "bg-yellow-500 hover:bg-yellow-600 text-white border-yellow-500" : ""}`}
                    onClick={() => setTechniqueRating(star)}
                  >
                    ★
                  </Button>
                ))}
              </div>
              <p className="text-xs text-muted-foreground">Only clips with ≥3 stars will be used to train correct technique models.</p>
            </div>

            {/* Notes */}
            <div className="space-y-3">
              <Label className="text-base font-semibold">6. Coach Notes (Optional)</Label>
              <Textarea 
                placeholder="Any specific observations about this execution..." 
                value={notes}
                onChange={e => setNotes(e.target.value)}
                className="resize-none"
                rows={3}
              />
            </div>

          </CardContent>
        </Card>
      </div>
    </div>
  )
}
