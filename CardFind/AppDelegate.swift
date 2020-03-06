//
//  AppDelegate.swift
//  scgfamily2020
//
//  Created by user23 on 8/8/2562 BE.
//  Copyright © 2562 user23. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        FirebaseApp.configure()
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Main")
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        
        return true
    }

}
