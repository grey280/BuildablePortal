//
//  Timesheet.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 9/2/20.
//

import Foundation
import Combine
import os.log

class Timesheet : ObservableObject {
    private let logger = Logger(subsystem: "com.buildableworks.portal", category: "timesheet")
    
    private var loadRequest: AnyCancellable?
    private var deleteRequest: AnyCancellable?
    private var upsertRequests: [AnyCancellable] = []
    
    @Published var entries: [TimesheetEntry] = []

    @Published var days: [TimesheetDay] = []
    var pager: Pager = Pager()
    var searchOptions: SearchOptions = {
        let so = SearchOptions()
        so.pageSize = 100
        return so
    }()
    
    @Published private var _loading = 0
    public var loading: Bool {
        _loading > 0
    }
    
    func load(){
        guard AuthService.shared.loggedIn else {
            logger.debug("Not logged in; skipping load")
            return
        }
        
        guard pager.totalPages == nil || (pager.pageNumber ?? 1) <= pager.totalPages! else {
            logger.debug("On last page; skipping load. Page \(self.pager.pageNumber ?? -1, privacy: .public), total \(self.pager.totalPages ?? -1, privacy: .public)")
            return
        }
        
        self.searchOptions.pageNumber = (self.searchOptions.pageNumber ?? 0) + 1
        self.pager.pageNumber = (self.pager.pageNumber ?? 0) + 1
        if let _ = loadRequest {
            _loading -= 1 // clear loading state if we're cancelling
        }
        _loading += 1
        
        // want to hit "https://portal.buildableworks.com/api/User/Timeclock/getItems" with a SearchOptions and the headers set
        let getURL = URL(string: "https://portal.buildableworks.com/api/User/Timeclock/getItems")!
        
        loadRequest?.cancel()
        loadRequest = Network.getItems(self.searchOptions, route: getURL)
            .sink(receiveCompletion: { (completion) in
                self.logger.debug("load() Got completion")
                self._loading -= 1
                switch(completion){
                case .failure(let error):
                    switch (error.errorType){
                    case .unauthorized:
                        self.logger.debug(("load() got error: unauthorized"))
                        AuthService.shared.loggedIn = false
                    default:
                        self.logger.error(("load() got error: \(error.localizedDescription, privacy: .public)"))
                        break
                    }
                default:
                    break
                    // do nothing
                }
            }, receiveValue: { (values: [TimesheetEntry]) in
                self.logger.debug("Received new timesheet entries")
                
                self.pager = values.last?.pager ?? self.pager
                if let totalItems = self.pager.totalItems, let pageSize = self.pager.pageSize {
                    self.pager.totalPages = totalItems / pageSize
                }
                let newValues = values.dropLast() // pager
                self.entries.append(contentsOf: Array(newValues))
                self.updateDays()
            })
    }
    
    func clear(){
        entries = []
        days = []
        pager = Pager()
        searchOptions.pageNumber = 0
        load()
    }
    
    func upsert(_ entry: TimesheetEntry, completion: @escaping ((Subscribers.Completion<NetworkError>) -> Void), receiveValue: ((TimesheetEntry) -> Void)?) {
        let wasAddition = entry.id == 0
        let url = entry.id == 0 ? URL(string: "https://portal.buildableworks.com/api/User/Timeclock/")! : URL(string: "https://portal.buildableworks.com/api/User/Timeclock/\(entry.id)")!
        let newRequest = entry.id == 0 ? Network.post(entry, route: url) : Network.put(entry, route: url)
        let sank = newRequest
            .sink(receiveCompletion: completion) { (entry) in
                if (wasAddition){
                    self.entries.append(entry)
                    self.updateDays()
                } else {
                    if let index = self.entries.firstIndex(of: entry) {
                        self.entries[index] = entry
                        self.updateDays()
                    }
                }
                
                receiveValue?(entry)
            }
        // stores it internally, so if the return doesn't get stored it doesn't get deinit-cancelled
        self.upsertRequests.append(sank)
    }
    
    private func updateDays(){
        let allEntries = entries.sorted(by: { $0.entryDate < $1.entryDate })
        let grouped = Dictionary(grouping: allEntries) { (entry: TimesheetEntry) -> String in
            entry.entryDateString
        }
        
        self.days = grouped.map { day -> TimesheetDay in
            TimesheetDay(entries: day.value)
        }.sorted { $0.date > $1.date }
    }
    
    func delete(at offsets: IndexSet, in day: TimesheetDay){
        guard let dayIndex = self.days.firstIndex(where: { (innerDay) -> Bool in
            innerDay.id == day.id
        }) else {
            logger.error("Invalid day \(day.date, privacy: .public); not saving")
            return
        }
        let items = offsets.map { self.days[dayIndex].entries[$0] }
        deleteRequest?.cancel()
        _loading += 1
        let url = URL(string: "https://portal.buildableworks.com/api/User/Timeclock/deleteBulk")!
        deleteRequest = Network.deleteBulk(items, route: url)
            .sink(receiveCompletion: { (completion) in
                self.logger.debug("delete() Received completion")
                self._loading -= 1
            }, receiveValue: { (_) in
                self.logger.debug("delete() Received value")
                self.clear()
            })
        // temporarily inaccurate, but makes the animation snappier, so we'll do it
        self.entries.removeAll { (entry) -> Bool in
            if let _ = items.firstIndex(where: { (entry2) -> Bool in
                entry.id == entry2.id
            }) {
                return true
            }
            return false
        }
        self.updateDays()
    }
}


struct TimesheetDay: Identifiable {
    var id: Date {
        entries[0].entryDate
    }
    
    let entries: [TimesheetEntry]
    var title: String {
        entries.first?.entryDateString ?? "Unknown"
    }
    var total: Double {
        entries.map { $0.entryHours }.reduce(0, +)
    }
    var date: Date {
        entries.first?.entryDate ?? Date()
    }
}
