//
//  Sheet.swift
//  Construction
//
//  Created by Macmini on 11/5/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class Sheet: Object {
    @objc dynamic var  name: String?
    @objc dynamic var  content: String?
    @objc dynamic var  userId: String?
    @objc dynamic var  userName: String?
    @objc dynamic var  backgroundImage: File?
    @objc dynamic var  shapeIds: Set<String> = []

    var image: UIImage!
    var shapes: [Shape]! = []
}
