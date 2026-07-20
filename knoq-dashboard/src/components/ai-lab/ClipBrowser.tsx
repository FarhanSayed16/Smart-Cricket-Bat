import { useState } from "react"
import { Card, CardContent } from "../ui/card"
import { Badge } from "../ui/badge"
import { Button } from "../ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../ui/select"
import { Link } from "react-router-dom"
import { Play, CheckCircle2, CircleDashed } from "lucide-react"

interface Clip {
  id: string
  playerName: string
  date: string
  power: number
  zone: string
  status: "tagged" | "untagged"
  thumbnailUrl: string
}

const mockClips: Clip[] = Array.from({ length: 12 }).map((_, i) => ({
  id: `clip_${i + 1}`,
  playerName: i % 3 === 0 ? "Rahul Deshmukh" : i % 2 === 0 ? "Aditya Sharma" : "Karan Singh",
  date: "Oct 24, 2023",
  power: Math.floor(Math.random() * 50) + 40,
  zone: ["Sweet Spot", "Middle", "Toe", "Edge"][Math.floor(Math.random() * 4)],
  status: i < 5 ? "tagged" : "untagged",
  thumbnailUrl: "https://via.placeholder.com/300x169?text=Video+Thumbnail", // 16:9 ratio placeholder
}))

export function ClipBrowser() {
  const [filter, setFilter] = useState("all")
  const [sort, setSort] = useState("newest")

  const filteredClips = mockClips
    .filter((clip) => {
      if (filter === "untagged") return clip.status === "untagged"
      if (filter === "tagged") return clip.status === "tagged"
      return true
    })
    .sort((a, b) => {
      if (sort === "untaggedFirst") {
        if (a.status === "untagged" && b.status === "tagged") return -1
        if (a.status === "tagged" && b.status === "untagged") return 1
      }
      return 0 // Placeholder for real sorting
    })

  return (
    <div className="space-y-4">
      {/* Toolbar */}
      <div className="flex flex-col sm:flex-row justify-between items-center gap-4 bg-muted/50 p-2 rounded-md">
        <div className="flex items-center gap-2 w-full sm:w-auto">
          <Select value={filter} onValueChange={setFilter}>
            <SelectTrigger className="w-[140px] h-8 text-xs bg-background">
              <SelectValue placeholder="Filter Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Clips</SelectItem>
              <SelectItem value="untagged">Untagged Only</SelectItem>
              <SelectItem value="tagged">Tagged Only</SelectItem>
            </SelectContent>
          </Select>
          
          <Select defaultValue="all-shots">
             <SelectTrigger className="w-[140px] h-8 text-xs bg-background">
              <SelectValue placeholder="Shot Type" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all-shots">All Shot Types</SelectItem>
              <SelectItem value="cover-drive">Cover Drive</SelectItem>
              <SelectItem value="pull">Pull Shot</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto">
          <span className="text-xs text-muted-foreground whitespace-nowrap">Sort by:</span>
          <Select value={sort} onValueChange={setSort}>
            <SelectTrigger className="w-[140px] h-8 text-xs bg-background">
              <SelectValue placeholder="Sort" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="newest">Newest First</SelectItem>
              <SelectItem value="oldest">Oldest First</SelectItem>
              <SelectItem value="untaggedFirst">Untagged First</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Grid */}
      <div className="grid gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
        {filteredClips.map((clip) => (
          <Link key={clip.id} to={`/ai-lab/tag/${clip.id}`}>
            <Card className="overflow-hidden hover:ring-2 ring-primary transition-all group cursor-pointer h-full flex flex-col">
              <div className="relative aspect-video bg-black flex items-center justify-center overflow-hidden">
                <img 
                  src={clip.thumbnailUrl} 
                  alt={`Shot by ${clip.playerName}`} 
                  className="w-full h-full object-cover opacity-70 group-hover:opacity-100 transition-opacity"
                />
                <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/30">
                  <Play className="h-10 w-10 text-white fill-white" />
                </div>
                <div className="absolute top-2 left-2 flex gap-1">
                  {clip.status === "tagged" ? (
                    <Badge variant="default" className="bg-green-600 hover:bg-green-700 text-[10px] px-1.5 py-0">
                      <CheckCircle2 className="h-3 w-3 mr-1" /> Tagged
                    </Badge>
                  ) : (
                    <Badge variant="destructive" className="text-[10px] px-1.5 py-0">
                      <CircleDashed className="h-3 w-3 mr-1" /> Untagged
                    </Badge>
                  )}
                </div>
              </div>
              <CardContent className="p-3 flex-1 flex flex-col justify-between">
                <div>
                  <p className="font-semibold text-sm truncate" title={clip.playerName}>{clip.playerName}</p>
                  <p className="text-xs text-muted-foreground">{clip.date}</p>
                </div>
                <div className="mt-2 flex items-center justify-between text-xs">
                  <span className="font-medium">{clip.zone}</span>
                  <span className="text-muted-foreground">{clip.power}% Pwr</span>
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      <div className="flex justify-center pt-4">
        <Button variant="outline">Load More</Button>
      </div>
    </div>
  )
}
