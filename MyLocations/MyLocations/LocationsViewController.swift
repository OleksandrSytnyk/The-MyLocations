//
//  LocationsViewController.swift
//  MyLocations
//
//  Created by MyMacbook on 3/1/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class LocationsViewController: UITableViewController {
    
    var managedObjectContext: NSManagedObjectContext!
    var locations = [Location]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest = NSFetchRequest()
        //The NSFetchRequest is the object that describes which objects you’re going to fetch from the data store.

        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: managedObjectContext)
        fetchRequest.entity = entity
 
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]//You can sort on any attribute here not "date" only.
        
        do {
       
            let foundObjects = try managedObjectContext.executeFetchRequest( fetchRequest)
          
            locations = foundObjects as! [Location]
        } catch {
        fatalCoreDataError(error)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count }
    
    override func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            
       let cell = tableView.dequeueReusableCellWithIdentifier( "LocationCell", forIndexPath: indexPath) as! LocationCell
            
            let location = locations[indexPath.row]
            cell.configureForLocation(location)
            
        return cell
    }
    
   
    
}
