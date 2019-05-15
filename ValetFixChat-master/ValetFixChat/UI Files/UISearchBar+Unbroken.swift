//
//  UISearchBar+Unbroken.swift
//  ValetFixChat
//
//  Created by Suhaib Mahmood on 5/9/19.
//  Copyright © 2019 Alex. All rights reserved.
//HERE workaround for bad apple uisearch bar class

import UIKit

class UnbrokenUISearchBar: UISearchBar{
    override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 11.0, *) {
            //removing this older than iOS 11 makes cursor disappear
            self.showsCancelButton = false
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        let labelIcon = UILabel()
        labelIcon.text = "To:"
        labelIcon.frame = CGRect.zero
        labelIcon.sizeToFit()
        labelIcon.textColor = .lightGray
        

        //down is old
        searchBarStyle = UISearchBar.Style.minimal
        
        // Configure text field
        let textField = value(forKey: "_searchField") as! UITextField
        
        //new, but only workes in iOS 11+
        if #available(iOS 11.0, *) {
            textField.leftView = labelIcon
        }

        // This will remove the border style, we need to do this
        // in order to configure border style through `textField.layer`
        // otherwise we'll have 2 borders.
        // You can remove `textField.borderStyle = .none` to see it yourself.
        textField.borderStyle = .none
        textField.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
        textField.clipsToBounds = true
        textField.layer.cornerRadius = 6.0
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.keyboardType = .namePhonePad
        textField.textColor = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
    }
}

class UnbrokenUISearchController: UISearchController{
    var unbrokenSearchBar = UnbrokenUISearchBar()
    override var searchBar: UISearchBar{
        get{
            return unbrokenSearchBar
        }
    }
}
