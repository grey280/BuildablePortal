//
//  AuthUser.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

class AuthUser: Codable {
    var login: String?
    var password: String?
//    var localTime: Date? // this os String? in the original, but I think Date should work?
    var localTime: String? // look into using Date? instead at some point
    var source: String?
    var passwordOld: String?
    var hash: String?
}
