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
    
    @IBOutlet weak var dateLabelOutlet: UILabel!
    
    @IBOutlet weak var inRangeLabelOutlet: UILabel!
    
    @IBOutlet weak var averageLabelOutlet: UILabel!
    
    @IBOutlet weak var cvLabelOutlet: UILabel!
    
    @IBOutlet weak var activityIndicatorOutlet: UIActivityIndicatorView!
    
    // glucoseChartManager - we'll use the Static class as there are no gestures needed
    private var glucoseChartManager: GlucoseChartManagerStatic?
    
    /// coreDataManager to be used throughout the project
    private var coreDataManager:CoreDataManager?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Core Data Manager - setting up coreDataManager happens asynchronously
        // completion handler is called when finished. This gives the app time to already continue setup which is independent of coredata, like initializing the views
        coreDataManager = CoreDataManager(modelName: ConstantsCoreData.modelName, completion: {
            
            
            // if coreDataManager is nil then there's no reason to continue
            guard self.coreDataManager != nil else {
                return
            }
            
            self.updateChart()
            
        })
        
        // initialize glucoseChartManager
        glucoseChartManager = GlucoseChartManagerStatic(coreDataManager: coreDataManager!)
        
        
        // initialize chartGenerator in chartOutlet
        self.landscapeChartOutlet.chartGenerator = { [weak self] (frame) in
            return self?.glucoseChartManager?.glucoseChartWithFrame(frame)?.view
        }
            
        updateChart()
        
        
    }
    
    private func updateChart() {
        
        let startOfDay = Calendar(identifier: .gregorian).startOfDay(for: Date())
        
        var endOfDay: Date {
            var components = DateComponents()
            components.day = 1
            components.second = -1
            return Calendar.current.date(byAdding: components, to: startOfDay)!
        }
        
        glucoseChartManager?.updateChartPoints(endDate: endOfDay, startDate: startOfDay, chartOutlet: landscapeChartOutlet, completionHandler: nil)
        
    }

}
