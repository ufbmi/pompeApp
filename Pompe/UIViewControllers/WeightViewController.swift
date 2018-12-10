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

    @IBOutlet var viewChart: UIView!

   //36* let email = self.userDefaults.value(forKey: "email") as! String
    let lambdaInvoker = AWSLambdaInvoker.default()
    
    fileprivate var chart: Chart? // arc
    fileprivate var popups: [UIView] = []
    
    let userDefaults = UserDefaults.standard
//    var chart: Chart?
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
        
        //Add Navigation Button
        let barBtnNavigation : UIBarButtonItem = UIBarButtonItem.init(image: #imageLiteral(resourceName: "navIcon"), style: .plain, target: navigationDrawerController(), action: #selector(NavigationDrawerController.toggleDrawer))
        barBtnNavigation.tintColor = UIColor(red: 0.3, green: 0.7, blue: 0, alpha: 0.5)
        self.navigationItem.leftBarButtonItem = barBtnNavigation
        self.navigationItem.title = "Weight Log"

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
    
    //Pulkit Rohilla

    func displayChart(){
        
        let labelFont = UIFont.systemFont(ofSize: 10)
        let labelSettings = ChartLabelSettings(font: labelFont)
        
        let sortedArray = self.weightArray.sorted(by: { $0.0 < $1.0 })
        
        let chartPoints = sortedArray.map{ChartPoint(x: MyMultiLabelAxisValue(position: Double(-$0.0), label: $0.1.0 ), y: ChartAxisValueDouble($0.1.1))}
        
        let allChartPoints = (chartPoints).sorted {(obj1, obj2) in return obj1.x.scalar < obj2.x.scalar}
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let currentMonth = dateFormatter.string(from: Date())
        
        let xValues: [ChartAxisValue] = (NSOrderedSet(array: allChartPoints).array as! [ChartPoint]).map{$0.x}
        let yValues = ChartAxisValuesStaticGenerator.generateYAxisValuesWithChartPoints(allChartPoints, minSegmentCount: 5, maxSegmentCount: 20, multiple: 5, axisValueGenerator: {ChartAxisValueDouble($0, labelSettings: labelSettings)}, addPaddingSegmentIfEdge: false)
        
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: currentMonth, settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "Your Weight", settings: labelSettings.defaultVertical()))
        let chartFrame = self.chartFrame(viewChart.bounds)
        
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
        chartSettings.labelsSpacing = 0
        chartSettings.zoomPan.panEnabled = true
        chartSettings.zoomPan.zoomEnabled = true
        
        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        let (xAxisLayer, yAxisLayer, innerFrame) = (coordsSpace.xAxisLayer, coordsSpace.yAxisLayer, coordsSpace.chartInnerFrame)
        
        let c1 = UIColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 0.7)
        
        let lineModel = ChartLineModel(chartPoints: chartPoints, lineColor: UIColor.black, animDuration: 1, animDelay: 0)
        
        let chartPointsLineLayer = ChartPointsLineLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, lineModels: [lineModel], pathGenerator: StraightLinePathGenerator())
        
        let chartPointsLayer = ChartPointsAreaLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, chartPoints: chartPoints, areaColors: [c1], animDuration: 3, animDelay: 0, addContainerPoints: true, pathGenerator: chartPointsLineLayer.pathGenerator)
        
        let circleViewGenerator = {[weak self] (chartPointModel: ChartPointLayerModel, layer: ChartPointsLayer, chart: Chart) -> UIView? in guard self != nil else {return nil}
            
            let circleView = ChartPointEllipseView(center: chartPointModel.screenLoc, diameter: 15)
            circleView.animDuration = 1.5
            circleView.fillColor = UIColor.white
            circleView.borderWidth = 5
            circleView.borderColor = UIColor.blue
            return circleView
        }
        
        let itemsDelay: Float = 0.08
        
        // To not have circles clipped by the chart bounds, pass clipViews: false (and ChartSettings.customClipRect in case you want to clip them by other bounds)
        let chartPointsCircleLayer = ChartPointsViewsLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, chartPoints: chartPoints, viewGenerator: circleViewGenerator, displayDelay: 0.9, delayBetweenItems: itemsDelay, mode: .translate)
        
        
        let settings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.black, linesWidth: 1.0)
        let guidelinesLayer = ChartGuideLinesDottedLayer(xAxisLayer: xAxisLayer, yAxisLayer: yAxisLayer, settings: settings)
        
        let chart = Chart(
            frame: chartFrame,
            innerFrame: innerFrame,
            settings: chartSettings,
            layers: [
                xAxisLayer,
                yAxisLayer,
                guidelinesLayer,
                chartPointsLayer,
                chartPointsLineLayer,
                chartPointsCircleLayer
            ]
        )
        
        viewChart.addSubview(chart.view)
        self.chart = chart
        
        updateWeightToAWSTable()
    }
    
    func chartFrame(_ containerBounds: CGRect) -> CGRect {
        return CGRect(x: 0, y: 0, width: containerBounds.size.width, height: containerBounds.size.height)
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
