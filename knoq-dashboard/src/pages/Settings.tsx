import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "../components/ui/card"
import { Button } from "../components/ui/button"
import { Input } from "../components/ui/input"
import { Label } from "../components/ui/label"
import { Switch } from "../components/ui/switch"
import { Building2, CreditCard, Link2, AlertTriangle, KeyRound, Copy, RefreshCw, Upload } from "lucide-react"
import toast from "react-hot-toast"

export default function Settings() {
  const [joinCode, setJoinCode] = useState("BCA-2026-X7K9")
  const [logoFile, setLogoFile] = useState<File | null>(null)
  const [isUploadingLogo, setIsUploadingLogo] = useState(false)

  const handleRegenerate = () => {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    const newCode = "BCA-" + Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join("") + "-" + Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join("")
    setJoinCode(newCode)
    toast.success("Join code regenerated!")
  }

  const handleLogoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0]
      setLogoFile(file)
      setIsUploadingLogo(true)
      
      // Simulate an upload API call
      setTimeout(() => {
        setIsUploadingLogo(false)
        toast.success("Logo uploaded successfully!")
      }, 1500)
    }
  }

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Academy Settings</h1>
        <p className="text-muted-foreground">
          Manage your academy profile, billing, and integrations.
        </p>
      </div>

      {/* Organization Profile */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Building2 className="h-5 w-5 text-primary" />
            <CardTitle>Organization Profile</CardTitle>
          </div>
          <CardDescription>Update your academy's public information.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="academy-name">Academy Name</Label>
              <Input id="academy-name" defaultValue="Bangalore Cricket Academy" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="contact-email">Contact Email</Label>
              <Input id="contact-email" type="email" defaultValue="admin@bca.in" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="city">City</Label>
              <Input id="city" defaultValue="Bangalore" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="state">State</Label>
              <Input id="state" defaultValue="Karnataka" />
            </div>
          </div>

          {/* Logo Upload */}
          <div className="space-y-2">
            <Label>Academy Logo</Label>
            <div className="flex items-center gap-4">
              <div className="h-16 w-16 rounded-lg border-2 border-dashed border-muted-foreground/30 flex items-center justify-center text-muted-foreground overflow-hidden bg-muted">
                {logoFile ? (
                  <img src={URL.createObjectURL(logoFile)} alt="Logo Preview" className="h-full w-full object-cover" />
                ) : (
                  <Upload className="h-5 w-5" />
                )}
              </div>
              <div>
                <input
                  type="file"
                  id="logo-upload"
                  className="hidden"
                  accept="image/png, image/jpeg"
                  onChange={handleLogoUpload}
                />
                <Button variant="outline" size="sm" onClick={() => document.getElementById("logo-upload")?.click()}>
                  <Upload className="mr-2 h-3 w-3" />
                  {isUploadingLogo ? "Uploading..." : "Upload Logo"}
                </Button>
                <p className="text-xs text-muted-foreground mt-1">PNG or JPG, max 2MB. Recommended 200×200px.</p>
              </div>
            </div>
          </div>
        </CardContent>
        <CardFooter className="border-t px-6 py-4">
          <Button>Save Changes</Button>
        </CardFooter>
      </Card>

      {/* Join Code */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <KeyRound className="h-5 w-5 text-primary" />
            <CardTitle>Academy Join Code</CardTitle>
          </div>
          <CardDescription>Share this code with players and coaches to let them join your academy in the KnoQ app.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-3">
            <code className="flex-1 text-2xl font-bold tracking-widest text-center py-3 bg-muted rounded-lg border font-mono select-all">
              {joinCode}
            </code>
            <Button
              variant="outline"
              size="icon"
              onClick={() => {
                navigator.clipboard.writeText(joinCode)
                toast.success("Join code copied!")
              }}
              title="Copy to clipboard"
            >
              <Copy className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              onClick={handleRegenerate}
              title="Regenerate code"
            >
              <RefreshCw className="h-4 w-4" />
            </Button>
          </div>
          <p className="text-xs text-muted-foreground mt-2">
            Regenerating will invalidate the current code. Anyone using the old code will not be able to join.
          </p>
        </CardContent>
      </Card>

      {/* Billing & Subscription */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <CreditCard className="h-5 w-5 text-primary" />
            <CardTitle>Plan Details</CardTitle>
          </div>
          <CardDescription>Your current KnoQ subscription and limits.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between p-4 border rounded-lg bg-muted/50">
            <div>
              <p className="font-semibold text-lg">Pro Academy Plan</p>
              <p className="text-sm text-muted-foreground">₹15,000 / month</p>
            </div>
            <Button variant="outline">Manage Subscription</Button>
          </div>
          
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="font-medium">Registered Devices</span>
                <span>5 / 10 Bats</span>
              </div>
              <div className="w-full bg-secondary rounded-full h-2">
                <div className="bg-primary h-2 rounded-full" style={{ width: "50%" }} />
              </div>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="font-medium">Player Slots</span>
                <span>42 / 100</span>
              </div>
              <div className="w-full bg-secondary rounded-full h-2">
                <div className="bg-primary h-2 rounded-full" style={{ width: "42%" }} />
              </div>
            </div>
          </div>
          
          <div className="flex items-center justify-between text-sm p-3 bg-muted/30 rounded-lg">
            <div>
              <span className="text-muted-foreground">Expiry Date:</span>
              <span className="font-medium ml-1">Nov 1, 2026</span>
            </div>
            <div>
              <span className="text-muted-foreground">Coaches Allowed:</span>
              <span className="font-medium ml-1">3 / 5</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Integrations */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Link2 className="h-5 w-5 text-primary" />
            <CardTitle>Integrations</CardTitle>
          </div>
          <CardDescription>Connect KnoQ with other tools you use.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div>
              <p className="font-semibold">WhatsApp Business API</p>
              <p className="text-sm text-muted-foreground">Send automated notifications via WhatsApp.</p>
            </div>
            <Switch />
          </div>
          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div>
              <p className="font-semibold">CoachNow</p>
              <p className="text-sm text-muted-foreground">Sync video clips directly to CoachNow player profiles.</p>
            </div>
            <Switch defaultChecked />
          </div>
        </CardContent>
      </Card>

      {/* Reports & Notifications */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-primary" />
            <CardTitle>Reports & Notifications</CardTitle>
          </div>
          <CardDescription>Manage automated emails and alerts.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div>
              <p className="font-semibold">Weekly Academy Report</p>
              <p className="text-sm text-muted-foreground">Receive a weekly summary of academy activity and top performers via email every Sunday.</p>
            </div>
            <Switch defaultChecked onCheckedChange={(checked) => {
              // In a real implementation, this would call an API to toggle 'weekly_report_opt_out' in db
              toast.success(`Weekly reports ${checked ? 'enabled' : 'disabled'}.`)
            }} />
          </div>
        </CardContent>
      </Card>

      {/* Danger Zone */}
      <Card className="border-red-200">
        <CardHeader>
          <div className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-destructive" />
            <CardTitle className="text-destructive">Danger Zone</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground mb-4">
            Archive your academy. This will disable all player and coach access. Only Super Admins can reactivate an archived academy.
          </p>
          <Button variant="destructive">Archive Academy</Button>
        </CardContent>
      </Card>
    </div>
  )
}
