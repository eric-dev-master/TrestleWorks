//
//  ProjectViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class ProjectViewController: UITabBarController {
//    var project: Project!
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        if let controllers = self.viewControllers {
            for controller: UIViewController in controllers {
                if controller is UINavigationController {
                    if let controller = (controller as! UINavigationController).topViewController {
                        controller.navigationItem.leftBarButtonItem = self.navigationItem.leftBarButtonItem
                    }
                }
            }
        }
    }
}
