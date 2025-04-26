//
//  PublicMessagePayload.swift
//  RealTimeChat
//
//  Created by Sandeep on 25/04/25.
//

import Foundation

struct PublicMessagePayload: Codable {
    let text: String
    let senderId: String
    let receiverId: String
}
