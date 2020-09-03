//
//  ContentView.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import SwiftUI
import Combine

struct TimesheetEntryCell: View {
    var entry: TimesheetEntry
    
    static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
    
    var body: some View {
        VStack (spacing: 3) {
            HStack {
                Text(entry.accountProjectName ?? "")
                Spacer()
                Text(TimesheetEntryCell.formatter.string(from: NSNumber(value: entry.entryHours)) ?? "0")
            }
            HStack {
                Circle().fill(Color(entry.timesheetActivityColor ?? "brand-blue")).frame(width: 5, height: 5, alignment: .leading)
                Text(entry.timesheetActivityName!).font(.footnote)
                Spacer()
                Text(entry.entryDateString).font(.footnote)
            }
        }
    }
}



struct TimesheetView: View {
    @ObservedObject var timesheet: Timesheet
    @ObservedObject var auth = AuthService.shared
    
    var body: some View {
        return NavigationView {
            List {
                ForEach(timesheet.days) { (day) in
                    Section(header: Text("\(day.title): \(TimesheetEntryCell.formatter.string(from: NSNumber(value: day.total)) ?? "0") hours")) {
                        ForEach(day.entries) { (entry) in
                            NavigationLink(destination: TimesheetEntryView(timesheet: self.timesheet, timesheetEntry: entry)) {
                                TimesheetEntryCell(entry: entry).onAppear(perform: {
                                    if self.timesheet.entries.last == entry {
                                        self.timesheet.load()
                                    }
                                })
                            }
                        }
                        .onDelete { (indices) in
                            self.timesheet.delete(at: indices, in: day)
                        }
                    }
                }
//                if ((self.timesheet.pager.totalItems ?? 0) > self.timesheet.entries.count){
//                    Button(action: {
//                        self.timesheet.searchOptions.pageNumber = (self.timesheet.searchOptions.pageNumber ?? 1) + 1
//                        self.timesheet.pager.pageNumber = (self.timesheet.pager.pageNumber ?? 1) + 1
//                        self.timesheet.load()
//                    }) {
//                        Text("Load more...")
//                    }
//                }
            }
            .navigationBarTitle(Text("Time Clock"))
            .navigationBarItems(
                leading:
                    Button(action: {
                        self.timesheet.clear()
                    }, label: {
                        Image(systemName: "arrow.clockwise")
                    }).padding().hoverEffect(),
                trailing:
                    NavigationLink(destination: TimesheetEntryView(timesheet: self.timesheet, timesheetEntry: TimesheetEntry()), label: {
                        Image(systemName: "plus")
                    }).padding().hoverEffect()
            )
        }.onAppear {
            self.timesheet.clear()
        }
    }
}

enum networkFailureCondition: Error {
    // 401, parsing failure, generic, 403
    case unauthorized, invalidResponse, unknown, forbidden
}

#if DEBUG
struct TimesheetView_Preview: PreviewProvider {
    static var previews: some View {
        TimesheetView(timesheet: Timesheet())
    }
}
#endif
