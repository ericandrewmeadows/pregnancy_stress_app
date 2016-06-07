//
//  serverQuery.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/6/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import Foundation

protocol serverQueryProtocol: class {
    func itemsDownloaded(items: NSArray)
}

class serverQuery:  NSObject, NSURLSessionDataDelegate {
    
    var data : NSMutableData = NSMutableData()
    weak var delegate: serverQueryProtocol!
    
    func getQuery() {
        
//        let semaphore = dispatch_semaphore_create(0);
        
        let url:  NSURL = NSURL(string: "https://io.calmlee.com/fetch_firstName.php")!
        var session: NSURLSession!
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        let task = session.dataTaskWithURL(url)
        
        task.resume()

    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        self.data.appendData(data);
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error != nil {
            print("Failed to download data")
        }else {
            print("Data downloaded")
            self.parseJSON()
        }
        
    }
    
    func parseJSON() {
        
        var jsonResult: NSMutableArray = NSMutableArray()
        
        do{
            jsonResult = try NSJSONSerialization.JSONObjectWithData(self.data, options:NSJSONReadingOptions.AllowFragments) as! NSMutableArray
            
        } catch let error as NSError {
            print(error)
            
        }
        
        var jsonElement: NSDictionary = NSDictionary()
        let locations: NSMutableArray = NSMutableArray()
        
        for item in jsonResult
        {
            
            jsonElement = item as! NSDictionary
            
            let information = userInfo()
            
            //the following insures none of the JsonElement values are nil through optional binding
            if let firstName = jsonElement["firstName"] as? String
            {
                
                information.firstName = firstName
                
            }
            
            locations.addObject(information)
            
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.delegate.itemsDownloaded(locations)
            
        })
    }
    
}