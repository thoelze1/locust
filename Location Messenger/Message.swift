//
//  Message.swift
//  Location Messenger
//
//  Created by Tanner Hoelzel on 2/26/17.
//  Copyright © 2017 Ryan Tanner. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

struct Message {
    
    let key: String
    let timestamp: String
    let text: String
    let lat: Double
    let long: Double
    let user: String
    let ref: FIRDatabaseReference?
    
    init(timestamp: String, text: String, lat:Double, long: Double, user: String, key: String = "") {
        self.key = key
        self.timestamp = timestamp
        self.text = text
        self.lat = lat
        self.long = long
        self.user = user
        self.ref = nil
    }
    
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        timestamp = snapshotValue["timestamp"] as! String
//        if (snapshotValue["timestamp"] as? String) != nil{
//            timestamp = snapshotValue["timestamp"] as! String
//        } else {
//            timestamp = snapshotValue["timestamp"] as! String
//        }
        text = snapshotValue["text"] as! String
        lat = snapshotValue["lat"] as! Double
        long = snapshotValue["long"] as! Double
        user = snapshotValue["user"] as! String
        ref = snapshot.ref
    }
    
    func toAnyObject() -> Any {
        return [
            "timestamp": timestamp,
            "text": text,
            "lat": lat,
            "long": long,
            "user": user
        ]
    }
    
}
