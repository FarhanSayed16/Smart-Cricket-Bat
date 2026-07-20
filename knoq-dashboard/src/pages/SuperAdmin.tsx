import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../components/ui/card"
import { Button } from "../components/ui/button"
import { Input } from "../components/ui/input"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table"
import { Badge } from "../components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../components/ui/tabs"
import { Server, Users, Activity, ShieldAlert, Plus, Upload, Search, Wifi, HardDrive, AlertCircle } from "lucide-react"
import toast from "react-hot-toast"

const ACADEMIES = [
  { id: "A01", name: "Bangalore Cricket Academy", city: "Bangalore", plan: "Pro", players: 142, coaches: 3, devices: 5, sessions: 1240, created: "Jan 2026", status: "Active" },
  { id: "A02", name: "Mumbai Indians Youth", city: "Mumbai", plan: "Enterprise", players: 350, coaches: 8, devices: 15, sessions: 4500, created: "Nov 2025", status: "Active" },
  { id: "A03", name: "Delhi Capitals Camp", city: "Delhi", plan: "Pro", players: 85, coaches: 2, devices: 3, sessions: 420, created: "Mar 2026", status: "Payment Overdue" },
  { id: "A04", name: "Chennai Super Academy", city: "Chennai", plan: "Basic", players: 40, coaches: 1, devices: 1, sessions: 150, created: "Apr 2026", status: "Active" },
]

const FIRMWARE_HISTORY = [
  { version: "2.4.1", date: "Apr 25, 2026", target: "All devices", success: 19, fail: 1, notes: "Fixed BLE reconnection on Android 15" },
  { version: "2.4.0", date: "Mar 14, 2026", target: "All devices", success: 18, fail: 0, notes: "Added OTA self-check, improved power sensing" },
  { version: "2.3.0", date: "Feb 2, 2026", target: "BCA only", success: 4, fail: 0, notes: "Beta of zone detection calibration" },
]

const RECENT_ERRORS = [
  { time: "2 min ago", endpoint: "POST /sessions/end", message: "Timeout: Firebase write exceeded 10s", academy: "Mumbai Indians Youth" },
  { time: "15 min ago", endpoint: "GET /users/me", message: "Auth token expired, refresh failed", academy: "Delhi Capitals Camp" },
  { time: "1 hr ago", endpoint: "POST /shots/batch", message: "Payload exceeded 1MB limit (batch of 450 shots)", academy: "Mumbai Indians Youth" },
]

export default function SuperAdmin() {
  const [searchEmail, setSearchEmail] = useState("")

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-purple-700 dark:text-purple-400">Super Admin</h1>
          <p className="text-muted-foreground">
            Platform-wide management and system health monitoring.
          </p>
        </div>
        <Button className="bg-purple-600 hover:bg-purple-700">
          <Plus className="mr-2 h-4 w-4" />
          Onboard New Academy
        </Button>
      </div>

      {/* Platform Overview Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card className="border-purple-200 dark:border-purple-900">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <Server className="h-4 w-4 text-purple-500" />
              API Health
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-2">
              <div className="h-3 w-3 rounded-full bg-green-500 animate-pulse" />
              <span className="text-xl font-bold">All Green</span>
            </div>
            <p className="text-xs text-muted-foreground mt-1">Latency: 42ms · Uptime: 99.97%</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <Users className="h-4 w-4 text-blue-500" />
              Platform Totals
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">617 <span className="text-sm font-normal text-muted-foreground">players</span></div>
            <p className="text-xs text-muted-foreground mt-1">14 coaches · 24 devices · 6,310 sessions</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <Activity className="h-4 w-4 text-orange-500" />
              Live Right Now
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">14 <span className="text-sm font-normal text-muted-foreground">active sessions</span></div>
            <p className="text-xs text-muted-foreground mt-1">Across 4 academies</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <HardDrive className="h-4 w-4 text-green-500" />
              Storage Used
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">24.7 <span className="text-sm font-normal text-muted-foreground">GB</span></div>
            <p className="text-xs text-muted-foreground mt-1">Firebase Storage total</p>
          </CardContent>
        </Card>
      </div>

      {/* Tabbed sections */}
      <Tabs defaultValue="academies" className="w-full">
        <TabsList className="grid w-full grid-cols-4 max-w-[560px]">
          <TabsTrigger value="academies">Academies</TabsTrigger>
          <TabsTrigger value="firmware">Firmware</TabsTrigger>
          <TabsTrigger value="health">System Health</TabsTrigger>
          <TabsTrigger value="users">Users</TabsTrigger>
        </TabsList>

        {/* Academy Management Tab */}
        <TabsContent value="academies" className="mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Registered Academies</CardTitle>
              <CardDescription>Manage B2B clients, plans, and platform usage.</CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Academy</TableHead>
                    <TableHead>City</TableHead>
                    <TableHead>Plan</TableHead>
                    <TableHead className="text-right">Players</TableHead>
                    <TableHead className="text-right">Coaches</TableHead>
                    <TableHead className="text-right">Sessions</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {ACADEMIES.map((academy) => (
                    <TableRow key={academy.id}>
                      <TableCell className="font-medium">
                        {academy.name}
                        <div className="text-xs text-muted-foreground font-mono mt-0.5">{academy.id} · {academy.created}</div>
                      </TableCell>
                      <TableCell className="text-sm">{academy.city}</TableCell>
                      <TableCell>
                        <Badge variant="outline" className={
                          academy.plan === "Enterprise" ? "border-purple-500 text-purple-600" : ""
                        }>
                          {academy.plan}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-right">{academy.players}</TableCell>
                      <TableCell className="text-right">{academy.coaches}</TableCell>
                      <TableCell className="text-right">{academy.sessions.toLocaleString()}</TableCell>
                      <TableCell>
                        <Badge variant={academy.status === "Active" ? "default" : "destructive"}>
                          {academy.status}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-right">
                        <Button variant="ghost" size="sm">Manage</Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Firmware Management Tab */}
        <TabsContent value="firmware" className="mt-6 space-y-6">
          <div className="grid gap-4 sm:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Current Deployed Version</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-3">
                  <Wifi className="h-8 w-8 text-green-500" />
                  <div>
                    <p className="text-3xl font-bold font-mono">v2.4.1</p>
                    <p className="text-sm text-muted-foreground">Released Apr 25, 2026</p>
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Upload New Firmware</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center gap-2">
                  <Input type="file" accept=".bin" className="flex-1" />
                </div>
                <Input placeholder="Release notes (e.g. Fixed BLE timeout)" />
                <Button className="w-full">
                  <Upload className="mr-2 h-4 w-4" />
                  Push OTA Update
                </Button>
              </CardContent>
            </Card>
          </div>
          <Card>
            <CardHeader>
              <CardTitle>Update History</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Version</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead>Pushed To</TableHead>
                    <TableHead className="text-right">Success</TableHead>
                    <TableHead className="text-right">Failed</TableHead>
                    <TableHead>Release Notes</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {FIRMWARE_HISTORY.map((fw) => (
                    <TableRow key={fw.version}>
                      <TableCell className="font-mono font-medium">v{fw.version}</TableCell>
                      <TableCell className="text-sm text-muted-foreground">{fw.date}</TableCell>
                      <TableCell className="text-sm">{fw.target}</TableCell>
                      <TableCell className="text-right font-medium text-green-600">{fw.success}</TableCell>
                      <TableCell className="text-right font-medium text-red-500">{fw.fail}</TableCell>
                      <TableCell className="text-sm max-w-[200px] truncate" title={fw.notes}>{fw.notes}</TableCell>
                      <TableCell className="text-right">
                        <Button variant="ghost" size="sm" onClick={() => toast.success(`Rolled back to v${fw.version}`)}>Rollback</Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* System Health Tab */}
        <TabsContent value="health" className="mt-6 space-y-6">
          <div className="grid gap-4 sm:grid-cols-3">
            <Card>
              <CardContent className="pt-6 text-center">
                <p className="text-sm text-muted-foreground">Error Rate (24h)</p>
                <p className="text-3xl font-bold text-green-600">0.02%</p>
                <p className="text-xs text-muted-foreground mt-1">3 errors / 14,200 requests</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6 text-center">
                <p className="text-sm text-muted-foreground">Avg Response Time</p>
                <p className="text-3xl font-bold">142<span className="text-base font-normal">ms</span></p>
                <p className="text-xs text-muted-foreground mt-1">P95: 380ms · P99: 720ms</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6 text-center">
                <p className="text-sm text-muted-foreground">FCM Delivery Rate</p>
                <p className="text-3xl font-bold text-green-600">98.4%</p>
                <p className="text-xs text-muted-foreground mt-1">1,204 / 1,224 delivered</p>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <AlertCircle className="h-4 w-4 text-red-500" />
                <CardTitle>Recent Error Log</CardTitle>
              </div>
              <CardDescription>Last 50 errors from the API — showing most recent 3.</CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Time</TableHead>
                    <TableHead>Endpoint</TableHead>
                    <TableHead>Error</TableHead>
                    <TableHead>Academy</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {RECENT_ERRORS.map((err, i) => (
                    <TableRow key={i}>
                      <TableCell className="text-sm text-muted-foreground whitespace-nowrap">{err.time}</TableCell>
                      <TableCell className="font-mono text-xs">{err.endpoint}</TableCell>
                      <TableCell className="text-sm text-red-500 max-w-[250px] truncate" title={err.message}>{err.message}</TableCell>
                      <TableCell className="text-sm">{err.academy}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* User Management Tab */}
        <TabsContent value="users" className="mt-6 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Global User Search</CardTitle>
              <CardDescription>Search any user by email across all academies.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex gap-2">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="Search by email address..."
                    value={searchEmail}
                    onChange={(e) => setSearchEmail(e.target.value)}
                    className="pl-9"
                  />
                </div>
                <Button>Search</Button>
              </div>

              {searchEmail && (
                <div className="border rounded-lg p-4 space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-semibold">Rahul Deshmukh</p>
                      <p className="text-sm text-muted-foreground">rahul@example.com</p>
                    </div>
                    <Badge>Player</Badge>
                  </div>
                  <div className="grid grid-cols-3 gap-4 text-sm">
                    <div>
                      <p className="text-muted-foreground">Academy</p>
                      <p className="font-medium">Bangalore Cricket Academy</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Sessions</p>
                      <p className="font-medium">127</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Last Active</p>
                      <p className="font-medium">Today at 9:00 AM</p>
                    </div>
                  </div>
                  <div className="flex gap-2 pt-2 border-t">
                    <Button variant="outline" size="sm">View Profile</Button>
                    <Button variant="outline" size="sm">Force Logout</Button>
                    <Button variant="outline" size="sm" className="text-destructive hover:text-destructive">Delete User</Button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
