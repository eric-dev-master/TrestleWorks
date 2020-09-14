//
//  UIManager.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

struct Colors {
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 255) -> UIColor {
        return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha/255.0);
    }
    
    static let darkColor = rgb(red: 55, green: 63, blue: 81)
    static let lightColor = rgb(red: 192, green: 155, blue: 103)
    static let textColor = rgb(red: 172, green: 139, blue: 92)
    static let grayTextColor = rgb(red: 199, green: 199, blue: 205)
}

class SlidingSegue: UIStoryboardSegue {
    override func perform() {
        let destination = self.destination
        UIManager.shared.showOnMain(viewController: destination)
    }
}

class UIManager {
    static let shared = UIManager()
    var window: UIWindow? {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            return appDelegate.window
        }
        return UIApplication.shared.keyWindow
    }
    
    var slideController: SlideMenuController?
    
    init() {
        themeInitialize()
        IQKeyboardManager.sharedManager().enable = true
    }
    
    func themeInitialize() {
        UINavigationBar.appearance().tintColor = Colors.lightColor
        UINavigationBar.appearance().barTintColor = Colors.darkColor
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: Colors.lightColor];
        
        UITabBar.appearance().tintColor = Colors.lightColor
        UITabBar.appearance().barTintColor = Colors.darkColor
    }
    
    func setRootViewController(viewController: UIViewController, animated: Bool = true) {
        if let window = self.window {
            viewController.view.frame = UIScreen.main.bounds;
            if animated {
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = viewController
                    window.makeKeyAndVisible()
                }, completion: nil)
            }
            else {
                window.rootViewController = viewController
                window.makeKeyAndVisible()
            }
        }
    }
    
    func showLogin(animated: Bool = true) {
        self.slideController = nil
        if let welcomeViewController = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() {
            self.setRootViewController(viewController: welcomeViewController, animated: animated)
        }
    }
    
    func showMain(animated: Bool = true) {
        if let controller = self.slideController {
            if let projectListController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() {
                controller.setMain(viewController: projectListController)
            }
        }
        else {
            if let projectListController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() {
                let menuController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MenuVC")
                self.slideController = SlideMenuController(mainViewController: projectListController, leftViewController: menuController, rightViewController: nil)
                slideController?.mainNavigationBarLeftToggleButtonIcon = UIImage(named: "icon_menu")
                slideController?.leftVisibleWidthPercentage = 0.85
                slideController?.allowedRightSwipe = false
                self.setRootViewController(viewController: self.slideController!, animated: animated)
            }
        }
    }
    
    func showProject(project: Project, animated: Bool = true) {
        if let projectController = UIStoryboard(name: "Project", bundle: nil).instantiateInitialViewController() as? ProjectViewController {
            Manager.shared.currentProject = project
            showOnMain(viewController:  projectController)
        }
    }
    
    func showOnMain(viewController: UIViewController) {
        if let controller = self.slideController {
            let navigationController = UINavigationController(rootViewController: viewController)
            controller.setMain(viewController: navigationController)
        }
    }
}
