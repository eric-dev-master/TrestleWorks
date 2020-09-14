//
//  TeamViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import SVProgressHUD

protocol TeamViewControllerDelegate {
    func didSelect(member user: User)
}

class TeamViewController: BarHidableViewController {
    @IBOutlet weak var tblUsers: UITableView!
    var dataSource: DataSource<User>?
    var delegate: TeamViewControllerDelegate?
    
    func addMemberWith(email: String, name: String) {
        let project: Project = Manager.shared.currentProject

        SVProgressHUD.show()
        User.load(email: email, completion: { (returnedUser) in
            SVProgressHUD.dismiss()
            if let returnedUser = returnedUser {
                if returnedUser.name == nil {
                    returnedUser.name = name
                }
                returnedUser.invited.contains(project, block: { (result) in
                    if (result) {
                        self.alert(message: "You had already sent invitation to this member.")
                    }
                    else {
                        project.users.contains(returnedUser, block: { (result) in
                            if (result) {
                                self.alert(message: "The user is already a member of the Project.")
                            }
                            else {
                                returnedUser.invited.insert(project)
                                let userName = returnedUser.name ?? returnedUser.email ?? ""
                                self.alert(message: "You sent invitation to " + userName)
                            }
                        })
                    }
                })
            }
            else {
                self.alert(title: "Sorry...", message: "No user with the email registered yet. Are you going to send an invitation email?", options: "Yes", "No", completion: { (index) in
                    if index == 0 {
                        //Send Email View Controller Here.
                    }
                })
            }
        })
    }
    
    func setupDataSource() {
        let options: Options = Options()
        options.limit = 10
        options.sortDescirptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        if let project = Manager.shared.currentProject {
            self.dataSource = DataSource(reference: project.users.ref, block: { (changes) in
                guard let tableView: UITableView = self.tblUsers else {return}
                
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDataSource()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier, identifier == "sid_addteammember" {
            let controller = segue.destination as! PromptViewController
            controller.delegate = self
            controller.type = .addMember
            controller.title = "Add Team Member"
        }
    }
}

extension TeamViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "USER_CELL", for: indexPath) as! UserTableViewCell
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(_ cell: UserTableViewCell, atIndexPath indexPath: IndexPath) {
        cell.disposer = self.dataSource?.observeObject(at: indexPath.item, block: { (user) in
            guard let user = user else {return}
            cell.reset(with: user)
            cell.setNeedsLayout()
        })
    }
    
    private func tableView(_ tableView: UITableView, didEndDisplaying cell: UserTableViewCell, forRowAt indexPath: IndexPath) {
        //self.dataSource?.removeObserver(at: indexPath.item)
        cell.disposer?.dispose()
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let source = self.dataSource {
                if indexPath.row < source.count {
                    let user = source.objects[indexPath.row]
                    if let project = Manager.shared.currentProject {
                        if let managerId = project.managerId, managerId != Manager.shared.user.id {
                            return
                        }
                        user.projects.remove(project)
                    }
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

extension TeamViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let source = self.dataSource {
            if indexPath.row < source.count {
                let user = source.objects[indexPath.row]
                if let delegate = self.delegate {
                    delegate.didSelect(member: user)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

extension TeamViewController: PromptDelegate {
    func done(with values: [String : Any]) {
        if let email = values["Email"] as? String,
            let name = values["Name"] as? String{
            self.addMemberWith(email: email, name: name)
        }
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
