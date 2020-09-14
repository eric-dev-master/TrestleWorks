//
//  SheetTableViewCell.swift
//  Construction
//
//  Created by Macmini on 4/2/18.
//  Copyright © 2018 LekshmySankar. All rights reserved.
//

import UIKit

class SheetTableViewCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var imgSheet: UIImageView!
    
    var disposer: Disposer<Sheet>?
    var sheet: Sheet?

    func reset(with newSheet: Sheet?) {
        self.sheet = newSheet
        
        if let sheet = self.sheet {
            lblTitle.text = sheet.name
            lblDescription.text = sheet.content
            lblUserName.text = sheet.userName
            lblDate.text = sheet.createdAt.toString(dateStyle: .medium, timeStyle: .none)
            if let file = sheet.backgroundImage, let data = file.data, let image = UIImage(data: data) {
                imgSheet.image = image
            }
        }
        self.contentView.layoutIfNeeded()
    }
}
