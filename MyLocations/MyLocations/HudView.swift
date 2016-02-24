//
//  HudView.swift
//  MyLocations
//
//  Created by MyMacbook on 2/24/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//

import UIKit
class HudView: UIView {
    var text = ""
    class func hudInView(view: UIView, animated: Bool) -> HudView {
    let hudView = HudView(frame: view.bounds)
    hudView.opaque = false
    view.addSubview(hudView)
    view.userInteractionEnabled = false
    return hudView
    }
    
    override func drawRect(rect: CGRect) {
        let boxWidth: CGFloat = 96
        let boxHeight: CGFloat = 96
        let boxRect = CGRect(x: round(bounds.size.width - boxWidth)/2, y: round(bounds.size.height - boxHeight)/2, width: boxWidth, height: boxHeight)
        let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
        UIColor(white: 0.3, alpha: 0.8).setFill()//alpha: 0.8 mean an 80% opaque opaque dark gray color.
        roundedRect.fill()
    }
}
