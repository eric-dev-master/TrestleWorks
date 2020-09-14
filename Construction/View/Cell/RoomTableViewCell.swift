//
//  JournalTableViewCell.swift
//  Construction
//
//  Created by Macmini on 3/13/18.
//  Copyright © 2018 LekshmySankar. All rights reserved.
//

import UIKit

class RoomTableViewCell: UITableViewCell {
    var disposer: Disposer<Room>?
    var room: Room?
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func reset(with newRoom: Room?) {
        self.room = newRoom
        
        if let room = self.room {
            lblTitle.text = room.name
            lblDate.text = room.updatedAt.toStringWithRelativeTime()
        }
        self.contentView.layoutIfNeeded()
    }
}
