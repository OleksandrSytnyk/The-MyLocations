//  Created by MyMacbook on 2/12/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import QuartzCore
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
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
    var logoVisible = false
    var soundID: SystemSoundID = 0 // 0 means no sound has been loaded yet.
    
    lazy var logoButton: UIButton = {
        
        let button = UIButton(type: .Custom)
        
        button.setBackgroundImage(UIImage(named: "Logo"), forState: .Normal)
        button.sizeToFit()
        button.addTarget(self, action: Selector("getLocation"), forControlEvents: .TouchUpInside)
        button.center.x = CGRectGetMidX(self.view.bounds)
        button.center.y = 220
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
        loadSoundEffect("Sound.caf")
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
        
        if logoVisible {
            hideLogoView()
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
                    
                    if self.placemark == nil {
                        print ("FIRST TIME!")
                        self.playSoundEffect()
                    }
                    
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
                statusMessage = ""
                showLogoView()
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
        let spinnerTag = 1000
            
        if updatingLocation {
        getButton.setTitle("Stop", forState: .Normal)
            
        if view.viewWithTag(spinnerTag) == nil {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
            spinner.center = messageLabel.center
            spinner.center.y += spinner.bounds.size.height/2 + 15
            spinner.startAnimating()
            spinner.tag = spinnerTag
            containerView.addSubview(spinner)//this makes the spinner visible
            }
        } else {
        getButton.setTitle("Get My Location", forState: .Normal)
            if let spinner = view.viewWithTag(spinnerTag) {
                spinner.removeFromSuperview()
            }
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
    
    // MARK: - Logo View
    func showLogoView() {
            
        if !logoVisible {
            logoVisible = true
            containerView.hidden = true
            view.addSubview(logoButton)
            }
    }
    
    func hideLogoView() {
        if !logoVisible { return }
        
        logoVisible = false
        containerView.hidden = false
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        let centerX = CGRectGetMidX(view.bounds)
        
        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.removedOnCompletion = false
        panelMover.fillMode = kCAFillModeForwards
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(CGPoint: containerView.center)
        panelMover.toValue = NSValue(CGPoint:CGPoint(x: centerX, y: containerView.center.y))
        panelMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        panelMover.delegate = self
        containerView.layer.addAnimation(panelMover, forKey: "panelMover")
        
        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.removedOnCompletion = false
        logoMover.fillMode = kCAFillModeForwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(CGPoint: logoButton.center)
        logoMover.toValue = NSValue(CGPoint: CGPoint(x: -centerX, y: logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        logoButton.layer.addAnimation(logoMover, forKey: "logoMover")
        
        let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
        logoRotator.removedOnCompletion = false
        logoRotator.fillMode = kCAFillModeForwards
        logoRotator.duration = 0.5
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -2 * M_PI
        logoRotator.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        logoButton.layer.addAnimation(logoRotator, forKey: "logoRotator")
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
            containerView.layer.removeAllAnimations()
            containerView.center.x = view.bounds.size.width / 2
            containerView.center.y = 40 + containerView.bounds.size.height / 2
            
            logoButton.layer.removeAllAnimations()
            logoButton.removeFromSuperview()
    }
    
    // MARK: - Sound Effect
    
    func loadSoundEffect(name: String) {
        
        if let path = NSBundle.mainBundle().pathForResource(name, ofType: nil) {
        
        let fileURL = NSURL.fileURLWithPath(path, isDirectory: false)
        let error = AudioServicesCreateSystemSoundID(fileURL, &soundID)
       //here we use the error hanling mechanism to let the app to make some sound
        if error != kAudioServicesNoError {
        print("Error code \(error) loading sound at path: \(path)")
        }
      }
    }
    
    func unloadSoundEffect() {
        AudioServicesDisposeSystemSoundID(soundID)
        soundID = 0
    }
    
    func playSoundEffect() {
        AudioServicesPlaySystemSound(soundID)
    }
}
