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
    
    @IBOutlet var viewChart: UIView!

    let userDefaults = UserDefaults.standard
    var chart: Chart?
    var stepsArray =  [Int:(Int,Int)]()
    var stepsValues = [(Int,Int)]()
    var totalDays = 7
    let deviceManager:DeviceManager = DeviceManager()
    
    @IBOutlet weak var timeSwitch: UISegmentedControl!
  
    //MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add Navigation Button
        let barBtnNavigation : UIBarButtonItem = UIBarButtonItem.init(image: #imageLiteral(resourceName: "navIcon"), style: .plain, target: navigationDrawerController(), action: #selector(NavigationDrawerController.toggleDrawer))
        barBtnNavigation.tintColor = UIColor(red: 0.3, green: 0.7, blue: 0, alpha: 0.5)
        
        self.navigationItem.leftBarButtonItem = barBtnNavigation
        self.navigationItem.title = "FitBit Log"
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
        getSteps()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        chart?.clearView()
        setStepstoZero()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: UISegmentedControl
    
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
    
    func setStepstoZero() {
        stepsArray.removeAll()
        stepsValues.removeAll()
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
                    if let dictLevel1 = result as? [String: Any] {  //json
                        if let dictLevel2 = dictLevel1["activities-steps"] as? NSArray {//days
                            for dictValues in dictLevel2{//for eachday
                                let values = dictValues as? [String: String]
                                let dateReturned = (values?["dateTime"])! as String     //get steps for each day
                                if dateReturned == dateComplete {
                                    let steps = values?["value"]
                                    self.stepsArray[-i] = (Int(dateNumber), Int(steps!)!)
                                    //print(self.stepsArray[-i] as Any)
                                    break
                                }
                            }
                        }
                }
               //if(self.stepsArray[-i] == nil){
                   //self.stepsArray[-i] = (dateNumber, 0)}
                print(self.stepsArray[-i] as Any)
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                self.displayChart()
                self.updateStepstToAWSTable()
            })
        }
    }
    
    func displayChart(){
        
        let labelFont = UIFont.systemFont(ofSize: 10)
        let labelSettings = ChartLabelSettings(font: labelFont)
        
        let sortedArray = self.stepsArray.sorted(by: { $0.0 < $1.0 })
        
        let chartPoints = sortedArray.map{ChartPoint(x: MyMultiLabelAxisValue(position: Int(-$0.0), label: $0.1.0 ), y: ChartAxisValueDouble($0.1.1))}

        let allChartPoints = (chartPoints).sorted {(obj1, obj2) in return obj1.x.scalar < obj2.x.scalar}
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let currentMonth = dateFormatter.string(from: Date())
        
        let xValues: [ChartAxisValue] = (NSOrderedSet(array: allChartPoints).array as! [ChartPoint]).map{$0.x}
        let yValues = ChartAxisValuesStaticGenerator.generateYAxisValuesWithChartPoints(allChartPoints, minSegmentCount: 5, maxSegmentCount: 20, multiple: 5, axisValueGenerator: {ChartAxisValueDouble($0, labelSettings: labelSettings)}, addPaddingSegmentIfEdge: false)
        
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: currentMonth, settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "Steps", settings: labelSettings.defaultVertical()))
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
    }
    
    func chartFrame(_ containerBounds: CGRect) -> CGRect {
        return CGRect(x: 0, y: 0, width: containerBounds.size.width, height: containerBounds.size.height)
    }
    
    func  updateStepstToAWSTable(){
        
        let email = self.userDefaults.value(forKey: "email") as! String
        let lambdaInvoker = AWSLambdaInvoker.default()
        //AWS
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        var updateExpression = "set"
        var expressionAttributeNames = [String:String]()
        var expressionAttributeValues = [String:String]()
        for i in 0 ..< self.totalDays {
            updateExpression = updateExpression + " #day" + String(i) + " = :steps" + String(i) + ","
            let indexDays = "#day" + String(i)
            let indexSteps = ":steps" + String(i)
            let dateString = dateFormatter.string(from: (Calendar.current as NSCalendar).date(byAdding: .day, value: -i, to: date, options: [])!)
            expressionAttributeNames[indexDays] = dateString
            if i < stepsArray.count {
                
               expressionAttributeValues[indexSteps] = String(Int(self.stepsArray[-i]!.1))
            }
            else
            {
                expressionAttributeValues[indexSteps] = "0";
            }
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
                print(task.error as Any)
            } else {
                if task.result != nil {
                    print("Updated the AWS steps table!")
                } else {
                    print("Exception: \(String(describing: task.exception))")
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
        
        override var labels:[ChartAxisLabel] {//x axis
            return [
                ChartAxisLabel(text: "\(self.label)", settings: ChartLabelSettings(font: UIFont.systemFont(ofSize: 5), fontColor: UIColor.darkGray))
            ]
        }
    }

}
