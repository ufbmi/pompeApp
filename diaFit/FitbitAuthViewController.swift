//
//  FitbitAuthViewController.swift
//  diaFit
//
//  Created by Liang,Franky Z on 5/9/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import OAuthSwift
import AWSCore
import AWSLambda
import SwiftCharts


class FitbitAuthViewController: UIViewController {
    
    let userDefaults = UserDefaults.standard
    var chart: Chart?
    var stepsArray =  [Int:(Int,Int)]()
    var stepsValues = [(Int,Int)]()
    var totalDays = 7
    let deviceManager:DeviceManager = DeviceManager()
    
    @IBOutlet weak var timeSwitch: UISegmentedControl!
    override func viewDidDisappear(_ animated: Bool) {
        chart?.clearView()
        setStepstoZero()
    }
    
    func setStepstoZero() {
        stepsArray.removeAll()
        stepsValues.removeAll()
    }
    
    @IBAction func onSegmentedControl(_ sender: AnyObject) {
        chart?.clearView()
        setStepstoZero()
        if(timeSwitch.selectedSegmentIndex == 0) {
            DispatchQueue.main.async(execute: { () -> Void in
                self.totalDays = 7
                self.getSteps()
            })
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                self.totalDays = 30
                self.getSteps()
            })
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
        self.getSteps()
    }
    
    
    
    func getSteps() {
        
        deviceManager.getFitbitSteps { (result) in
            let calendar = Calendar.current
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "yyyy-MM-dd"
            for i in 0 ..< self.totalDays {
                let dateComplete = dateformatter.string(from: (calendar as NSCalendar).date(byAdding: [.day],value: -i,to: Date(),options: [])!)
                let formattedGrabbedDate = dateformatter.date(from: dateComplete)
                let components = (calendar as NSCalendar).components(.day , from: formattedGrabbedDate!)
                let dateNumber = Int(components.day!)
                    if let dictLevel1 = result as? [String: Any] {
                        if let dictLevel2 = dictLevel1["activities-steps"] as? NSArray {
                            for dictValues in dictLevel2{
                                let values = dictValues as? [String: String]
                                let dateReturned = (values?["dateTime"])! as String
                                if dateReturned == dateComplete {
                                    let steps = values?["value"]
                                    self.stepsArray[-i] = (Int(dateNumber), Int(steps!)!)
                                    break
                                }
                            }
                        }
                }
                if(self.stepsArray[-i] == nil){
                    self.stepsArray[-i] = (dateNumber, 0)
                }
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
        let sortedArray = self.stepsArray.sorted(by: { $0.0 < $1.0 })
        let chartPoints = sortedArray.map{ChartPoint(x: MyMultiLabelAxisValue(position: Int(-$0.0), label: $0.1.0 ), y: ChartAxisValueDouble($0.1.1))}
        let labelSettings   = ChartLabelSettings(font: UIFont.systemFont(ofSize: 10))
        let allChartPoints = chartPoints
        let xValues: [ChartAxisValue] = (NSOrderedSet(array: allChartPoints).array as! [ChartPoint]).map{$0.x}
        let yValues = ChartAxisValuesGenerator.generateYAxisValuesWithChartPoints(allChartPoints, minSegmentCount: 5, maxSegmentCount: 20, multiple: 2, axisValueGenerator: {ChartAxisValueDouble($0, labelSettings: labelSettings)}, addPaddingSegmentIfEdge: false)
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: currentMonth, settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "Steps", settings: labelSettings.defaultVertical()))
        let chartFrame = CGRect(x: 10, y: 100, width: screenWidth , height: screenHeight * 0.70)
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
        //saveResults()
    }
    
    func  saveResults(){
        let email = self.userDefaults.value(forKey: "email") as! String
         let lambdaInvoker = AWSLambdaInvoker.default()
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
        let jsonObject: [String: AnyObject] = [
            "TableName":  "userSteps" as AnyObject,
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
                print(task.error)
            } else {
                if task.result != nil {
                    print("Posted!")
                } else {
                    print("Exception: \(task.exception)")
                }
            }
            return nil
        })
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
    
    
}
