//
//  ViewController.swift
//  VideoSplitter
//
//  Created by Alex Lim on 19/9/16.
//  Copyright © 2016 dev. All rights reserved.
//

import UIKit
import MediaPlayer
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UIPickerViewDelegate {

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func btnLoadAction(sender: AnyObject) {
        
    }
    
}

extension ViewController: UIImagePickerControllerDelegate{
    
}