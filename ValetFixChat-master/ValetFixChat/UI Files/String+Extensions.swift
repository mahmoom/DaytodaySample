//
//  String+Extensions.swift
//  ValetFixChat
//
//  Created by Suhaib Mahmood on 5/9/19.
//  Copyright © 2019 Alex. All rights reserved.
//HERE added extension class

import Foundation

extension String {
    var numbersOnly: String {
        let str = self
        let pattern = "[^0-9]+"
        let result = str.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        return result
    }
    var condensedWhitespace: String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    //function provided by interviewer
    var formatNum: String {
        let formNumber = String(self.filter { !" -()".contains($0) })
        var newNumber: String?
        if formNumber.hasPrefix("+"){
            newNumber = formNumber
        } else {
            newNumber = "+1\(formNumber)"
        }
        return newNumber!
    }
    var formatForDisplayNumAmerican: String {
        
        if self.contains("+1") && self.count == 12{
            let firstIndex = self.index(self.startIndex, offsetBy: 2)
            let secondIndex = self.index(firstIndex, offsetBy: 3)
            let thirdIndex = self.index(secondIndex, offsetBy: 3)
            
            let firstPart = self[firstIndex..<secondIndex]
            let secondPart = self[secondIndex..<thirdIndex]
            let thirdPart = self[thirdIndex...]
            return "+1 (\(firstPart)) \(secondPart)-\(thirdPart)"
    }
        return self
    }
}
