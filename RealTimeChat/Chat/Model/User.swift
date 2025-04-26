//
//  User.swift
//  RealTimeChat
//
//  Created by Sandeep on 25/04/25.
//

import Foundation

struct User: Identifiable, Hashable, Equatable, Codable {
    let id: String
    let name: String

    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}
