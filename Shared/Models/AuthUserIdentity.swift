//
//  AuthUserIdentity.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

class AuthUserIdentity: Codable{
    enum IdentityType: String, Codable {
        case User = "user"
    }
    
    var description: String?
    var hash: String?
    var identityType: IdentityType? // originally a string, but I'm going Swifty
    var systemUserID: SystemUser.ID? // is marked as [TypewriterIgnore] in the C#, so... we'll make it optional, I guess?
}
