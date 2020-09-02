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
    
    @Published var entries: [TimesheetEntry] = []

    @Published var days: [TimesheetDay] = []
    var pager: Pager = Pager()
    var searchOptions: SearchOptions = {
        let so = SearchOptions()
        so.pageSize = 100
        return so
    }()
    
    func load(){
        guard AuthService.shared.loggedIn else {
            return
        }
        
        guard pager.totalPages == nil || (pager.pageNumber ?? 1) < pager.totalPages! else {
            return
        }
        
        // want to hit "https://portal.buildableworks.com/api/User/Timeclock/getItems" with a SearchOptions and the headers set
        let getURL = URL(string: "https://portal.buildableworks.com/api/User/Timeclock/getItems")!
        
        loadRequest?.cancel()
        loadRequest = CacheService.getItems(self.searchOptions, route: getURL)
            .sink(receiveCompletion: { (completion) in
                print(completion)
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
