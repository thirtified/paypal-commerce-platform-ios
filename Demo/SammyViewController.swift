//
//  SammyViewController.swift
//  Demo
//
//  Created by Cannillo, Sammy on 10/2/19.
//  Copyright © 2019 Braintree Payments. All rights reserved.
//

import UIKit
import BraintreePayPalValidator

class SammyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        let client = BTPayPalValidatorClient()
    }
}
