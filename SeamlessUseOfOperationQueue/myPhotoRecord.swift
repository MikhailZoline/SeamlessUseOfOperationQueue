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
class myPhotoRecord : Decodable{
// The following fields are specified in JSON from the REST API
    var  post_url: String
    var  author: String
    var  author_url: String
    var width: Double = 0
    var height: Double = 0
    var  format: String
    var  filename: String
    var  id: Int
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
        post_url = dictionary["post_url"] as! String + "/download";
        author = dictionary["author"] as? String ?? ""
        author_url = dictionary["author_url"] as? String ?? ""
        width = dictionary["width"] as? Double ?? 0
        height = dictionary["height"] as? Double ?? 0
        format = dictionary["format"] as? String ?? ""
        filename = dictionary["filename"] as? String ?? ""
        id = dictionary["id"] as? Int ?? 0
    }
    
    enum CodingKeys: String, CodingKey {
        case post_url = "post_url"
        case author = "author"
        case author_url = "author_url"
        case width = "width"
        case height = "height"
        case format = "format"
        case filename = "filename"
        case id = "id"
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        post_url = try values.decode(String.self, forKey: .post_url) + "/download"
        author = try values.decode(String.self, forKey: .author)
        author_url = try values.decode(String.self, forKey: .author_url)
        width = try values.decode(Double.self, forKey: .width)
        height = try values.decode(Double.self, forKey: .height)
        format = try values.decode(String.self, forKey: .format)
        filename = try values.decode(String.self, forKey: .filename)
        id = try values.decode(Int.self, forKey: .id)
    }
}
