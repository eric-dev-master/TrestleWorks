//
//  JournalViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import SVProgressHUD
import SDWebImage

class JournalListViewController: BarHidableViewController {
    var dataSource: DataSource<Journal>?
    @IBOutlet weak var tblJournals: UITableView!
    var selectedJournal: Journal?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblJournals.rowHeight = UITableViewAutomaticDimension
        tblJournals.estimatedRowHeight = 520

        self.setupDataSource()
    }
    
    func createJournal(title: String?, comment: String? = nil, image: UIImage? = nil) {
        guard let title = title, let comment = comment, let image = image else { return }
        
        let journal: Journal = Journal()
        journal.title = title
        journal.content = comment
        if let data = UIImagePNGRepresentation(image) {
            journal.attachment = File(data: data)
        }

        if let user = Manager.shared.user {
            journal.userId = user.id
            journal.userName = user.name
            
            SVProgressHUD.show()
            
            journal.save({ (ref, err) in
                SVProgressHUD.dismiss()
                if let project = Manager.shared.currentProject {
                    project.journals.insert(journal)
                }
            })
        }
    }
    
    func setupDataSource() {
        let options: Options = Options()
        options.limit = 10
        //        options.predicate = NSPredicate(format: "age == 21")
        options.sortDescirptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        if let project = Manager.shared.currentProject {
            self.dataSource = DataSource(reference: project.journals.ref, block: { (changes) in
                guard let tableView: UITableView = self.tblJournals else {return}
                
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
            if identifier == "sid_addjournal" {
                let controller = segue.destination as! PromptViewController
                controller.delegate = self
                controller.type = .addJournal
                controller.title = "Post a Journal"
            }
            else if identifier == "sid_addcomment" {
                let controller = segue.destination as! PromptViewController
                controller.delegate = self
                controller.type = .addComment
                controller.title = "Add a comment"
            }
            else if identifier == "sid_journal_detail" {
                let controller = segue.destination as! JournalDetailViewController
                if let cell = sender as? JournalTableViewCell {
                    controller.journal = cell.journal
                }
            }
        }
    }
}

extension JournalListViewController: UITableViewDataSource {
    func reload(rowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.tblJournals.beginUpdates()
            self.tblJournals.reloadRows(at: [indexPath], with: .fade)
            self.tblJournals.endUpdates()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JOURNAL_CELL", for: indexPath) as! JournalTableViewCell
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(_ cell: JournalTableViewCell, atIndexPath indexPath: IndexPath) {
        cell.disposer = self.dataSource?.observeObject(at: indexPath.item, block: { (journal) in
            guard let journal = journal else {return}
            cell.delegate = self
            if let file = journal.attachment {
                if let url = file.downloadURL {
                    if SDImageCache.shared().diskImageDataExists(withKey: url.absoluteString) == false {
                        cell.reset(with: journal)
                        if file.data == nil {
                            if file.downloadTask == nil {
                                let _ = file.dataWithMaxSize(9999999, completion: { (data, err) in
                                    if let data = data {
                                        file.data = data
                                        DispatchQueue.global(qos: .background).async {
                                            SDImageCache.shared().storeImageData(toDisk: data, forKey: url.absoluteString)
                                            DispatchQueue.main.async {
                                                self.reload(rowAt: indexPath)
                                            }
                                        }
                                    }
                                })
                            }
                        }
                    }
                    else {
                        if let image = SDImageCache.shared().imageFromCache(forKey: url.absoluteString) {
                            if let data = image.sd_imageData() {
                                file.data = data
                            }
                        }
                        cell.reset(with: journal)
                    }
                }
            }
        })
    }
    
    private func tableView(_ tableView: UITableView, didEndDisplaying cell: JournalTableViewCell, forRowAt indexPath: IndexPath) {
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
                    let journal = source.objects[indexPath.row]
                    if let managerId = project.managerId, managerId != user.id {
                        return
                    }
                    project.journals.remove(journal)
                    journal.remove()
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

extension JournalListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let source = self.dataSource {
            if indexPath.row < source.count {
//                let journal = source.objects[indexPath.row]
            }
        }
    }
}

extension JournalListViewController: CommentableCellDelegate {
    func onCommentTapped(_ journal: Any?) {
        if let journal = journal as? Journal {
            self.selectedJournal = journal
            self.performSegue(withIdentifier: "sid_addcomment", sender: self)
        }
    }
}

extension JournalListViewController: PromptDelegate {
    func createComment(text: String, journal: Journal) {
        let comment = Comment()
        comment.userID = Manager.shared.user.id
        comment.userName = Manager.shared.user.name
        comment.comment = text
        SVProgressHUD.show(withStatus: "Saving...")
        comment.save({ (ref, err) in
            SVProgressHUD.dismiss()
            journal.comments.insert(comment)
            self.selectedJournal = nil
        })
    }
    
    func done(with values: [String : Any]) {
        if values.count == 1 {
            if let journal = self.selectedJournal {
                if let text = values["Comment"] as? String {
                    self.createComment(text: text, journal: journal)
                }
            }
        }
        else {
            let image = values["Image"] as? UIImage
            let comment = values["Comment"] as? String
            let title = values["Title"] as? String
            self.createJournal(title: title, comment: comment, image: image)
        }
    }
    
    func invalidField(values: [String : Any]) -> String? {
        for (key, value) in values {
            if value is UIImage {
                if (value as! UIImage).size == CGSize.zero {
                    return key
                }
            }
            else if value is String {
                if (value as! String).count == 0 {
                    return key
                }
            }
        }
        return nil
    }
}

