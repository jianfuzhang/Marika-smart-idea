//
//  AddressSuggestionTableVC.swift
//  smap
//
//  Created by Jianfu Zhang on 4/19/16.
//  Copyright © 2016 Lee, Marika. All rights reserved.
//

import Foundation
import UIKit

class AddressSuggestion: UITableViewController {
    
    @IBOutlet var FirstLineTableView: UITableView!
    
    @IBOutlet weak var EditTextField: UITextField!
    @IBAction func SearchWhileEditting(sender: AnyObject) {
        print(EditTextField.text)
    }
    
}