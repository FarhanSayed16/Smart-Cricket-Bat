import { useState, useEffect, useMemo } from "react"
import { DevicesTable } from "../components/devices/DevicesTable"
import type { DeviceData } from "../components/devices/DevicesTable"
import { RegisterBatModal } from "../components/devices/RegisterBatModal"
import { FleetSummary } from "../components/devices/FleetSummary"
import api from "../lib/axios"
import toast from "react-hot-toast"

const LATEST_FIRMWARE = "v1.0.4" // In a real app, this would come from a global config API

export default function Devices() {
  const [devices, setDevices] = useState<DeviceData[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchDevices = async () => {
      try {
        const res = await api.get("/dashboard/devices")
        const mappedDevices: DeviceData[] = res.data.data.map((d: any) => ({
          id: d.id,
          name: d.name,
          macAddress: d.mac_address,
          firmwareVersion: d.firmware_version,
          latestFirmware: LATEST_FIRMWARE,
          batteryLevel: d.battery_level || 0,
          lastSeen: d.last_seen ? new Date(d.last_seen).toLocaleString() : "Never",
          assignedTo: d.assigned_to_name || null,
          status: d.status as "online" | "offline" | "charging",
        }))
        setDevices(mappedDevices)
      } catch (error) {
        console.error("Failed to fetch devices", error)
        toast.error("Failed to load devices")
      } finally {
        setLoading(false)
      }
    }
    fetchDevices()
  }, [])

  const fleetStats = useMemo(() => {
    return {
      total: devices.length,
      activeNow: devices.filter((d) => d.status === "online").length,
      needCharging: devices.filter((d) => d.batteryLevel < 20).length,
      needFirmwareUpdate: devices.filter(
        (d) => d.firmwareVersion !== d.latestFirmware
      ).length,
    }
  }, [devices])

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Devices</h1>
          <p className="text-muted-foreground">
            Manage your KnoQ smart bats — track battery, firmware, and
            assignments.
          </p>
        </div>
        <RegisterBatModal />
      </div>

      <FleetSummary {...fleetStats} />

      {loading ? (
        <div className="flex justify-center py-12">Loading devices...</div>
      ) : (
        <DevicesTable data={devices} />
      )}
    </div>
  )
}
