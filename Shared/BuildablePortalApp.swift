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
    @ObservedObject var auth = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            if (auth.needsLogin){
                LoginView()
            } else {
                TimesheetView(timesheet: timesheet)
            }
        }
    }
}
