import { Card, CardContent } from "../ui/card"
import { Smartphone, Wifi, BatteryWarning, AlertTriangle } from "lucide-react"

interface FleetSummaryProps {
  total: number
  activeNow: number
  needCharging: number
  needFirmwareUpdate: number
}

export function FleetSummary({
  total,
  activeNow,
  needCharging,
  needFirmwareUpdate,
}: FleetSummaryProps) {
  const items = [
    {
      label: "Total Bats",
      value: total,
      icon: Smartphone,
      color: "text-foreground",
    },
    {
      label: "Active Now",
      value: activeNow,
      icon: Wifi,
      color: "text-green-500",
    },
    {
      label: "Need Charging",
      value: needCharging,
      icon: BatteryWarning,
      color: "text-orange-500",
    },
    {
      label: "Need Update",
      value: needFirmwareUpdate,
      icon: AlertTriangle,
      color: "text-red-500",
    },
  ]

  return (
    <div className="grid gap-4 grid-cols-2 md:grid-cols-4">
      {items.map((item) => {
        const Icon = item.icon
        return (
          <Card key={item.label}>
            <CardContent className="flex items-center gap-3 pt-6">
              <div className={`p-2 rounded-lg bg-muted ${item.color}`}>
                <Icon className="h-5 w-5" />
              </div>
              <div>
                <p className="text-2xl font-bold">{item.value}</p>
                <p className="text-xs text-muted-foreground">{item.label}</p>
              </div>
            </CardContent>
          </Card>
        )
      })}
    </div>
  )
}
