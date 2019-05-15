//
//  ChatSelectionTableViewCell.swift
//  ValetFixChat
//
//  Created by Ryan on 1/31/19.
//  Copyright © 2019 Ryan. All rights reserved.
//

import UIKit
import Firebase

class ChatSelectionTableViewCell: UITableViewCell {
    
    // MARK: - Constants
    struct Constants {
        static let DefaultDateFormat = "MM/dd/yy"
    }

    
    // MARK: - Message
    var message : Message? {
        didSet {
            if message != nil {
                setupCellWith(setMessage: message!)
            }
        }
    }
    
    var userPhoneNumber : String? 
    
    // MARK: - Instance Variables
    private lazy var dateFormatter : DateFormatter = {
       let df = DateFormatter()
        df.dateFormat = Constants.DefaultDateFormat
        return df
    }()
    
    var chatUserName : String? {
        return nameLabel.text
    }

    // MARK: - Outlets
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
           profileImageView.makeCircle()
//           profileImageView.image = UIImage(named: "DefaultProfileImage")
           profileImageView.backgroundColor = UIColor(red:0.90, green:0.90, blue:0.92, alpha:1.0)
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var initialsLabel: UILabel!
    
    
    // MARK: - Cell Setup
    private func setupCellWith(setMessage : Message) {
        
        //We check to make sure that the receiver is not ourselves, since we only want to display the other users display name in the chat selection
        let idOfUserNameToFetch = setMessage.receiverID == userPhoneNumber! ? setMessage.senderID : setMessage.receiverID
        
        FirebaseDatabase.UserDatabaseReference.child(idOfUserNameToFetch).observeSingleEvent(of: .value) { (data) in
            if let dictionaryValues = data.value as? [String : Any] {
                let nameToDisplay = dictionaryValues[UserKeys.UserNameKey] as! String
                
                //Always display the other user's name
                self.nameLabel.text = nameToDisplay
                //grabs the first letter of EACH word: change to grab only the first letter of the first word and last word (in case people have multiple spaces in either of their names
                self.initialsLabel.text = self.nameLabel.text?.components(separatedBy: " ").map { String($0.prefix(1))}.joined()
            }
            
        }
        switch setMessage.kind {
        case .text(let bodyMessage) :
            self.bodyLabel.text = bodyMessage
        default :
            break
        }
        self.dateLabel.text = dateFormatter.string(from: setMessage.sentDate)
    }
    
    // MARK: - Init
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
