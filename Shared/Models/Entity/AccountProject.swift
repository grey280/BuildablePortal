//
//  AccountProject.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

class AccountProject: Codable {
    typealias ID = Int
    typealias AccountID = Int
    
    var timesheetEntries: [TimesheetEntry]?
    var accountProjectItems: [AccountProjectItem]?
//    var account: Account?
    var ID: ID? // from accountProjectId
    var accountID: AccountID? // from accountId
    var name: String?
    var description: String?
    var isActive: Bool?
    var dateAdded: Date?
    var dateModified: Date?
    var isBillable: Bool?
    var dateStart: Date?
    var dateEnd: Date?
    var accountName: String? // notmapped
    var isCurrent: Bool {
        guard let dateEnd = dateEnd else {
            return true
        }
        return dateEnd > Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case timesheetEntries, ID = "accountProjectId", accountID = "accountId", name, description, isActive, dateAdded, dateModified, isBillable, dateStart, dateEnd, accountName, accountProjectItems
    }
}
