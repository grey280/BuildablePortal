//
//  TimesheetEntryCell.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 9/7/20.
//

import SwiftUI

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
                Text(entry.timesheetActivityName ?? "Unknown").font(.footnote)
                Spacer()
                Text(entry.entryDateString).font(.footnote)
            }
        }
    }
}

struct TimesheetEntryCell_Previews: PreviewProvider {
    static var previews: some View {
        TimesheetEntryCell(entry: TimesheetEntry())
    }
}
