//
//  UIView+Extensions.swift
//  ValetFixChat
//
//  Created by Alex on 1/29/19.
//  Copyright © 2019 Ryan. All rights reserved.
//

import Foundation
import UIKit

struct UIViewExtensionConstants {
    static let CornerRadiusForButton : CGFloat = 25
    static let CornerRadiusForLabel : CGFloat = 10
}

extension UIView {
    func roundButtonEdge() {
        self.layer.cornerRadius = UIViewExtensionConstants.CornerRadiusForButton
        self.layer.masksToBounds = true 
    }
    
    func roundLabelEdge() {
        self.layer.cornerRadius = UIViewExtensionConstants.CornerRadiusForLabel
        self.layer.masksToBounds = true 
    }
    
    func makeCircle() {
        self.layer.cornerRadius = self.frame.size.height / 2;
        self.layer.masksToBounds = true;
    }
    
    func hideOver(duration : TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
            self.alpha = 0
        }, completion: nil)
    }
    
    func showOver(duration : TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
            self.alpha = 1
        }, completion: nil)
    }
    //HERE
    public func anchorCenterXToSuperview(constant: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        if let anchor = superview?.centerXAnchor {
            centerXAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        }
    }
    
    public func anchorCenterYToSuperview(constant: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        if let anchor = superview?.centerYAnchor {
            centerYAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        }
    }
    
    public func anchorCenterSuperview() {
        anchorCenterXToSuperview()
        anchorCenterYToSuperview()
    }
    
}
