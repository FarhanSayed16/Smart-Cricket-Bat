import { Card, CardContent, CardHeader, CardTitle } from "../ui/card"
import { Trophy, TrendingUp, Activity, Target } from "lucide-react"

const leaderboards = [
  {
    title: "Most Improved (This Month)",
    icon: TrendingUp,
    color: "text-blue-500",
    bg: "bg-blue-500/10",
    players: [
      { name: "Yashasvi Jaiswal", metric: "+15% Sweet Spot", value: "+15%" },
      { name: "Shubman Gill", metric: "+12% Sweet Spot", value: "+12%" },
      { name: "Rishabh Pant", metric: "+8% Power", value: "+8%" },
    ],
  },
  {
    title: "Most Consistent",
    icon: Target,
    color: "text-purple-500",
    bg: "bg-purple-500/10",
    players: [
      { name: "Virat Kohli", metric: "92/100 Consistency Score", value: "92" },
      { name: "Cheteshwar Pujara", metric: "89/100 Consistency Score", value: "89" },
      { name: "KL Rahul", metric: "85/100 Consistency Score", value: "85" },
    ],
  },
  {
    title: "Most Active",
    icon: Activity,
    color: "text-green-500",
    bg: "bg-green-500/10",
    players: [
      { name: "Rohit Sharma", metric: "24 Sessions", value: "24" },
      { name: "Shubman Gill", metric: "21 Sessions", value: "21" },
      { name: "Ishan Kishan", metric: "19 Sessions", value: "19" },
    ],
  },
  {
    title: "Best Sweet Spot %",
    icon: Trophy,
    color: "text-yellow-500",
    bg: "bg-yellow-500/10",
    players: [
      { name: "Virat Kohli", metric: "68% Average", value: "68%" },
      { name: "Suryakumar Yadav", metric: "65% Average", value: "65%" },
      { name: "Hardik Pandya", metric: "61% Average", value: "61%" },
    ],
  },
]

export function Leaderboards() {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      {leaderboards.map((board) => (
        <Card key={board.title}>
          <CardHeader className="pb-2">
            <div className="flex items-center gap-2">
              <div className={`p-1.5 rounded-md ${board.bg}`}>
                <board.icon className={`h-4 w-4 ${board.color}`} />
              </div>
              <CardTitle className="text-sm font-medium">{board.title}</CardTitle>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {board.players.map((player, idx) => (
                <div key={player.name} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="flex h-6 w-6 items-center justify-center rounded-full bg-muted text-xs font-bold text-muted-foreground">
                      {idx + 1}
                    </div>
                    <div>
                      <p className="text-sm font-medium leading-none">{player.name}</p>
                    </div>
                  </div>
                  <div className="font-semibold text-sm">{player.value}</div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
