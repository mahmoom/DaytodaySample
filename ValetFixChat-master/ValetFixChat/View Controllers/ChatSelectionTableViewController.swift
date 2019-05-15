//
//  ChatSelectionTableViewController.swift
//  ValetFixChat
//
//  Created by Ryan on 1/30/19.
//  Copyright © 2019 Ryan. All rights reserved.
//

import Foundation
import UIKit

class ChatSelectionTableViewController: UITableViewController {
    
    // MARK: - Storyboard
    struct Storyboard {
        static let ChatSegue = "Chat Segue"
        static let ConversationCellIdentifier = "Conversation Cell"
        
        static let GoBackToChatSelectionSegue = "Go Back To Chat Selection"
        
        static let LogoutSegue = "Logout Segue"
        
    }
    
    // MARK: - Constants
    struct Constants {    
        static let NewConversationErrorAlertTitle = "There was a problem"
        static let NewConversationErrorAlertBody = "Chat could not be established with the given number."
        
        static let NewConversationAlertTitle = "Find a person to chat with"
        static let NewConversationAlertBody = "Enter the number of the person you wish to chat with"
        
        static let NewConversationAlertStartChatButtonText = "Start"
        static let NewConversationAlertCancelButtonText = "Cancel"
        
        static let PhoneNumberLength = 6
        static let TableViewCellHeight : CGFloat = 80
    }
    
    // MARK: - Instance Variables
    var userPhoneNumber : String?
    
    //Receiver Phone number, we will start a new chat to this number
    private var toPhoneNumber : String?
    
    //The name of the user we are chatting with to display in chat
    private var toUserName : String?
    
    //The action that is called when the user decides to start a conversation with entered phone number
    private var startChatAction : UIAlertAction?
    
    //Network manager that will be responsible for storing messages, and downloaded messages from firebase
    private lazy var chatSelectionNM : ChatSelectionNetworkManager = {
        let nm = ChatSelectionNetworkManager(delegate: self, userPhoneNumber: userPhoneNumber!)
        return nm
    }()
    
    // MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: - Chat Message Composition functions
    @IBAction func composeNewMessage(_ sender: Any) {
        //User pressed the compose button, we present them with a alert VC that allows them to enter the number of a user they wish to chat with
        //HERE
//        let newConversationAlertVC = createNewChatVC()
//        present(newConversationAlertVC, animated: true, completion: nil)
        let newConversationTableVC = createNewChatVC()
        self.navigationController?.pushViewController(newConversationTableVC, animated: true)
    }
    
    // MARK: - Sign Out functions
    
    //User pressed sign out, we unwind and send them back to the main screen
    @IBAction func signOut(_ sender: Any) {
        performSegue(withIdentifier: Storyboard.LogoutSegue, sender: self)
    }
    
    // MARK: - New Conversation Alert Functions
    
    //HERE: We want to display the view controller, not the popup so commenting out below and rewriting up here appropriately (so you can easily compare)
    
    private func createNewChatVC() -> UITableViewController {
        let newConversationTableVC = ComposeMessage()
        //do any data passing or setup for the table view controller here
        newConversationTableVC.userPhoneNumber = self.userPhoneNumber
        return newConversationTableVC
        
    }
    
    // establish whether the user exists and if so opens a chat with them
//    private func createNewChatVC() -> UIAlertController {
//        let newConversationAlertVC = UIAlertController(title: Constants.NewConversationAlertTitle, message: Constants.NewConversationAlertBody, preferredStyle: .alert)
//        newConversationAlertVC.addTextField { (textField) in
//            textField.delegate = self
//            textField.placeholder = "4441234"
//        }
//        //Action to use if user decides to cancel
//        let cancelAction = UIAlertAction(title: Constants.NewConversationAlertCancelButtonText, style: .cancel, handler: nil)
//        //Action to use if user decides to start chat
//        let continueAction = UIAlertAction(title: Constants.NewConversationAlertStartChatButtonText, style: .default) { [unowned self] (action) in
//
//
//            if let toPhoneNumber = newConversationAlertVC.textFields?.first?.text {
//
//                //Check to see if the person you wish to chat with exists on the server
//                self.chatSelectionNM.shouldStartConversation(withReceiverPhoneNumber: toPhoneNumber, completionHandler: { (numberExists) in
//                    //If it does, we begin the chat by sending them to the chat view controller
//                    if numberExists {
//                        self.toPhoneNumber = toPhoneNumber
//                        self.performSegue(withIdentifier: Storyboard.ChatSegue, sender: self)
//                    } else {
//                        //Otherwise, we were unable to find the user and we send the user an error
//                        let errorVC = self.createErrorAlert()
//                        self.present(errorVC, animated: true, completion: nil)
//                    }
//                })
//            }
//        }
//
//        //We set the continue action to false at first until the user enters a valid phone number
//        continueAction.isEnabled = false
//        startChatAction = continueAction
//        newConversationAlertVC.addAction(cancelAction)
//        newConversationAlertVC.addAction(continueAction)
//        return newConversationAlertVC
//
//    }
    
    //Error alert to display incase the user entered an invalid phone number 
    private func createErrorAlert() -> UIAlertController {
        let errorAlertVC = UIAlertController(title: Constants.NewConversationErrorAlertTitle, message: Constants.NewConversationErrorAlertBody, preferredStyle: .alert)
        errorAlertVC.addAction(UIAlertAction(title: Constants.NewConversationAlertCancelButtonText, style: .cancel, handler: nil))
        return errorAlertVC
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatSelectionNM.currentChats.count
    }
    
    // MARK: - Tableview Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 0){
            tableView.deselectRow(at: indexPath, animated: true)
            let message = chatSelectionNM.currentChats[indexPath.row]
            
            //Check to make sure we arent sending messages to our own number.
            self.toPhoneNumber = message.receiverID == userPhoneNumber! ? message.senderID : message.receiverID
            performSegue(withIdentifier: Storyboard.ChatSegue, sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.TableViewCellHeight
    }
    
    // MARK: - TableView Cell Registration
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.ConversationCellIdentifier, for: indexPath) as! ChatSelectionTableViewCell
        var message : Message
        message = chatSelectionNM.currentChats[indexPath.row]

        cell.userPhoneNumber = userPhoneNumber
        cell.message = message
        return cell
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case Storyboard.ChatSegue :
            
            if let chatVC = segue.destination as? ChatViewController {
                chatVC.myPhoneNumber = userPhoneNumber
                chatVC.receiverPhoneNumber = toPhoneNumber
            }
        default :
            break
        }
    }
    
    @IBAction func unwindBackToChatSelection(segue : UIStoryboardSegue) {
    }
}

extension ChatSelectionTableViewController : ChatSelectionViewModelDelegate {
    func conversationsUpdated() {
        self.tableView.reloadData()
    }
}

extension ChatSelectionTableViewController : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, text.count == Constants.PhoneNumberLength {
            startChatAction?.isEnabled = true
        }
        return true
    }
    
}
