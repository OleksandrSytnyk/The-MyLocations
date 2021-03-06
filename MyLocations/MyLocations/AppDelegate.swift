//
//  AppDelegate.swift
//  MyLocations
//
//  Created by MyMacbook on 2/12/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//

import UIKit
import CoreData

let MyManagedObjectContextSaveDidFailNotification = "MyManagedObjectContextSaveDidFailNotification"
func fatalCoreDataError(error: ErrorType) {
    print("*** Fatal error: \(error)")
    NSNotificationCenter.defaultCenter().postNotificationName(MyManagedObjectContextSaveDidFailNotification, object: nil)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        guard let modelURL = NSBundle.mainBundle().URLForResource("DataModel", withExtension: "momd") else {
            fatalError("Could not find data model in app bundle")
        }//The Core Data model you created earlier is stored in your application bundle in a folder named “DataModel.momd”. Here you create an NSURL object pointing at this folder in the app bundle.
        
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing model from: \(modelURL)")
        }//Create an NSManagedObjectModel from that URL.
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsDirectory = urls[0]
        let storeURL = documentsDirectory.URLByAppendingPathComponent("DataStore.sqlite")
        // The app’s data is stored in an SQLite database inside the app’s Documents folder. Here you create an NSURL object pointing at the DataStore.sqlite file.
        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            // The NSPersistentStoreCoordinator object is in charge of the SQLite database.
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                configuration: nil, URL: storeURL, options: nil)
            //Add SQLite database to the store coordinator
            let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)//create the NSManagedObjectContext object, which is the object that you use to talk to Core Data. You first make your changes to the context and then you call its save() method to store those changes permanently in the data store. That means every object that needs to do something with Core Data needs to have a reference to the NSManagedObjectContext object.
            context.persistentStoreCoordinator = coordinator
            //print(storeURL)
            print(documentsDirectory)
            
            return context
        }
            
        catch {
            fatalError("Error adding persistent store at \(storeURL): \(error)")
        }
    }()//This is the method to load the data model that is defined in DataModel.xcdatamodeld, and connect it to an SQLite data store. This is very standard stuff that will be the same for almost any Core Data app you’ll write.
    
    func customizeAppearance() {
        UINavigationBar.appearance().barTintColor = UIColor.blackColor()//this is background color of all navigation bars
        UINavigationBar.appearance().titleTextAttributes = [ NSForegroundColorAttributeName: UIColor.whiteColor() ]
        UITabBar.appearance().barTintColor = UIColor.blackColor()//background color of all tab bars
        
        let tintColor = UIColor(red: 255/255.0, green: 238/255.0, blue: 136/255.0, alpha: 1.0)
        UITabBar.appearance().tintColor = tintColor
    }


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        customizeAppearance()
        
        let tabBarController = window!.rootViewController
            as! UITabBarController
        if let tabBarViewControllers = tabBarController.viewControllers {
        let currentLocationViewController = tabBarViewControllers[0] as! CurrentLocationViewController
        currentLocationViewController.managedObjectContext = managedObjectContext
            
            let navigationController = tabBarViewControllers[1]
                as! UINavigationController
            let locationsViewController = navigationController.viewControllers[0] as! LocationsViewController
            locationsViewController.managedObjectContext = managedObjectContext
            
            let _ = locationsViewController.view// You need this line to fix the IOS bug
            
            let mapViewController = tabBarViewControllers[2] as! MapViewController
            mapViewController.managedObjectContext = managedObjectContext
        }
        listenForFatalCoreDataNotifications()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func listenForFatalCoreDataNotifications() {
    
        NSNotificationCenter.defaultCenter().addObserverForName( MyManagedObjectContextSaveDidFailNotification, object: nil, queue: NSOperationQueue.mainQueue(),
        usingBlock: { notification in
   
        let alert = UIAlertController(title: "Internal Error", message: "There was a fatal error in the app and it cannot continue.\n\n" + "Press OK to terminate the app. Sorry for the inconvenience.", preferredStyle: .Alert)
     
        let action = UIAlertAction(title: "OK", style: .Default) { _ in let exception = NSException(
        name: NSInternalInconsistencyException,
        reason: "Fatal Core Data error", userInfo: nil)
            exception.raise()
            }
        alert.addAction(action)
     
        self.viewControllerForShowingAlert().presentViewController(
        alert, animated: true, completion: nil)
        })
    }

        func viewControllerForShowingAlert() -> UIViewController {
            let rootViewController = self.window!.rootViewController!
            if let presentedViewController =
        rootViewController.presentedViewController {
            return presentedViewController
        } else {
        return rootViewController
        }
    }
}

