//
//  NewChatNetworkManager.swift
//  ValetFixChat
//
//  Created by Suhaib Mahmood on 5/11/19.
//  Copyright © 2019 Alex. All rights reserved.
//HERE

import UIKit
import Firebase

struct NewChatNetworkManager {
    func checkPhoneNumberInDB(_ phoneNumber: String, completion: @escaping (_ phoneInDatabase: Bool) -> Void) {
        
        FirebaseDatabase.UserDatabaseReference.observeSingleEvent(of: .value, with: {(snapshot) in
            
            if snapshot.hasChild(phoneNumber.numbersOnly){
                completion(true)
            } else{
                completion(false)
            }
            
        })
        
    }
}
