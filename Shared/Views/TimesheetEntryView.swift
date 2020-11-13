//
//  TimesheetEntryView.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/20/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import SwiftUI

struct TimesheetEntryView: View {
    @ObservedObject var timesheet: Timesheet
    
    var isNew: Bool{
        return timesheetEntry.id == 0
    }
    
    @ObservedObject var timesheetEntry: TimesheetEntry
    @EnvironmentObject var cache: CacheService
    
    @State var hasError = false
    @State var error: String? = nil
    
    @Environment(\.presentationMode) var presentationMode
    
    let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
    
    var body: some View {
        Form{
            Picker(selection: $timesheetEntry.accountID, label: Text("Account")) {
                ForEach(cache.cachedAccounts, id: \.valueInt){
                    Text($0.label).tag($0.valueInt ?? -1)
                }
            }
            Picker(selection: $timesheetEntry.accountProjectID, label: Text("Project")) {
                ForEach(cache.cachedAccountProjects.filter { $0.accountID == self.timesheetEntry.accountID }.sorted(by: { (a, b) -> Bool in
                    if let aEnd = a.dateEnd, let bEnd = b.dateEnd {
                        return aEnd > bEnd
                    }
                    return a.ID! > b.ID!
                }), id: \.ID) { accountProject in
                    AccountProjectCellView(accountProject: accountProject).tag(accountProject.ID ?? -1)
                }
            }.disabled(timesheetEntry.accountProjectAccountID == 0 || timesheetEntry.accountProjectAccountID == nil)
            if (timesheetEntry.accountProjectItems != nil && timesheetEntry.accountProjectItems!.count > 0) {
                Picker(selection: $timesheetEntry.accountProjectItemID, label: Text("Project Item")) {
                    ForEach(timesheetEntry.accountProjectItems!, id: \.id) {
                        Text("\(String(format: "%.2f", arguments: [($0.itemNumber ?? 1.01)])) - \($0.deliverable ?? "Unknown")").tag($0.id ?? -1)
                    }
                }
            }
            Picker(selection: $timesheetEntry.timesheetActivityID, label: Text("Activity")) {
                ForEach(cache.cachedActivities, id: \.valueInt){
                    Text($0.label).tag($0.valueInt ?? -1)
                }
            }
            DatePicker(selection: $timesheetEntry.entryDate, displayedComponents: .date) {
                Text("Date")
            }
            Stepper(value: $timesheetEntry.entryHours, in: 0...24, step: 0.25) {
                Text("Hours: \(formatter.string(from: NSNumber(value: self.timesheetEntry.entryHours)) ?? "0")")
            }
            TextField("Description", text: $timesheetEntry.description)
        }
        .navigationTitle(Text(isNew ? "New Entry" : "Edit Entry"))//, displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                Button(action: {
                    self.timesheetEntry.systemUserID = AuthService.shared.authInfo?.userID ?? 0
                    self.timesheet.upsert(self.timesheetEntry) { (completion) in
                        switch completion{
                        case .failure(let error):
                            self.error = error.statusText
                            self.hasError = true
                        case .finished:
                            if (!self.hasError){
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }
                    } receiveValue: { (value) in
                        print(value)
                    }
                }) {
                    Text("Save")
                        .padding()//.hoverEffect()
                }
            }
        }
            .alert(isPresented: self.$hasError) { () -> Alert in
                Alert(title: Text("Unable to save"), message: Text(self.error ?? "Unknown error"), dismissButton: nil)
        }
        
    }
}

//#if DEBUG
//struct TimesheetEntryView_Previews: PreviewProvider {
//    static var previews: some View {
//        TimesheetEntryView()
//    }
//}
//#endif
