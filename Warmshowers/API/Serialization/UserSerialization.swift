//
//  UserSerialization.swift
//  Warmshowers
//
//  Created by Michael Haeuslmann on 23/05/15.
//  Copyright (c) 2015 Michael Haeuslmann. All rights reserved.
//

import SwiftyJSON

public class UserSerialization
{
    public static func deserializeJSON(json: JSON) -> User
    {
        var user = User()
        user.id = json["uid"].intValue
        user.username = json["name"].stringValue
        
        user.fullname = json["fullname"].stringValue
        user.picture = json["picture"].stringValue
        user.comments = json["comments"].stringValue
        
        user.spokenLanguages = json["languagesspoken"].stringValue
        user.mobilePhone = json["mobilePhone"].stringValue
        
        user.street = json["street"].stringValue
        user.city = json["city"].stringValue
        user.zipCode = json["postal_code"].stringValue
        user.country = json["country"].stringValue
        
        user.latitude = json["latitude"].doubleValue
        user.longitude = json["longitude"].doubleValue
        
        return user
    }
}
