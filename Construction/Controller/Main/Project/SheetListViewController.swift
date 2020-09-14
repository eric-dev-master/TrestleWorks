//
//  SheetViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import SVProgressHUD
import SDWebImage

class SheetListViewController: BarHidableViewController {
    var dataSource: DataSource<Sheet>?
    @IBOutlet weak var tblSheets: UITableView!
    var selectedSheet: Sheet?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblSheets.rowHeight = UITableViewAutomaticDimension
        tblSheets.estimatedRowHeight = 520
        
        self.setupDataSource()
    }
    
    func createSheet(title: String?, comment: String? = nil, image: UIImage? = nil) {
        guard let title = title, let comment = comment, let image = image else { return }
        
        let sheet: Sheet = Sheet()
        sheet.name = title
        sheet.content = comment
        if let data = UIImagePNGRepresentation(image) {
            sheet.backgroundImage = File(data: data)
        }
        
        if let user = Manager.shared.user {
            sheet.userId = user.id
            sheet.userName = user.name
            
            SVProgressHUD.show()
            sheet.save({ (ref, err) in
                SVProgressHUD.dismiss()
                if let project = Manager.shared.currentProject {
                    project.sheets.insert(sheet)
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
            self.dataSource = DataSource(reference: project.sheets.ref, block: { (changes) in
                guard let tableView: UITableView = self.tblSheets else {return}
                
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
            if identifier == "sid_addsheet" {
                let controller = segue.destination as! PromptViewController
                controller.delegate = self
                controller.type = .addSheet
                controller.title = "Create a Sheet"
            }
            else if identifier == "sid_sheet_detail" {
                let controller = segue.destination as! SheetViewController
                if let cell = sender as? SheetTableViewCell {
                    controller.sheet = cell.sheet
                }
            }
        }
    }
    
    func openSheet(_ sheet: Sheet?) {
        let controller = UIStoryboard(name: "Project", bundle: nil).instantiateViewController(withIdentifier: "sid_sheet") as! SheetViewController
        controller.sheet = sheet
//        let navController = UINavigationController(rootViewController: controller)
        controller.modalPresentationStyle = .overFullScreen
        if let window = UIManager.shared.window {
            if let viewController = window.rootViewController {
                viewController.present(controller, animated: true, completion: nil)
            }
        }
    }
}

extension SheetListViewController: UITableViewDataSource {
    func reload(rowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.tblSheets.beginUpdates()
            self.tblSheets.reloadRows(at: [indexPath], with: .fade)
            self.tblSheets.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SHEET_CELL", for: indexPath) as! SheetTableViewCell
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(_ cell: SheetTableViewCell, atIndexPath indexPath: IndexPath) {
        cell.disposer = self.dataSource?.observeObject(at: indexPath.item, block: { (sheet) in
            guard let sheet = sheet else {return}
            if let file = sheet.backgroundImage {
                if let url = file.downloadURL {
                    if SDImageCache.shared().diskImageDataExists(withKey: url.absoluteString) == false {
                        cell.reset(with: sheet)
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
                        cell.reset(with: sheet)
                    }
                }
            }
        })
    }
    
    private func tableView(_ tableView: UITableView, didEndDisplaying cell: SheetTableViewCell, forRowAt indexPath: IndexPath) {
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
                    let sheet = source.objects[indexPath.row]
                    if let managerId = project.managerId, managerId != user.id {
                        return
                    }
                    project.sheets.remove(sheet)
                    sheet.remove()
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

extension SheetListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let source = self.dataSource {
            if indexPath.row < source.count {
                let sheet = source.objects[indexPath.row]
                self.openSheet(sheet)
            }
        }
    }
}

extension SheetListViewController: PromptDelegate {
    func done(with values: [String : Any]) {
        let image = values["Image"] as? UIImage
        let comment = values["Description"] as? String
        let title = values["Title"] as? String
        self.createSheet(title: title, comment: comment, image: image)
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


