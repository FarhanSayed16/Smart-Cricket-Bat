import { useState } from "react"
import type {
  ColumnDef,
  ColumnFiltersState,
  SortingState,
} from "@tanstack/react-table"
import {
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table"

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../ui/table"
import { Button } from "../ui/button"
import { Input } from "../ui/input"
import { Badge } from "../ui/badge"
import { MoreHorizontal, ArrowUpDown, Wifi, WifiOff } from "lucide-react"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "../ui/dropdown-menu"

export interface DeviceData {
  id: string
  name: string
  macAddress: string
  firmwareVersion: string
  latestFirmware: string
  batteryLevel: number
  lastSeen: string
  assignedTo: string | null
  status: "online" | "offline" | "charging"
}

function BatteryBadge({ level }: { level: number }) {
  if (level > 50) {
    return <Badge variant="default" className="bg-green-600 hover:bg-green-700">{level}%</Badge>
  } else if (level > 20) {
    return <Badge variant="default" className="bg-orange-500 hover:bg-orange-600">{level}%</Badge>
  }
  return <Badge variant="destructive">{level}%</Badge>
}

function FirmwareBadge({ current, latest }: { current: string; latest: string }) {
  if (current === latest) {
    return <span className="text-sm text-muted-foreground">{current}</span>
  }
  // Parse version numbers for comparison
  const currentParts = current.split(".").map(Number)
  const latestParts = latest.split(".").map(Number)
  const majorBehind = latestParts[0] - currentParts[0]
  const minorBehind = latestParts[1] - currentParts[1]

  if (majorBehind >= 1 || minorBehind >= 2) {
    return <Badge variant="destructive">{current} (outdated)</Badge>
  }
  return <Badge variant="outline" className="border-orange-400 text-orange-600">{current}</Badge>
}

function StatusIndicator({ status }: { status: string }) {
  if (status === "online") {
    return (
      <div className="flex items-center gap-1.5">
        <span className="relative flex h-2.5 w-2.5">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
          <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-green-500"></span>
        </span>
        <Wifi className="h-3.5 w-3.5 text-green-500" />
        <span className="text-sm text-green-600 font-medium">Online</span>
      </div>
    )
  }
  if (status === "charging") {
    return (
      <div className="flex items-center gap-1.5">
        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-orange-400"></span>
        <span className="text-sm text-orange-500 font-medium">Charging</span>
      </div>
    )
  }
  return (
    <div className="flex items-center gap-1.5">
      <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-gray-400"></span>
      <WifiOff className="h-3.5 w-3.5 text-gray-400" />
      <span className="text-sm text-muted-foreground">Offline</span>
    </div>
  )
}

const columns: ColumnDef<DeviceData>[] = [
  {
    accessorKey: "name",
    header: ({ column }) => (
      <Button
        variant="ghost"
        onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
      >
        Device Name
        <ArrowUpDown className="ml-2 h-4 w-4" />
      </Button>
    ),
    cell: ({ row }) => <div className="font-medium px-4">{row.getValue("name")}</div>,
  },
  {
    accessorKey: "macAddress",
    header: "MAC Address",
    cell: ({ row }) => (
      <code className="text-xs bg-muted px-1.5 py-0.5 rounded font-mono">
        {row.getValue("macAddress")}
      </code>
    ),
  },
  {
    accessorKey: "firmwareVersion",
    header: "Firmware",
    cell: ({ row }) => (
      <FirmwareBadge
        current={row.getValue("firmwareVersion")}
        latest={row.original.latestFirmware}
      />
    ),
  },
  {
    accessorKey: "batteryLevel",
    header: ({ column }) => (
      <Button
        variant="ghost"
        onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
      >
        Battery
        <ArrowUpDown className="ml-2 h-4 w-4" />
      </Button>
    ),
    cell: ({ row }) => <BatteryBadge level={row.getValue("batteryLevel")} />,
  },
  {
    accessorKey: "lastSeen",
    header: "Last Seen",
    cell: ({ row }) => (
      <div className="text-sm text-muted-foreground">{row.getValue("lastSeen")}</div>
    ),
  },
  {
    accessorKey: "assignedTo",
    header: "Assigned To",
    cell: ({ row }) => {
      const assignedTo = row.getValue("assignedTo") as string | null
      return assignedTo ? (
        <span className="text-sm">{assignedTo}</span>
      ) : (
        <span className="text-sm text-muted-foreground italic">Unassigned</span>
      )
    },
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => <StatusIndicator status={row.getValue("status")} />,
  },
  {
    id: "actions",
    cell: ({ row }) => {
      const device = row.original
      return (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="h-8 w-8 p-0">
              <span className="sr-only">Open menu</span>
              <MoreHorizontal className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuLabel>Actions</DropdownMenuLabel>
            <DropdownMenuItem
              onClick={() => navigator.clipboard.writeText(device.macAddress)}
            >
              Copy MAC address
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem>Assign to player</DropdownMenuItem>
            <DropdownMenuItem>Unassign</DropdownMenuItem>
            <DropdownMenuItem>Push firmware update</DropdownMenuItem>
            <DropdownMenuItem>View diagnostic log</DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem className="text-destructive">
              Remove device
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      )
    },
  },
]

interface DevicesTableProps {
  data: DeviceData[]
}

export function DevicesTable({ data }: DevicesTableProps) {
  const [sorting, setSorting] = useState<SortingState>([])
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([])

  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    onSortingChange: setSorting,
    getSortedRowModel: getSortedRowModel(),
    onColumnFiltersChange: setColumnFilters,
    getFilteredRowModel: getFilteredRowModel(),
    state: {
      sorting,
      columnFilters,
    },
  })

  return (
    <div>
      <div className="flex items-center py-4">
        <Input
          placeholder="Filter devices by name..."
          value={(table.getColumn("name")?.getFilterValue() as string) ?? ""}
          onChange={(event) =>
            table.getColumn("name")?.setFilterValue(event.target.value)
          }
          className="max-w-sm"
        />
      </div>
      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <TableHead key={header.id}>
                    {header.isPlaceholder
                      ? null
                      : flexRender(
                          header.column.columnDef.header,
                          header.getContext()
                        )}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow
                  key={row.id}
                  data-state={row.getIsSelected() && "selected"}
                >
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext()
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="h-24 text-center"
                >
                  No devices found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      <div className="flex items-center justify-end space-x-2 py-4">
        <Button
          variant="outline"
          size="sm"
          onClick={() => table.previousPage()}
          disabled={!table.getCanPreviousPage()}
        >
          Previous
        </Button>
        <Button
          variant="outline"
          size="sm"
          onClick={() => table.nextPage()}
          disabled={!table.getCanNextPage()}
        >
          Next
        </Button>
      </div>
    </div>
  )
}
