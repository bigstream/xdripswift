//
//  LandscapeChartViewController.swift
//  xdrip
//
//  Created by Paul Plant on 16/9/21.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class LandscapeChartViewController: UIViewController {

    @IBOutlet weak var landscapeChartOutlet: BloodGlucoseChartView!
    
    @IBOutlet weak var inRangeTitleLabelOutlet: UILabel!
    @IBOutlet weak var inRangeLabelOutlet: UILabel!
    
    @IBOutlet weak var averageTitleLabelOutlet: UILabel!
    @IBOutlet weak var averageLabelOutlet: UILabel!
    
    @IBOutlet weak var cvTitleLabelOutlet: UILabel!
    @IBOutlet weak var cvLabelOutlet: UILabel!
    
    @IBOutlet weak var activityIndicatorOutlet: UIActivityIndicatorView!
    
    @IBOutlet weak var dateLabelOutlet: UILabel!
    
    @IBAction func backButtonPressed(_ sender: Any) {
        
        // remove one day from the selectedDate
        var newDateToUse: Date {
            var components = DateComponents()
            components.day = -1
            return Calendar.current.date(byAdding: components, to: selectedDate)!
        }
        
        selectedDate = newDateToUse
        
        updateChartAndLabels()
        
    }
    
    @IBAction func forwardButtonPressed(_ sender: Any) {
        
        // add one day to the selectedDate
        var newDateToUse: Date {
            var components = DateComponents()
            components.day = +1
            return Calendar.current.date(byAdding: components, to: selectedDate)!
        }
        
        selectedDate = newDateToUse
        
        updateChartAndLabels()
        
    }
    
    
    // MARK: private variables
    
    /// glucoseChartManager
    private var glucoseChartManager: GlucoseChartManager?
    
    /// coreDataManager to be used throughout the project
    private var coreDataManager: CoreDataManager?
    
    /// statisticsManager needed to calculate the stats
    private var statisticsManager: StatisticsManager?
    
    /// date that will be used to show the 24 hour chart. Initialise it for today.
    private var selectedDate: Date = Date()
    
    private let dateFormatter: DateFormatter = {
        
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = ConstantsGlucoseChart.dateFormatLandscapeChart
        
        return dateFormatter
        
    }()
    
    
    // MARK: overriden functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Core Data Manager - setting up coreDataManager happens asynchronously
        // completion handler is called when finished. This gives the app time to already continue setup which is independent of coredata, like initializing the views
        coreDataManager = CoreDataManager(modelName: ConstantsCoreData.modelName, completion: {
            
            // if coreDataManager is nil then there's no reason to continue
            guard self.coreDataManager != nil else {
                return
            }
            
            self.updateChartAndLabels()
            
        })
        
        // initialize glucoseChartManager
        glucoseChartManager = GlucoseChartManager(coreDataManager: coreDataManager!)
        
        
        // initialize chartGenerator in chartOutlet
        self.landscapeChartOutlet.chartGenerator = { [weak self] (frame) in
            return self?.glucoseChartManager?.glucoseChartWithFrame(frame)?.view
        }
        
        // set the title labels to their correct localization
        self.inRangeTitleLabelOutlet.text = Texts_Common.inRangeStatistics
        self.averageTitleLabelOutlet.text = Texts_Common.averageStatistics
        self.cvTitleLabelOutlet.text = Texts_Common.cvStatistics
            
        updateChartAndLabels()
        
    }
    
    // this function should do the following:
    // - show the currently selected date
    // - clear the text values in the statistics
    // - activate the activity indicator whilst we display the chart and calculate the statistics
    // - update the chart points
    // - call the StatisticsManager and wait for the results to be finished
    // - update the label outlets
    // - disable/enable buttons if no more readings are available before or after the selected date
    private func updateChartAndLabels() {
        
        // set the selected date outlet
        dateLabelOutlet.text = dateFormatter.string(from: selectedDate)
        
        // we need to define the start and end times of the day that has been selected
        let startOfDay = Calendar(identifier: .gregorian).startOfDay(for: selectedDate)
        
        var components = DateComponents()
        components.day = 1
        components.second = -1
        let endOfDay = Calendar.current.date(byAdding: components, to: startOfDay)!
        
        // update the chart
        glucoseChartManager?.updateChartPoints(endDate: endOfDay, startDate: startOfDay, chartOutlet: landscapeChartOutlet, completionHandler: nil)
        
        updateStatistics()
        
        
    }

    
    // helper function to calculate the statistics and update the pie chart and label outlets
    private func updateStatistics() {
        
        // don't calculate statis if app is not running in the foreground
        guard UIApplication.shared.applicationState == .active else {return}
        
        
        // declare constants/variables
        let isMgDl: Bool = UserDefaults.standard.bloodGlucoseUnitIsMgDl
        
        let startOfDay = Calendar(identifier: .gregorian).startOfDay(for: selectedDate)
        
        var components = DateComponents()
        components.day = 1
        components.second = -1
        let endOfDay = Calendar.current.date(byAdding: components, to: startOfDay)!
        
        // blank out the statistics and show the activity indicator
        inRangeLabelOutlet.text = "-"
        averageLabelOutlet.text = "-"
        cvLabelOutlet.text = "-"
        activityIndicatorOutlet.isHidden = false
        
        // statisticsManager will calculate the statistics in background thread and call the callback function in the main thread
        statisticsManager?.calculateStatistics(fromDate: startOfDay, toDate: endOfDay, callback: { statistics in
            
            self.inRangeLabelOutlet.text = Int(statistics.inRangeStatisticValue.round(toDecimalPlaces: 0)).description + "%"
        
            // if there are no values returned (new sensor?) then just leave the default "-" showing
            if statistics.averageStatisticValue.value > 0 {
                self.averageLabelOutlet.text = (isMgDl ? Int(statistics.averageStatisticValue.round(toDecimalPlaces: 0)).description : statistics.averageStatisticValue.round(toDecimalPlaces: 1).description) + (isMgDl ? " mg/dl" : " mmol/l")
            }
            
            
            // if there are no values returned (new sensor?) then just leave the default "-" showing
            if statistics.cVStatisticValue.value > 0 {
                self.cvLabelOutlet.text = Int(statistics.cVStatisticValue.round(toDecimalPlaces: 0)).description + "%"
            }
            
            // calculations are done so let's hide the activity indicator again
            self.activityIndicatorOutlet.isHidden = true
            
        })
    }
    
}
