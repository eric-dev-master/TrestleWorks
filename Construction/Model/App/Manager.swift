//
//  Manager.swift
//  Construction
//
//  Created by Macmini on 2/20/18.
//  Copyright © 2018 LekshmySankar. All rights reserved.
//

import UIKit

class Manager: NSObject {
    static let shared: Manager = Manager()
    var user: User!
    var currentProject: Project!
}
