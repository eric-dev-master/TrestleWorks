//
//  Project.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class ProjectJournals: Relation<Journal> {
    override class var _name: String {
        return "project_journals"
    }
}

class ProjectTasks: Relation<Task> {
    override class var _name: String {
        return "project_tasks"
    }
}

class ProjectSheets: Relation<Sheet> {
    override class var _name: String {
        return "project_sheets"
    }
}

class Project: Object {
    @objc dynamic var cover: File?
    @objc dynamic var title: String?
    @objc dynamic var content: String?
    
    @objc dynamic var managerId: String?
    @objc dynamic var chatRooms: Set<String> = []

    var users: Relation<User> = []
    var journals: ProjectJournals = []
    var tasks: ProjectTasks = []
    var sheets: ProjectSheets = []
//    var drawings: Relation<Task> = []
}
