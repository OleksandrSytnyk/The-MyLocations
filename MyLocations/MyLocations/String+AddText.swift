//
//  String+AddText.swift
//  MyLocations
//
//  Created by MyMacbook on 4/17/16.
//  Copyright © 2016 Oleksandr. All rights reserved.
//

extension String {
    
    mutating func addText(text: String?, withSeparator separator: String = "") {
        
        if let text = text {
            
            if !text.isEmpty {
                self += separator
            }
            self += text
        }
    }
}