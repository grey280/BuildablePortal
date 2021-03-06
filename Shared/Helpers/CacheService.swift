//
//  CacheService.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 9/7/20.
//

import Foundation
import Combine
import os.log

class CacheService: ObservableObject {
    private let logger = Logger(subsystem: "com.buildableworks.portal", category: "cache")
    
    public init(auth: AuthService){
        self.reloadCacheAll()
        // allows auto-refresh when signin happens
        signinSubscription = auth.objectWillChange.print("objectWillChange").sink(receiveValue: { (_) in
            if (auth.loggedIn){
                self.reloadCacheAll()
            }
        })
    }
    
    private var signinSubscription: AnyCancellable!
    private var subscriptions: [AnyCancellable] = []
    
    private func splitActivities(items: [TimesheetActivity]) -> Void {
        self.logger.debug("splitActivities got \(items.count, privacy: .public) items")
        self.cachedActivities = items.filter { $0.name != nil && $0.ID != nil }.map {
            ListResultItem(label: $0.name!, value: $0.ID!)
        }
        let withIDs = items.filter { $0.ID != nil }
        let asValues = withIDs.map {
                ($0.ID!, $0.color)
            }
        self.cachedActivityColors = Dictionary(uniqueKeysWithValues: asValues)
        let nameValues = withIDs.map {
            ($0.ID!, $0.name)
        }
        self.cachedActivityNames = Dictionary(uniqueKeysWithValues: nameValues)
    }
    
    func reloadCacheAll(){
        self.logger.debug("reloadCacheAll()")
        for sub in subscriptions{
            sub.cancel()
        }
        let accounts = Network.getResultItems(nil, route: URL(string: "\(Network.appBase)/api/Account/Accounts/getResultItems")!)
            .print("reloadCacheAll.accounts")
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { (items) in
                self.cachedAccounts = items
                let nonNilItems = items.filter { $0.valueInt != nil }
                self.accountNames = Dictionary(uniqueKeysWithValues: nonNilItems.map { ($0.valueInt!, $0.label)})
                self.accountShortNames = Dictionary(uniqueKeysWithValues: nonNilItems.map { ($0.valueInt!, String($0.label.split(separator: " ")[0]))})
            }
        let options = SearchOptions()
        options.pagingDisabled = true
        options.fields = SearchFields()
        options.fields?.deviceID = 1 // used in AccountProjects.getItems(getItemsData) to not bring *every* timesheet entry - significant data use reduction
        let activities = Network.getItems(options, route: URL(string: "\(Network.appBase)/api/Finance/TimesheetActivities/getItems")!)
            .print("reloadCacheAll.activities")
//            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {
                print($0)
            }, receiveValue: splitActivities)
//            .sink(receiveValue: splitActivities)
        
        let accountProjects = Network.getItems(options, route: URL(string: "\(Network.appBase)/api/Account/AccountProjects/getItems")!)
            .print("reloadCacheAll.accountProjects")
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { (items: [AccountProject]) in
                self.cachedAccountProjects = items
                let asValues = items.filter { $0.ID != nil }
                    .map {
                        ($0.ID!, $0)
                    }
                self.accountProjects = Dictionary(uniqueKeysWithValues: asValues)
            })
        subscriptions = [accounts, activities, accountProjects]
    }
    
    @Published private(set) var cachedAccounts: [ListResultItem] = []
    @Published private(set) var accountNames: [AccountProject.AccountID: String?] = [:]
    @Published private(set) var accountShortNames: [AccountProject.AccountID: String?] = [:]
    
    @Published private(set) var cachedActivities: [ListResultItem] = []
    @Published private(set) var cachedActivityColors: [TimesheetActivity.ID: String?] = [:]
    @Published private(set) var cachedActivityNames: [TimesheetActivity.ID: String?] = [:]
    
    @Published private(set) var cachedAccountProjects: [AccountProject] = []
    @Published private(set) var accountProjects: [AccountProject.ID: AccountProject] = [:]
}
