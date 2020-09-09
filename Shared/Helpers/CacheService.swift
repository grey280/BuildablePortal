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
    
    func reloadCacheAll(){
        print("reloadCacheAll()")
        for sub in subscriptions{
            sub.cancel()
        }
        let accounts = Network.getResultItems(nil, route: URL(string: "https://portal.buildableworks.com/api/Account/Accounts/getResultItems")!)
            .print("reloadCacheAll.accounts")
            .replaceError(with: [])
            .assign(to: \.cachedAccounts, on: self)
        let activities = Network.getResultItems(nil, route: URL(string: "https://portal.buildableworks.com/api/Finance/TimesheetActivities/getResultItems")!)
            .print("reloadCacheAll.activities")
            .replaceError(with: [])
            .assign(to: \.cachedActivities, on: self)
        let options = SearchOptions()
        options.pagingDisabled = true
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
//            .map { (items: [AccountProject]) -> [Int: AccountProject] in
//                let withID = items.filter { $0.ID != nil }
//                let asValues = withID.map { ($0.ID!, $0) }
//                return Dictionary(uniqueKeysWithValues: asValues)
//            }
//            .assign(to: \.cachedAccountProjects, on: self)
        subscriptions = [accounts, activities, accountProjects]
    }
    
    @Published private(set) var cachedAccounts: [ListResultItem] = []
    @Published private(set) var cachedActivities: [ListResultItem] = []
    
    @Published private(set) var cachedAccountProjects: [AccountProject] = []
    @Published private(set) var accountProjectNames: [AccountProject.ID: String?] = [:]
}
