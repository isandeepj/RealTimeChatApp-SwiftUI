//
//  Message.swift .swift
//  RealTimeChat
//
//  Created by Sandeep on 25/04/25.
//

import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let text: String
    let timestamp: Date
    let isSentByUser: Bool
    let sender: User
    let receiver: User
    var isQueued: Bool = false
    var isRead: Bool = false

    init(id: UUID = UUID(), text: String, timestamp: Date, isSentByUser: Bool, sender: User, receiver: User, isQueued: Bool = false, isRead: Bool = false) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.isSentByUser = isSentByUser
        self.sender = sender
        self.receiver = receiver
        self.isQueued = isQueued
        self.isRead = isRead
    }
}
