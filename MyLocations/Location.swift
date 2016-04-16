//
//  Location.swift
//  MyLocations
//
//  Created by MyMacbook on 2/26/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Location: NSManagedObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    var title: String? {
        if locationDescription.isEmpty {
        return "(No Description)"
    } else {
        return locationDescription
        }
    }
    
    var subtitle: String? {
        return category
    }//The title and subtitle are used for the “call-out” that appears when you tap on the pin.
    
    var hasPhoto: Bool {
        return photoID != nil
    }
    
    var photoPath: String {
        
        assert(photoID != nil, "No photo ID set")
        
        let filename = "Photo-\(photoID!.integerValue).jpg"
        return (applicationDocumentsDirectory as NSString)
        .stringByAppendingPathComponent(filename)
    }
    
    var photoImage: UIImage? {
        return UIImage(contentsOfFile: photoPath)
    }
    
    class func nextPhotoID() -> Int {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let currentID = userDefaults.integerForKey("PhotoID")
        userDefaults.setInteger(currentID + 1, forKey: "PhotoID")
        userDefaults.synchronize()
        return currentID
    }
}
