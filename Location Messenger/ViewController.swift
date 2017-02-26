//
//  ViewController.swift
//  Location Messenger
//
//  Created by Tanner Hoelzel on 2/25/17.
//  Copyright © 2017 Ryan Tanner. All rights reserved.
//

import UIKit
import CoreLocation
import NotificationCenter
import Firebase
import FirebaseDatabase

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate {

    // MARK: Properties
    
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var inbox: UITableView!
    var ref = FIRDatabase.database().reference(withPath: "messages")
    let locationManager = CLLocationManager()
    var messageText = ""
    var latitude = 0.0
    var longitude = 0.0
    var messageList: [Message] = []
    var activeMessageList: [Message] = []
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        messageField.delegate = self
        inbox.dataSource = self
        inbox.delegate = self
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        ref.observe(.value, with: { snapshot in
            
            var newItems: [Message] = []
            
            for item in snapshot.children {
                let message = Message(snapshot: item as! FIRDataSnapshot)
                newItems.append(message)
                print(message.text)
            }
            
            self.messageList = newItems
            self.activeMessageList.removeAll()
            
            for message in self.messageList {
                let msgCoordinate = CLLocation(latitude: message.lat, longitude: message.long)
                let userCoordinate = CLLocation(latitude: self.latitude, longitude: self.longitude)
                let meters = userCoordinate.distance(from: msgCoordinate)
                if meters < 10 {
                    self.activeMessageList.append(message)
                }
            }
            
            self.inbox.reloadData()
        })

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Keyboard Movement
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if messageField.frame.origin.y > (self.view.frame.height - keyboardSize.height) {
                messageField.frame.origin.y -= keyboardSize.height
                inbox.bounds.size.height -= keyboardSize.height
                inbox.frame.origin.y -= keyboardSize.height
            }
            /*if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }*/
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if messageField.frame.origin.y < (self.view.frame.height - keyboardSize.height) {
                messageField.frame.origin.y += keyboardSize.height
                inbox.bounds.size.height += keyboardSize.height
                inbox.frame.origin.y += keyboardSize.height
            }
            /*if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }*/
        }
    }
    
    // MARK: UITableView Delegate methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeMessageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let newMessage = activeMessageList[indexPath.row]
        
        cell.textLabel?.text = newMessage.text
        
        //cell.textLabel?.numberOfLines = 0
        //cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        let numberOfSections = inbox.numberOfSections
        let numberOfRows = inbox.numberOfRows(inSection: numberOfSections-1)
        
        let indexPath = IndexPath(row: numberOfRows-1 , section: numberOfSections-1)
        inbox.scrollToRow(at: indexPath, at: UITableViewScrollPosition.middle, animated: true)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /*
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        var groceryItem = items[indexPath.row]
        let toggledCompletion = !groceryItem.completed
        
        toggleCellCheckbox(cell, isCompleted: toggledCompletion)
        groceryItem.completed = toggledCompletion
        tableView.reloadData()
    }

    func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.black
        } else {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = UIColor.gray
            cell.detailTextLabel?.textColor = UIColor.gray
        }
    }
    */
    
    // MARK: Location Services
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("TRUE: \(locValue.latitude)\(locValue.longitude)")
        print("DATA: \(self.latitude)\(self.longitude)")

        if self.latitude == 0 && self.longitude == 0 {
            self.latitude = locValue.latitude
            self.longitude = locValue.longitude
        }
        
        if self.latitude != locValue.latitude && self.longitude != locValue.longitude {
            self.latitude = locValue.latitude
            self.longitude = locValue.longitude
            self.activeMessageList.removeAll()
            for message in messageList {
                let msgCoordinate = CLLocation(latitude: message.lat, longitude: message.long)
                let userCoordinate = CLLocation(latitude: self.latitude, longitude: self.longitude)
                let meters = userCoordinate.distance(from: msgCoordinate)
                if meters < 10 {
                    self.activeMessageList.append(message)
                }
            }
            self.inbox.reloadData()
        }
            
    }
    
    // MARK: UITextFieldDelegate methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.placeholder = ""
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        messageText = textField.text!
        
        if messageText != "" {
            let newMessage = Message.init(timestamp: "\(Date())",
                                          text: self.messageText,
                                          lat: self.latitude,
                                          long: self.longitude,
                                          user: "User")
            let newMessageRef = self.ref.child(newMessage.timestamp)
            newMessageRef.setValue(newMessage.toAnyObject())
        
            print("\(messageText)")
        }
        
        textField.text = ""
        textField.placeholder = "Text Message"
    }
    
    // MARK: Actions

    @IBAction func moveDown(_ sender: UITextField) {
    }
}

