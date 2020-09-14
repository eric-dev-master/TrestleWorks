//
//  PromptTableViewCell.swift
//  Construction
//
//  Created by Macmini on 11/26/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import UITextView_Placeholder

class PromptTableViewCell: UITableViewCell {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if textView != nil {
            textView.placeholderColor = Colors.grayTextColor
        }
    }

    func reset(with placeholder: String, index: Int = 0, type: FieldType = .text, data: Any? = nil) {
        if type == .text {
            textField.placeholder = placeholder
            textField.tag = index
            textField.text = data as? String
        }
        else if type == .password {
            textField.placeholder = placeholder
            textField.tag = index
            textField.isSecureTextEntry = true
            textField.text = data as? String
        }
        else if type == .sentence {
            textView.placeholder = placeholder
            textView.tag = index
            textView.text = data as? String
        }
    }
}
