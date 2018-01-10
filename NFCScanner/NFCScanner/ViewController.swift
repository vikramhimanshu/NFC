//
//  ViewController.swift
//  NFCScanner
//
//  Created by Himanshu Tantia on 3/1/18.
//  Copyright © 2018 Kreativ Apps, LLC. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var nfcReader: NFCReader?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        nfcReader = NFCReader(withController: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func scanNFC(_ sender: UIBarButtonItem) {
        if let reader = nfcReader {
            reader.start()
        } else {
            let reader = NFCReader(withController: self)
            self.nfcReader = reader
            reader.start()
        }
    }
}

