//
//  JournalDetailViewController.swift
//  Construction
//
//  Created by Macmini on 3/30/18.
//  Copyright © 2018 LekshmySankar. All rights reserved.
//

import UIKit
import SVProgressHUD
import SDWebImage

class JournalDetailViewController: BarHidableViewController {
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var lblLikes: UILabel!
    @IBOutlet weak var lblComments: UILabel!
    @IBOutlet weak var lblPostedDate: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var lblCreator: UILabel!
    
    var journal: Journal?
    var dataSource: DataSource<Comment>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let journal = self.journal {
            self.title = journal.title
        }
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300

        self.loadDetail()
        self.setupDataSource()
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
        if let journal = self.journal {
            lblTitle.text = journal.title
            lblDescription.text = journal.content
            lblCreator.text = journal.userName
            lblPostedDate.text = journal.createdAt.toString(dateStyle: .medium, timeStyle: .none)
            lblComments.text = "\(journal.comments.count)"
            lblLikes.text = "\(journal.likes.count)"
            if let file = journal.attachment, let data = file.data, let image = UIImage(data: data) {
                imgPhoto.image = image
                self.layoutTableHeader()
                return
            }
            
            if let file = journal.attachment {
                if let url = file.downloadURL {
                    if SDImageCache.shared().diskImageDataExists(withKey: url.absoluteString) == false {
                        if file.data == nil {
                            if file.downloadTask == nil {
                                let _ = file.dataWithMaxSize(9999999, completion: { (data, err) in
                                    if let data = data {
                                        file.data = data
                                        DispatchQueue.global(qos: .background).async {
                                            SDImageCache.shared().storeImageData(toDisk: data, forKey: url.absoluteString)
                                            DispatchQueue.main.async {
                                                self.imgPhoto.image = UIImage(data: data)
                                                self.layoutTableHeader()
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
                                self.imgPhoto.image = image
                                self.layoutTableHeader()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setupDataSource() {
        let options: Options = Options()
        options.limit = 20
        //        options.predicate = NSPredicate(format: "age == 21")
        options.sortDescirptors = [NSSortDescriptor(key: "_createdAt", ascending: false)]
        if let journal = self.journal {
            self.dataSource = DataSource(reference: journal.comments.ref, block: { (changes) in
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
        }
    }
    
    
    @IBAction func onLike(_ sender: Any) {
        if let journal = self.journal {
            if !journal.likes.contains(Manager.shared.user.id) {
                journal.likes.insert(Manager.shared.user.id)
                lblLikes.text = "\(journal.likes.count)"
            }
        }
    }
}

extension JournalDetailViewController: UITableViewDataSource {
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
                    
                    if let journal = self.journal {
                        journal.comments.remove(comment)
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

extension JournalDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let source = self.dataSource {
            if indexPath.row < source.count {
            }
        }
    }
}

extension JournalDetailViewController: PromptDelegate {
    func createComment(text: String, journal: Journal) {
        let comment = Comment()
        comment.userID = Manager.shared.user.id
        comment.userName = Manager.shared.user.name
        comment.comment = text
        SVProgressHUD.show(withStatus: "Saving...")
        comment.save({ (ref, err) in
            SVProgressHUD.dismiss()
            self.lblComments.text = "\(journal.comments.count + 1)"
            journal.comments.insert(comment)
        })
    }
    
    func done(with values: [String : Any]) {
        if let journal = self.journal {
            if let text = values["Comment"] as? String {
                self.createComment(text: text, journal: journal)
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

