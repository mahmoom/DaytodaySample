//
//  ComposeMessage.swift
//  ValetFixChat
//
//  Created by Ryan on 2/4/19.
//  Copyright © 2019 Ryan. All rights reserved.
//
//HERE built the entire class
import UIKit
import Contacts
import Firebase



class ComposeMessage: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    struct Constants {
        static let contactCellId = "contactCellId"
        static let numberOfSections = 2
        static let contactsSectionHeaderTitle = "Contacts"
        static let firebaseUsersSectionHeaderTitle = "Firebase Users"
        static let noNumber = "No Number"
    }
    
    struct effeciencyCutoffs {
        static let minimumContactsToLoad = 20
        static let minimumSearchResultsToLoad = 55
    }
    
    
    //MARK: VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.contactCellId)
        tableView.delegate = self
        tableView.dataSource = self
        setupNavigationFeatures()
        setupSearchController()
        setupViews()
        
        //gets rid of lines on empty rows
        tableView.tableFooterView = UIView()
        //get access to user contacts
        requestAccess {_ in }
        
        //We add in a gesture recognizer here to dismiss any keyboards if the user clicks on nav bar, clicking cell will select it
    self.navigationController?.navigationBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboards)))
        
        //this is really just for iOS 10 and earlier, iOS11+ manages this on it's own
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //more closely resembles iPhone new Message creator as we start in search
        searchController.isActive = true
    }
    
    // MARK: - Gesture Functions
    @objc func dismissKeyboards() {
        searchController.searchBar.resignFirstResponder()
    }
    
    //MARK: Instance Variables
    var searchController: UISearchController!
    lazy var headerSearchBarIfNeeded: UIView = {
        let view = UIView()
        return view
    }()
    var contactStore = CNContactStore()
    var contacts = [ContactStruct]()
    var searchedContacts = [ContactStruct]()
    var firebaseContacts = [UserDetails]()
    var searchedFirebaseContacts = [UserDetails]()
    //handles checking firebase phone number
    private let newChatNetworkManager = NewChatNetworkManager()
    //assigned when starting a new chat
    var toPhoneNumber: String?
    //this is set from the class before, can be traced back to initial login/signup
    var userPhoneNumber : String?
    //tracks whether to show full list of contacts regardless of cursor placement in search bar
    var isSearchActive = false

    //MARK: Views

    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.center = self.view.center
        indicator.hidesWhenStopped = true
        indicator.style = .whiteLarge
        indicator.color = .gray
        return indicator
    }()
    
    //MARK: Setup View functions
    
    private func setupViews(){
        self.navigationController?.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    
    //MARK: Navigation related view setup
    private func setupNavigationFeatures(){
        
        //doing this to more closely resemble iPhone new message UI
            self.navigationItem.hidesBackButton = true
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(popNavController))
            self.navigationItem.title = "New Message"
    }
    
    @objc func popNavController(){
        self.navigationController?.popViewController(animated: true)
    }
    
    
    //MARK: Requesting access to Contacts
    
    func requestAccess(completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            self.fetchConctacts()
            self.tableView.reloadData()
            completionHandler(true)
        case .denied:
            contacts.removeAll()
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
            showSettingsAlert(completionHandler)
        case .restricted, .notDetermined:
            contactStore.requestAccess(for: .contacts) { granted, error in
                if granted {
                    self.fetchConctacts()
                    completionHandler(true)
                } else {
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.showSettingsAlert(completionHandler)
                    }
                }
            }
        }
    }
    private func showSettingsAlert(_ completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: "This app requires access to Contacts to proceed. Would you like to open settings and grant permission to contacts?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { action in
            completionHandler(false)
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
            completionHandler(false)
        })
        present(alert, animated: true)
    }
    
    private func fetchConctacts(){
        //put on lower priority queue so longer contact list doesn't freeze app
        DispatchQueue.global(qos: .userInitiated).async {
        let key = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: key)
        do{
            try self.contactStore.enumerateContacts(with: request) { (contact, stoppingPointer) in
            let firstName = contact.givenName
            let lastName = contact.familyName
                
                for number in contact.phoneNumbers{
                let numberString = number.value.stringValue
                    
                    let contactToAppend = ContactStruct(firstName: firstName, lastName: lastName, number: numberString)
                    self.contacts.append(contactToAppend)
                    self.searchedContacts = self.contacts
                    
                    //to ensure responsiveness, let's reload table once we have 20 contacts
                    if self.contacts.count == effeciencyCutoffs.minimumContactsToLoad {
                        //allow user search entry and reload table
                        DispatchQueue.main.async(execute: {
                            self.tableView.reloadData()
                            self.activityIndicator.stopAnimating()
                            self.searchController.searchBar.isUserInteractionEnabled = true
                        })
                    }
                
                //if phone number is in firebase, get fb user and add to tableview
                self.newChatNetworkManager.checkPhoneNumberInDB(numberString, completion:{ (phoneNumberInDatabase) in
                    if phoneNumberInDatabase{
                        self.pullUserInformation(fromNumber: numberString.numbersOnly)
                    }
                })
            }
            }
            
        } catch{
            print(error.localizedDescription)
        }
            DispatchQueue.main.async(execute: {
                //allow user search entry and reload table
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
                self.searchController.searchBar.isUserInteractionEnabled = true
            })
        }
    }
    
    
    //MARK: Setup search bar
    
    func didPresentSearchController(_ searchController: UISearchController) {
        //        searchController.searchBar.becomeFirstResponder()
        //a bug Apple needs to fix makes this necessary
        DispatchQueue.main.async {
            searchController.searchBar.becomeFirstResponder()
        }
    }
    
    //this should work but it doesn't, Apple bug again so implementing workaround with subclass
    //    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    //
    //        searchController.searchBar.showsCancelButton = false
    //    }
    func setupSearchController() {
        
        //custom subclass of UISearch for more control over UI layout and first responder (cursor is in search bar but keyboard doesn't appear)
            searchController = UnbrokenUISearchController(searchResultsController: nil)
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        searchController.hidesNavigationBarDuringPresentation = false
        UISearchBar.appearance().searchTextPositionAdjustment = UIOffset(horizontal: 10, vertical: 0)
        searchController.searchBar.placeholder = ""
        
        //we don't want to let user search on data before it exists
        searchController.searchBar.isUserInteractionEnabled = false
        
        if #available(iOS 11.0, *) {
            // For iOS 11 and later, we place the search bar in the navigation bar.
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            // For iOS 10 and earlier, we place the search bar in the table view's header.
            let searchBar = searchController.searchBar
            searchBar.backgroundColor = .white
            tableView.tableHeaderView?.backgroundColor = .white
            tableView.tableHeaderView = searchBar
            tableView.backgroundView = UIView()
        }
        
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false // default is YES
        searchController.searchBar.delegate = self    // so we can monitor text changes + others
        self.searchController.searchBar.barTintColor = .clear
        definesPresentationContext = true
    }
    
    //MARK: Tableview Delegate
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: Constants.contactCellId, for: indexPath)
        
        if isSearchActive{
        if indexPath.section == 1{
            if searchedFirebaseContacts.isEmpty{
                cell = UITableViewCell(style: UITableViewCell.CellStyle.default,
                                       reuseIdentifier: Constants.contactCellId)
                cell.textLabel?.text = "N/A"
                return cell
            } else{
                cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle,
                                       reuseIdentifier: Constants.contactCellId)
                let contactToDisplay = searchedFirebaseContacts[indexPath.row]
                
                cell.textLabel?.text = contactToDisplay.userName
                cell.detailTextLabel?.text = contactToDisplay.userPhoneNumber.formatNum.formatForDisplayNumAmerican
            }
        } else{
            if searchedContacts.isEmpty{
                cell = UITableViewCell(style: UITableViewCell.CellStyle.default,
                                       reuseIdentifier: Constants.contactCellId)
                cell.textLabel?.text = "N/A"
                return cell
            } else{
                cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle,
                                       reuseIdentifier: Constants.contactCellId)
                let contactToDisplay = searchedContacts[indexPath.row]
                cell.textLabel?.text = contactToDisplay.firstName + " " + contactToDisplay.lastName
                cell.detailTextLabel?.text = contactToDisplay.number.formatNum.formatForDisplayNumAmerican
            }
            }} else{
            if indexPath.section == 1{
                if firebaseContacts.isEmpty{
                    cell = UITableViewCell(style: UITableViewCell.CellStyle.default,
                                           reuseIdentifier: Constants.contactCellId)
                    cell.textLabel?.text = "N/A"
                    return cell
                } else{
                    cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle,
                                           reuseIdentifier: Constants.contactCellId)
                    let contactToDisplay = firebaseContacts[indexPath.row]
                    
                    cell.textLabel?.text = contactToDisplay.userName
                    cell.detailTextLabel?.text = contactToDisplay.userPhoneNumber.formatNum.formatForDisplayNumAmerican
                }
            } else{
                if contacts.isEmpty{
                    cell = UITableViewCell(style: UITableViewCell.CellStyle.default,
                                           reuseIdentifier: Constants.contactCellId)
                    cell.textLabel?.text = "N/A"
                    return cell
                } else{
                    cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle,
                                           reuseIdentifier: Constants.contactCellId)
                    let contactToDisplay = contacts[indexPath.row]
                    cell.textLabel?.text = contactToDisplay.firstName + " " + contactToDisplay.lastName
                    cell.detailTextLabel?.text = contactToDisplay.number.formatNum.formatForDisplayNumAmerican
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchActive{
        if section == 1 {
            if searchedFirebaseContacts.isEmpty{
                return 1
            } else{
                return searchedFirebaseContacts .count
            }
        } else{
            if searchedContacts.isEmpty{
                return 1
            } else{
                return searchedContacts.count
            }
        }
        } else{
            if section == 1 {
                if firebaseContacts.isEmpty{
                    return 1
                } else{
                    return firebaseContacts .count
                }
            } else{
                if contacts.isEmpty{
                    return 1
                } else{
                    return contacts.count
                }
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if !contacts.isEmpty{
            return Constants.numberOfSections
        } else{
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        //instructions stated to start conversation with "user", since not all contacts
        //are users, I take this to mean we can only message users. If that's incorrect,
        //the following conditional can easily be removed to allow messaging contacts
        
        if indexPath.section == 0{
            Alert.showBasic(title: "Whoops", message: "This contact isn't a registered user yet (to remove this restriction, look at didSelectRow)", vc: self, tableView: self.tableView, indexPath: indexPath)
        } else{
            self.toPhoneNumber = cell?.detailTextLabel?.text?.numbersOnly
            guard let phoneNumber = self.toPhoneNumber, let username = cell?.textLabel?.text else {
                Alert.showBasic(title: "Sorry", message: "We don't have enough information to start a chat", vc: self, tableView: self.tableView, indexPath: indexPath)
                return
            }
            //perhaps there isn't a number but a string instead
            if !phoneNumber.condensedWhitespace.isEmpty {
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let chatVC = storyBoard.instantiateViewController(withIdentifier: "Chatting") as! ChatViewController
                chatVC.myPhoneNumber = userPhoneNumber
                chatVC.receiverPhoneNumber = toPhoneNumber
                chatVC.navigationItem.title = username
                self.navigationController?.pushViewController(chatVC, animated: true)
            } else{
                Alert.showBasic(title: "Sorry", message: "There's no number to start a chat with", vc: self, tableView: self.tableView, indexPath: indexPath)
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !contacts.isEmpty{
            if section == 0{
                return Constants.contactsSectionHeaderTitle
            } else{
                return Constants.firebaseUsersSectionHeaderTitle
            }
        } else{
            return nil
        }
    }
    
    
    // MARK: - Network functions
    
    //Fetch user name and from number from firebase
    private func pullUserInformation(fromNumber : String) {
        
        FirebaseDatabase.UserDatabaseReference.child(fromNumber).observeSingleEvent(of: .value) {[weak self] (data) in
            
            guard let dataDictionary = data.value as? [String : Any] else {
                return
            }
            
            if let userName = dataDictionary[UserKeys.UserNameKey] as? String, let phoneNumber = dataDictionary[UserKeys.UserPhoneNumberKey] as? String {
                let userToAppend = UserDetails(userName: userName, userPhoneNumber: phoneNumber)
                self?.firebaseContacts.append(userToAppend)
                self?.searchedFirebaseContacts.append(userToAppend)
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        }
    }
}

