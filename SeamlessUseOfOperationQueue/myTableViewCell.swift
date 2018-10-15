//
//  myTableViewCell.swift
//  SeamlessUseOfOperationQueue
//
//  Created by Mikhail Zoline on 10/10/18.
//  Copyright © 2018 MZ. All rights reserved.
//

import UIKit

class myTableViewCell: UITableViewCell {

    
    @IBOutlet var myImage: UIImageView!
    @IBOutlet var myAuthorLbl: UILabel!
    @IBOutlet var myResizeButton: UIButton!
    @IBOutlet var myDwnldButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
