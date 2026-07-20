import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../components/ui/card"
import { Button } from "../components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select"
import { Label } from "../components/ui/label"
import { FileText, Download, CalendarDays, FileSpreadsheet, Send } from "lucide-react"

export default function Reports() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Reports & Exports</h1>
        <p className="text-muted-foreground">
          Generate PDF reports for players or export raw CSV data for external analysis.
        </p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Academy Report */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2 mb-1">
              <div className="p-1.5 bg-primary/10 text-primary rounded-md">
                <FileText className="h-5 w-5" />
              </div>
              <CardTitle>Academy Summary Report</CardTitle>
            </div>
            <CardDescription>
              Comprehensive PDF report of academy performance, leaderboards, and overall metrics.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Date Range</Label>
              <Select defaultValue="this-month">
                <SelectTrigger>
                  <SelectValue placeholder="Select Range" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="this-month">This Month</SelectItem>
                  <SelectItem value="last-month">Last Month</SelectItem>
                  <SelectItem value="last-90">Last 90 Days</SelectItem>
                  <SelectItem value="custom">Custom Range...</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div className="pt-2 flex gap-2">
              <Button className="flex-1">
                <Download className="mr-2 h-4 w-4" />
                Generate PDF
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Player Report */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2 mb-1">
              <div className="p-1.5 bg-blue-500/10 text-blue-500 rounded-md">
                <FileText className="h-5 w-5" />
              </div>
              <CardTitle>Individual Player Report</CardTitle>
            </div>
            <CardDescription>
              Detailed PDF for a specific player, including session history, shot charts, and coach notes.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Select Player</Label>
                <Select>
                  <SelectTrigger>
                    <SelectValue placeholder="Search players..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="p1">Rahul Deshmukh</SelectItem>
                    <SelectItem value="p2">Karan Singh</SelectItem>
                    <SelectItem value="p3">Aditya Sharma</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Date Range</Label>
                <Select defaultValue="all-time">
                  <SelectTrigger>
                    <SelectValue placeholder="Select Range" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="this-month">This Month</SelectItem>
                    <SelectItem value="last-90">Last 90 Days</SelectItem>
                    <SelectItem value="all-time">All Time</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            
            <div className="pt-2 flex gap-2">
              <Button className="flex-1 bg-blue-600 hover:bg-blue-700">
                <Download className="mr-2 h-4 w-4" />
                Generate PDF
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Raw Data Export */}
        <Card className="md:col-span-2">
          <CardHeader>
            <div className="flex items-center gap-2 mb-1">
              <div className="p-1.5 bg-green-500/10 text-green-500 rounded-md">
                <FileSpreadsheet className="h-5 w-5" />
              </div>
              <CardTitle>Raw Data Exports (CSV)</CardTitle>
            </div>
            <CardDescription>
              Export raw database tables for use in Excel, Tableau, or custom analysis tools.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid sm:grid-cols-3 gap-4">
              <Button variant="outline" className="justify-start h-auto py-3 px-4">
                <div className="flex flex-col items-start gap-1">
                  <span className="font-semibold flex items-center">
                    <Download className="h-4 w-4 mr-2 text-green-600" />
                    Sessions.csv
                  </span>
                  <span className="text-xs text-muted-foreground font-normal">All session metadata</span>
                </div>
              </Button>
              <Button variant="outline" className="justify-start h-auto py-3 px-4">
                <div className="flex flex-col items-start gap-1">
                  <span className="font-semibold flex items-center">
                    <Download className="h-4 w-4 mr-2 text-green-600" />
                    Shots.csv
                  </span>
                  <span className="text-xs text-muted-foreground font-normal">Individual shot data (power, zone)</span>
                </div>
              </Button>
              <Button variant="outline" className="justify-start h-auto py-3 px-4">
                <div className="flex flex-col items-start gap-1">
                  <span className="font-semibold flex items-center">
                    <Download className="h-4 w-4 mr-2 text-green-600" />
                    CoachNotes.csv
                  </span>
                  <span className="text-xs text-muted-foreground font-normal">All feedback and timestamps</span>
                </div>
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Scheduled Reports Config */}
        <Card className="md:col-span-2 border-dashed bg-muted/30">
          <CardContent className="p-6 flex flex-col sm:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-background rounded-full border shadow-sm">
                <CalendarDays className="h-6 w-6 text-muted-foreground" />
              </div>
              <div>
                <h3 className="font-semibold text-lg">Automated Weekly Summary</h3>
                <p className="text-sm text-muted-foreground">Automatically email a summary PDF to all coaches every Sunday at 6 PM.</p>
              </div>
            </div>
            <Button variant="secondary" className="whitespace-nowrap">
              <Send className="mr-2 h-4 w-4" />
              Configure Schedule
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
