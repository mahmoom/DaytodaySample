//
//  Alert.swift
//  ValetFixChat
//
//  Created by Suhaib Mahmood on 5/12/19.
//  Copyright © 2019 Alex. All rights reserved.
//HERE

import UIKit

class Alert{
    class func showBasic(title: String, message: String, vc: UIViewController, tableView: UITableView? = nil, indexPath: IndexPath? = nil) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        //if tableview message, let's deselect the cell
        if let tV = tableView, let iP = indexPath{
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                tV.deselectRow(at: iP, animated: true)
            })
        }else{
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }
        
        vc.present(alert,animated: true)
    }
}
