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
    
    @IBAction func tapSendToiPhone() {
        //let data: [String: Any] = ["watch": "data from watch" as Any] //Create your dictionary as per uses
        let data: [String: Any] = ["action": "refresh" as Any] //Create your dictionary as per uses
        
        session.sendMessage(data, replyHandler: nil, errorHandler: nil)
    }
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        session.delegate = self
        session.activate()
        
        refreshData()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
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
        
        if let value = message["value"] as? String {
            self.valueLabelOutlet.setText(value)
        }
        
        if let minutesAgo = message["minutesAgo"] as? String {
            self.minutesAgoLabelOutlet.setText(minutesAgo)
        }
        
        if let delta = message["delta"] as? String {
            self.deltaLabelOutlet.setText(delta)
        }
        
        if let valueColor = message["valueColor"] as? String {
            
            switch valueColor
            {
            case "inRange":
                self.valueLabelOutlet.setTextColor(UIColor.green)
                
            case "notUrgent":
                self.valueLabelOutlet.setTextColor(UIColor.yellow)
                
            case "urgent":
                self.valueLabelOutlet.setTextColor(UIColor.red)
                
            case "stale":
                self.valueLabelOutlet.setTextColor(UIColor.lightGray)
                
            default:
                break
            }
        }
        
    }
}
