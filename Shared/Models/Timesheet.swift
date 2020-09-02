//
//  Timesheet.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 9/2/20.
//

import Foundation
import Combine

class Timesheet : ObservableObject {
    private var loadRequest: AnyCancellable?
    private var deleteRequest: AnyCancellable?
    
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
            return
        }
        
        guard pager.totalPages == nil || (pager.pageNumber ?? 1) < pager.totalPages! else {
            return
        }
        
        _loading += 1
        
        // want to hit "https://portal.buildableworks.com/api/User/Timeclock/getItems" with a SearchOptions and the headers set
        let getURL = URL(string: "https://portal.buildableworks.com/api/User/Timeclock/getItems")!
        
        loadRequest?.cancel()
        loadRequest = CacheService.getItems(self.searchOptions, route: getURL)
            .sink(receiveCompletion: { (completion) in
                print(completion)
                self._loading -= 1
                switch(completion){
                case .failure(let error):
                    switch (error){
                    case .unauthorized:
                        AuthService.shared.loggedIn = false
                    default:
                        break
                    }
                default:
                    break
                    // do nothing
                }
            }, receiveValue: { (values: [TimesheetEntry]) in
                print("Received new timesheet entries")
                
                self.pager = values.last?.pager ?? self.pager
                let newValues = values.dropLast() // pager
                self.entries.append(contentsOf: Array(newValues))
                self.updateDays()
            })
    }
    
    func clear(){
        entries = []
        days = []
        pager = Pager()
        searchOptions.pageNumber = 1
        load()
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
            print("Invalid day")
            return
        }
        let items = offsets.map { self.days[dayIndex].entries[$0] }
        deleteRequest?.cancel()
        _loading += 1
        let url = URL(string: "https://portal.buildableworks.com/api/User/Timeclock/deleteBulk")!
        deleteRequest = CacheService.deleteBulk(items, route: url)
            .sink(receiveCompletion: { (completion) in
                print(completion)
                _loading -= 1
            }, receiveValue: { (_) in
                print("value")
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
    let id = UUID()
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
