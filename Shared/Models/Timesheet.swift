//
//  Timesheet.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 9/2/20.
//

import Foundation

class Timesheet : ObservableObject {
    @Published var entries: [TimesheetEntry] = []

    @Published var days: [TimesheetDay] = []
    var pager: Pager = Pager()
    var searchOptions: SearchOptions = {
        let so = SearchOptions()
        so.pageSize = 100
        return so
    }()
    
    func load(){
        
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
