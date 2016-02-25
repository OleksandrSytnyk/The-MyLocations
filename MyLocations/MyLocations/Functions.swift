//
//  Functions.swift
//  MyLocations
//
//  Created by MyMacbook on 2/25/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//

import Foundation
import Dispatch

func afterDelay(seconds: Double, closure: () -> ()) {
    let when = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    dispatch_after(when, dispatch_get_main_queue(), closure)
}//This is a free function, not a method inside an object, and as a result it can be used from anywhere in your code.

