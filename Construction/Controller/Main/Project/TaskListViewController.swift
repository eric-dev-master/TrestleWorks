//
//  TaskViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import SVProgressHUD

class TaskListViewController: BarHidableViewController {
    var dataSource: DataSource<Task>?
    @IBOutlet weak var tblTasks: UITableView!
    var selectedTask: Task?

    override func viewDidLoad() {
        super.viewDidLoad()
        tblTasks.rowHeight = UITableViewAutomaticDimension
        tblTasks.estimatedRowHeight = 520
        
        self.setupDataSource()
    }
    
    func createTask(title: String?, content: String?) {
        guard let title = title, let content = content else { return }
        
        let task: Task = Task()
        task.title = title
        task.content = content
        task.state = .notStarted

        if let user = Manager.shared.user {
            task.creatorId = user.id
            task.creatorName = user.name
        }
        
        SVProgressHUD.show(withStatus: "Wait...")
        task.save({ (ref, err) in
            SVProgressHUD.dismiss()
            if let project = Manager.shared.currentProject {
                project.tasks.insert(task)
            }
        })
    }
    
    func setupDataSource() {
        let options: Options = Options()
        options.limit = 10
        //        options.predicate = NSPredicate(format: "age == 21")
        options.sortDescirptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        if let project = Manager.shared.currentProject {
            self.dataSource = DataSource(reference: project.tasks.ref, options: options, block: { (changes) in
                guard let tableView: UITableView = self.tblTasks else {return}
                
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
            if identifier == "sid_addtask" {
                let controller = segue.destination as! PromptViewController
                controller.delegate = self
                controller.type = .addTask
                controller.title = "Add Task"
            }
            else if identifier == "sid_addcomment" {
                let controller = segue.destination as! PromptViewController
                controller.delegate = self
                controller.type = .addComment
                controller.title = "Add a comment"
            }
            else if identifier == "sid_task_detail" {
                let controller = segue.destination as! TaskDetailViewController
                if let cell = sender as? TaskTableViewCell {
                    controller.task = cell.task
                }
            }
        }
    }
}

extension TaskListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TASK_CELL", for: indexPath) as! TaskTableViewCell
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(_ cell: TaskTableViewCell, atIndexPath indexPath: IndexPath) {
        cell.disposer = self.dataSource?.observeObject(at: indexPath.item, block: { (task) in
            guard let task = task else {return}
            cell.reset(with: task)
            cell.delegate = self
            cell.setNeedsLayout()
        })
    }
    
    private func tableView(_ tableView: UITableView, ddidEndDisplaying cell: TaskTableViewCell, forRowAt indexPath: IndexPath) {
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
                    let task = source.objects[indexPath.row]
                    if let managerId = project.managerId, managerId != user.id {
                        return
                    }
                    project.tasks.remove(task)
                    task.remove()
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

extension TaskListViewController: CommentableCellDelegate {
    func onCommentTapped(_ task: Any?) {
        if let task = task as? Task {
            self.selectedTask = task
            self.performSegue(withIdentifier: "sid_addcomment", sender: self)
        }
    }
}

extension TaskListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let source = self.dataSource {
            if indexPath.row < source.count {
                //                let task = source.objects[indexPath.row]
            }
        }
    }
}

extension TaskListViewController: PromptDelegate {
    func createComment(text: String, task: Task) {
        let comment = Comment()
        comment.userID = Manager.shared.user.id
        comment.userName = Manager.shared.user.name
        comment.comment = text
        SVProgressHUD.show(withStatus: "Saving...")
        comment.save({ (ref, err) in
            SVProgressHUD.dismiss()
            task.comments.insert(comment)
            self.selectedTask = nil
        })
    }
    
    func done(with values: [String : Any]) {
        if values.count == 1 {
            if let task = self.selectedTask {
                if let text = values["Comment"] as? String {
                    self.createComment(text: text, task: task)
                }
            }
        }
        else {
            let title = values["Title"] as? String
            let description = values["Description"] as? String
            self.createTask(title: title, content: description)
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
