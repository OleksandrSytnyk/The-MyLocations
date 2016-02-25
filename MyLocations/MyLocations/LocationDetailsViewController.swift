//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by MyMacbook on 2/21/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

private let dateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateStyle = .MediumStyle
    formatter.timeStyle = .ShortStyle
    return formatter }()

class LocationDetailsViewController: UITableViewController {
    
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
 
    
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var categoryName = "No Category"
   
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionTextView.text = ""
        categoryLabel.text = categoryName
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        if let placemark = placemark {
        addressLabel.text = stringFromPlacemark(placemark)
    } else {
        addressLabel.text = "No Address Found"
        }
        dateLabel.text = formatDate(NSDate())
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("hideKeyboard:"))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
    }
    
    func hideKeyboard(gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(point)
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0 {//It is possible that the user taps inside the table view but not on a cell, for example somewhere in between two sections or on the section header. In that case indexPath will be nil, making this an optional (of type NSIndexPath?).
        return
        }
        descriptionTextView.resignFirstResponder()
    }
    
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        var text = ""
        
        if let s = placemark.subThoroughfare {
            text += s + " "
        }
        if let s = placemark.thoroughfare {
            text += s + ", "
        }
        if let s = placemark.locality {
                text += s + ", "
        }
        if let s = placemark.administrativeArea {
            text += s + " "
        }
        if let s = placemark.postalCode {
            text += s + ", "
        }
        if let s = placemark.country {
                text += s
        }
        return text
    }
    
    func formatDate(date: NSDate) -> String {
                return dateFormatter.stringFromDate(date)
    }

    
    @IBAction func done() {
        let hudView = HudView.hudInView(navigationController!.view,
            animated: true)
        hudView.text = "Tagged"
        
        afterDelay(0.6, closure: {
            self.dismissViewControllerAnimated(true, completion: nil)
        })
    }
    
    @IBAction func cancel() {
            dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 88
        } else if indexPath.section == 2 && indexPath.row == 2 {
          addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115, height: 10000)//115 points less than the width of the screen
            //Because you’re changing the frame property, the multi-line UILabel will now word- wrap the text to fit the requested width. This works because you already set the text on the label in viewDidLoad().
            addressLabel.sizeToFit()
            //A rectangle whose height is10,000 points is tall enough to fit a lot of text and now you’ll have to size the label back to the proper height
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
            //The call to sizeToFit() removed any spare space to the right and bottom of the label. It may also have changed the width so that the text fits inside the label as snugly as possible, but because of that the X-position of the label may no longer be correct.
            return addressLabel.frame.size.height + 28// we didn't know the label height before but now we can know using height property
        } else {
            return 44
        }
    }
    
       override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 {
        return indexPath
    } else {
        return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
        descriptionTextView.becomeFirstResponder()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
            if segue.identifier == "PickCategory" {
            let controller = segue.destinationViewController as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
            }
    }
    
      @IBAction func categoryPickerDidPickCategory(segue: UIStoryboardSegue) {
        let controller = segue.sourceViewController as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    
}
