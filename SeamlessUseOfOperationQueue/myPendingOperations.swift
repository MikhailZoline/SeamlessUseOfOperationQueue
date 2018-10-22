//
//  myPendingOperations.swift
//  ReactiveJSONAsgn
//
//  Created by Mikhail Zoline on 7/24/17.
//  Copyright © 2017 MZ. All rights reserved.
//

import Foundation


final class myPendingOperations {
    
    private init(){
        asyncQueue.name = "async_queue"
        asyncQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    }
    //MARK: -  Singleton of operation queue
    static let sharedInstance = myPendingOperations()
    //storing opertions in a dictionary with the index path as a key means lookup is fast and efficient
    var operationInProgress = [IndexPath:Operation]()
    var asyncQueue = OperationQueue()
}

