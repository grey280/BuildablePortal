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
        let project = CacheService.shared.accountProjects[entry.accountProjectID]
        var accountName: String? = nil
        if let accountID = project?.accountID {
            accountName = CacheService.shared.accountNames[accountID] ?? nil
        }
        let projectName = "\(accountName ?? "Unknown"): \(project?.name ?? "Unknown")"
        let color = (CacheService.shared.cachedActivityColors[entry.timesheetActivityID] ?? "brand-blue") ?? "brand-blue"
        let activityName = (CacheService.shared.cachedActivityNames[entry.timesheetActivityID] ?? "Not Cached") ?? "No Name"
        
        return VStack (spacing: 3) {
            HStack {
                Text(projectName)
                Spacer()
                Text(TimesheetEntryCell.formatter.string(from: NSNumber(value: entry.entryHours)) ?? "0")
            }
            HStack {
                Circle().fill(Color(color)).frame(width: 5, height: 5, alignment: .leading)
                Text(activityName).font(.footnote)
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
