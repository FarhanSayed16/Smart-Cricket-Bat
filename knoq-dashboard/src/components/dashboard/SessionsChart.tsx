import { Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

interface SessionsChartProps {
  data: { date: string; sessions: number }[];
}

export function SessionsChart({ data }: SessionsChartProps) {
  return (
    <ResponsiveContainer width="100%" height={350}>
      <LineChart data={data}>
        <XAxis
          dataKey="date"
          stroke="#888888"
          fontSize={12}
          tickLine={false}
          axisLine={false}
          tickFormatter={(value) => value.substring(5)} // e.g., "10-25" from "2023-10-25"
        />
        <YAxis
          stroke="#888888"
          fontSize={12}
          tickLine={false}
          axisLine={false}
          tickFormatter={(value) => `${value}`}
        />
        <Tooltip 
          contentStyle={{ backgroundColor: 'hsl(var(--card))', borderColor: 'hsl(var(--border))', borderRadius: '8px' }}
          itemStyle={{ color: 'hsl(var(--foreground))' }}
          labelStyle={{ color: 'hsl(var(--muted-foreground))' }}
        />
        <Line
          type="monotone"
          dataKey="sessions"
          stroke="currentColor"
          strokeWidth={2}
          className="stroke-primary"
          dot={false}
          activeDot={{ r: 6, style: { fill: 'hsl(var(--primary))' } }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
