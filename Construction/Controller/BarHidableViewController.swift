
//
//  BaseViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class BarHidableViewController: UIViewController {
    @IBInspectable var showNavigationBar: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        self.extendedLayoutIncludesOpaqueBars = false
        self.edgesForExtendedLayout = []
        if let navController = self.navigationController{
            navController.navigationBar.isTranslucent = false
            navController.setNavigationBarHidden(!showNavigationBar, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navController = self.navigationController{
            navController.setNavigationBarHidden(!showNavigationBar, animated: false)
            if navController.navigationBar.topItem?.title == nil {
                navController.navigationBar.topItem?.title = self.title
            }
        }
        if let tabBarController = self.tabBarController, let navTab = tabBarController.navigationController {
            navTab.navigationBar.topItem?.title = self.title
        }
    }
}

