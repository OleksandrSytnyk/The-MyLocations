//  Created by MyMacbook on 2/12/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

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
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: NSError?
    var timer: NSTimer?
    var managedObjectContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
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
        
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        
        updateLabels()
        configureGetButton()
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
        configureGetButton()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateWithError \(newLocation)")
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 {// it's the time that has elapsed since the last location fix
            return
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        var distance = CLLocationDistance(DBL_MAX)
        
        if let location = location {
            distance = newLocation.distanceFromLocation(location)
        }//This calculates the distance between the new reading and the previous reading, if there was one. If there was no previous reading, then the distance is DBL_MAX. That is a built-in constant that represents the maximum value that a floating-point number can have. You’re doing that so any of the following calculations still work even if you weren’t able to calculate a true distance yet.
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            lastLocationError = nil
            location = newLocation
            updateLabels()
        
        if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
            print("*** We're done!")
            stopLocationManager()
            configureGetButton()
            
            if distance > 0 {
                performingReverseGeocoding = false
                }
            }
            
            if !performingReverseGeocoding {
                print("*** Going to geocode")
                performingReverseGeocoding = true
                geocoder.reverseGeocodeLocation(newLocation, completionHandler: {
                placemarks, error in
                print("*** Found placemarks: \(placemarks), error: \(error)")
                
                self.lastGeocodingError = error
                if error == nil, let p = placemarks where !p.isEmpty {
                    self.placemark = p.last!
                } else {
                    self.placemark = nil }
                self.performingReverseGeocoding = false
                self.updateLabels()
                })
            //the statements in the closure are not executed right away when locationManager(didUpdateLocations) is called. Instead, the closure and everything inside it is given to CLGeocoder, which keeps it until later when it has performed the reverse geocoding operation. Only then will it execute the code from the closure.
            }
                } else if distance < 1.0 {
            let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
            if timeInterval > 10 {
            print("*** Forcedone!")
            }
            stopLocationManager()
            updateLabels()
            configureGetButton()
        }
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
           
            if let placemark = placemark {
                addressLabel.text = stringFromPlacemark(placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
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
            if let timer = timer {
                timer.invalidate()//to cancel the timer in case the location manager is stopped before the time-out fires.
            }
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
            
        timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("didTimeOut"), userInfo: nil, repeats: false)
            //it's a timer object that sends the “didTimeOut” message to self after 60 seconds; didTimeOut is the name of a method that you have to provide.
        }
    }
    
        func configureGetButton() {
        if updatingLocation {
        getButton.setTitle("Stop", forState: .Normal)
        } else {
        getButton.setTitle("Get My Location", forState: .Normal)
        }
    }
    
    func stringFromPlacemark (placemark: CLPlacemark) -> String {
        var line1 = ""
        
        line1.addText(placemark.subThoroughfare)
        line1.addText(placemark.thoroughfare, withSeparator: " ")
        
        var line2 = ""
        
        line2.addText(placemark.locality)
        line2.addText(placemark.administrativeArea, withSeparator: " ")
        line2.addText(placemark.postalCode, withSeparator: " ")
        
        line1.addText(line2, withSeparator: "\n")
        return line1
    }
    
    func didTimeOut() {
        print("*** Time out")
        if location == nil {
        stopLocationManager()
        lastLocationError = NSError(domain: "MYLocationErrorDomain", code: 1, userInfo: nil)// So it's not an error from kCLErrorDomain. It's user's own domain which is just a String.
        updateLabels()
        configureGetButton()
        }
    }
    
       override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TagLocation" {
        let navigationController = segue.destinationViewController as! UINavigationController
        let controller = navigationController.topViewController as! LocationDetailsViewController
        controller.coordinate = location!.coordinate
        controller.placemark = placemark
        controller.managedObjectContext = managedObjectContext
        }
    }
}
