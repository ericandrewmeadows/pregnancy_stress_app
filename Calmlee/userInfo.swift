//
//  userInfo.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/6/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import Foundation

class userInfo: NSObject {
    
    //properties
    
    var firstName: String?
//    var address: String?
//    var latitude: String?
//    var longitude: String?
    
    
    //empty constructor
    
    override init()
    {
        
    }
    
    //construct with @name, @address, @latitude, and @longitude parameters
    
    init(firstName: String) {//, address: String, latitude: String, longitude: String) {
        
        self.firstName = firstName
//        self.address = address
//        self.latitude = latitude
//        self.longitude = longitude
        
    }
    
    
    //prints object's current state
    
    override var description: String {
        return "Name: \(firstName)"//, Address: \(address), Latitude: \(latitude), Longitude: \(longitude)"
        
    }
    
    
}