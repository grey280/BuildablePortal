//
//  SearchFields.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

class SearchFields: Codable {
    var accountID: Int? // from accountId
    var accountInvoiceID: Int? // from accountInvoiceId
    var accountProjectID: AccountProject.ID? // from accountProjectId
    var systemTeamID: Int? // from systemTeamId
    var systemUserID: SystemUser.ID? // from systemUserId
    var deviceID: Int? // from deviceId
    var dateStart: Date?
    var dateEnd: Date?
    
    enum CodingKeys: String, CodingKey {
        case accountID = "accountId"
        case accountProjectID = "accountProjectId"
        case accountInvoiceID = "accountInvoiceId"
        case systemTeamID = "systemTeamId"
        case systemUserID = "systemUserId"
        case deviceID = "deviceId"
        case dateStart, dateEnd
    }
}
