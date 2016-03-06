//
//  MapViewController.swift
//  MyLocations
//
//  Created by MyMacbook on 3/5/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    var locations = [Location]()
    
    var managedObjectContext: NSManagedObjectContext! {
        
        didSet {
            NSNotificationCenter.defaultCenter().addObserverForName( NSManagedObjectContextObjectsDidChangeNotification,
            object: managedObjectContext,
            queue: NSOperationQueue.mainQueue()) {//This notification is sent out by the managedObjectContext whenever the data store changes. In response you would like the following closure to be called.
            notification in //Because this closure gets called by NSNotificationCenter, you’re given an NSNotification object in the notification parameter.
            if self.isViewLoaded() {//You only call updateLocations() when the Maps screen’s view is loaded.
                
                if let dictionary = notification.userInfo {
                print(dictionary["inserted"])
                print(dictionary["deleted"])
                print(dictionary["updated"])
                print("Hello \(dictionary["updated"])")
                print("Hello \(dictionary["deleted"])")
                    self.updateLocations()
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocations()
         
        if !locations.isEmpty {
            showLocations()
        }
    }
    
    @IBAction func showUser() {
    let region = MKCoordinateRegionMakeWithDistance(
        mapView.userLocation.coordinate, 1000, 1000)//this zooms in the map to a region that is 1000 by 1000 meters around the user’s position.
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    @IBAction func showLocations() {
        let region = regionForAnnotations(locations)
        mapView.setRegion(region, animated: true)
    }

    func updateLocations() {
    mapView.removeAnnotations(locations)//an annotation is a pin on the map
    
    let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: managedObjectContext)
        
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        
        locations = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Location]
        mapView.addAnnotations(locations)
        
    }
    
    
    func regionForAnnotations(annotations: [MKAnnotation]) -> MKCoordinateRegion {
        
        var region: MKCoordinateRegion
        
        switch annotations.count {
            
        case 0: region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
            
        case 1:
            let annotation = annotations[annotations.count - 1]
            region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000)
            
        default:
            var topLeftCoord = CLLocationCoordinate2D(latitude:  -90, longitude: 180)
            var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
            
        for annotation in annotations {
                topLeftCoord.latitude = max( topLeftCoord.latitude, annotation.coordinate.latitude)
                topLeftCoord.longitude = min(topLeftCoord.longitude, annotation.coordinate.longitude)
                bottomRightCoord.latitude = min(bottomRightCoord.latitude, annotation.coordinate.latitude)
                bottomRightCoord.longitude = max(bottomRightCoord.longitude, annotation.coordinate.longitude)
            }
            
            let center = CLLocationCoordinate2D(latitude: topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude)/2, longitude: topLeftCoord.longitude - (topLeftCoord.longitude - bottomRightCoord.longitude)/2)
            
            let extraSpace = 1.1
        
        let span = MKCoordinateSpan(latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace, longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace)
            
            region = MKCoordinateRegion(center: center, span: span)
                    }
        return mapView.regionThatFits(region)
    }
    
    func showLocationDetails(sender: UIButton) {
    performSegueWithIdentifier("EditLocation", sender: sender)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditLocation" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext
            let button = sender as! UIButton
            let location = locations[button.tag]
            controller.locationToEdit = location
        }
    }
}

extension MapViewController: MKMapViewDelegate {
        
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
   
    guard annotation is Location else {
    return nil
    }
  
    let identifier = "location"
    var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as! MKPinAnnotationView!
    
    if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)//you’re not limited to using MKPinAnnotationView for your annotations. This is the standard annotation view class, but you can also create your own MKAnnotationView subclass and make it look like anything you want. Pins are only one option.
     
        annotationView.enabled = true
        annotationView.canShowCallout = true
        annotationView.animatesDrop = false
        annotationView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
      
        let rightButton = UIButton(type: .DetailDisclosure)
        rightButton.addTarget(self, action: Selector("showLocationDetails:"), forControlEvents: .TouchUpInside)//it's the target-action pattern to hook up the button’s “Touch Up Inside” event with a showLocationDetails() method
        
        annotationView.rightCalloutAccessoryView = rightButton
    } else {
        annotationView.annotation = annotation
        }

    let button = annotationView.rightCalloutAccessoryView as! UIButton
    
    if let index = locations.indexOf(annotation as! Location) {
        button.tag = index
        }
        return annotationView
        }
    }

