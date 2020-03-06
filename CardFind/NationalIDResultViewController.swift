//
//  NationalIDResultViewController.swift
//  CardFind
//
//  Created by Pisit W on 5/3/2563 BE.
//  Copyright © 2563 23. All rights reserved.
//

import UIKit

class NationalIDResultViewController: UITableViewController {

    var nationalID: NationalID?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nationalID?.dataCount ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = nationalID?.dataArray[indexPath.row]
        return cell
    }

}
