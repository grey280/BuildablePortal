//
//  CacheService.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 9/7/20.
//

import Foundation
import Combine

class CacheService: ObservableObject {
    public static var shared = CacheService()
    private init(){
        self.reloadCacheAll()
        // allows auto-refresh when signin happens
        signinSubscription = AuthService.shared.objectWillChange.print("objectWillChange").sink(receiveValue: { (_) in
            if (AuthService.shared.loggedIn){
                self.reloadCacheAll()
            }
        })
    }
    
    private var signinSubscription: AnyCancellable!
    private var subscriptions: [AnyCancellable] = []
    
    private func splitActivities(items: [TimesheetActivity]) -> Void {
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
        print("reloadCacheAll()")
        for sub in subscriptions{
            sub.cancel()
        }
        let accounts = Network.getResultItems(nil, route: URL(string: "https://portal.buildableworks.com/api/Account/Accounts/getResultItems")!)
            .print("reloadCacheAll.accounts")
            .replaceError(with: [])
            .assign(to: \.cachedAccounts, on: self)
        let options = SearchOptions()
        options.pagingDisabled = true
        let activities = Network.getItems(options, route: URL(string: "https://portal.buildableworks.com/api/Finance/TimesheetActivities/getItems")!)
            .print("reloadCacheAll.activities")
            .replaceError(with: [])
            .sink(receiveValue: splitActivities)
        
        let accountProjects = Network.getItems(options, route: URL(string: "https://portal.buildableworks.com/api/Account/AccountProjects/getItems")!)
            .print("reloadCacheAll.accountProjects")
            .replaceError(with: [])
            .sink(receiveValue: { (items: [AccountProject]) in
                self.cachedAccountProjects = items
                let asValues = items.filter { $0.ID != nil }
                    .map {
                        ($0.ID!, $0.name)
                    }
                self.accountProjectNames = Dictionary(uniqueKeysWithValues: asValues)
            })
        subscriptions = [accounts, activities, accountProjects]
    }
    
    @Published private(set) var cachedAccounts: [ListResultItem] = []
    
    @Published private(set) var cachedActivities: [ListResultItem] = []
    @Published private(set) var cachedActivityColors: [TimesheetActivity.ID: String?] = [:]
    @Published private(set) var cachedActivityNames: [TimesheetActivity.ID: String?] = [:]
    
    @Published private(set) var cachedAccountProjects: [AccountProject] = []
    @Published private(set) var accountProjectNames: [AccountProject.ID: String?] = [:]
}
