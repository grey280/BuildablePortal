//
//  DateFormatter+Extensions.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/16/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

extension DateFormatter {
    static let buildableDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.calendar = Calendar(identifier: .iso8601)
//        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.timeZone = .current // we want PST, I guess?
        formatter.locale = Locale(identifier: "en_us_POSIX")
        return formatter
    }()
}
