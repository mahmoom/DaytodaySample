//
//  ComposeMessage+Extensions.swift
//  ValetFixChat
//
//  Created by Suhaib Mahmood on 5/11/19.
//  Copyright © 2019 Alex. All rights reserved.
//HERE

import UIKit
import Firebase
// MARK: - UISearchBarDelegate

extension ComposeMessage {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UISearchResultsUpdating

extension ComposeMessage {
    
    func updateSearchResults(for searchController: UISearchController) {
        // Update the filtered array based on the search text.
        let searchResults = contacts
        let firebaseSearchResults = firebaseContacts
        let searchString = searchController.searchBar.text!
        if searchString.condensedWhitespace == ""{
            //let VC know that we don't need to show the searchResults array. If user
            //input is fast enough, we could reload table with an empty array and crash
            self.isSearchActive = false
            self.tableView.reloadData()
            return
        }
        isSearchActive = true
        
        //make search string case insensitive, and get components seperated by spaces
        //then remove empty components, followed by searching on components
        let searchItems = searchString.components(separatedBy: " ").map{$0.lowercased()}.filter({ $0.condensedWhitespace != "" })
        
        //keep track of how many contacts being searched over to reload table
        //after what user can reasonably see is displayed while remainder loads
        var searchCounter: Int?
        if contacts.count >= effeciencyCutoffs.minimumSearchResultsToLoad{
            searchCounter = 0
        }
        
        //implementing a basic debounced function in case contacts object is very large and running search with each character click is performance intensive
        let debouncedSearch = debounce(interval: 150, queue: DispatchQueue.global(qos: .userInitiated)) {
            
            //we create this to store database users found by username
            //so we can show the contact with that phone number as search
            //result too
            var firebaseUserNumbersFromUsernameSearch: [String] = []
            
            
            if (searchCounter != nil){
                searchCounter! += 1
                if searchCounter! % effeciencyCutoffs.minimumSearchResultsToLoad == 0{
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
            
            //filter firebase contacts from search items, look through username and number
            self.searchedFirebaseContacts = firebaseSearchResults.filter ({( user : UserDetails) -> Bool in
                var foundBySearch = true
                let userName = user.userName.lowercased(), userPhoneNumber = user.userPhoneNumber.formatNum
                
                //look through all name and phone search item, and username can include
                //number, but number will only be numbers
                for searchItem in searchItems{
                    let searchItemString = searchItem.lowercased(), searchItemPhone = searchItem.formatNum
                    foundBySearch = userName.contains(searchItemString) ||
                        userPhoneNumber.contains(searchItemPhone)
                    if userName.contains(searchString){
                        //save number to add matching number to contact list after
                        //contact search (gets filtered out if we do it here)
                        firebaseUserNumbersFromUsernameSearch.append(userPhoneNumber)
                    }
                    //if a single search item doesn't match, let's quit and return false
                    if !foundBySearch {
                        break
                    }
                }
                return foundBySearch
            })
            
            self.searchedContacts = searchResults.filter ({( contact : ContactStruct) -> Bool in
                var foundBySearch = true
                var numberFoundBySearch: String?
                let firstName = contact.firstName.lowercased(), lastName = contact.lastName.lowercased(), contactPhoneNumber = contact.number.formatNum
                
                //loop through first last name and number
                for searchItem in searchItems{
                    let searchItemString = searchItem.lowercased(), searchItemPhone = searchItem.formatNum
                    foundBySearch = firstName.contains(searchItemString) ||
                        lastName.contains(searchItemString) || contactPhoneNumber.contains(searchItemPhone)
                    if firstName.contains(searchItemString) ||
                        lastName.contains(searchItemString) {
                        numberFoundBySearch = contactPhoneNumber
                    }
                    if !foundBySearch {
                        break
                    }
                }
                
                //if found contact with name search, find matching number and add to
                //firebase search results
                if let number = numberFoundBySearch?.formatNum{
                    var alreadyIncluded = false
                    for user in self.searchedFirebaseContacts{
                        if user.userPhoneNumber.formatNum == number {
                            alreadyIncluded = true
                        }
                    }
                    //add only if the number isn't already there (if username is same
                    //as first and last
                    if !alreadyIncluded {
                        let firebaseUsersWithNumber = self.firebaseContacts.filter{ $0.userPhoneNumber.formatNum == number }
                        //contacts are a superset of firebase users
                        if !firebaseUsersWithNumber.isEmpty{
                            self.searchedFirebaseContacts.append(firebaseUsersWithNumber[0])
                            
                        }
                        
                    }
                }
                return foundBySearch
            })
            
            //add back to contacts the firebase users found by username
            for number in firebaseUserNumbersFromUsernameSearch{
                var alreadyIncluded = false
                for contact in self.searchedContacts{
                    if contact.number.formatNum == number {
                        alreadyIncluded = true
                    }
                }
                if !alreadyIncluded {
                    //firebase users are subset of contacts
                    self.searchedContacts.append(self.contacts.filter{ $0.number.formatNum == number }[0])
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }
        debouncedSearch()
    }
}


