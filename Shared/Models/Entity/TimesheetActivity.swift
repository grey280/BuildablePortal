//
//  TimesheetActivity.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

class TimesheetActivity: Codable {
    typealias ID = Int
    
    var ID: ID? // from timesheetActivityId
    var name: String?
    var code: String?
    var isActive: Bool?
    var color: String?
    var dateAdded: Date?
    var dateModified: Date?
    
    enum CodingKeys: String, CodingKey {
        case ID = "timesheetActivityId", name, code, isActive, color, dateAdded, dateModified
    }
}
