//
//  myPhotoRecord.swift
//  ReactiveJSONAsgn
//
//  Created by Mikhail Zoline on 7/24/17.
//  Copyright © 2017 MZ. All rights reserved.
//

import UIKit
// track the state of each operation, and whether it is a downloading or resizing operation
enum myPhotoRecordState {
    case New, Downloaded, Failed, Resized
}

// myPhotoRecord contains an image, url and state of operation
class myPhotoRecord {
// The following fields are specified in JSON from the REST API
    let post_url: String
    let author: String
    let author_url: String
    var width: CGFloat = 0
    var height: CGFloat = 0
    let format: String
    let filename: String
    let id: Int
// Load time
    var ltime: TimeInterval?
// Resize time
    var rtime: TimeInterval?
//.New for newly created records
    var state = myPhotoRecordState.New
// The image defaults to a placeholder
    var image = UIImage(named: "placeholder")
// Init with dictionary
    init(dictionary: [String: Any]) {
        self.post_url = dictionary["post_url"] as! String + "/download";
        self.author = dictionary["author"] as? String ?? ""
        self.author_url = dictionary["author_url"] as? String ?? ""
        self.width = dictionary["width"] as? CGFloat ?? 0
        self.height = dictionary["height"] as? CGFloat ?? 0
        self.format = dictionary["format"] as? String ?? ""
        self.filename = dictionary["filename"] as? String ?? ""
        self.id = dictionary["id"] as? Int ?? 0
    }
}
