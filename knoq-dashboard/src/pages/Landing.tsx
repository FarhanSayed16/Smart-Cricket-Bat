import { Link } from "react-router-dom";
import { Button } from "../components/ui/button";
import { 
  Activity, 
  BarChart3, 
  BrainCircuit, 
  ShieldCheck, 
  ChevronRight, 
  Target, 
  Zap, 
  TrendingUp, 
  Smartphone,
  CheckCircle2
} from "lucide-react";

export default function Landing() {
  return (
    <div className="min-h-screen bg-background flex flex-col font-sans selection:bg-primary/20 selection:text-primary">
      {/* Navbar */}
      <header className="px-6 lg:px-14 py-4 flex items-center justify-between border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-50">
        <div className="flex items-center gap-2">
          <span className="text-2xl font-black tracking-tighter text-foreground">KnoQ</span>
        </div>
        <nav className="flex items-center gap-4">
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
        </nav>
      </header>

      <main className="flex-1 flex flex-col">
        {/* Structural Grid Hero Section */}
        <section className="relative w-full py-24 md:py-32 lg:py-48 flex flex-col items-center justify-center text-center px-4 overflow-hidden bg-slate-50 dark:bg-background border-b">
          {/* Technical Grid Background */}
          <div className="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]"></div>
          
          <div className="max-w-[900px] space-y-8 relative z-10 animate-in fade-in slide-in-from-bottom-8 duration-700">
            <div className="inline-flex items-center rounded-full border border-border/50 px-3 py-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground bg-background shadow-sm">
              <span className="flex h-2 w-2 rounded-full bg-primary mr-2"></span>
              The Operating System for Cricket Academies
            </div>
            
            <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight text-foreground leading-[1.1]">
              Data-driven cricket. <br/>
              <span className="text-muted-foreground">Built for professionals.</span>
            </h1>
            
            <p className="text-xl text-muted-foreground max-w-[700px] mx-auto leading-relaxed">
              KnoQ combines ultra-precise IoT bat sensors with advanced AI video analysis to track bat speed, impact angles, and sweet spot percentage in real-time.
            </p>
            
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-6">
              <Link to="/login">
                <Button size="lg" className="w-full sm:w-auto text-base h-12 px-8 shadow-sm">
                  Access Dashboard <ChevronRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
              <div className="flex gap-3 w-full sm:w-auto">
                <Button size="lg" variant="outline" className="flex-1 sm:flex-none text-base h-12 px-6 bg-background">
                  <Smartphone className="mr-2 h-4 w-4" /> iOS App
                </Button>
                <Button size="lg" variant="outline" className="flex-1 sm:flex-none text-base h-12 px-6 bg-background">
                  <Smartphone className="mr-2 h-4 w-4" /> Android
                </Button>
              </div>
            </div>
          </div>
        </section>

        {/* How it Works Pipeline */}
        <section className="w-full py-24 bg-background">
          <div className="container mx-auto px-4 md:px-6">
            <div className="text-center mb-16">
              <h2 className="text-3xl font-bold tracking-tight">How KnoQ Works</h2>
              <p className="text-muted-foreground mt-2">From physical swing to digital insight in milliseconds.</p>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-12 max-w-5xl mx-auto relative">
              {/* Connecting Line (Desktop) */}
              <div className="hidden md:block absolute top-12 left-[15%] right-[15%] h-[2px] bg-border z-0"></div>
              
              {/* Step 1 */}
              <div className="flex flex-col items-center text-center space-y-4 relative z-10">
                <div className="w-24 h-24 rounded-2xl bg-slate-100 dark:bg-slate-800 border flex items-center justify-center shadow-sm">
                  <Zap className="h-10 w-10 text-foreground" />
                </div>
                <h3 className="text-xl font-bold">1. Attach Sensor</h3>
                <p className="text-muted-foreground text-sm leading-relaxed max-w-[250px]">
                  Snap our lightweight 9g IoT sensor onto any standard cricket bat. It seamlessly connects via Bluetooth.
                </p>
              </div>

              {/* Step 2 */}
              <div className="flex flex-col items-center text-center space-y-4 relative z-10">
                <div className="w-24 h-24 rounded-2xl bg-slate-100 dark:bg-slate-800 border flex items-center justify-center shadow-sm">
                  <Activity className="h-10 w-10 text-foreground" />
                </div>
                <h3 className="text-xl font-bold">2. Play & Record</h3>
                <p className="text-muted-foreground text-sm leading-relaxed max-w-[250px]">
                  Take your shots in the nets. The sensor captures 1000 data points per second during every swing.
                </p>
              </div>

              {/* Step 3 */}
              <div className="flex flex-col items-center text-center space-y-4 relative z-10">
                <div className="w-24 h-24 rounded-2xl bg-slate-100 dark:bg-slate-800 border flex items-center justify-center shadow-sm">
                  <Smartphone className="h-10 w-10 text-foreground" />
                </div>
                <h3 className="text-xl font-bold">3. Instant Analysis</h3>
                <p className="text-muted-foreground text-sm leading-relaxed max-w-[250px]">
                  View bat speed, backlift angle, and impact zones immediately on your smartphone or coach tablet.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Dual Value Proposition */}
        <section className="w-full py-24 bg-slate-50 dark:bg-slate-900/50 border-y">
          <div className="container mx-auto px-4 md:px-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 max-w-6xl mx-auto">
              
              {/* For Coaches */}
              <div className="space-y-6">
                <div className="inline-flex items-center rounded-md border px-2.5 py-0.5 text-sm font-semibold bg-background">
                  For Academies & Coaches
                </div>
                <h2 className="text-3xl font-bold tracking-tight">Scale your coaching business.</h2>
                <ul className="space-y-4">
                  <li className="flex items-start">
                    <CheckCircle2 className="mr-3 h-5 w-5 text-primary shrink-0 mt-0.5" />
                    <div>
                      <strong className="block text-foreground">Fleet Management</strong>
                      <span className="text-muted-foreground text-sm">Monitor all smart bats and active sessions across your entire academy from a single dashboard.</span>
                    </div>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle2 className="mr-3 h-5 w-5 text-primary shrink-0 mt-0.5" />
                    <div>
                      <strong className="block text-foreground">At-Risk Player Detection</strong>
                      <span className="text-muted-foreground text-sm">Automatically flag players who are struggling with specific mechanics or losing consistency over time.</span>
                    </div>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle2 className="mr-3 h-5 w-5 text-primary shrink-0 mt-0.5" />
                    <div>
                      <strong className="block text-foreground">Data-Backed Feedback</strong>
                      <span className="text-muted-foreground text-sm">Stop guessing. Show parents and players exactly how their bat speed and sweet spot accuracy is improving.</span>
                    </div>
                  </li>
                </ul>
              </div>

              {/* For Players */}
              <div className="space-y-6 lg:border-l lg:pl-16">
                <div className="inline-flex items-center rounded-md border px-2.5 py-0.5 text-sm font-semibold bg-background">
                  For Professional Players
                </div>
                <h2 className="text-3xl font-bold tracking-tight">Perfect the mechanics.</h2>
                <ul className="space-y-4">
                  <li className="flex items-start">
                    <CheckCircle2 className="mr-3 h-5 w-5 text-foreground shrink-0 mt-0.5" />
                    <div>
                      <strong className="block text-foreground">Sweet Spot Mapping</strong>
                      <span className="text-muted-foreground text-sm">A 3D heat map showing exactly where the ball impacts your bat on every single drive, cut, or pull.</span>
                    </div>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle2 className="mr-3 h-5 w-5 text-foreground shrink-0 mt-0.5" />
                    <div>
                      <strong className="block text-foreground">AI Video Tagging</strong>
                      <span className="text-muted-foreground text-sm">Upload your net session video. Our AI automatically synchronizes the video with your sensor data.</span>
                    </div>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle2 className="mr-3 h-5 w-5 text-foreground shrink-0 mt-0.5" />
                    <div>
                      <strong className="block text-foreground">Biomechanical Baselines</strong>
                      <span className="text-muted-foreground text-sm">Compare your backlift angle and follow-through metrics against international player benchmarks.</span>
                    </div>
                  </li>
                </ul>
              </div>

            </div>
          </div>
        </section>

        {/* Final CTA */}
        <section className="w-full py-24 bg-foreground text-background">
          <div className="container mx-auto px-4 text-center space-y-8 max-w-3xl">
            <h2 className="text-4xl font-bold tracking-tight">Ready to step up to the crease?</h2>
            <p className="text-lg text-slate-300">
              Join the hundreds of coaches and players already using KnoQ to bring professional-grade data analytics to their daily practice.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-4">
              <Link to="/login">
                <Button size="lg" variant="secondary" className="w-full sm:w-auto text-base h-12 px-8">
                  Open Web Dashboard
                </Button>
              </Link>
              <Button size="lg" variant="outline" className="w-full sm:w-auto text-base h-12 px-8 border-slate-600 bg-transparent text-slate-300 hover:text-white hover:bg-slate-800">
                Download Mobile App
              </Button>
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="w-full py-8 border-t bg-background">
        <div className="container mx-auto px-4 flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-sm text-muted-foreground font-medium">
            © 2026 KnoQ Analytics. All rights reserved.
          </p>
          <div className="flex gap-4 text-sm text-muted-foreground font-medium">
            <span className="hover:text-foreground cursor-pointer transition-colors">Twitter</span>
            <span className="hover:text-foreground cursor-pointer transition-colors">LinkedIn</span>
            <span className="hover:text-foreground cursor-pointer transition-colors">Support</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
