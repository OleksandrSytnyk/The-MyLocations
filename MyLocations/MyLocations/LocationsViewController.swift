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
    //var locations = [Location]()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: self.managedObjectContext)
        
        fetchRequest.entity = entity
        
        let sortDescriptor1 = NSSortDescriptor(key: "category", ascending: true)
        let sortDescriptor2 = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]
        
        fetchRequest.fetchBatchSize = 20//The fetch batch size setting allows you to tweak how many objects will be fetched at a time.
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "category", cacheName: "Locations")//The cacheName needs to be a unique name that NSFetchedResultsController uses to cache the search results.
        
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()//The fetched results controller keeps an eye on any changes that you make to the data store and notifies its delegate in response. It doesn’t matter where in the app you make these changes, they can happen on any screen.
    
    deinit {
        fetchedResultsController.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        performFetch()
        navigationItem.rightBarButtonItem = editButtonItem()//Every view controller has a built-in Edit button that can be accessed through the editButtonItem() method.
        tableView.backgroundColor = UIColor.blackColor()
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
        tableView.indicatorStyle = .White
    }
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalCoreDataError(error)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditLocation" {
            let navigationController = segue.destinationViewController
                as! UINavigationController
            
            let controller = navigationController.topViewController
                as! LocationDetailsViewController
            
            controller.managedObjectContext = managedObjectContext
            
            if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
                
                let location = fetchedResultsController.objectAtIndexPath(indexPath)  as! Location
                
                controller.locationToEdit = location//Because prepareForSegue() – and therefore locationToEdit’s didSet – is called before viewDidLoad(), this puts the right values on the screen when it becomes visible.
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            
       let cell = tableView.dequeueReusableCellWithIdentifier( "LocationCell", forIndexPath: indexPath) as! LocationCell
            
            let location = fetchedResultsController.objectAtIndexPath(indexPath)  as! Location
             
            cell.configureForLocation(location)
            
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if  editingStyle == .Delete {
            let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
            location.removePhotoFile()
            managedObjectContext.deleteObject(location)
            
            do {
                
                try managedObjectContext.save()
                
                changedLocation = location
                operation = "deleted"
                NSNotificationCenter.defaultCenter().postNotificationName(updateLocationMessage, object: managedObjectContext)
                
            } catch {
                fatalCoreDataError(error)
            }
        }
    }// As soon as you implement this method in your view controller, it enables swipe-to-delete.
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name.uppercaseString
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView,
        viewForHeaderInSection section: Int) -> UIView? {
        
        let labelRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 14, width: 300, height: 14)
        let label = UILabel(frame: labelRect)
        label.font = UIFont.boldSystemFontOfSize(11)
        
        label.text = tableView.dataSource!.tableView!( tableView, titleForHeaderInSection: section)
        
        label.textColor = UIColor(white: 1.0, alpha: 0.4)
        label.backgroundColor = UIColor.clearColor()
        
        let separatorRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 0.5,
        width: tableView.bounds.size.width - 15, height: 0.5)
        let separator = UIView(frame: separatorRect)
        separator.backgroundColor = tableView.separatorColor
        
        let viewRect = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.sectionHeaderHeight)
        let view = UIView(frame: viewRect)
        view.backgroundColor = UIColor(white: 0, alpha: 0.85)
        view.addSubview(label)
        view.addSubview(separator)
        
        return view
    }
}

extension LocationsViewController: NSFetchedResultsControllerDelegate {
    
        func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("*** controllerWillChangeContent")
        tableView.beginUpdates()
        }
        
        func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?,
            forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
            
        switch type {
            
    case .Insert:
        print("*** NSFetchedResultsChangeInsert (object)")
        tableView.insertRowsAtIndexPaths([newIndexPath!],
        withRowAnimation: .Fade)
    
    case .Delete:
        print("*** NSFetchedResultsChangeDelete (object)")
        tableView.deleteRowsAtIndexPaths([indexPath!],
        withRowAnimation: .Fade)
    
    case .Update:
        print("*** NSFetchedResultsChangeUpdate (object)")
        
    if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? LocationCell {
            
        let location = controller.objectAtIndexPath(indexPath!) as! Location
        cell.configureForLocation(location)
    }
    
    case .Move:
        print("*** NSFetchedResultsChangeMove (object)")
        tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
        
        func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int,
            forChangeType type: NSFetchedResultsChangeType) {
            
            switch type {
        case .Insert:
        print("*** NSFetchedResultsChangeInsert (section)")
        tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            
        case .Delete:
        print("*** NSFetchedResultsChangeDelete (section)")
        tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            
        case .Update:
        print("*** NSFetchedResultsChangeUpdate (section)")
            
        case .Move:
        print("*** NSFetchedResultsChangeMove (section)")
            }
        }
        
        func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("*** controllerDidChangeContent")
        tableView.endUpdates()
        }
}

