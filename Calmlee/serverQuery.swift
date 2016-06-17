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
    let defaults = NSUserDefaults.standardUserDefaults()
    var returnVal = false
    
    func getQuery(username: String) -> Bool {
        
        let semaphore = dispatch_semaphore_create(0);
        
        let url:  NSURL = NSURL(string: "https://io.calmlee.com/fetch_firstName.php")!
        
        let request = NSMutableURLRequest(URL:url)
        request.HTTPMethod = "POST"
        
        let postString = "username=\(username)"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        
//        print(postString)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data,response,error) in
            
            if error != nil {
                print("error = \(error)")
            }
            
//            print("response = \(response)")
            
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("=====")
            print(responseString!)
            print("=====")
            if responseString! != "0 results" {
//            print("\(responseString!)")
                
                let fieldsArr = responseString!.componentsSeparatedByString("\n")
                for items in fieldsArr {
                    let fieldAndValue = items.componentsSeparatedByString(" ")
                    let fieldName = fieldAndValue[0].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).stringByReplacingOccurrencesOfString(":", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                    let fieldValue = fieldAndValue[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    if (fieldValue.characters.count > 0) && (username == self.defaults.stringForKey("username")) {
                        self.defaults.setValue(fieldValue, forKey: fieldName)
                    }
                }
                print(self.defaults.stringForKey("firstName"))
                print(self.defaults.stringForKey("lastName"))
                print(self.defaults.stringForKey("email"))
                print(self.defaults.stringForKey("dueDate"))
                print(self.defaults.stringForKey("female"))
                self.returnVal = true
            }
            else {
                self.returnVal = false
            }
            dispatch_semaphore_signal(semaphore);
        }
        
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        print("-----")
        print(self.returnVal)
        print("-----")
        return self.returnVal

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
        let informations: NSMutableArray = NSMutableArray()
        
        for item in jsonResult
        {
            
            jsonElement = item as! NSDictionary
            
            let information = userInfo()
            
            //the following insures none of the JsonElement values are nil through optional binding
            if let firstName = jsonElement["firstName"] as? String
            {
                
                information.firstName = firstName
                
            }
            
            informations.addObject(information)
            
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.delegate.itemsDownloaded(informations)
            
        })
    }
    
}