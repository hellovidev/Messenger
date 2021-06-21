//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    private let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        loadMessages()
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email {
            var ref: DocumentReference? = nil
            ref = db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.senderField: messageSender,
                K.FStore.bodyField: messageBody,
                K.FStore.dateField: Date().timeIntervalSince1970
            ]) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }
                    print("Document added with ID: \(ref!.documentID)")
                }
            }
        }
    }
    
    private func loadMessages() {
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                if let documentSnapshot = querySnapshot?.documents {
                    self.messages = []
                    for document in documentSnapshot {
                        if let sender = document.data()[K.FStore.senderField] as? String, let body = document.data()[K.FStore.bodyField] as? String {
                            self.messages.append(Message(sender: sender, body: body))
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                let indexPath = IndexPath.init(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func logoutAction(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row].body
        let user = self.messages[indexPath.row].sender
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.messageLabel.text = message

        if let currentUser = Auth.auth().currentUser?.email {
            if user == currentUser {
                cell.senderAvatarImage.isHidden = true
                cell.avatarImage.isHidden = false
                cell.messageBubble.backgroundColor = .cyan
                cell.messageLabel.textColor = .black
            } else {
                cell.senderAvatarImage.isHidden = false
                cell.avatarImage.isHidden = true
                cell.messageBubble.backgroundColor = .purple
                cell.messageLabel.textColor = .white
            }
        }
        return cell
    }
    
}
