//
//  ProjectTableViewCell.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class ProjectTableViewCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    var disposer: Disposer<Project>?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func reset(with project: Project) {
        self.lblTitle.text = project.title
    }
}
