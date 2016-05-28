//
//  loginCommunications.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/25/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import Foundation

class loginCommunications:  NSObject {
    let last_username: String! = NSTemporaryDirectory() + "lastUser.txt"

    func storeLastUsername(logString: String) {
        // For logging purposes
        _ = try! logString.writeToFile(self.last_username,
                                       atomically: true,
                                       encoding: NSUTF8StringEncoding)
    }
    
    func readLastUsername() -> String {
        let readFile:NSString? = try! NSString(contentsOfFile: self.last_username,
                                          encoding: NSUTF8StringEncoding) as? String
        if let fileContents = readFile {
            return String(fileContents)
        } else {
            return String("No Stored Password")
        }
    }
}