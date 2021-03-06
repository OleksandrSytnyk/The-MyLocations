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
import CoreData

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
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var categoryName = "No Category"
    var managedObjectContext: NSManagedObjectContext!
    var date = NSDate()
    var descriptionText = ""
    var imageCellHeight: CGFloat = 280
    var observer: AnyObject!
    
    var image: UIImage? {
        didSet {
            
      if let image = image {
        showImage(image)
            }
        }
    }
    
    var locationToEdit: Location? {
        didSet {
            if let location = locationToEdit {
                descriptionText = location.locationDescription
                categoryName = location.category
                date = location.date
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                placemark = location.placemark
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let location = locationToEdit {
            title = "Edit Location"
 
            if location.hasPhoto {
                if let image = location.photoImage {
                    showImage(image)
                }
            }
        }
        
        tableView.backgroundColor = UIColor.blackColor()
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
        tableView.indicatorStyle = .White
        
        descriptionTextView.textColor = UIColor.whiteColor()
        descriptionTextView.backgroundColor = UIColor.blackColor()
        
        addPhotoLabel.textColor = UIColor.whiteColor()
        addPhotoLabel.highlightedTextColor = addPhotoLabel.textColor
        
        addressLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
        addressLabel.highlightedTextColor = addressLabel.textColor
        
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        if let placemark = placemark {
        addressLabel.text = stringFromPlacemark(placemark)
        } else {
        addressLabel.text = "No Address Found"
        }
        dateLabel.text = formatDate(date)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("hideKeyboard:"))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
            
        listenForBackgroundNotification()
    }
    
    func hideKeyboard(gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(point)
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0 {//It is possible that the user taps inside the table view but not on a cell, for example somewhere in between two sections or on the section header. In that case indexPath will be nil, making this an optional (of type NSIndexPath?).
        return
        }
        descriptionTextView.resignFirstResponder()
    }
    
    func listenForBackgroundNotification() {
        
        observer = NSNotificationCenter.defaultCenter().addObserverForName(
            UIApplicationDidEnterBackgroundNotification, object: nil, queue: NSOperationQueue.mainQueue()) {[weak self] _ in
                
                if let strongSelf = self {
                    if strongSelf.presentedViewController != nil {
                        strongSelf.dismissViewControllerAnimated(false, completion: nil)
                    }
                    
                    strongSelf.descriptionTextView.resignFirstResponder()
                }
        }
    }
    
    deinit {
        print("*** deinit \(self)")
        NSNotificationCenter.defaultCenter().removeObserver(observer)
    }
    
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        var line = ""
        
        line.addText(placemark.subThoroughfare)
        line.addText(placemark.thoroughfare, withSeparator: " ")
        line.addText(placemark.locality, withSeparator: ", ")
        line.addText(placemark.administrativeArea, withSeparator: ", ")
        line.addText(placemark.postalCode, withSeparator: " ")
        line.addText(placemark.country, withSeparator: ", ")
        
        return line
    }
    
    func formatDate(date: NSDate) -> String {
                return dateFormatter.stringFromDate(date)
    }
    
    func showImage(image: UIImage) {
        imageView.image = image
        imageView.hidden = false
        imageView.frame = CGRect(x: 10, y: 10, width: 260, height:  (image.size.height / image.size.width) * imageView.frame.size.width)
        addPhotoLabel.hidden = true
        imageCellHeight = imageView.frame.height
    }
    
    @IBAction func done() {
        let hudView = HudView.hudInView(navigationController!.view,
            animated: true)
        
        let location: Location
        if let temp = locationToEdit {
            hudView.text = "Updated"
            location = temp
        } else {
            hudView.text = "Tagged"
            location = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: managedObjectContext) as! Location
            location.photoID = nil
        }
               
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
            
            if let image = image {
           
            if !location.hasPhoto {
            location.photoID = Location.nextPhotoID()
            }
            
            if let data = UIImageJPEGRepresentation(image, 0.5) {//this converts the UIImage into the JPEG format and returns an NSData object.
            
            do {
            
            try data.writeToFile(location.photoPath, options: .DataWritingAtomic)
            } catch {
            
            print("Error writing file: \(error)")
            }
          }
        }
            
        
        do {
            
        try managedObjectContext.save()
            
            if locationToEdit == nil {
                operation = "inserted"
            } else {
                operation = "updated"
            }
            changedLocation = location

             NSNotificationCenter.defaultCenter().postNotificationName(updateLocationMessage, object: managedObjectContext)
           
        } catch {
            fatalCoreDataError(error)
        }
        
        afterDelay(0.6) {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func cancel() {
            dismissViewControllerAnimated(true, completion: nil)
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
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        switch (indexPath.section, indexPath.row) {
        
        case (0, 0):
            return 88
            
        case (1, _):
                return imageView.hidden ? 44 : imageCellHeight
            
        case (2, 2):
            addressLabel.frame.size = CGSize( width: view.bounds.size.width - 115, height: 10000)//115 points less than the width of the screen
                //Because you’re changing the frame property, the multi-line UILabel will now word- wrap the text to fit the requested width. This works because you already set the text on the label in viewDidLoad().
            addressLabel.sizeToFit()//A rectangle whose height is10,000 points is tall enough to fit a lot of text and now you’ll have to size the label back to the proper height
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15//The call to sizeToFit() removed any spare space to the right and bottom of the label. It may also have changed the width so that the text fits inside the label as snugly as possible, but because of that the X-position of the label may no longer be correct.
        return
            addressLabel.frame.size.height + 20 // we didn't know the label height before but now we can know using height property
        default:
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
        } else if indexPath.section == 1 && indexPath.row == 0 {
            pickPhoto()
             }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
            
            cell.backgroundColor = UIColor.blackColor()
            
            if let textLabel = cell.textLabel {
                textLabel.textColor = UIColor.whiteColor()
                textLabel.highlightedTextColor = textLabel.textColor
            }
            
            if let detailLabel = cell.detailTextLabel {
                detailLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
                detailLabel.highlightedTextColor = detailLabel.textColor
            }
            
            let selectionView = UIView(frame: CGRect.zero)
            selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
            cell.selectedBackgroundView = selectionView
            
            if indexPath.row == 2 {
                let addressLabel = cell.viewWithTag(100) as! UILabel
                addressLabel.textColor = UIColor.whiteColor()
                addressLabel.highlightedTextColor = addressLabel.textColor
            }
    }
}

extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //LocationDetailsViewController must conform to both UIImagePickerControllerDelegate and UINavigationControllerDelegate to provide picking photo function, but you don’t have to implement any of the UINavigationControllerDelegate methods.
    func takePhotoWithCamera() {
        let imagePicker = MyImagePickerController()
        imagePicker.view.tintColor = view.tintColor
        imagePicker.sourceType = .Camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
            let imagePicker = MyImagePickerController()
            imagePicker.view.tintColor = view.tintColor
            imagePicker.sourceType = .PhotoLibrary
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
                
       image = info[UIImagePickerControllerEditedImage] as? UIImage
                
       /*if let image = image {
        showImage(image)
        } this code is replaced to the observer for image variable as alternative variant*/
         tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
        showPhotoMenu()
    } else {
        choosePhotoFromLibrary()
        }
    }
   
    func showPhotoMenu() {
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let takePhotoAction = UIAlertAction(title: "Take Photo", style: .Default, handler:{ _ in self.takePhotoWithCamera() })
            alertController.addAction(takePhotoAction)//A handler is a closure that calls the corresponding method from the extension.
            //you ignore the parameter that is passed to this closure which is a reference to the UIAlertAction itself
            let chooseFromLibraryAction = UIAlertAction(title: "Choose From Library", style: .Default, handler: { _ in self.choosePhotoFromLibrary()} )
            alertController.addAction(chooseFromLibraryAction)
            
            presentViewController(alertController, animated: true, completion: nil)
    }
}

