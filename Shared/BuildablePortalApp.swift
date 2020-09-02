//
//  BuildablePortalApp.swift
//  Shared
//
//  Created by Grey Patterson on 9/2/20.
//

import SwiftUI

@main
struct BuildablePortalApp: App {
    @StateObject var timesheet = Timesheet()
    
    var body: some Scene {
        WindowGroup {
            TimesheetView(timesheet: timesheet)
        }
    }
}
