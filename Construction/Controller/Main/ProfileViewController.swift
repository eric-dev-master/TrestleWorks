//
//  ProfileViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import FirebaseAuth
import SVProgressHUD

class ProfileViewController: UITableViewController {
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var imgEmail: UIImageView!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imgUser.tintColor = #colorLiteral(red: 0.7326959968, green: 0.612052381, blue: 0.435046494, alpha: 1)
        imgEmail.tintColor = #colorLiteral(red: 0.7326959968, green: 0.612052381, blue: 0.435046494, alpha: 1)

        
        // Do any additional setup after loading the view.
        imgPhoto.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.choosePhoto))
        imgPhoto.addGestureRecognizer(gesture)
        
        if let user = Manager.shared.user {
            lblUserName.text = user.name
            lblEmail.text = user.email
            if let file = user.thumbnail {
                if let url = file.downloadURL {
                    imgPhoto.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "user_placeholder"), options: .refreshCached, completed: nil)
                }
            }
        }
    }
    
    @objc func choosePhoto() {
        self.showImagePicker()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        imgPhoto.layer.cornerRadius = imgPhoto.bounds.size.height/2
        imgPhoto.layer.borderWidth = 5
        imgPhoto.layer.borderColor = Colors.lightColor.cgColor
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 { // Change Username
            updateUserName()
        }
        else if indexPath.row == 2 { // Change Email Address
            updateEmail()
        }
    }
    
    func updateUserName() {
        let controller = UIStoryboard(name: "Project", bundle: nil).instantiateViewController(withIdentifier: "sid_prompt") as! PromptViewController
        controller.delegate = self
        controller.type = .changeUserName
        controller.title = "Change User's Name"
        controller.modalPresentationStyle = .overFullScreen
        self.present(controller, animated: true, completion: nil)
    }
    
    func updateEmail() {
        let controller = UIStoryboard(name: "Project", bundle: nil).instantiateViewController(withIdentifier: "sid_prompt") as! PromptViewController
        controller.delegate = self
        controller.type = .changeEmail
        controller.title = "Change Email"
        controller.modalPresentationStyle = .overFullScreen
        self.present(controller, animated: true, completion: nil)
    }
}

extension ProfileViewController: PromptDelegate {
    func done(with values: [String : Any]) {
        if let email = values["Email"] as? String {
            if let fbUser = Auth.auth().currentUser {
                SVProgressHUD.show()
                fbUser.updateEmail(to: email, completion: { (error) in
                    SVProgressHUD.dismiss()
                    if let error = error {
                        self.alert(message: error.localizedDescription)
                    }
                    else {
                        self.alert(message: "Email changed successfully.")
                        if let currentUser = Manager.shared.user {
                            currentUser.email = email
                            self.lblEmail.text = email
                        }
                    }
                })
            }
        }
        else if let username = values["Full Name"] as? String{
            if let user = Manager.shared.user {
                user.name = username
                lblUserName.text = username
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


extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
            actionSheet.popoverPresentationController?.sourceView = self.imgPhoto
            actionSheet.popoverPresentationController?.sourceRect = CGRect(x: self.imgPhoto.frame.size.width/2, y: self.imgPhoto.frame.size.width/2, width: 1, height: 1)
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
                    imagePickerController.popoverPresentationController?.sourceView = self.imgPhoto
                    imagePickerController.popoverPresentationController?.sourceRect = CGRect(x: self.imgPhoto.frame.size.width/2, y: self.imgPhoto.frame.size.width/2, width: 1, height: 1)
                    imagePickerController.popoverPresentationController?.permittedArrowDirections = .up
                }
            }
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let selectedImage = info[UIImagePickerControllerEditedImage] as! UIImage
        let image = selectedImage.resizeImage(newWidth: 300)
        self.imgPhoto.image = image
        if let user = Manager.shared.user {
            if let data = UIImagePNGRepresentation(image) {
                user.thumbnail = File(data: data)
                if let file = user.thumbnail {
                    let _ = file.update(completion: { (metadata, error) in
                        if let error = error {
                            self.alert(message: error.localizedDescription)
                        }
                    })
                }
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}
