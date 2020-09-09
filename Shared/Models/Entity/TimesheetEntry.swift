//
//  TimesheetEntry.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation
import Combine

class TimesheetEntry: Decodable, Identifiable, ObservableObject {
    init(){
        
    }
    
    private var networkRequest: AnyCancellable?
    
    // MARK: Inherited
    @Published var selected: Bool = false
    @Published var editing: Bool = false
    @Published var pager: Pager?
    
    // MARK: TimesheetEntry
    
    typealias ID = Int
    
    @Published var systemUser: SystemUser?
    @Published var accountProject: AccountProject?
    @Published var timesheetActivity: TimesheetActivity?
    
    @Published var id: ID = 0 // from timesheetEntryId
    @Published var systemUserID: SystemUser.ID = -1 // from systemUserId
    var accountProjectID: AccountProject.ID = -1{ // from accountProjectId {
        didSet {
            objectWillChange.send()
            let getURL = URL(string: "https://portal.buildableworks.com/api/Account/AccountProjectItems/getItems")!
            let options = SearchOptions()
            options.pagingDisabled = true
            let fields = SearchFields()
            fields.accountProjectID = self.accountProjectID
            options.fields = fields
            self.networkRequest = Network.getItems(options, route: getURL)
                .print("accountProjectItems.getItems:")
                .catch { error -> Just<[AccountProjectItem]?> in
                    print(error)
                    let res: [AccountProjectItem]? = []
                    return Just(res)
                }
                .map {
                    $0?.dropLast() // pager
                }
                .assign(to: \.accountProjectItems, on: self)
        }
    }
    @Published var timesheetActivityID: TimesheetActivity.ID = -1 // from timesheetActivityId
    @Published var accountProjectItemID: AccountProjectItem.ID? // from accountProjectItemId
    @Published var accountProjectItems: [AccountProjectItem]? // doesn't get transmitted on here, only attached locally
    @Published var dateAdded: Date = Date()
    @Published var dateModified: Date = Date()
    @Published var entryDate: Date = Date()
    @Published var entryHours: Double = 0 // originally a Decimal, but Foundation's Decimal type doesn't support... being a string
    @Published var description: String = ""
    
    // MARK: Notmapped
    @available(*, deprecated)
    @Published var systemUserName: String?
    @available(*, deprecated)
    @Published var accountProjectName: String?
    @available(*, deprecated)
    @Published var accountProjectAccountID: AccountProject.AccountID? // from accountProjectAccountId
    @available(*, deprecated)
    @Published var accountProjectAccountName: String?
    @available(*, deprecated)
    @Published var timesheetActivityName: String?
    @available(*, deprecated)
    @Published var timesheetActivityCode: String?
    @available(*, deprecated)
    @Published var timesheetActivityColor: String?
    
    enum CodingKeys: String, CodingKey {
        case selected, editing, pager
        case systemUser, accountProject, timesheetActivity
        case id = "timesheetEntryId"
        case systemUserID = "systemUserId"
        case accountProjectID = "accountProjectId"
        case timesheetActivityID = "timesheetActivityId"
        case accountProjectItemID = "accountProjectItemId"
        case dateAdded, dateModified, entryDate, entryHours, description
        case systemUserName, accountProjectName
        case accountProjectAccountID = "accountProjectAccountId"
        case accountProjectAccountName, timesheetActivityName, timesheetActivityCode, timesheetActivityColor
    }
    
    // MARK: Helpers
    var entryDateString: String {
        return TimesheetEntry.dateFormatter.string(from: entryDate)
    }
    private static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    @available(*, deprecated)
    var accountID: AccountProject.AccountID{
        get{
            return accountProjectAccountID ?? -1
        }
        set{
            accountProjectAccountID = newValue
        }
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selected = (try? values.decode(Bool.self, forKey: .selected)) ?? false
        editing = (try? values.decode(Bool.self, forKey: .editing)) ?? false
        pager = try values.decode(Pager?.self, forKey: .pager)
        systemUser = try values.decode(SystemUser?.self, forKey: .systemUser)
        accountProject = try values.decode(AccountProject?.self, forKey: .accountProject)
        timesheetActivity = try values.decode(TimesheetActivity?.self, forKey: .timesheetActivity)
        id = (try? values.decode(ID.self, forKey: .id)) ?? 0
        systemUserID = (try? values.decode(SystemUser.ID.self, forKey: .systemUserID)) ?? -1 // from systemUserId
        accountProjectID = (try? values.decode(AccountProject.ID.self, forKey: .accountProjectID)) ?? -1
        timesheetActivityID = (try? values.decode(TimesheetActivity.ID.self, forKey: .timesheetActivityID)) ?? -1
        accountProjectItemID = try? values.decode(AccountProjectItem.ID.self, forKey: .accountProjectItemID)
        dateAdded = (try? values.decode(Date.self, forKey: .dateAdded)) ?? Date()
        dateModified = (try? values.decode(Date.self, forKey: .dateModified)) ?? Date()
        entryDate = (try? values.decode(Date.self, forKey: .entryDate)) ?? Date()
        entryHours = (try? values.decode(Double.self, forKey: .entryHours)) ?? 0 // originally a Decimal, but Foundation's Decimal type doesn't support... being a string
        description = (try? values.decode(String.self, forKey: .description)) ?? ""

        // NotMapped
        systemUserName = try values.decode(String?.self, forKey: .systemUserName)
        accountProjectName = try values.decode(String?.self, forKey: .accountProjectName)
        accountProjectAccountID = try values.decode(AccountProject.AccountID?.self, forKey: .accountProjectAccountID)
        accountProjectAccountName = try values.decode(String?.self, forKey: .accountProjectAccountName)
        timesheetActivityName = try values.decode(String?.self, forKey: .timesheetActivityName)
        timesheetActivityCode = try values.decode(String?.self, forKey: .timesheetActivityCode)
        timesheetActivityColor = try values.decode(String?.self, forKey: .timesheetActivityColor)
    }
}

extension TimesheetEntry: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selected, forKey: .selected)
        try container.encode(editing, forKey: .editing)
        try container.encode(pager, forKey: .pager)
        try container.encode(systemUser, forKey: .systemUser)
        try container.encode(accountProject, forKey: .accountProject)
        try container.encode(timesheetActivity, forKey: .timesheetActivity)
        try container.encode(id, forKey: .id)
        try container.encode(systemUserID, forKey: .systemUserID)
        try container.encode(accountProjectID, forKey: .accountProjectID)
        try container.encode(accountProjectItemID, forKey: .accountProjectItemID)
        try container.encode(timesheetActivityID, forKey: .timesheetActivityID)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encode(dateModified, forKey: .dateModified)
        try container.encode(entryDate, forKey: .entryDate)
        try container.encode(entryHours, forKey: .entryHours)
        try container.encode(description, forKey: .description)
        try container.encode(systemUserName, forKey: .systemUserName)
        try container.encode(accountProjectName, forKey: .accountProjectName)
        try container.encode(accountProjectAccountID, forKey: .accountProjectAccountID)
        try container.encode(accountProjectAccountName, forKey: .accountProjectAccountName)
        try container.encode(timesheetActivityName, forKey: .timesheetActivityName)
        try container.encode(timesheetActivityCode, forKey: .timesheetActivityCode)
        try container.encode(timesheetActivityColor, forKey: .timesheetActivityColor)
    }
}

extension TimesheetEntry: Equatable {
    static func == (lhs: TimesheetEntry, rhs: TimesheetEntry) -> Bool {
        lhs.id == rhs.id
    }
}
