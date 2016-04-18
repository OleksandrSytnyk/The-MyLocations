//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by MyMacbook on 4/18/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//
//This class is needed because the Navigation Controller that embeds the Tag/Edit Location screen is presented modally on top of the other screens and is therefore not part of the Tab Bar Controller hierarchy.

import UIKit

class MyTabBarController: UITabBarController {
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .LightContent
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
    return nil// nil means that the tab bar controller will look at its own preferredStatusBarStyle() method.
    }
}