//
//  SystemUser.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

class SystemUser: Codable{
    typealias ID = Int
    
    // var systemUserRoleAssignments: [SystemUserRoleAssignment]?
    // var systemTeamMembers: [SystemTeamMember]?
    // var systemUserSettings: [SystemUserSetting]?
    
    var ID: ID? // renamed from systemUserId
    var isActive: Bool?
    var isDeleted: Bool?
    var dateAdded: Date?
    var dateModified: Date?
    var emailAddress: String?
    var password: String?
    var firstName: String?
    var lastName: String?
    var dateLastLogin: Date?
    var passwordResetHash: String?
    var datePasswordResetHashExpire: Date?
    var isTimesheetRequired: Bool?
    
    enum CodingKeys: String, CodingKey {
        case ID = "systemUserId", isActive, isDeleted, dateAdded, dateModified, emailAddress, password, firstName, lastName, dateLastLogin, passwordResetHash, datePasswordResetHashExpire, isTimesheetRequired
    }
}
