//  Created by MyMacbook on 2/12/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false //You’re using the updatingLocation boolean to let the user know that the app is actively looking up her location.
    var lastLocationError: NSError?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func getLocation() {
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .Denied || authStatus == .Restricted { showLocationServicesDeniedAlert()
            return
        }
        
        startLocationManager()
        updateLabels()
    }

    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailWithError \(error)")
        
        if error.code == CLError.LocationUnknown.rawValue {//You ask for the rawValue to convert enumaration names for CLError back to an integer values.
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateWithError \(newLocation)")
        
        lastLocationError = nil
        location = newLocation
        updateLabels()
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled",
        message: "Please enable location services for this app in Settings.",
        preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default,handler: nil)
        presentViewController(alert, animated: true, completion: nil)
        alert.addAction(okAction)
    }//This pops up an alert with a helpful hint.
    
    func updateLabels() {
        if let location = location {//that it’s OK for the unwrapped variable to have the same name as the optional
        latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
        tagButton.hidden = false
        messageLabel.text = ""
    } else {
        latitudeLabel.text = ""
        longitudeLabel.text = ""
        addressLabel.text = ""
        tagButton.hidden = true
        messageLabel.text = "Tap 'Get My Location' to Start"
            
            let statusMessage: String
            if let error = lastLocationError {
                if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue {
                statusMessage = "Location Service Disabled"
            } else {
                statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled(){
                statusMessage = "Location Service Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
        }
    }
   
    func stopLocationManager() {
        if updatingLocation {
        locationManager.startUpdatingLocation()
        locationManager.delegate = nil
        updatingLocation = false
        }
    }
    
        func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        updatingLocation = true
        }
    }
}

