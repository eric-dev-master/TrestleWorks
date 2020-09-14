//
//  taskDetailViewController.swift
//  Construction
//
//  Created by Macmini on 3/30/18.
//  Copyright © 2018 LekshmySankar. All rights reserved.
//

import UIKit
import SVProgressHUD
import SDWebImage

class TaskDetailViewController: BarHidableViewController {
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblContent: UILabel!
    @IBOutlet weak var btnComment: UIButton!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblComments: UILabel!
    @IBOutlet weak var lblStatus: UILabel!
    
    var task: Task?
    var dataSource: DataSource<Comment>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300
        
        imgUser.layer.cornerRadius = 18
        imgUser.layer.borderWidth = 2
        imgUser.layer.borderColor = Colors.lightColor.cgColor
        
        
        if let task = self.task {
            self.title = task.title
        }
        
        self.loadDetail()
        self.setupDataSource()
        
        lblUserName.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(TaskDetailViewController.chooseMember))
        lblUserName.addGestureRecognizer(gesture)
        
        lblStatus.isUserInteractionEnabled = true
        let gestureStatus = UITapGestureRecognizer(target: self, action: #selector(TaskDetailViewController.chooseStatus))
        lblStatus.addGestureRecognizer(gestureStatus)
    }
    
    @objc func chooseStatus() {
        self.alert(title: "Change the status", message: "", options:
            "Not Started", "In Progress", "Review", "On Hold", "Need Help", "Completed", "Cancel") { (index) in
                if let status = TaskStatus(rawValue: index), let task = self.task {
                    task.state = status
                    self.lblStatus.textColor = task.state.color
                    self.lblStatus.text = task.state.status
                }
        }
    }
    
    @objc func chooseMember() {
        self.performSegue(withIdentifier: "sid_choose_member", sender: self)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.layoutTableHeader()
    }
    
    func layoutTableHeader() {
        if let headerView = tableView.tableHeaderView {
            
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
                        //Comparison necessary to avoid infinite loop
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }
    
    func loadDetail() {
        if let task = self.task {
            lblTitle.text = task.title
            lblContent.text = task.content
            lblDate.text = task.createdAt.toStringWithRelativeTime()
            lblStatus.textColor = task.state.color
            lblStatus.text = task.state.status
            lblComments.text = "\(task.comments.count)"
            
            if let userId = task.userId {
                lblUserName.text  = task.userName
                lblUserName.textColor = #colorLiteral(red: 0.2780584991, green: 0.3169239163, blue: 0.391651094, alpha: 1)
                User.observeSingle(userId, eventType: .value) { (user) in
                    if let user = user {
                        if let file = user.thumbnail {
                            if let url = file.downloadURL {
                                self.imgUser.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "user_placeholder"), options: .refreshCached, completed: nil)
                            }
                        }
                    }
                };
            }
            else {
                lblUserName.text = "Not assigned yet."
                lblUserName.textColor = #colorLiteral(red: 1, green: 0.1490196078, blue: 0, alpha: 1)
            }
        }
    }
    
    func setupDataSource() {
        let options: Options = Options()
        options.limit = 20
        //        options.predicate = NSPredicate(format: "age == 21")
        options.sortDescirptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        if let task = self.task {
            self.dataSource = DataSource(reference: task.comments.ref, block: { (changes) in
                guard let tableView: UITableView = self.tableView else {return}
                
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
            if identifier == "sid_addcomment" {
                let controller = segue.destination as! PromptViewController
                controller.delegate = self
                controller.type = .addComment
                controller.title = "Add a comment"
            }
            else if identifier == "sid_choose_member" {
                let controller = segue.destination as! TeamViewController
                controller.delegate = self
                controller.title = "Select a member"
            }
        }
    }
}

extension TaskDetailViewController: TeamViewControllerDelegate {
    func didSelect(member user: User) {
        if let task = self.task {
            task.userId = user.id
            task.userName = user.name
            self.lblUserName.text = user.name
        }
        if let file = user.thumbnail {
            if let url = file.downloadURL {
                imgUser.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "user_placeholder"), options: .refreshCached, completed: nil)
            }
        }
    }
}

extension TaskDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "COMMENT_CELL", for: indexPath) as! CommentTableViewCell
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(_ cell: CommentTableViewCell, atIndexPath indexPath: IndexPath) {
        cell.disposer = self.dataSource?.observeObject(at: indexPath.item, block: { (comment) in
            guard let comment = comment else {return}
            cell.reset(with: comment)
            cell.setNeedsLayout()
        })
    }
    
    private func tableView(_ tableView: UITableView, didEndDisplaying cell: CommentTableViewCell, forRowAt indexPath: IndexPath) {
        //self.dataSource?.removeObserver(at: indexPath.item)
        cell.disposer?.dispose()
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let source = self.dataSource,
                let user = Manager.shared.user {
                if indexPath.row < source.count {
                    let comment = source.objects[indexPath.row]
                    if comment.userID != user.id {
                        return
                    }
                    
                    if let task = self.task {
                        task.comments.remove(comment)
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

extension TaskDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let source = self.dataSource {
            if indexPath.row < source.count {
            }
        }
    }
}

extension TaskDetailViewController: PromptDelegate {
    func createComment(text: String, task: Task) {
        let comment = Comment()
        comment.userID = Manager.shared.user.id
        comment.userName = Manager.shared.user.name
        comment.comment = text
        SVProgressHUD.show(withStatus: "Saving...")
        comment.save({ (ref, err) in
            SVProgressHUD.dismiss()
            self.lblComments.text = "\(task.comments.count + 1)"
            task.comments.insert(comment)
        })
    }
    
    func done(with values: [String : Any]) {
        if let task = self.task {
            if let text = values["Comment"] as? String {
                self.createComment(text: text, task: task)
            }
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


