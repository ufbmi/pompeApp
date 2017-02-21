//
//  GlucoViewController.swift
//  diaFit
//
//  Created by Liang,Franky Z on 4/8/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import AWSCore
import AWSLambda
import SwiftCharts
import SwiftyJSON
import ActionSheetPicker_3_0
import DLRadioButton

class GlucoViewController: UIViewController {
    
    var totalDays = 7
    var dictionaryForMax = [Int:Double]()
    var glucoseArray = [Int:(Int,Double)]()
    var sortedGlucoseArray = [(Int,Double)]()
    var glucoseEnumeration: [Int] = []
    var myDictionary = Dictionary<Int, [Int:Double]>()
    let userDefaults = UserDefaults.standard
    var chart: Chart?
    var isNonFasting = Bool()
    var fastingValue = ""
    let deviceManager:DeviceManager = DeviceManager()
    @IBOutlet weak var onSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var onSubmit: UIButton!
    
    @IBOutlet weak var healthKitOption: DLRadioButton!
    @IBOutlet var nonFasting: DLRadioButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        createValues()
        nonFasting.isMultipleSelectionEnabled = true;
        // Do any additional setup after loading the view.
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        chart?.clearView()
        let hKInput = self.userDefaults.bool(forKey: "HKInput")
        if !(hKInput){
            saveHKToAWS();
        }
        setGlucoseLevelsToZero()
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        deviceManager.hKGlucoseIsEmpty { (result) in
            if(result) {
                self.getAWSGlucoseValues()
            }
            else {
                self.deviceManager.healthKitGetGlucose(self.totalDays, completionHandler: { (result) in
                    self.glucoseArray = result;
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.displayChart()
                    })
                })
            }
        }
        checkConnection()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet var sugarTextfield: UITextField!
    
    
    
    func setGlucoseLevelsToZero() {
        glucoseArray.removeAll()
        sortedGlucoseArray.removeAll()
    }
    
    @IBAction func onSegmentedControl(_ sender: AnyObject) {
        self.chart?.clearView()
        self.setGlucoseLevelsToZero()
        deviceManager.hKGlucoseIsEmpty { (result) in
            self.userDefaults.setValue(result, forKey: "HKInput")
            let hKInput = self.userDefaults.bool(forKey: "HKInput")
            if(self.onSegmentedControl.selectedSegmentIndex == 0) {
                self.totalDays = 7
                if(hKInput){
                    self.getAWSGlucoseValues()
                } else {
                    self.deviceManager.healthKitGetGlucose(self.totalDays, completionHandler: { (result) in
                        self.glucoseArray = result;
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.displayChart()
                        })
                    })
                }
            } else {
                self.totalDays = 31
                if(hKInput){
                    self.getAWSGlucoseValues()
                } else {
                    self.deviceManager.healthKitGetGlucose(self.totalDays, completionHandler: { (result) in
                        self.glucoseArray = result;
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.displayChart()
                        })
                    })
                    
                }
            }
            
        }
    }
    
    @IBAction func onNonFasting(_ sender: AnyObject) {
        if(nonFasting.isSelected) {
            self.isNonFasting = true
        } else {
            self.isNonFasting = false
        }
    }
    
    func getAWSGlucoseValues() {
        DispatchQueue.main.async(execute: { () -> Void in
            let email = self.userDefaults.value(forKey: "email") as! String
            let lambdaInvoker = AWSLambdaInvoker.default()
            let jsonSecondObject: [String: AnyObject] = [
                "operation": "read" as AnyObject,
                "TableName": "diaFitGlucose" as AnyObject,
                "Key": ["email": email] as AnyObject
            ]
            let secondTask = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonSecondObject)
            secondTask.continue(successBlock: { (task: AWSTask) -> Any? in
                if task.error != nil {
                    print(task.error)
                } else {
                    if task.result != nil {
                        do {
                            let calendar = NSCalendar.current
                            let dateFormatterTwo = DateFormatter()
                            dateFormatterTwo.dateFormat = "dd/MM/yyyy"
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd/MM/yyyy,H:mm"
                            if task.result?.count == 0 {
                                for i in 0..<self.totalDays {
                                    let emptyDate = dateFormatterTwo.string(from: calendar.date(byAdding: .day, value: -i, to: NSDate() as Date)!)
                                    let formattedEmptyDate = dateFormatterTwo.date(from: emptyDate)
                                    let componentsDay = calendar.component(.day, from: formattedEmptyDate!)
                                    let dateNumber = Int(componentsDay)
                                    self.glucoseArray[-i] = (dateNumber, 0.0)
                                }
                            }
                            else {
                                let json = task.result as! Dictionary<String, AnyObject>
                                var listOfGlucoseValues = json["Item"] as! Dictionary<String, AnyObject>
                                //getting rid of email in dictionary
                                listOfGlucoseValues.removeValue(forKey: "email")
                                let jsonOfGlucoseValues = JSON(listOfGlucoseValues)
                                for grabbedDate in jsonOfGlucoseValues {
                                    for i in 0..<self.totalDays {
                                        let loopedDate = dateFormatterTwo.string(from: calendar.date(byAdding: .day, value: -i, to: NSDate() as Date)!)
                                        if (loopedDate == grabbedDate.0) {
                                            let formattedGrabbedDate = dateFormatterTwo.date(from: grabbedDate.0)
                                            let componentsDay = calendar.component(.day, from: formattedGrabbedDate!)
                                            let dateNumber = Int(componentsDay)
                                            self.glucoseArray[-i] = (dateNumber, grabbedDate.1.doubleValue)
                                        }
                                        else {
                                            let emptyDate = dateFormatterTwo.string(from: calendar.date(byAdding: .day, value: -i, to: NSDate() as Date)!)
                                            let formattedEmptyDate = dateFormatterTwo.date(from: emptyDate)
                                            let componentsDay = calendar.component(.day, from: formattedEmptyDate!)
                                            let dateNumber = Int(componentsDay)
                                            if (self.glucoseArray[-i] == nil) {
                                                self.glucoseArray[-i] = (dateNumber, 0.0)
                                            }
                                        }
                                  }
                                    
                                }
                            }
                            DispatchQueue.main.async {
                                self.displayChart()
                            }
                        }
                    }
                }
                return nil
            })
        })
    }
    
    func displayChart() {
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let currentMonth = dateFormatter.string(from: Date())
        let sortedArray = self.glucoseArray.sorted(by: { $0.0 < $1.0 })
        let chartPoints = sortedArray.map{ChartPoint(x: MyMultiLabelAxisValue(position: Int(-$0.0), label: $0.1.0 ), y: ChartAxisValueDouble($0.1.1))}
        let labelSettings   = ChartLabelSettings(font: UIFont.systemFont(ofSize: 10))
        let allChartPoints = chartPoints
        let xValues: [ChartAxisValue] = (NSOrderedSet(array: allChartPoints).array as! [ChartPoint]).map{$0.x}
        let yValues = ChartAxisValuesGenerator.generateYAxisValuesWithChartPoints(allChartPoints, minSegmentCount: 5, maxSegmentCount: 20, multiple: 2, axisValueGenerator: {ChartAxisValueDouble($0, labelSettings: labelSettings)}, addPaddingSegmentIfEdge: false)
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: currentMonth, settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "Glucose Level", settings: labelSettings.defaultVertical()))
        let chartFrame = CGRect(x: 10, y: 100, width: screenWidth , height: screenHeight * 0.70)
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
    
    
    func createValues() {
        for i in 1...500 {
            glucoseEnumeration.append(i)
        }
        
    }
    
    
    @IBAction func onSubmitButton(_ sender: AnyObject) {
        DispatchQueue.main.async {
            self.chart?.clearView()
            self.setGlucoseLevelsToZero()
        }
        let email = self.userDefaults.value(forKey: "email") as! String
        if isNonFasting == true {
            self.fastingValue = "_NoFasting"
        } else {
            self.fastingValue = ""
        }
        let sugarLevel: String = onSubmit.titleLabel!.text!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let currentDate =  dateFormatter.string(from: Date())
        let lambdaInvoker = AWSLambdaInvoker.default()
        let jsonObject: [String: AnyObject] = [
            "TableName":  "diaFitGlucose" as AnyObject,
            "operation": "update" as AnyObject ,
            "Key": ["email": email] as AnyObject,
            "UpdateExpression": "set #date = :sugar" as AnyObject,
            "ExpressionAttributeValues" :
                [
                    ":sugar" : sugarLevel,
            ] as AnyObject,
            "ExpressionAttributeNames": [
                "#date": currentDate + fastingValue
            ] as AnyObject,
            "ReturnValues": "UPDATED_NEW" as AnyObject
        ]
        let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print(task.error)
            } else {
                if task.result != nil {
                    let record = UIAlertController(title: "Done", message: "Your glucose measurement is recorded.", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                        record.dismiss(animated: true, completion: nil)
                    })
                    record.addAction(OKAction)
                    DispatchQueue.main.async {
                        self.onSubmit.setTitle("Enter Glucose Value...", for: UIControlState.normal)
                        let hKInput = self.userDefaults.bool(forKey: "HKInput")
                        if(hKInput){
                            self.getAWSGlucoseValues()
                        } else {
                            self.deviceManager.healthKitGetGlucose(self.totalDays, completionHandler: { (result) in
                                self.glucoseArray = result;
                                DispatchQueue.main.async {
                                    self.displayChart()
                                }
                            })
                            
                        }
                        self.present(record, animated: true, completion: nil);
                    }
                } else {
                    print("Exception: \(task.exception)")
                }
            }
            return nil
        })
    }
    
    
    @IBAction func submitSugar(_ sender: AnyObject) {
        
        ActionSheetMultipleStringPicker.show(withTitle: "Enter Glucose Value", rows: [
            glucoseEnumeration,
            
            ], initialSelection: [200], doneBlock: {
                picker, values, indexes in
                let arrayRows = indexes as! NSArray
                self.onSubmit.setTitle((arrayRows[0] as AnyObject).stringValue, for: UIControlState())
                return
            }, cancel: { ActionMultipleStringCancelBlock in return }, origin: onSubmit)
    }
    
    func saveHKToAWS(){
        let email = self.userDefaults.value(forKey: "email") as! String
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        var updateExpression = "set"
        var expressionAttributeNames = [String:String]()
        var expressionAttributeValues = [String:String]()
        for i in 0 ..< self.totalDays {
            if ( String(Int(self.glucoseArray[-i]!.1)) != "0" ) {
                updateExpression = updateExpression + " #day" + String(i) + " = :glucose" + String(i) + ","
                let indexDays = "#day" + String(i)
                let indexSteps = ":glucose" + String(i)
                let dateString = dateFormatter.string(from: (Calendar.current as NSCalendar).date(byAdding: .day, value: -i, to: date, options: [])!) + "_HK"
                expressionAttributeNames[indexDays] = dateString
                expressionAttributeValues[indexSteps] = String(Int(self.glucoseArray[-i]!.1))
            }
        }
        updateExpression = String(updateExpression.characters.dropLast())
        if(!expressionAttributeNames.isEmpty) {
            let lambdaInvoker = AWSLambdaInvoker.default()
            let jsonObject: [String: AnyObject] = [
                "TableName":  "diaFitGlucose" as AnyObject,
                "operation": "update" as AnyObject ,
                "Key": ["email": email] as AnyObject,
                "UpdateExpression": updateExpression as AnyObject,
                "ExpressionAttributeNames": expressionAttributeNames as AnyObject,
                "ExpressionAttributeValues": expressionAttributeValues as AnyObject,
                "ReturnValues": "UPDATED_NEW" as AnyObject
            ]
            let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
            task.continue(successBlock: { (task: AWSTask) -> Any? in
                if task.error != nil {
                    print(task.error)
                } else {
                    if task.result != nil {
                        print("Posted HK Values!")
                    } else {
                        print("Exception: \(task.exception)")
                    }
                }
                return nil
            })
        }
        
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
