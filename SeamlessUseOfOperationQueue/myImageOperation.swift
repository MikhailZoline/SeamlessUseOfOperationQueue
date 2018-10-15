//
//  myImageOperation.swift
//  ReactiveJSONAsgn
//
//  Created by Mikhail Zoline on 7/20/17.
//  Copyright © 2017 MZ. All rights reserved.
//
import Foundation
import UIKit

class myImageOperation: Operation {
    var photoRecord: myPhotoRecord
    init(photoRecord: myPhotoRecord) {
        self.photoRecord = photoRecord
    }
}

class myImageDownloadOperation: myImageOperation {
    
    // NSOPeration download task
    override func main() {
        
        let startDownload: Date = Date()
        
        //check for cancellation before starting if current operation is cancelled, return
        if self.isCancelled {
            return
        }
        
        // guard statement comes very handy to download the image data
        guard let imageData = NSData(contentsOf: URL(string: self.photoRecord.post_url)!)
            else {
                self.photoRecord.state = .Failed
                self.photoRecord.image = UIImage(named: "failed")!
                return
        }
        
        // check again if current operation is cancelled, return
        if self.isCancelled {
            return
        }
        
        // update the state upon if there is data from download request
        if (imageData.length) > 0 {
            // create an image object and add it to the record
            self.photoRecord.image = UIImage(data:imageData as Data)!
            // update the state of operation to downloaded
            self.photoRecord.state = .Downloaded
        }
        else
        {
            // mark the record as failed and set the appropriate image
            self.photoRecord.state = .Failed
            self.photoRecord.image = UIImage(named: "failed")!
        }
        
        let elapsed = Date().timeIntervalSince(startDownload)
        self.photoRecord.ltime = elapsed
    }

}

// NSOPeration resize task is similar to the downloading operation
class myImageResizeOperation: myImageOperation {
    
     // override in NSOperation main to actually perform resize task
    override func main () {
        
        let startResize: Date = Date()
        
        //if current operation is cancelled or there is no image to resize, return
        if self.isCancelled || self.photoRecord.state != .Downloaded {
            return
        }
    
        // call the resizing function
        if let resizedImage = self.resizeImage(image: self.photoRecord.image!, targetSize: CGSize(width: 200, height: 150) ) {
            self.photoRecord.image = resizedImage
            self.photoRecord.state = .Resized
            
        }
        
        let elapsed = Date().timeIntervalSince(startResize)
        self.photoRecord.rtime = elapsed
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize)  -> UIImage? {
        
        // before starting check for cancellation
        if self.isCancelled {
            return nil
        }
        var returnImage:UIImage? = nil
        
        guard let ciImage = image.ciImage else{
            // regularly check for cancellation before attempting any work
            if self.isCancelled {
                return nil
            }
            // do the resizing using GraphicsBegin, draw and GraphicsEnd
            UIGraphicsBeginImageContext(targetSize)
            image.draw(in: CGRect(origin: CGPoint.zero, size: targetSize))
            returnImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return returnImage
        }
        
        if self.isCancelled {
            return nil
        }
        
        // do the resizing using createCGImage
        let outImage =  CIContext().createCGImage(ciImage, from: CGRect(x:0, y:0, width:targetSize.width , height: targetSize.height))
        returnImage = UIImage(cgImage: outImage!)
        if self.isCancelled {
            return nil
        }
        return returnImage
    }
}



