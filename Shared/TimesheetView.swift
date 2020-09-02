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
    @State var isLoggingIn = false
    @State var authInfo: AuthResult = AuthResult() // this should be properly set up elsewhere, maybe with a BindableObject? dunno yet
    
    @ObservedObject var timesheet: Timesheet
    @ObservedObject var auth = AuthService.shared
    
    var body: some View {
        return NavigationView {
            List {
                ForEach(timesheet.days) { (day) in
                    Section(header: Text("\(day.title): \(TimesheetEntryCell.formatter.string(from: NSNumber(value: day.total)) ?? "0") hours")) {
                        ForEach(day.entries) { (entry) in
                            NavigationLink(destination: TimesheetEntryView(timesheetEntry: entry, onSave: {
                                self.timesheet.clear()
                            })) {
                                TimesheetEntryCell(entry: entry)
                            }
                        }
//                        .onDelete { (indices) in
//                            self.delete(at: indices, in: day)
//                        }
                    }
                }
                if ((self.timesheet.pager.totalItems ?? 0) > self.timesheet.entries.count){
                    Button(action: {
                        self.timesheet.searchOptions.pageNumber = (self.timesheet.searchOptions.pageNumber ?? 1) + 1
                        self.timesheet.pager.pageNumber = (self.timesheet.pager.pageNumber ?? 1) + 1
                        self.timesheet.load()
                    }) {
                        Text("Load more...")
                    }
                }
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
                    NavigationLink(destination: TimesheetEntryView(timesheetEntry: TimesheetEntry(), onSave: {
                        self.timesheet.clear()
                    }), label: {
                        Image(systemName: "plus")
                    }).padding().hoverEffect()
            )
        }.sheet(isPresented: self.$auth.needsLogin) {
            LoginView().onDisappear(
                perform: self.timesheet.clear
            )
        }.onAppear {
            self.timesheet.clear()
        }.onReceive(self.auth.objectWillChange) { (_) in
            self.timesheet.clear()
        }
    }
    
    
    
    
    
//    func delete(at offsets: IndexSet, in day: TimesheetDay){
//        guard let dayIndex = self.days.firstIndex(where: { (innerDay) -> Bool in
//            innerDay.id == day.id
//        }) else {
//            print("Invalid day")
//            return
//        }
//        let items = offsets.map { self.days[dayIndex].entries[$0] }
//        cancelHolder.cancellable?.cancel()
//        guard let url = URL(string: "https://portal.buildableworks.com/api/User/Timeclock/deleteBulk") else {
//            return
//        }
//        cancelHolder.cancellable = CacheService.deleteBulk(items, route: url)
//            .sink(receiveCompletion: { (completion) in
//                print(completion)
//            }, receiveValue: { (_) in
//                print("value")
//                self.resetAndReload()
//            })
//        // temporarily inaccurate, but makes the animation snappier, so we'll do it
//        self.entries.removeAll { (entry) -> Bool in
//            if let _ = items.firstIndex(where: { (entry2) -> Bool in
//                entry.id == entry2.id
//            }) {
//                return true
//            }
//            return false
//        }
//        self.updateDays()
//    }
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
