//
//  CheckInTableViewCell.swift
//  CheckedIn
//
//  Created by Ya Kao on 11/6/14.
//  Copyright (c) 2014 Group6. All rights reserved.
//

import UIKit

class CheckInTableViewCell: UITableViewCell {

    @IBOutlet weak var checkInButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onCheckIn(sender: AnyObject) {
        println("Check in!")
    }
}
