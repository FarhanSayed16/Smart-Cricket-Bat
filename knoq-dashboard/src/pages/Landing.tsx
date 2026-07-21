import { Link } from "react-router-dom";
import { Button } from "../components/ui/button";
import { 
  Activity, 
  BarChart3, 
  BrainCircuit, 
  ChevronRight, 
  Target, 
  Zap, 
  TrendingUp, 
  Smartphone,
  CheckCircle2,
  Cpu,
  Bluetooth,
  WifiOff,
  ChevronDown,
  Download
} from "lucide-react";
import { useState, useEffect } from "react";
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

function FAQAccordion({ question, answer }: { question: string, answer: string }) {
  const [isOpen, setIsOpen] = useState(false);
  return (
    <div className="border border-border rounded-xl overflow-hidden mb-4 bg-background/50">
      <button 
        className="w-full px-6 py-4 text-left flex justify-between items-center focus:outline-none"
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className="font-semibold text-foreground">{question}</span>
        <ChevronDown className={cn("h-5 w-5 text-muted-foreground transition-transform duration-200", isOpen && "rotate-180")} />
      </button>
      <div 
        className={cn(
          "px-6 overflow-hidden transition-all duration-300 ease-in-out",
          isOpen ? "max-h-96 pb-4 opacity-100" : "max-h-0 opacity-0"
        )}
      >
        <p className="text-muted-foreground">{answer}</p>
      </div>
    </div>
  );
}

function AnimatedCounter({ end, label, suffix = "" }: { end: number, label: string, suffix?: string }) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    let start = 0;
    const duration = 2000;
    const increment = end / (duration / 16);
    
    const timer = setInterval(() => {
      start += increment;
      if (start >= end) {
        setCount(end);
        clearInterval(timer);
      } else {
        setCount(Math.floor(start));
      }
    }, 16);
    
    return () => clearInterval(timer);
  }, [end]);

  return (
    <div className="flex flex-col items-center">
      <span className="text-4xl md:text-5xl font-black text-primary mb-2 tracking-tighter">
        {count}{suffix}
      </span>
      <span className="text-sm md:text-base font-medium text-muted-foreground uppercase tracking-wider">{label}</span>
    </div>
  );
}

export default function Landing() {
  const scrollTo = (id: string) => {
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <div className="min-h-screen bg-background flex flex-col font-sans selection:bg-primary/20 selection:text-primary overflow-x-hidden">
      {/* 1. Navbar */}
      <header className="px-6 lg:px-14 py-4 flex items-center justify-between border-b bg-background/80 backdrop-blur-md sticky top-0 z-50">
        <div className="flex items-center gap-3 cursor-pointer" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
          <div className="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center p-1 border border-primary/20 shadow-sm overflow-hidden">
            <img src="/logo.png" alt="KnoQ Logo" className="w-full h-full object-cover rounded-lg" />
          </div>
          <span className="text-2xl font-black tracking-tighter text-foreground">KnoQ</span>
        </div>
        
        <nav className="hidden md:flex items-center gap-8">
          <button onClick={() => scrollTo('features')} className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">Features</button>
          <button onClick={() => scrollTo('app')} className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">App Showcase</button>
          <button onClick={() => scrollTo('hardware')} className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">Smart Bat</button>
          <button onClick={() => scrollTo('team')} className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">Team</button>
        </nav>

        <div className="flex items-center gap-4">
          <Link to="/login">
            <Button variant="ghost" className="font-medium hidden sm:inline-flex text-muted-foreground hover:text-foreground">
              Sign In
            </Button>
          </Link>
          <Link to="/login">
            <Button className="font-semibold shadow-sm">
              Get Started
            </Button>
          </Link>
        </div>
      </header>

      <main className="flex-1 flex flex-col">
        {/* 2. Hero Section */}
        <section className="relative w-full pt-20 pb-32 md:pt-32 md:pb-48 flex flex-col items-center justify-center text-center px-4 bg-slate-50 dark:bg-background overflow-x-hidden border-b">
          <div className="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]"></div>
          
          {/* Subtle glowing orbs */}
          <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-primary/20 rounded-full blur-[128px] pointer-events-none"></div>
          <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-blue-500/20 rounded-full blur-[128px] pointer-events-none"></div>

          <div className="max-w-[1000px] space-y-8 relative z-10 animate-in fade-in slide-in-from-bottom-8 duration-700">
            <div className="inline-flex items-center rounded-full border border-border/50 px-3 py-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground bg-background shadow-sm">
              <span className="flex h-2 w-2 rounded-full bg-primary mr-2 animate-pulse"></span>
              The Operating System for Cricket Academies
            </div>
            
            <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight text-foreground leading-[1.1]">
              Your Cricket Bat, <br/>
              <span className="text-primary bg-clip-text text-transparent bg-gradient-to-r from-primary to-orange-500">Upgraded with Intelligence.</span>
            </h1>
            
            <p className="text-xl text-muted-foreground max-w-[750px] mx-auto leading-relaxed">
              KnoQ embeds professional-grade IoT sensors directly into your bat, tracking swing speed, impact zones, and power metrics in real-time. Paired with AI insights to perfect your technique.
            </p>
            
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-6">
              <button onClick={() => scrollTo('download')} className="w-full sm:w-auto">
                <Button size="lg" className="w-full text-base h-12 px-8 shadow-md">
                  <Download className="mr-2 h-4 w-4" /> Download the App
                </Button>
              </button>
              <Link to="/login" className="w-full sm:w-auto">
                <Button size="lg" variant="outline" className="w-full text-base h-12 px-8 bg-background border-border shadow-sm hover:bg-slate-100 dark:hover:bg-slate-800">
                  Try Web Dashboard <ChevronRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
            </div>
          </div>

          {/* Product Mockups */}
          <div className="mt-16 md:mt-24 w-full max-w-5xl mx-auto px-4 hidden md:flex items-end justify-center gap-8 lg:gap-12">
            {/* Mobile Mockup */}
            <div className="w-[220px] lg:w-[260px] flex-shrink-0 animate-float">
              <div className="rounded-[2rem] overflow-hidden border-[8px] border-slate-900 shadow-2xl bg-background">
                <img src="/screenshots/mobile/home.jpg" alt="KnoQ Mobile App" className="w-full h-auto" />
              </div>
            </div>

            {/* Dashboard Mockup */}
            <div className="flex-1 max-w-[700px] animate-float-delayed">
              <div className="rounded-xl overflow-hidden border border-border shadow-2xl bg-background">
                <div className="h-8 bg-slate-100 dark:bg-slate-800 border-b flex items-center px-4 gap-2">
                  <div className="w-3 h-3 rounded-full bg-red-400"></div>
                  <div className="w-3 h-3 rounded-full bg-yellow-400"></div>
                  <div className="w-3 h-3 rounded-full bg-green-400"></div>
                </div>
                <img src="/screenshots/dashboard/dashboard1.png" alt="KnoQ Web Dashboard" className="w-full h-auto" />
              </div>
            </div>
          </div>
        </section>

        {/* 3. Live Stats Bar */}
        <section className="w-full py-16 bg-slate-900 text-white border-b border-slate-800 relative z-20">
          <div className="container mx-auto px-4">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8 divide-y md:divide-y-0 md:divide-x divide-slate-800">
              <AnimatedCounter end={1000} suffix="+" label="Shots Tracked" />
              <AnimatedCounter end={50} suffix="+" label="Players Enrolled" />
              <AnimatedCounter end={10} suffix="+" label="Academies" />
              <div className="flex flex-col items-center justify-center pt-8 md:pt-0">
                <span className="text-4xl md:text-5xl font-black text-primary mb-2 flex items-center">
                  <Activity className="h-10 w-10 mr-2" />
                </span>
                <span className="text-sm md:text-base font-medium text-slate-400 uppercase tracking-wider">Real-time BLE</span>
              </div>
            </div>
          </div>
        </section>

        {/* 4. Features Grid */}
        <section id="features" className="w-full py-24 bg-background">
          <div className="container mx-auto px-4 md:px-6">
            <div className="text-center mb-16 max-w-3xl mx-auto">
              <h2 className="text-3xl md:text-4xl font-bold tracking-tight mb-4">Professional analytics in your kitbag.</h2>
              <p className="text-lg text-muted-foreground">Everything you need to understand your game at a biomechanical level, packaged in a beautifully simple interface.</p>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {/* Feature 1 */}
              <div className="p-8 rounded-2xl bg-slate-50 dark:bg-slate-900 border border-border/50 hover:border-primary/50 transition-colors">
                <Target className="h-10 w-10 text-primary mb-6" />
                <h3 className="text-xl font-bold mb-3">Impact Heatmap</h3>
                <p className="text-muted-foreground leading-relaxed">Visualize exactly where the ball strikes your bat. Understand your sweet spot percentage and adjust your technique accordingly.</p>
              </div>
              {/* Feature 2 */}
              <div className="p-8 rounded-2xl bg-slate-50 dark:bg-slate-900 border border-border/50 hover:border-primary/50 transition-colors">
                <BrainCircuit className="h-10 w-10 text-primary mb-6" />
                <h3 className="text-xl font-bold mb-3">AI Coaching Insights</h3>
                <p className="text-muted-foreground leading-relaxed">Our AI analyzes your session history to detect trends. Get actionable insights like "Power Improving" or "Consistency Dropping".</p>
              </div>
              {/* Feature 3 */}
              <div className="p-8 rounded-2xl bg-slate-50 dark:bg-slate-900 border border-border/50 hover:border-primary/50 transition-colors">
                <TrendingUp className="h-10 w-10 text-primary mb-6" />
                <h3 className="text-xl font-bold mb-3">Session Analytics</h3>
                <p className="text-muted-foreground leading-relaxed">Review historical data. Track total hits, average power, peak power, and compare sessions over time to measure real progress.</p>
              </div>
              {/* Feature 4 */}
              <div className="p-8 rounded-2xl bg-slate-50 dark:bg-slate-900 border border-border/50 hover:border-primary/50 transition-colors">
                <Bluetooth className="h-10 w-10 text-primary mb-6" />
                <h3 className="text-xl font-bold mb-3">BLE Connectivity</h3>
                <p className="text-muted-foreground leading-relaxed">Ultra-low latency Bluetooth Low Energy connection streams sensor data from the bat to your phone in real-time as you swing.</p>
              </div>
              {/* Feature 5 */}
              <div className="p-8 rounded-2xl bg-slate-50 dark:bg-slate-900 border border-border/50 hover:border-primary/50 transition-colors">
                <BarChart3 className="h-10 w-10 text-primary mb-6" />
                <h3 className="text-xl font-bold mb-3">Coach Dashboard</h3>
                <p className="text-muted-foreground leading-relaxed">A dedicated web portal for academies to manage fleets of bats, view academy-wide leaderboards, and monitor all players.</p>
              </div>
              {/* Feature 6 */}
              <div className="p-8 rounded-2xl bg-slate-50 dark:bg-slate-900 border border-border/50 hover:border-primary/50 transition-colors">
                <WifiOff className="h-10 w-10 text-primary mb-6" />
                <h3 className="text-xl font-bold mb-3">Offline-First</h3>
                <p className="text-muted-foreground leading-relaxed">No internet at the nets? No problem. The app saves sessions locally and automatically syncs to the cloud when connectivity returns.</p>
              </div>
            </div>
          </div>
        </section>

        {/* 5. App Showcase */}
        <section id="app" className="w-full py-24 bg-slate-50 dark:bg-slate-900/40 border-y">
          <div className="container mx-auto px-4">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-4xl font-bold tracking-tight mb-4">See KnoQ in Action</h2>
              <p className="text-lg text-muted-foreground">A beautifully native Flutter application designed for players on the go.</p>
            </div>

            <div className="flex overflow-x-auto pb-12 gap-8 snap-x snap-mandatory hide-scrollbar justify-start lg:justify-center px-4">
              {[
                { src: "/screenshots/mobile/home.jpg", label: "Player Dashboard" },
                { src: "/screenshots/mobile/session-details.jpg", label: "Session Heatmap" },
                { src: "/screenshots/mobile/insights.jpg", label: "AI Coaching Insights" },
                { src: "/screenshots/mobile/settings.jpg", label: "Preferences" }
              ].map((img, i) => (
                <div key={i} className="flex-none w-[280px] snap-center flex flex-col items-center">
                  <div className="rounded-[2rem] overflow-hidden border-[8px] border-slate-900 shadow-xl bg-background w-full">
                    <img src={img.src} alt={img.label} className="w-full h-auto object-cover" loading="lazy" />
                  </div>
                  <span className="mt-6 font-medium text-foreground">{img.label}</span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* 6. Dashboard Showcase */}
        <section className="w-full py-24 bg-background">
          <div className="container mx-auto px-4 max-w-6xl">
            <div className="flex flex-col lg:flex-row items-center gap-12 mb-16">
              <div className="flex-1 space-y-6">
                <div className="inline-flex items-center rounded-md border px-2.5 py-0.5 text-sm font-semibold bg-background">
                  For Coaches & Academies
                </div>
                <h2 className="text-3xl md:text-4xl font-bold tracking-tight">Scale your coaching business.</h2>
                <p className="text-lg text-muted-foreground">Monitor all smart bats and active sessions across your entire academy from a single, powerful web dashboard.</p>
                <ul className="space-y-4 pt-4">
                  <li className="flex items-start">
                    <CheckCircle2 className="mr-3 h-5 w-5 text-primary shrink-0 mt-0.5" />
                    <span className="text-foreground font-medium">Fleet Management for IoT devices</span>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle2 className="mr-3 h-5 w-5 text-primary shrink-0 mt-0.5" />
                    <span className="text-foreground font-medium">Player leaderboards and trend analytics</span>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle2 className="mr-3 h-5 w-5 text-primary shrink-0 mt-0.5" />
                    <span className="text-foreground font-medium">Identify struggling players instantly</span>
                  </li>
                </ul>
              </div>
              <div className="flex-1 w-full relative">
                <div className="rounded-xl overflow-hidden border border-border shadow-2xl bg-background">
                  <div className="h-8 bg-slate-100 dark:bg-slate-800 border-b flex items-center px-4 gap-2">
                    <div className="w-3 h-3 rounded-full bg-red-400"></div>
                    <div className="w-3 h-3 rounded-full bg-yellow-400"></div>
                    <div className="w-3 h-3 rounded-full bg-green-400"></div>
                  </div>
                  <img src="/screenshots/dashboard/dashboard2.png" alt="Analytics Dashboard" className="w-full h-auto" />
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="rounded-xl overflow-hidden border shadow-sm">
                <img src="/screenshots/dashboard/leaderboards.png" alt="Leaderboards" className="w-full h-auto hover:scale-105 transition-transform duration-500" />
              </div>
              <div className="rounded-xl overflow-hidden border shadow-sm">
                <img src="/screenshots/dashboard/devices.png" alt="Devices" className="w-full h-auto hover:scale-105 transition-transform duration-500" />
              </div>
              <div className="rounded-xl overflow-hidden border shadow-sm">
                <img src="/screenshots/dashboard/players.png" alt="Players" className="w-full h-auto hover:scale-105 transition-transform duration-500" />
              </div>
            </div>
          </div>
        </section>

        {/* 7. Hardware Section */}
        <section id="hardware" className="w-full py-24 bg-slate-900 text-white relative overflow-hidden">
          {/* Circuit board aesthetic background pattern */}
          <div className="absolute inset-0 opacity-10 bg-[url('data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI4OCIgaGVpZ2h0PSI4OCI+PGNpcmNsZSBjeD0iNDQiIGN5PSI0NCIgcj0iMiIgZmlsbD0iI2ZmZiIvPjxwYXRoIGQ9Ik00NCA0NGwxNS0xNW0wIDBoMTVtLTMwIDE1bC0xNSAxNW0wIDBoLTE1IiBzdHJva2U9IiNmZmYiIGZpbGw9Im5vbmUiLz48L3N2Zz4=')] bg-repeat"></div>
          
          <div className="container mx-auto px-4 relative z-10">
            <div className="flex flex-col lg:flex-row items-center gap-16">
              <div className="flex-1 w-full max-w-md mx-auto">
                <div className="rounded-2xl overflow-hidden border-[4px] border-slate-700 shadow-2xl relative group">
                  <div className="absolute inset-0 bg-primary/20 group-hover:bg-transparent transition-colors z-10 pointer-events-none"></div>
                  <img src="/screenshots/hardware/smart-bat.jpeg" alt="ESP32 Smart Bat Hardware" className="w-full h-auto object-cover transform group-hover:scale-105 transition-transform duration-700" />
                </div>
              </div>
              <div className="flex-1 space-y-6">
                <div className="inline-flex items-center rounded-md border border-slate-700 px-2.5 py-0.5 text-sm font-semibold bg-slate-800 text-primary">
                  The Hardware
                </div>
                <h2 className="text-3xl md:text-5xl font-bold tracking-tight">Custom built for the crease.</h2>
                <p className="text-lg text-slate-300">Our proprietary embedded system is shock-isolated and seamlessly integrated into the bat without affecting balance or weight distribution.</p>
                
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 pt-6">
                  <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700">
                    <Cpu className="h-6 w-6 text-primary mb-2" />
                    <strong className="block text-white">ESP32 Core</strong>
                    <span className="text-sm text-slate-400">High-performance dual-core processing with built-in BLE.</span>
                  </div>
                  <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700">
                    <Target className="h-6 w-6 text-primary mb-2" />
                    <strong className="block text-white">Piezoelectric Sensors</strong>
                    <span className="text-sm text-slate-400">Multi-point disc sensors detect precise impact locations.</span>
                  </div>
                  <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700">
                    <Activity className="h-6 w-6 text-primary mb-2" />
                    <strong className="block text-white">9-Axis IMU</strong>
                    <span className="text-sm text-slate-400">MPU-9250 tracks swing speed and 3D bat path mechanics.</span>
                  </div>
                  <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700">
                    <Zap className="h-6 w-6 text-primary mb-2" />
                    <strong className="block text-white">LiPo Battery</strong>
                    <span className="text-sm text-slate-400">USB-C rechargeable with over 4 hours of continuous tracking.</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* 8. Download Section */}
        <section id="download" className="w-full py-24 bg-slate-50 dark:bg-slate-900/50 border-y">
          <div className="container mx-auto px-4 text-center max-w-3xl space-y-8">
            <h2 className="text-3xl md:text-5xl font-bold tracking-tight">Ready to play?</h2>
            <p className="text-xl text-muted-foreground">
              Download the app today. Use Demo Mode to explore the features even without a physical smart bat.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-4">
              <a href="/knoq-app.apk" download="KnoQ-App.apk">
                <Button size="lg" className="w-full sm:w-auto h-14 px-8 text-lg font-semibold shadow-md">
                  <Smartphone className="mr-2 h-5 w-5" /> Download APK (Android)
                </Button>
              </a>
              <Button size="lg" variant="outline" disabled className="w-full sm:w-auto h-14 px-8 text-lg font-semibold bg-background">
                iOS App (Coming Soon)
              </Button>
            </div>
            <p className="text-sm text-muted-foreground pt-4">
              Are you a coach? <Link to="/login" className="text-primary hover:underline font-medium">Access the web dashboard here.</Link>
            </p>
          </div>
        </section>

        {/* 9. Team Section */}
        <section id="team" className="w-full py-24 bg-background">
          <div className="container mx-auto px-4">
            <div className="text-center mb-16">
              <h2 className="text-3xl font-bold tracking-tight mb-2">Built by Cricket Lovers.</h2>
              <p className="text-muted-foreground">The engineering team behind the smart bat.</p>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl mx-auto">
              <div className="flex flex-col items-center text-center p-6 bg-slate-50 dark:bg-slate-900 rounded-2xl border">
                <div className="w-24 h-24 rounded-full bg-primary/20 flex items-center justify-center text-primary text-2xl font-bold mb-4">FS</div>
                <h3 className="text-xl font-bold">Farhan Sayed</h3>
                <p className="text-primary text-sm font-medium mb-3">Project Lead</p>
                <p className="text-sm text-muted-foreground">System architecture, full-stack software development, and hardware design.</p>
              </div>
              
              <div className="flex flex-col items-center text-center p-6 bg-slate-50 dark:bg-slate-900 rounded-2xl border">
                <div className="w-24 h-24 rounded-full bg-blue-500/20 flex items-center justify-center text-blue-500 text-2xl font-bold mb-4">VD</div>
                <h3 className="text-xl font-bold">Viraj Dalvi</h3>
                <p className="text-blue-500 text-sm font-medium mb-3">Software Developer</p>
                <p className="text-sm text-muted-foreground">Mobile application development and frontend UI architecture.</p>
              </div>

              <div className="flex flex-col items-center text-center p-6 bg-slate-50 dark:bg-slate-900 rounded-2xl border">
                <div className="w-24 h-24 rounded-full bg-green-500/20 flex items-center justify-center text-green-500 text-2xl font-bold mb-4">HK</div>
                <h3 className="text-xl font-bold">Harsh Khudtarkar</h3>
                <p className="text-green-500 text-sm font-medium mb-3">Hardware Engineer</p>
                <p className="text-sm text-muted-foreground">Hardware prototyping, circuit design, and sensor integration.</p>
              </div>
            </div>
          </div>
        </section>

        {/* 10. FAQ Section */}
        <section className="w-full py-24 bg-slate-50 dark:bg-slate-900/50 border-t">
          <div className="container mx-auto px-4 max-w-3xl">
            <h2 className="text-3xl font-bold tracking-tight text-center mb-12">Frequently Asked Questions</h2>
            
            <div className="space-y-2">
              <FAQAccordion 
                question="Do I need the physical bat to use the app?" 
                answer="While the physical bat provides the actual data, the app includes a 'Demo Mode' that allows you to explore the interface, view sample sessions, and simulate hits to see how the analytics work." 
              />
              <FAQAccordion 
                question="How does the sensor connect to my phone?" 
                answer="The KnoQ sensor uses Bluetooth Low Energy (BLE). Simply turn on the bat, open the app, and tap 'Scan'. It connects instantly and maintains a stable connection throughout your net session." 
              />
              <FAQAccordion 
                question="Does the hardware affect the weight of the bat?" 
                answer="The entire sensor module weighs less than 15 grams and is embedded within a custom cavity near the handle, ensuring the bat's center of gravity and balance remain completely unaffected." 
              />
              <FAQAccordion 
                question="Is my session data saved if my phone dies?" 
                answer="Yes! KnoQ uses an offline-first architecture. If the app crashes or your phone dies, the data is saved locally on the device. It will automatically recover and sync to the cloud on your next launch." 
              />
              <FAQAccordion 
                question="Can coaches see data for all their academy players?" 
                answer="Yes, that's exactly what the web dashboard is for. Coaches can invite players to their academy, monitor their individual sessions, and view academy-wide leaderboards for metrics like sweet spot percentage." 
              />
            </div>
          </div>
        </section>
      </main>

      {/* 11. Footer */}
      <footer className="w-full py-12 border-t bg-background">
        <div className="container mx-auto px-4 flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 bg-primary/10 rounded flex items-center justify-center p-0.5">
              <img src="/logo.png" alt="KnoQ Logo" className="w-full h-full object-cover rounded-sm" />
            </div>
            <span className="font-bold text-foreground">KnoQ</span>
          </div>
          
          <div className="flex gap-6 text-sm text-muted-foreground font-medium">
            <button onClick={() => scrollTo('features')} className="hover:text-foreground transition-colors">Features</button>
            <Link to="/login" className="hover:text-foreground transition-colors">Dashboard</Link>
            <button onClick={() => scrollTo('team')} className="hover:text-foreground transition-colors">Team</button>
          </div>

          <div className="text-center md:text-right">
            <p className="text-sm text-muted-foreground font-medium">
              © 2026 KnoQ Team. All rights reserved.
            </p>
            <p className="text-xs text-muted-foreground/60 mt-1">
              Proprietary Software. No unauthorized distribution.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
