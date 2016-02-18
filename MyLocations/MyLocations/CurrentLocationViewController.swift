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
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: NSError?
    
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
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            lastLocationError = nil
            location = newLocation
            updateLabels()
        
        if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
            print("*** We're done!")
            stopLocationManager()
            configureGetButton()
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
    
        func configureGetButton() {
        if updatingLocation {
        getButton.setTitle("Stop", forState: .Normal)
        } else {
        getButton.setTitle("Get My Location", forState: .Normal)
        }
    }
    
    func stringFromPlacemark (placemark: CLPlacemark) -> String {
        var line1 = ""
        
        if let s = placemark.subThoroughfare {//subThoroughfare is a strange name for house number.
        line1 += s + " "
        }
        if let s = placemark.thoroughfare {//the thoroughfare is the street name
        line1 += s
        }
        var line2 = ""
        if let s = placemark.locality {//the locality is the city name
        line2 += s + " "
        }
        if let s = placemark.administrativeArea {//the administrativearea is the state or province name
        line2 += s + " "
        }
        if let s = placemark.postalCode {
        line2 += s
        }
        return line1 + "\n" + line2
    }
    
}

