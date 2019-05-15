//
//  UINavigationController+Extensions.swift
//  ValetFixChat
//
//  Created by Ryan on 1/31/19.
//  Copyright © 2019 Ryan. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {
    func currentviewController() -> UIViewController {
        if visibleViewController != nil {
            return visibleViewController!
        } else {
            return self
        }
    }
}
