//
//  InterfaceController.swift
//  Watch App WatchKit Extension
//
//  Created by Paul Plant on 5/10/21.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController {

    let session = WCSession.default
    
    @IBOutlet weak var minutesAgoLabelOutlet: WKInterfaceLabel!
    @IBOutlet weak var deltaLabelOutlet: WKInterfaceLabel!
    @IBOutlet weak var valueLabelOutlet: WKInterfaceLabel!
    
    private var currentBGTimestamp: Date = Date()
    private var currentBGValue: Double = 0
    private var currentBGValueText: String = ""
    private var deltaTextLocalized: String = ""
    private var lastBGValue: Double = 0
    private var lastBGTimestamp: Date = Date()
    private var lastCommunicationTimestamp: Date = Date()
    
    private var markValuesSet: Bool = false
    private var urgentLowMarkValueInUserChosenUnit: Double = 0
    private var lowMarkValueInUserChosenUnit: Double = 0
    private var highMarkValueInUserChosenUnit: Double = 0
    private var urgentHighMarkValueInUserChosenUnit: Double = 0
    
    private var minutesAgoTextLocalized: String = "---"
    
    @IBAction func tapSendToiPhone() {
        
        let data: [String: Any] = ["action": "refresh" as Any]
        
        session.sendMessage(data, replyHandler: nil, errorHandler: nil)
    }
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        session.delegate = self
        session.activate()
        
        updateWatchView()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        //updateWatchView()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    private func updateWatchView() {
            
        if urgentLowMarkValueInUserChosenUnit > 0 && lowMarkValueInUserChosenUnit > 0 && highMarkValueInUserChosenUnit > 0 && urgentHighMarkValueInUserChosenUnit > 0 && currentBGValue > 0 && currentBGValueText != "" && deltaTextLocalized != "" {
            
            let minutesAgo = -Int(currentBGTimestamp.timeIntervalSinceNow) / 60
            let minutesAgoText = minutesAgo.description + " " + minutesAgoTextLocalized
            minutesAgoLabelOutlet.setText(minutesAgoText)
            minutesAgoLabelOutlet.setTextColor(UIColor.lightGray)
            
            deltaLabelOutlet.setText(deltaTextLocalized)
            deltaLabelOutlet.setTextColor(UIColor.white)
            
            valueLabelOutlet.setText(String(currentBGValueText))
            
            if minutesAgo > 21 {
                
                minutesAgoLabelOutlet.setTextColor(UIColor.red)
                deltaLabelOutlet.setTextColor(UIColor.darkGray)
                valueLabelOutlet.setText("Waiting for BG data...")
                valueLabelOutlet.setTextColor(UIColor.orange)
                
            } else if minutesAgo > 11 {
                                
                minutesAgoLabelOutlet.setTextColor(UIColor.yellow)
                deltaLabelOutlet.setTextColor(UIColor.lightGray)
                valueLabelOutlet.setTextColor(UIColor.lightGray)
                
            } else if currentBGValue >= urgentHighMarkValueInUserChosenUnit || currentBGValue <= urgentLowMarkValueInUserChosenUnit {
                
                // BG is higher than urgentHigh or lower than urgentLow objectives
                valueLabelOutlet.setTextColor(UIColor.red)
                
            } else if currentBGValue >= highMarkValueInUserChosenUnit || currentBGValue <= lowMarkValueInUserChosenUnit {
                
                // BG is between urgentHigh/high and low/urgentLow objectives
                valueLabelOutlet.setTextColor(UIColor.yellow)
                
            } else {
                
                // BG is between high and low objectives so considered "in range"
                valueLabelOutlet.setTextColor(UIColor.green)
            }
            
        }
    }
    
    private func refreshData() {
        
        let data: [String: Any] = ["action": "refresh" as Any] //Create your dictionary as per uses
        
        session.sendMessage(data, replyHandler: nil, errorHandler: nil)
        
    }

}

extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        print("received data: \(message)")
        
        if let data = message["currentBGValue"] as? String {
            
            if let doubleValue = Double(data) {
                
                lastBGValue = currentBGValue
                
                currentBGValue = doubleValue
                
            }
            
        }
        
        if let data = message["currentBGTimeStamp"] as? String {
            
            if let date = ISO8601DateFormatter().date(from: data) {
                
                lastBGTimestamp = currentBGTimestamp
                
                currentBGTimestamp = date
            }
            
        }
        
        if let data = message["currentBGValueText"] as? String {
            currentBGValueText = data
        }
        
        if let data = message["deltaTextLocalized"] as? String {
            deltaTextLocalized = data
        }
        
        if let data = message["minutesAgoTextLocalized"] as? String {
            minutesAgoTextLocalized = data
        }
        
        if let data = message["urgentLowMarkValueInUserChosenUnit"] as? String {
            
            if let doubleValue = Double(data) {
                urgentLowMarkValueInUserChosenUnit = doubleValue
            }
            
        }
        
        if let data = message["lowMarkValueInUserChosenUnit"] as? String {
            
            if let doubleValue = Double(data) {
                lowMarkValueInUserChosenUnit = doubleValue
            }
            
        }
        
        if let data = message["highMarkValueInUserChosenUnit"] as? String {
            
            if let doubleValue = Double(data) {
                highMarkValueInUserChosenUnit = doubleValue
            }
            
        }
        
        if let data = message["urgentHighMarkValueInUserChosenUnit"] as? String {
            
            if let doubleValue = Double(data) {
                urgentHighMarkValueInUserChosenUnit = doubleValue
            }
            
        }
        
        lastCommunicationTimestamp = Date()
        
        updateWatchView()
        
    }
}
