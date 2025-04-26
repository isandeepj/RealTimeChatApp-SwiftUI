//
//  Date+Format.swift
//  RealTimeChat
//
//  Created by Sandeep on 26/04/25.
//

import Foundation

extension Date {
    static let sharedTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    var formattedString: String {
        return Date.sharedTimeFormatter.string(from: self)
    }
}


