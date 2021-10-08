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
    
    // MARK: - Properties - Outlets and Actions for buttons and labels in home screen
    
    @IBOutlet weak var minutesAgoLabelOutlet: WKInterfaceLabel!
    @IBOutlet weak var deltaLabelOutlet: WKInterfaceLabel!
    @IBOutlet weak var valueLabelOutlet: WKInterfaceLabel!
    @IBOutlet weak var iconImageOutlet: WKInterfaceImage!
    
    /// we can attach this action to the value label (or whatever) and use it to force refresh the data if it is needed for some reason. We'll set it to require a 2 second push so it should not be triggered accidentally
    @IBAction func longPressToRefresh(_ sender: Any) {
        
        // set all label outlets to deactivated and show a message to the user to acknowledge that a refresh has been requested
        minutesAgoLabelOutlet.setText("Refreshing...")
        minutesAgoLabelOutlet.setTextColor(ConstantsWatchApp.labelColorDeactivated)
        
        deltaLabelOutlet.setText("---")
        deltaLabelOutlet.setTextColor(ConstantsWatchApp.labelColorDeactivated)
        
        valueLabelOutlet.setText("---")
        valueLabelOutlet.setTextColor(ConstantsWatchApp.labelColorDeactivated)
        
        requestBGData()
        
    }
    
    // MARK: - Properties - other private properties
    
    // WatchConnectivity session needed for messaging with the companion app
    private let session = WCSession.default
    
    // declare and initialise app-wide variables
    private var currentBGValue: Double = 0
    private var currentBGValueText: String = ""
    private var currentBGTimestamp: Date = Date()
    private var deltaTextLocalized: String = "---"
    private var minutesAgoTextLocalized: String = "---"
    private var urgentLowMarkValueInUserChosenUnit: Double = 0
    private var lowMarkValueInUserChosenUnit: Double = 0
    private var highMarkValueInUserChosenUnit: Double = 0
    private var urgentHighMarkValueInUserChosenUnit: Double = 0
    
    
    // MARK: - overriden functions
    
    // we don't need to do much here except configure the session and delegate
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
        
        session.delegate = self
        session.activate()
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        // pull new BG data from xDrip4iOS
        requestBGData()
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        // when the app is deactivated or pushed to the background and then we'll change the text colours to gray to indicate (in case the user sees the screen without taking it) that the app is currently not being updated. As soon as the app is activated, fresh data will be requested and the label colours updated again.
        minutesAgoLabelOutlet.setTextColor(ConstantsWatchApp.labelColorDeactivated)
        deltaLabelOutlet.setTextColor(ConstantsWatchApp.labelColorDeactivated)
        valueLabelOutlet.setTextColor(ConstantsWatchApp.labelColorDeactivated)
        
    }
    
    
    // MARK: - private helper functions
    
    /// This will update the watch view based upon the current values of the Interface Controller's private variables at the current time
    private func updateWatchView() {
        
        // first we need to make sure that *all* required variables have been updated at least once by receiving a message for each from an active WKSession. This is needed because the messages will arrive asynchronously in a queue and it makes no sense to apply any logic unless they are all updated.
        if (urgentLowMarkValueInUserChosenUnit > 0 && lowMarkValueInUserChosenUnit > 0 && highMarkValueInUserChosenUnit > 0 && urgentHighMarkValueInUserChosenUnit > 0 && currentBGValue > 0 && currentBGValueText != "" && deltaTextLocalized != "") {
            
            // calculate how long ago the last BG value was processed by the iOS app
            let minutesAgo = -(Int(currentBGTimestamp.timeIntervalSinceNow) / 60)
            
            // build a locale-friendly text string using the freshly calculated value and the localized text sent by iOS
            let minutesAgoText = minutesAgo.description + " " + minutesAgoTextLocalized
            
            minutesAgoLabelOutlet.setText(minutesAgoText)
            minutesAgoLabelOutlet.setTextColor(ConstantsWatchApp.minsAgoLabelColor)
            
            // let's see how long the "mins ago" string is. Some localizations produce a really long string (Dutch, Swedish) that isn't easily abbreviated without losing context. In this case, let's just hide the icon to allow the text to fit without issues
            iconImageOutlet.setHidden(minutesAgoText.count > 13 ? true : false)
            
            deltaLabelOutlet.setText(deltaTextLocalized)
            deltaLabelOutlet.setTextColor(ConstantsWatchApp.deltaLabelColor)
            
            valueLabelOutlet.setText(currentBGValueText.description)
            
            // make a simple check to ensure that there is no incoherency between the BG and objective values (i.e. some values in mg/dl whilst others are still in mmol/l). This can happen as the message sending from the iOS session is asynchronous. When one value is updated before the others, then it can cause the wrong colour text to be displayed until the next messages arrive 0.5 seconds later and the view is corrected.
            let coherencyCheck = (currentBGValue < 30 && urgentLowMarkValueInUserChosenUnit < 10 && lowMarkValueInUserChosenUnit < 10 && highMarkValueInUserChosenUnit < 30 && urgentHighMarkValueInUserChosenUnit < 30) || (currentBGValue > 20 && urgentLowMarkValueInUserChosenUnit > 20 && lowMarkValueInUserChosenUnit > 20 && highMarkValueInUserChosenUnit > 80 && urgentHighMarkValueInUserChosenUnit > 80)
            
            if minutesAgo > ConstantsWatchApp.minutesAgoUrgentMinutes {
                
                // if there's a clear problem and iOS hasn't sent any new data in 20-30 minutes
                minutesAgoLabelOutlet.setTextColor(ConstantsWatchApp.minsAgoLabelColorUrgent)
                deltaLabelOutlet.setTextColor(ConstantsWatchApp.labelColorDeactivated)
                valueLabelOutlet.setText("Waiting for xDrip4iOS...")
                valueLabelOutlet.setTextColor(ConstantsWatchApp.labelColorDeactivated)
                
            } else if minutesAgo > ConstantsWatchApp.minutesAgoWarningMinutes {
                
                // if there's a potential problem and iOS hasn't sent any new data in 10-15 minutes
                minutesAgoLabelOutlet.setTextColor(ConstantsWatchApp.minsAgoLabelColorWarning)
                deltaLabelOutlet.setTextColor(ConstantsWatchApp.labelColorDeactivated)
                valueLabelOutlet.setTextColor(ConstantsWatchApp.labelColorDeactivated)
                
            } else if (currentBGValue >= urgentHighMarkValueInUserChosenUnit || currentBGValue <= urgentLowMarkValueInUserChosenUnit) && coherencyCheck {
                
                // BG is higher than urgentHigh or lower than urgentLow objectives
                valueLabelOutlet.setTextColor(ConstantsWatchApp.glucoseUrgentRangeColor)
                
            } else if (currentBGValue >= highMarkValueInUserChosenUnit || currentBGValue <= lowMarkValueInUserChosenUnit) && coherencyCheck {
                
                // BG is between urgentHigh/high and low/urgentLow objectives
                valueLabelOutlet.setTextColor(ConstantsWatchApp.glucoseNotUrgentRangeColor)
                
            } else if coherencyCheck {
                
                // BG is between high and low objectives so considered "in range"
                valueLabelOutlet.setTextColor(ConstantsWatchApp.glucoseInRangeColor)
            }
            
        }
    }
    
    /// send a message to the iOS WCSession to request the delegate to immediately resend all current BG and other info
    private func requestBGData() {
        
        let data: [String: Any] = ["action": "refreshBGData" as Any]
        
        session.sendMessage(data, replyHandler: nil, errorHandler: nil)
        
    }
    
}


// MARK: - conform to WCSessionDelegate protocol

/// This will process all messages received from the active WCSession.
/// This is done asynchronously in individual messages so we need to test which one has arrived before trying to process and assign values
/// All messages are sent as Strings so we will need to cast them into the required types before assigning to the class properties
extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        // uncomment the following for debug console use
        // print("received message from iOS App: \(message)")
        
        if let data = message["currentBGValue"] as? String, let doubleValue = Double(data) {
                currentBGValue = doubleValue
        }
        
        if let data = message["currentBGTimeStamp"] as? String, let date = ISO8601DateFormatter().date(from: data) {
            if date != currentBGTimestamp {
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
        
        if let data = message["urgentLowMarkValueInUserChosenUnit"] as? String, let doubleValue = Double(data) {
                urgentLowMarkValueInUserChosenUnit = doubleValue
        }
        
        if let data = message["lowMarkValueInUserChosenUnit"] as? String, let doubleValue = Double(data) {
                lowMarkValueInUserChosenUnit = doubleValue
        }
        
        if let data = message["highMarkValueInUserChosenUnit"] as? String, let doubleValue = Double(data) {
                highMarkValueInUserChosenUnit = doubleValue
        }
        
        if let data = message["urgentHighMarkValueInUserChosenUnit"] as? String, let doubleValue = Double(data) {
                urgentHighMarkValueInUserChosenUnit = doubleValue
        }
        
        // when we've finished, update the view
        updateWatchView()
        
    }
    
}
