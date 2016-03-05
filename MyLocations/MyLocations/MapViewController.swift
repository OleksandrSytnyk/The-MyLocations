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
    var managedObjectContext: NSManagedObjectContext!
    
    @IBAction func showUser() {
    let region = MKCoordinateRegionMakeWithDistance(
        mapView.userLocation.coordinate, 1000, 1000)//this zooms in the map to a region that is 1000 by 1000 meters around the user’s position.
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    @IBAction func showLocations() {
        
    }
}

extension MapViewController: MKMapViewDelegate {

}