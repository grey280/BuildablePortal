//
//  AccountProjectItem.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 5/18/20.
//  Copyright © 2020 Grey Patterson. All rights reserved.
//

import Foundation

class AccountProjectItem: Codable {
    typealias ID = Int
    
    var id: ID?
    var accountProjectID: AccountProject.ID?
    var itemNumber: Double?
    var deliverable: String?
    var category: String?
    var description: String?
//    var estimatedHours: Int?
//    var contact: String?
//    var dateAdded: Date?
//    var dateModified: Date?
    
    enum CodingKeys: String, CodingKey {
        case accountProjectID = "accountProjectId"
        case id = "accountProjectItemId"
        case itemNumber = "itemNo"
        case deliverable, category, description//, estimatedHours, contact, dateAdded, dateModified
    }
}

extension AccountProjectItem: Equatable {
    static func ==(lhs: AccountProjectItem, rhs: AccountProjectItem) -> Bool {
        lhs.id == rhs.id
    }
}
