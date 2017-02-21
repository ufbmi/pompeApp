import UIKit
import HealthKit
import SwiftCharts
import AWSCore
import AWSLambda

class StepsViewController: UIViewController {
    
    
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    let healthManager:HealthManager = HealthManager()
    var steps: HKQuantitySample?
    var height: HKQuantitySample?
    var age: Int?
    var weight: HKQuantitySample?
    var totalDays = 8
    var stepsArray =  [Int:(Int,Double)]()
    var stepsValues = [(Int,Int)]()
    @IBOutlet weak var onSegmentedControl: UISegmentedControl!
    
    
    var chart: Chart?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                authorizeHealthKit()
        // Do any additional setup after loading the view.
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        chart?.clearView()
        setStepstoZero()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setSteps()
        checkConnection()
        
    }
    @IBAction func onBack(_ sender: AnyObject) {
        let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
        let Menu = storyBoard.instantiateViewController(withIdentifier: "MenuNavigation")
        present(Menu, animated: true, completion: nil)
        
    }
    
    func setStepstoZero() {
        stepsArray.removeAll()
        stepsValues.removeAll()
    }
    
    
    func authorizeHealthKit() {
        healthManager.authorizeHealthKit { (authorized,  error) -> Void in
            if authorized {
                print("Authorized to HealthKit")
            } else {
                
                if error != nil {
                    print(error)
                }
            }
        }
    }
    
    @IBAction func onSegmentedControl(_ sender: AnyObject) {
        chart?.clearView()
        setStepstoZero()
        if(onSegmentedControl.selectedSegmentIndex == 0) {
            DispatchQueue.main.async(execute: { () -> Void in
                self.totalDays = 7
                self.setSteps()
            })
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                self.totalDays = 31
                self.setSteps()
            })
        }
    }


    
    func setSteps() {
        let formatter  = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.full
        let stepSample = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        self.healthManager.getSteps(stepSample!) { (stepCounts, error) -> Void in
            if( error != nil ) {
                //print("Error: \(error.localizedDescription)")
                return
            }
            //set a sample for each day of the current day and the past seven days
            let calendar = Calendar.current
            for stepCount in stepCounts {
                self.steps = stepCount as? HKQuantitySample
                let tempStepCount = stepCount as? HKQuantitySample
                let startDate = formatter.string(from: (tempStepCount?.startDate)!)
                let calendar = Calendar.current
                let dateFormatterTwo = DateFormatter()
                dateFormatterTwo.dateFormat = "M/dd/yyyy"
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "M/dd/yyyy,H:mm"
                for i in 0 ..< self.totalDays {
                    if(formatter.string(from: (calendar as NSCalendar).date(byAdding: [.day],value: -i,to: Date(),options: [])!) == startDate){
                        if (self.stepsArray.index(forKey: -i) != nil){
                            let currentDate = dateFormatterTwo.string(from: (calendar as NSCalendar).date(byAdding: .day
                                , value: -i, to: Date(), options: [])!)
                            let formattedGrabbedDate = dateFormatterTwo.date(from: currentDate)
                            let components = (calendar as NSCalendar).components(.day , from: formattedGrabbedDate!)
                            let dateNumber = Int(components.day!)
                            let addedSteps = self.stepsArray[-i]!.1  + tempStepCount!.quantity.doubleValue(for: HKUnit.count())
                            self.stepsArray[-i] = (dateNumber, addedSteps)
                        }
                        else {
                            let currentDate = dateFormatterTwo.string(from: (calendar as NSCalendar).date(byAdding: .day
                                , value: -i, to: Date(), options: [])!)
                            let formattedGrabbedDate = dateFormatterTwo.date(from: currentDate)
                            let components = (calendar as NSCalendar).components(.day , from: formattedGrabbedDate!)
                            let dateNumber = Int(components.day!)
                            self.stepsArray[-i] =  (dateNumber, tempStepCount!.quantity.doubleValue(for: HKUnit.count()))
                        }
                    }
                    else {
                        if(self.stepsArray[-i] == nil){
                            let emptyDate = dateFormatterTwo.string(from: (calendar as NSCalendar).date(byAdding: .day, value: (-i), to: Date(), options: [])!)
                            let formattedEmptyDate = dateFormatterTwo.date(from: emptyDate)
                            let components = (calendar as NSCalendar).components(.day , from: formattedEmptyDate!)
                            let dateNumber = Int(components.day!)
                            if (self.stepsArray[-i] == nil) {
                                self.stepsArray[-i] = (dateNumber, 0.0)
                            }
                        }
                    }
                }
            }
            if self.stepsArray.isEmpty {
                for i in 0 ..< self.totalDays {
                    let dateFormatterTwo = DateFormatter()
                    dateFormatterTwo.dateFormat = "M/dd/yyyy"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "M/dd/yyyy,H:mm"
                    let emptyDate = dateFormatterTwo.string(from: (calendar as NSCalendar).date(byAdding: .day, value: (-i), to: Date(), options: [])!)
                    let formattedEmptyDate = dateFormatterTwo.date(from: emptyDate)
                    let components = (calendar as NSCalendar).components(.day , from: formattedEmptyDate!)
                    let dateNumber = Int(components.day!)
                    self.stepsArray[-i] =  (dateNumber,0.0)
                }
            }
            DispatchQueue.main.async(execute: { () -> Void in
                self.saveToAWS()
                self.displayChart()
            })
            
        }
    }
    
    func displayChart() {
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let currentMonth = dateFormatter.string(from: Date())
        let sortedArray = self.stepsArray.sorted(by: { $0.0 < $1.0 })
        let chartPoints = sortedArray.map{ChartPoint(x: MyMultiLabelAxisValue(position: -$0.0, label: $0.1.0 ), y: ChartAxisValueDouble($0.1.1))}
        let labelSettings   = ChartLabelSettings(font: UIFont.systemFont(ofSize: 10))
        let allChartPoints = chartPoints
        let xValues: [ChartAxisValue] = (NSOrderedSet(array: allChartPoints).array as! [ChartPoint]).map{$0.x}
        let yValues = ChartAxisValuesGenerator.generateYAxisValuesWithChartPoints(allChartPoints, minSegmentCount: 5, maxSegmentCount: 20, multiple: 2, axisValueGenerator: {ChartAxisValueDouble($0, labelSettings: labelSettings)}, addPaddingSegmentIfEdge: false)
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: currentMonth, settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "Steps", settings: labelSettings.defaultVertical()))
        let chartFrame = CGRect(x: 10, y: 100, width: screenWidth , height: screenHeight * 0.80)
        let chartSettings = ChartSettings()
        chartSettings.leading = 10
        chartSettings.top = 10
        chartSettings.trailing = 10
        chartSettings.bottom = 10
        chartSettings.labelsToAxisSpacingX = 5
        chartSettings.labelsToAxisSpacingY = 5
        chartSettings.axisTitleLabelsToLabelsSpacing = 4
        chartSettings.axisStrokeWidth = 0.2
        chartSettings.spacingBetweenAxesX = 8
        chartSettings.spacingBetweenAxesY = 8
        chartSettings.trailing = 20
        
        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        let (xAxis, yAxis, innerFrame) = (coordsSpace.xAxis, coordsSpace.yAxis, coordsSpace.chartInnerFrame)
        let c1 = UIColor(red: 0.1, green: 0.1, blue: 0.9, alpha: 0.4)
        let chartPointsLayer = ChartPointsAreaLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, chartPoints: chartPoints, areaColor: c1, animDuration: 2, animDelay: 0, addContainerPoints: true)
        let lineModel = ChartLineModel( chartPoints: chartPoints, lineColor: UIColor.black, animDuration: 1, animDelay: 0)
        let chartPointsLineLayer = ChartPointsLineLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, lineModels: [lineModel])
        
        let circleViewGenerator = {(chartPointModel: ChartPointLayerModel, layer: ChartPointsLayer, chart: Chart) -> UIView? in
            let circleView = ChartPointEllipseView(center: chartPointModel.screenLoc, diameter: 11)
            circleView.animDuration = 1.5
            circleView.fillColor = UIColor.white
            circleView.borderWidth = 5
            circleView.borderColor = UIColor.blue
            return circleView
        }
        
        let itemsDelay: Float = 0.08
        let chartPointsCircleLayer = ChartPointsViewsLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, chartPoints: chartPoints, viewGenerator: circleViewGenerator, displayDelay: 0.9, delayBetweenItems: itemsDelay)
        let settings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.black, linesWidth: 0.1)
        let guidelinesLayer = ChartGuideLinesDottedLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, settings: settings)
        
        let chart = Chart(
            frame: chartFrame,
            layers: [
                xAxis,
                yAxis,
                guidelinesLayer,
                chartPointsLineLayer,
                chartPointsCircleLayer,
                chartPointsLayer
            ]
        )
        self.view.addSubview(chart.view)
        self.chart = chart
    }


    
    
    func saveToAWS(){
        //AWS
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        var updateExpression = "set"
        var expressionAttributeNames = [String:String]()
        var expressionAttributeValues = [String:String]()
        for i in 0 ..< self.totalDays {
            updateExpression = updateExpression + " #day" + String(i) + " = :steps" + String(i) + ","
            let indexDays = "#day" + String(i)
            let indexSteps = ":steps" + String(i)
            let dateString = dateFormatter.string(from: (Calendar.current as NSCalendar).date(byAdding: .day, value: -i, to: date, options: [])!)
            expressionAttributeNames[indexDays] = dateString
            expressionAttributeValues[indexSteps] = String(Int(self.stepsArray[-i]!.1))
        }
        updateExpression = String(updateExpression.characters.dropLast())
        let lambdaInvoker = AWSLambdaInvoker.default()
        let jsonObject: [String: AnyObject] = [
            "TableName":  "userSteps" as AnyObject,
            "operation": "update" as AnyObject ,
            "Key": ["email": "el_tona@hotmail.com"]  as AnyObject,
            "UpdateExpression": updateExpression as AnyObject,
            "ExpressionAttributeNames": expressionAttributeNames as AnyObject,
            "ExpressionAttributeValues": expressionAttributeValues as AnyObject,
            "ReturnValues": "UPDATED_NEW" as AnyObject
        ]
        let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                //print(task.error)
            } else {
                if task.result != nil {
                    //print(task.result)
                    print("Posted!")
                } else {
                    //print("Exception: \(task.exception)")
                }
            }
            return nil
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    fileprivate class MyMultiLabelAxisValue: ChartAxisValue {
        
        fileprivate var position: Int
        fileprivate var label: Int
        
        init(position: Int, label:Int) {
            self.position = position
            self.label = label
            super.init(scalar: Double(-self.position))
        }
        
        
        override var labels:[ChartAxisLabel] {
            return [
                ChartAxisLabel(text: "\(self.label)", settings: ChartLabelSettings(font: UIFont.systemFont(ofSize: 5), fontColor: UIColor.purple))
            ]
        }
    }

    
    
    
    /*
     // MARK: - Navigation
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
