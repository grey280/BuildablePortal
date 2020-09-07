//
//  ErrorResult.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 9/7/20.
//

import Foundation

class ErrorResult: Codable {
    var status: Int = 200
    var statusText: String?
    var doLogout: Bool = false
    var responseText: String?
    // Object ResponseData can't be mapped to Swift - no base Object class
}
