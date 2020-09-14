//
//  PromptViewController.swift
//  Construction
//
//  Created by Macmini on 11/26/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

protocol PromptDelegate {
    func done(with values: [String: Any])
    func invalidField(values: [String: Any]) -> String?
}

enum PromptType: Int {
    case addProject = 0
    case addMember = 1
    case addJournal = 2
    case addTask = 3
    case addChatRoom = 4
    case addComment = 5
    case changePassword = 6
    case changeUserName = 7
    case changeEmail = 8
    case addSheet = 9
}

enum FieldType: Int {
    case text
    case image
    case sentence
    case password
    
    var height: CGFloat {
        if self == .text {
            return 44
        }
        else if self == .password {
            return 44
        }
        else if self == .image {
            return 250
        }
        else if self == .sentence {
            return 100
        }
        return 0
    }
    
    var cellIdentifier: String {
        if self == .text {
            return "TEXT_CELL"
        }
        else if self == .image {
            return "IMAGE_CELL"
        }
        else if self == .sentence{
            return "SENTENCE_CELL"
        }
        else if self == .password {
            return "TEXT_CELL"
        }
        return ""
    }
}

class PromptViewController: BarHidableViewController {
    static let headerHeight: CGFloat = 50
    static let footerHeight: CGFloat = 50
    
    @IBOutlet weak var promptHeight: NSLayoutConstraint!
    @IBOutlet weak var tblFields: UITableView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var container: UIView!
    
    var selectedImageView: UIImageView!
    
    var type: PromptType! {
        didSet {
            updateFields()
        }
    }
    var delegate: PromptDelegate!
    var fields: [String]!
    var fieldTypes: [FieldType]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViewHeight()
        lblTitle.text = self.title
        
        container.layer.shadowColor = Colors.darkColor.cgColor
        container.layer.shadowRadius = 3.0
        container.layer.shadowOpacity = 0.8
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
    }
    
    func updateViewHeight() {
        if let types = self.fieldTypes {
            var height: CGFloat = 0
            for fieldType in types {
                height += fieldType.height
            }
            promptHeight.constant = height + PromptViewController.headerHeight + PromptViewController.footerHeight
            tblFields.reloadData()
        }
    }
    
    func updateFields(){
        switch type {
        case .addProject:
            self.fields = ["Name", "Description"];
            self.fieldTypes = [.text, .text];
            break
        case .addMember:
            self.fields = ["Name", "Email"];
            self.fieldTypes = [.text, .text];
            break
        case .addJournal:
            self.fields = ["Title", "Comment", "Image"];
            self.fieldTypes = [.text, .sentence, .image];
            break
        case .addSheet:
            self.fields = ["Title", "Description", "Image"];
            self.fieldTypes = [.text, .sentence, .image];
            break
        case .addTask:
            self.fields = ["Title", "Description"];
            self.fieldTypes = [.text, .sentence];
            break
        case .addChatRoom:
            self.fields = ["Room Name"];
            self.fieldTypes = [.text];
            break
        case .changeUserName:
            self.fields = ["Full Name"];
            self.fieldTypes = [.text];
            break
        case .changeEmail:
            self.fields = ["Email"];
            self.fieldTypes = [.text];
            break
        case .addComment:
            self.fields = ["Comment"];
            self.fieldTypes = [.sentence];
            break
        case .changePassword:
            self.fields = ["Old Password", "New Password", "Confirm Password"];
            self.fieldTypes = [.text, .password, .password];
        default:
            break
        }
    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onOk(_ sender: Any) {
        if let delegate = self.delegate {
            if let fields = self.fields, fields.count > 0 {
                var data = [String: Any]()
                for i in 0..<self.fields.count {
                    let indexPath = IndexPath(row: i, section: 0)
                    if let cell = self.tblFields.cellForRow(at: indexPath) as? PromptTableViewCell {
                        if self.fieldTypes[i] == .text {
                            data[fields[i]] = cell.textField.text
                        }
                        else if self.fieldTypes[i] == .password {
                            data[fields[i]] = cell.textField.text
                        }
                        else if self.fieldTypes[i] == .image {
                            if let image = cell.imgView.image {
                                data[fields[i]] = image
                            }
                            else {
                                data[fields[i]] = UIImage()
                            }
                        }
                        else if self.fieldTypes[i] == .sentence {
                            data[fields[i]] = cell.textView.text
                        }
                    }
                }
                
                if let field = delegate.invalidField(values: data) {
                    alert(message: field + " is wrong. Please check again.")
                }
                else {
                    self.dismiss(animated: true) {
                        delegate.done(with: data)
                    }
                }
            }
        }
    }
    
    func notify() {
        if let delegate = self.delegate {
            if let fields = self.fields, fields.count > 0 {
                var data = [String: Any]()
                for i in 0..<self.fields.count {
                    let indexPath = IndexPath(row: i, section: 0)
                    if let cell = self.tblFields.cellForRow(at: indexPath) as? PromptTableViewCell {
                        if self.fieldTypes[i] == .text {
                            data[fields[i]] = cell.textField.text
                        }
                        else if self.fieldTypes[i] == .text {
                            data[fields[i]] = cell.textField.text
                        }
                        else if self.fieldTypes[i] == .image {
                            if let image = cell.imgView.image {
                                data[fields[i]] = image
                            }
                            else {
                                data[fields[i]] = UIImage()
                            }
                        }
                        else if self.fieldTypes[i] == .sentence {
                            data[fields[i]] = cell.textView.text
                        }
                    }
                }
                delegate.done(with: data)
            }
        }
    }
}

extension PromptViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fields = self.fields {
            return fields.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let fieldType = fieldTypes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: fieldType.cellIdentifier, for: indexPath) as! PromptTableViewCell
        cell.reset(with: self.fields[indexPath.row], index: indexPath.row, type: fieldType)
        return cell
    }
}

extension PromptViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return fieldTypes[indexPath.row].height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if fieldTypes[indexPath.row] == .image {
            if let cell = self.tblFields.cellForRow(at: indexPath) as? PromptTableViewCell {
                self.selectedImageView = cell.imgView
                showImagePicker()
            }
        }
    }
}

extension PromptViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func showImagePicker() {
        let actionSheet = UIAlertController(title: "Take a photo from", message: "", preferredStyle: .actionSheet)
        let actionTakePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            self.takePhoto(sourceType: .photoLibrary)
        }
        
        let actionCamera = UIAlertAction(title: "Camera", style: .default) { (action) in
            self.takePhoto(sourceType: .camera)
        }
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(actionTakePhoto)
        actionSheet.addAction(actionCamera)
        actionSheet.addAction(actionCancel)
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            actionSheet.popoverPresentationController?.sourceView = self.selectedImageView
            actionSheet.popoverPresentationController?.sourceRect = CGRect(x: self.selectedImageView.frame.size.width/2, y: self.selectedImageView.frame.size.width/2, width: 1, height: 1)
            actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        }
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func takePhoto(sourceType: UIImagePickerControllerSourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = sourceType
            imagePickerController.delegate = self
            imagePickerController.allowsEditing = true
            
            if sourceType != .camera {
                if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                    imagePickerController.modalPresentationStyle = .popover
                    imagePickerController.popoverPresentationController?.sourceView = self.selectedImageView
                    imagePickerController.popoverPresentationController?.sourceRect = CGRect(x: self.selectedImageView.frame.size.width/2, y: self.selectedImageView.frame.size.width/2, width: 1, height: 1)
                    imagePickerController.popoverPresentationController?.permittedArrowDirections = .up
                }
            }
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let selectedImage = info[UIImagePickerControllerEditedImage] as! UIImage
        self.selectedImageView.image = selectedImage.resizeImage(newWidth: 300)
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

