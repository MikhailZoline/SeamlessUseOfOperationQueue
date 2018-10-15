//
//  myUnSplashViewController.swift
//  ReactiveJSONAsgn
//
//  Created by Mikhail Zoline on 7/26/17.
//  Refactored on 10/15/18
//  Copyright © 2017 MZ. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

// MARK: - Network constants""
fileprivate let myNetworkRequestHost : String = "unsplash.it"
fileprivate let myNetworkRequestScheme : String = "https"
fileprivate let myNetworkRequestPath : String = Optional<String>.none ?? ""
fileprivate let myNetworkRequestEndpoint : String = "list"
public let mySplashURL = "https://unsplash.it/list"

// MARK: - Table Cell Reuse Identifier
fileprivate let myReuseIdentifier = "myTableViewCell"

// MARK: -  Aamofire debug extention
extension Request {
    public func debugLog() -> Self {
        #if DEBUG
        debugPrint("=======================================")
        debugPrint(self)
        debugPrint("=======================================")
        #endif
        return self
    }
}

//MARK: -  Singleton of memory cache
final class myImageCache{
    private init(){}
    static let sharedInstance = myImageCache()
    let imageCache :  NSCache<AnyObject, AnyObject> = NSCache<NSString, AnyObject>() as! NSCache<AnyObject, AnyObject>
}

class  myUnSplashViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate{
    //MARK: -  Instance variables
    var lastScrollOffset: CGPoint = CGPoint()
    var previousScrollMoment: Date = Date()
    var fastScrolling:Bool = false
    var scrollingBackwards:Bool = false
    var previousScrollY: CGFloat = 0
    var currentMaxIndex = 0
    var advanceNumOfCellsOffset = 10
    let maxOperationsInProgress = 50
    var myPhotos: [myPhotoRecord] = [myPhotoRecord]()
    @IBOutlet var myTableView: UITableView!
    @IBOutlet weak var myNumOfThreads: UILabel!
    @IBOutlet weak var myScrollingVelocity: UILabel!
    //MARK: - KVO variable
    @objc dynamic var scrollingVelocity: Int = 0
    //MARK: - KVO object
    @objc var objectToObserve: OperationQueue
    var observation: [NSKeyValueObservation?] = [NSKeyValueObservation?](repeating: nil, count: 2)
    //MARK: - Helper functions
    enum getFailureReason: Int, Error {
        case unAuthorized = 401
        case notFound = 404
    }
    
    enum scrollinggSpeed : String{
        case zero // 0 - 30 pps
        case slow // 30 - 200 pps
        case normal // 200 - 400 pps
        case fast // 400 - 3000 pps
        case veryFast // > 3000
    }
    
    // normal drag is at 200 - 400 pps
    // fast launch is at 1000 - 3000 pps
    func getScrollingVelocity() ->scrollinggSpeed{
        return scrollingVelocity < 30 ? .zero : scrollingVelocity < 200 ? .slow : scrollingVelocity < 400  ? .normal : scrollingVelocity < 3000 ? .fast : .veryFast
    }
    
    //MARK: -  Object lifecycle methods
    required init?(coder aDecoder: NSCoder) {
        self.objectToObserve = myPendingOperations.sharedInstance.asyncQueue
        super.init(coder: aDecoder)
        //Monitor changes to the value of OpertionQueue.operationCount property using Key-value observing.
        //Configure an observer to monitor the operationCount key path of the operation queue
        observation[0] = observe(\.objectToObserve.operationCount, options:[.new],  changeHandler: { object, value  in
            DispatchQueue.main.async {
                object.myNumOfThreads.text = "\(value.newValue!)"
            }
        })
        observation[1] = observe(\.scrollingVelocity, options:[.new], changeHandler: { object, value in
            DispatchQueue.main.async {
                object.myScrollingVelocity.text = object.getScrollingVelocity().rawValue
            }
        })

    }
    
    override func viewDidLoad() {
        // Call the parent class viewDidLoad
        super.viewDidLoad()
        // Make a REST request to the Unsplash API to get the list of photos with corresponding URLs
        Alamofire.request(mySplashURL, method: .get).validate().responseJSON { [unowned self] response in
            switch response.result {
            // If the request is successful, the property list data is extracted into an array of dictionnaries
            // and then processed again into an array of PhotoRecord objects
            case .success (let value):
                let jsonarray = JSON(value).arrayValue
                for ( _, obj) in jsonarray.enumerated(){
                    self.myPhotos.append(myPhotoRecord(dictionary: (JSON(obj).dictionaryObject ?? nil)!))
                }
            case .failure(let error):
                print(getFailureReason(rawValue: error as! Int) as Any)
            }
            // Call of unsynchronized process scheduling to populate visible cells with photos
            DispatchQueue.main.async {
                self.loadImagesForCurrentCells(completion: {self.myTableView.reloadData()} )
            }
        }
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.suspendAllOperations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.resumeAllOperations()
        
    }
    
    //MARK: - Scheduling methods
    // Schedule the dowload an resize operations only for visible and nearby cells
    func loadImagesForCurrentCells (completion: (() -> Void)?) {
        // check for out of bounds
        if (currentMaxIndex < self.myPhotos.count)  {
            
            // construct a set of operations to be started
            // currentMaxIndex is the global counter of how many photos was downloaded to this moment
            var offsetPath: [IndexPath] = []
            // create a range of currently visible and nearby cells
            
            let myRange: Range = scrollingBackwards ? (currentMaxIndex - advanceNumOfCellsOffset > 0 ? currentMaxIndex - advanceNumOfCellsOffset : 0) ..< currentMaxIndex : currentMaxIndex..<(currentMaxIndex + advanceNumOfCellsOffset < myPhotos.count ? currentMaxIndex + advanceNumOfCellsOffset : myPhotos.count)
            
            for index in myRange.lowerBound..<myRange.upperBound {
                offsetPath.append( IndexPath(row: index, section: 0))
            }
            
            // start operations for photos to be downloaded
            for indexPath in offsetPath {
                let indexPath = indexPath as IndexPath
                // check if there is already an operation In Progress
                if (myPendingOperations.sharedInstance.operationInProgress[indexPath] != nil  || self.myPhotos[indexPath.row ].state == .Resized || self.myPhotos[indexPath.row].state == .Failed)
                {
                    continue
                }
                else {// schedule the photo to appear in the cell specified by indexPath.row
                    startOperationsForPhotoRecord(photoDetails: self.myPhotos[indexPath.row ], indexPath: indexPath, qualityOfService: QualityOfService.userInteractive )
                }
            }
            // update currentMaxIndex
            currentMaxIndex += (currentMaxIndex + advanceNumOfCellsOffset > self.myPhotos.count) ? (self.myPhotos.count - currentMaxIndex) : ( scrollingBackwards ? (currentMaxIndex - advanceNumOfCellsOffset > 0 ? -advanceNumOfCellsOffset : 0) : advanceNumOfCellsOffset )
        }
        // call the completion block if there is one
        completion?()
    }
    
 /*
    // Schedule the dowload an resize operations only for visible and nearby cells
    // Basically the same function as loadImagesForCurrentCells except tha batch of
    // cells is deducted differently
    func loadImagesForVisibleCells (completion: (() -> Void)?) {
        let pathsArray = myTableView.indexPathsForVisibleRows
        var first = 0 ; var last = 6
        if pathsArray != nil && (pathsArray?.count)! > 0 {
            first =  (pathsArray?.first?.row)! - 3 > 0 ? (pathsArray?.first?.row)! - 3 : 0
            last = pathsArray == nil ? 6 : (pathsArray?.last?.row)! + 3 < self.myPhotos.count  ? (pathsArray?.last!.row)! + 3 : self.myPhotos.count
        }
       
        let myRange: Range = first..<last
        print("\(#function),  range: \(myRange) ")
        for index in myRange {
            let indexPath = IndexPath(row: index, section: 0)
            // check if there is already an operation In Progress
            if ( myPendingOperations.sharedInstance.operationInProgress[indexPath] != nil || self.myPhotos[indexPath.row ].state == .Resized || self.myPhotos[indexPath.row].state == .Failed) {
                continue
            }
            else {// schedule the photo to appear in the cell specified by indexPath.row
                startOperationsForPhotoRecord(photoDetails: self.myPhotos[indexPath.row ], indexPath: indexPath, qualityOfService: QualityOfService.userInteractive, queuePriority: Operation.QueuePriority.veryHigh )
            }
        }
        completion?()
    }
*/
    // Create and schedule the download and resize operation of the photo scpecified by photoDetails for the cell specified by indexPath
    func startOperationsForPhotoRecord(photoDetails: myPhotoRecord, indexPath: IndexPath, qualityOfService: QualityOfService = QualityOfService.userInteractive, queuePriority: Operation.QueuePriority =  Operation.QueuePriority.normal){
        // check if there is already an operation for that cell
        if (myPendingOperations.sharedInstance.operationInProgress[indexPath] != nil || photoDetails.state == .Resized || photoDetails.state == .Failed || myPendingOperations.sharedInstance.operationInProgress.count >= self.maxOperationsInProgress || self.getScrollingVelocity() == .veryFast){
            return
        }
        if(photoDetails.state == .New)
        {
            // first, create the download operation of the photo from the REST API
            let downloadOperation = myImageDownloadOperation(photoRecord: photoDetails)
            downloadOperation.qualityOfService = qualityOfService
            downloadOperation.queuePriority = queuePriority
            // once the photo is downloaded we need to format it to fit the cell, create the resize
            let resizeOperation = myImageResizeOperation(photoRecord: photoDetails)
            resizeOperation.qualityOfService = qualityOfService
            resizeOperation.queuePriority = queuePriority
            // resize could be launched only if the download is finished
            resizeOperation.addDependency(downloadOperation)
            // the following will be called when the download operation is complete or canceled
            // if the download is canceled, remove pending resize as well
            downloadOperation.completionBlock = { [unowned downloadOperation, resizeOperation] in
                if downloadOperation.isCancelled {
                    resizeOperation.removeDependency(downloadOperation)
                    resizeOperation.cancel()
                    return
                }
                // if the download is complete, schedule the resizing
                DispatchQueue.main.async(execute: {
                    myPendingOperations.sharedInstance.asyncQueue.addOperation(resizeOperation)
                })
            }
            // the following will be called when the resize operation is complete or canceled
            resizeOperation.completionBlock = { [unowned resizeOperation, self] in
                if resizeOperation.isCancelled {
                    return
                }
                // now, when the resizing is complete, post photo in the interface
                DispatchQueue.main.async(execute:{ [unowned self] in
                    self.myTableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.right)
                    myPendingOperations.sharedInstance.operationInProgress.removeValue(forKey: indexPath)
                })
                
                DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute:{
                    myImageCache.sharedInstance.imageCache.setObject(self.myPhotos[indexPath.row], forKey: indexPath.row as AnyObject )
                })
            }
 
            // schedule the download operation
            myPendingOperations.sharedInstance.operationInProgress[indexPath] = downloadOperation
            myPendingOperations.sharedInstance.asyncQueue.addOperation(downloadOperation)
        }
    }
    
    // remove all operations from queue
    func cancelAllOperations () {
        myPendingOperations.sharedInstance.asyncQueue.cancelAllOperations()
        myPendingOperations.sharedInstance.operationInProgress.removeAll()
    }
    
    // suspend all operations in a queue
    func suspendAllOperations () {
        myPendingOperations.sharedInstance.asyncQueue.isSuspended = true
    }
    
    // sresume all operations in a queue
    func resumeAllOperations () {
        myPendingOperations.sharedInstance.asyncQueue.isSuspended = false
    }
    
    //MARK: - ScrollView methods
    // tells the delegate when the scroll view is about to start scrolling the content
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        fastScrolling = false
    }
    
    // tells the delegate when dragging ended in the scroll view
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
    
    // tells the delegate that the scrolling movement comes to a halt
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
    
    // tells the delegate that the scroll view will continue to move a short distance
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
         DispatchQueue.main.async {
            self.loadImagesForCurrentCells(completion: {})
        }
    }
    
    // tells the delegate when the user scrolls the content view
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let d = Date()
        let y = scrollView.contentOffset.y
        let elapsed = Date().timeIntervalSince(self.previousScrollMoment)
        let distance = (y - self.previousScrollY)

        self.scrollingVelocity = (elapsed == 0) ? 0 : Int(abs(distance / CGFloat(elapsed)))
    
        self.previousScrollMoment = d
        self.previousScrollY = y
        
        let pathsArray = myTableView.indexPathsForVisibleRows
        
        // normal drag is at 200 - 400 pps
        // fast launch is at 1000 - 3000 pps
        // slows down to a stop at 20 - 30 pps
        if scrollingVelocity > 1000 && !fastScrolling {
        // very fast scrolling
            self.fastScrolling = true
        }
        if distance < 0  {
            // backward scrolling
            self.scrollingBackwards = true
        }
        
        if scrollingVelocity < 300 && (fastScrolling || scrollingBackwards)  {
            // very fast going to stop soon
            currentMaxIndex = (pathsArray?.first?.row)!
            DispatchQueue.main.async {
                self.loadImagesForCurrentCells(completion: { [weak self] in self?.fastScrolling = false ; self?.scrollingBackwards = false } )
            }
        }
    }
    
    //MARK: -  DataSource  protocol
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows
        return self.myPhotos.count
    }
    
    //MARK: -  TableView  protocol
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let myCell = tableView.dequeueReusableCell(withIdentifier: myReuseIdentifier, for: indexPath) as! myTableViewCell
        
        let photoDetails = myPhotos[indexPath.row]
        
        myCell.myAuthorLbl.text = photoDetails.author
        
        myCell.myImage.image = myImageCache.sharedInstance.imageCache.object(forKey: indexPath.row as AnyObject) as? UIImage
        if (myCell.myImage?.image == nil){
            myCell.myImage?.image = photoDetails.image
        }

        else{
            // free the heap if the image is loaded and resized
            self.myPhotos[indexPath.row].image  = nil;
        }
        switch (photoDetails.state){
            
        case .Resized:
            // final image is ready
            myCell.myResizeButton.setImage(UIImage(named: "checkbox_full"), for: UIControl.State.normal)
            myCell.myDwnldButton.setImage(UIImage(named: "checkbox_full"), for: UIControl.State.normal)
        case .Downloaded:
            //
           myCell.myDwnldButton.setImage(UIImage(named: "checkbox_full"), for: UIControl.State.normal)
        case .New , .Failed:
            myCell.myResizeButton.setImage(UIImage(named: "checkbox_empty"), for: UIControl.State.normal)
            myCell.myDwnldButton.setImage(UIImage(named: "checkbox_empty"), for: UIControl.State.normal)
 
        }
        return myCell
    }
    
}
