//
//  WeightViewController.swift
//  diaFit
//
//  Created by Wang,Rongrong on 4/12/17.
//  Copyright © 2017 Liang,Franky Z. All rights reserved.
//

import UIKit
import OAuthSwift
import AWSCore
import AWSLambda
import SwiftCharts
import HealthKit
import ActionSheetPicker_3_0

class WeightViewController: UIViewController{

   //36* let email = self.userDefaults.value(forKey: "email") as! String
    let lambdaInvoker = AWSLambdaInvoker.default()
    
    let userDefaults = UserDefaults.standard
    var chart: Chart?
    var weightArray =  [Int:(Int,Double)]()
    var weightArrayForTable =  [Int:(Int,String)]()
    var weightValues = [(Int,Int)]()
    var totalDays = 7
    let dm:DeviceManager = DeviceManager()
    
    @IBOutlet weak var timeSwitch: UISegmentedControl!
    override func viewDidDisappear(_ animated: Bool) {
        chart?.clearView()
        setWeightToZero()
    }
    
    func setWeightToZero() {
        weightArray.removeAll()
        weightArrayForTable.removeAll()
        weightValues.removeAll()
    }
    
    @IBAction func onSegmentedControl(_ sender: AnyObject) {
        chart?.clearView()
        setWeightToZero()
        if(timeSwitch.selectedSegmentIndex == 0) {
            DispatchQueue.main.async(execute: { () -> Void in
                self.totalDays = 7
                self.getWeight()
            })
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                self.totalDays = 30
                self.getWeight()
            })
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //barChartView.delegate = self
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
        self.getWeight()
    }
    
    
    
    func getWeight() {
        
        dm.getFitbitWeight{ (result) in
            let calendar = Calendar.current
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "yyyy-MM-dd"
              var storedValue = 0.0
            var i = self.totalDays
            while i >= 0 {
                let dateComplete = dateformatter.string(from: (calendar as NSCalendar).date(byAdding: [.day],value: -i,to: Date(),options: [])!)
                let formattedGrabbedDate = dateformatter.date(from: dateComplete)
                let components = (calendar as NSCalendar).components(.day , from: formattedGrabbedDate!)
                let dateNumber = Int(components.day!)//具体日期, started from today
                 let dictLevel1 = result as? [String: Any]
        
                
                if let dictLevel2 = dictLevel1?["weight"] as? NSArray{//weigh
                        for dictValues in dictLevel2{
                            let values = dictValues as? [String: Any]
                            let dateReturned = (values?["date"])! as! String     //date
                           if (dateReturned == dateComplete){       //only cared about the date that is in json
                            if let weight = (values?["weight"]) as? Double {//weight
                            
                                let weightPounds = Double(round(100*weight * 2.20462)/100)
                                storedValue = weightPounds
                                print(weightPounds)
                                self.weightArray[-i] = (Int(dateNumber), storedValue)
                                self.weightArrayForTable[-i] = (Int(dateNumber), String(weightPounds))

                                print(self.weightArrayForTable[-i] as Any)
                            }
                            }
                    }
                }
               if(self.weightArray[-i] == nil){
                    self.weightArray[-i] = (dateNumber, storedValue)
                }
                if(self.weightArrayForTable[-i] == nil){
                    self.weightArrayForTable[-i] = (dateNumber, " ")}
                //print(self.weightArray[-i] as Any)
                i -= 1
               // print(self.weightArrayForTable[-i] as Any)
            }
            DispatchQueue.main.async(execute: { () -> Void in
                self.displayChart()
            })
        }
    }
    
    
    func displayChart(){
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let currentMonth = dateFormatter.string(from: Date())
        let sortedArray = self.weightArray.sorted(by: { $0.0 < $1.0 })
        let chartPoints = sortedArray.map{ChartPoint(x: MyMultiLabelAxisValue(position: Double(-$0.0), label: $0.1.0 ), y: ChartAxisValueDouble($0.1.1))}
        let labelSettings = ChartLabelSettings(font: UIFont.systemFont(ofSize: 10))
        let allChartPoints = chartPoints
        let xValues: [ChartAxisValue] = (NSOrderedSet(array: allChartPoints).array as! [ChartPoint]).map{$0.x}
        let yValues = ChartAxisValuesStaticGenerator.generateYAxisValuesWithChartPoints(allChartPoints, minSegmentCount: 5, maxSegmentCount: 20, multiple: 2, axisValueGenerator: {ChartAxisValueDouble($0, labelSettings: labelSettings)}, addPaddingSegmentIfEdge: false)
        
        
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: currentMonth, settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "Your Steps", settings: labelSettings.defaultVertical()))
        let chartFrame = CGRect(x: 5, y: 100, width: screenWidth , height: screenHeight * 0.78)
        var chartSettings = ChartSettings()
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
        let (xAxis, yAxis) = (coordsSpace.xAxisLayer, coordsSpace.yAxisLayer)
        
        let lineModel = ChartLineModel( chartPoints: chartPoints, lineColor: UIColor.black, animDuration: 1, animDelay: 0)
        let chartPointsLayer = ChartPointsLineLayer<ChartPoint>(xAxis: xAxis.axis, yAxis: yAxis.axis, lineModels: [lineModel])
        
        //let chartPointsLayer = ChartPointsAreaLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, chartPoints: chartPoints, areaColor: c1, animDuration: 2, animDelay: 0, addContainerPoints: true)
        
        let chartPointsLineLayer = ChartPointsLineLayer(xAxis: xAxis.axis, yAxis: yAxis.axis, lineModels: [lineModel])
        
        let circleViewGenerator = {(chartPointModel: ChartPointLayerModel, layer: ChartPointsLayer, chart: Chart) -> UIView? in
            let circleView = ChartPointEllipseView(center: chartPointModel.screenLoc, diameter: 11)
            circleView.animDuration = 1.5
            circleView.fillColor = UIColor.white
            circleView.borderWidth = 5
            circleView.borderColor = UIColor.blue
            return circleView
        }
        let itemsDelay: Float = 0.08
        let chartPointsCircleLayer = ChartPointsViewsLayer(xAxis: xAxis.axis, yAxis: yAxis.axis, chartPoints: chartPoints, viewGenerator: circleViewGenerator, displayDelay: 0.9, delayBetweenItems: itemsDelay)
        let settings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.black, linesWidth: 0.1)
        let guidelinesLayer = ChartGuideLinesDottedLayer(xAxisLayer: xAxis, yAxisLayer: yAxis, settings: settings)
        
        let chart = Chart(
            frame: chartFrame,
            settings: chartSettings,
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
        updateWeightToAWSTable()
        
    }
    
    func  updateWeightToAWSTable(){
        let email = self.userDefaults.value(forKey: "email") as! String
        let lambdaInvoker = AWSLambdaInvoker.default()
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        var updateExpression = "set"
        var expressionAttributeNames = [String:String]()
        var expressionAttributeValues = [String:String]()
        for i in 0 ..< self.totalDays {
            updateExpression = updateExpression + " #day" + String(i) + " = :weight" + String(i) + ","
            let indexDays = "#day" + String(i)
            let indexWeight = ":weight" + String(i)
            let dateString = dateFormatter.string(from: (Calendar.current as NSCalendar).date(byAdding: .day, value: -i, to: date, options: [])!)
            expressionAttributeNames[indexDays] = dateString
            expressionAttributeValues[indexWeight] = String(self.weightArrayForTable[-i]!.1)
        }
        updateExpression = String(updateExpression.characters.dropLast())
        let jsonObject: [String: AnyObject] = [
            "TableName":  "diaFitWeight" as AnyObject,
            "operation": "update" as AnyObject ,
            "Key": ["email": email] as AnyObject,
            "UpdateExpression": updateExpression as AnyObject,
            "ExpressionAttributeNames": expressionAttributeNames as AnyObject,
            "ExpressionAttributeValues": expressionAttributeValues as AnyObject,
            "ReturnValues": "UPDATED_NEW"as AnyObject
        ]
        let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print(task.error as Any)
            } else {
                if task.result != nil {
                    print("Update weight to AWSTable!")
                } else {
                    print("Exception: \(String(describing: task.exception))")
                }
            }
            return nil
        })
    }

    fileprivate class MyMultiLabelAxisValue: ChartAxisValue {
        
        fileprivate var position: Double
        fileprivate var label: Int
        init(position: Double, label:Int) {
            self.position = position
            self.label = label
            super.init(scalar: Double(-self.position))
        }
        
        override var labels:[ChartAxisLabel] {//x axis
            return [
                ChartAxisLabel(text: "\(self.label)", settings: ChartLabelSettings(font: UIFont.systemFont(ofSize: 5), fontColor: UIColor.darkGray))
            ]
        }
    }
    
}
