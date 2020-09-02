//
//  AuthResult.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

class AuthResult: Codable {
    var token: String?
    var expiresIn: Int?
    var errorMessage: String?
    var userID: SystemUser.ID?
    var primaryUserID: Int?
    var userLogin: String?
    var userName: String?
    var userRoles: [String]?
    var fullName: String?
    
    var userIdentityCurrent: AuthUserIdentity?
    var userIdentities: [AuthUserIdentity]?
    
    enum CodingKeys: String, CodingKey{
        case token, expiresIn, errorMessage, userID = "userId", primaryUserID, userLogin, userName, userRoles, fullName, userIdentityCurrent, userIdentities
    }
}
