import { DataCollectionOverview } from "../components/ai-lab/DataCollectionOverview"
import { ClipBrowser } from "../components/ai-lab/ClipBrowser"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../components/ui/tabs"
import { Button } from "../components/ui/button"
import { Download, UploadCloud, BrainCircuit } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../components/ui/card"

export default function AILab() {
  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">AI Lab</h1>
          <p className="text-muted-foreground">
            Manage data collection, clip tagging, and AI model training pipelines.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm">
            <Download className="mr-2 h-4 w-4" />
            Export Training Data
          </Button>
          <Button size="sm">
            <UploadCloud className="mr-2 h-4 w-4" />
            Deploy Model
          </Button>
        </div>
      </div>

      <Tabs defaultValue="collection" className="w-full">
        <TabsList className="grid w-full grid-cols-3 max-w-[400px]">
          <TabsTrigger value="collection">Data Collection</TabsTrigger>
          <TabsTrigger value="tagging">Clip Tagging</TabsTrigger>
          <TabsTrigger value="models">Models</TabsTrigger>
        </TabsList>
        
        <TabsContent value="collection" className="mt-6 space-y-6">
          <DataCollectionOverview />
        </TabsContent>
        
        <TabsContent value="tagging" className="mt-6 space-y-6">
          <div className="bg-muted/30 p-4 rounded-lg border flex items-center justify-between">
            <div>
              <h3 className="font-semibold flex items-center gap-2">
                <BrainCircuit className="h-4 w-4 text-primary" />
                Tagging Queue
              </h3>
              <p className="text-sm text-muted-foreground">You have 14 untagged clips assigned to you.</p>
            </div>
            <Button>Start Tagging Queue</Button>
          </div>
          <ClipBrowser />
        </TabsContent>
        
        <TabsContent value="models" className="mt-6 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Model Management</CardTitle>
              <CardDescription>View deployed models and performance metrics.</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex flex-col items-center justify-center py-12 text-center border-2 border-dashed rounded-lg">
                <BrainCircuit className="h-12 w-12 text-muted-foreground mb-4" />
                <h3 className="text-lg font-semibold">No Models Deployed Yet</h3>
                <p className="text-sm text-muted-foreground max-w-md mt-2">
                  You need to tag more data before training the first V2 ML model. 
                  Target at least 500 tagged clips across various shot types.
                </p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
