//
//  ChatViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import SVProgressHUD

class ChatViewController: BarHidableViewController {
    @IBOutlet weak var tblChats: UITableView!
    var dataSource: DataSource<Room>?
    var selectedRoom: Room?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let tabBarController = self.tabBarController {
            tabBarController.tabBar.isHidden = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDataSource()
    }
    
    func createRoom(title: String?) {
        guard let title = title else { return }
        
        let room: Room = Room()
        room.name = title
        SVProgressHUD.show(withStatus: "Wait...")
        room.save({ (ref, err) in
            SVProgressHUD.dismiss()
            if let project = Manager.shared.currentProject {
                project.chatRooms.insert(room.id)
            }
        })
    }

    func setupDataSource() {
        let options: Options = Options()
        options.limit = 50
        //        options.predicate = NSPredicate(format: "age == 21")
        options.sortDescirptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        if let project = Manager.shared.currentProject {
            self.dataSource = DataSource(reference: project.ref.child("chatRooms"), block: { (changes) in
                guard let tableView: UITableView = self.tblChats else {return}
                
                switch changes {
                case .initial:
                    tableView.reloadData()
                case .update(let deletions, let insertions, let modifications):
                    tableView.beginUpdates()
                    tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    tableView.endUpdates()
                case .error(let error):
                    print(error)
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "sid_createchatroom" {
                let controller = segue.destination as! PromptViewController
                controller.delegate = self
                controller.type = .addChatRoom
                controller.title = "Create a Chat Room"
            }
            else if identifier == "sid_chatroom" {
                if let tabBarController = self.tabBarController {
                    tabBarController.tabBar.isHidden = true
                }
                let roomController = segue.destination as! RoomViewController
                roomController.room = self.selectedRoom
            }
        }
    }
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ROOM_CELL", for: indexPath) as! RoomTableViewCell
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(_ cell: RoomTableViewCell, atIndexPath indexPath: IndexPath) {
        cell.disposer = self.dataSource?.observeObject(at: indexPath.item, block: { (room) in
            guard let room = room else {return}
            cell.reset(with: room)
            cell.setNeedsLayout()
        })
    }
    
    private func tableView(_ tableView: UITableView, didEndDisplaying cell: RoomTableViewCell, forRowAt indexPath: IndexPath) {
        //self.dataSource?.removeObserver(at: indexPath.item)
        cell.disposer?.dispose()
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let source = self.dataSource,
                let project = Manager.shared.currentProject,
                let user = Manager.shared.user {
                if indexPath.row < source.count {
                    let room = source.objects[indexPath.row]
                    if let managerId = project.managerId, managerId != user.id {
                        return
                    }
                    project.chatRooms.remove(room.id)
                    for messageId in room.messages {
                        if let message = Message(id: messageId) {
                            message.remove()
                        }
                    }
                    room.messages.removeAll()
                    room.remove()
                }
            }
            self.dataSource?.removeObject(at: indexPath.item, block: { (key, error) in
                if let error: Error = error {
                    print(error)
                }
            })
        }
    }
}

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let source = self.dataSource {
            if indexPath.row < source.count {
                self.selectedRoom = source.objects[indexPath.row]
                self.performSegue(withIdentifier: "sid_chatroom", sender: self)
            }
        }
    }
}

extension ChatViewController: PromptDelegate {
    func done(with values: [String : Any]) {
        let name = values["Room Name"] as? String
        self.createRoom(title: name)
    }
    
    func invalidField(values: [String : Any]) -> String? {
        for (key, value) in values {
            if (value as! String).count == 0 {
                return key
            }
        }
        return nil
    }
}
