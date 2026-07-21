import { cn } from "../../lib/utils";

export function Logo({ className }: { className?: string }) {
  return (
    <svg 
      viewBox="0 0 32 32" 
      fill="none" 
      xmlns="http://www.w3.org/2000/svg"
      className={cn("w-full h-full", className)}
    >
      {/* Background Circle */}
      <circle cx="16" cy="16" r="16" className="fill-primary/10" />
      
      {/* Handle */}
      <rect x="14.5" y="5" width="3" height="7" rx="1.5" className="fill-foreground" />
      
      {/* Cricket Bat Blade */}
      <path 
        d="M13 11H19V24C19 25.6569 17.6569 27 16 27C14.3431 27 13 25.6569 13 24V11Z" 
        className="fill-primary"
      />
      
      {/* IoT Sensor Dot */}
      <circle cx="16" cy="19" r="2.5" className="fill-background" />
      <circle cx="16" cy="19" r="1" className="fill-primary" />
      
      {/* Data Signal Waves */}
      <path d="M9 20C9 16 11.5 13 11.5 13" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="stroke-foreground/40" />
      <path d="M23 20C23 16 20.5 13 20.5 13" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="stroke-foreground/40" />
    </svg>
  );
}
