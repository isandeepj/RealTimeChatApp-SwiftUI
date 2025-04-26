//
//  PieSocketManager.swift
//  RealTimeChat
//
//  Created by Sandeep on 25/04/25.
//

import Foundation
import Channels
import Combine

class PieSocketManager {
    static let shared = PieSocketManager()
    
    private var piesocket: PieSocket?
    private var channels: [String: Channel] = [:]  // ✅ Manage multiple channels
    private var listeners: [String: [String]] = [:] // roomId -> list of listenerIds
    
    let messagePublisher = PassthroughSubject<PublicMessagePayload, Never>()
    let socketStatusPublisher = PassthroughSubject<Bool, Never>()

    init() {
        
    }
    
    func connect(roomId: String, userId: String) {
        if piesocket == nil {
            let options = PieSocketOptions()
            options.setClusterId(clusterId: "s14526.blr1")
            options.setApiKey(apiKey: "mvPZpUXmxTeqwMUfjFnVLgnimi3nfKncqDhOCUC0")
            options.setUserId(userId: userId)

            piesocket = PieSocket(pieSocketOptions: options)
        }
        
        let channel = piesocket!.join(roomId: roomId)
        channels[roomId] = channel
        
        var roomListeners: [String] = []
        
        // Connected
        let connectedListener = channel.listen(eventName: "system:connected") { [weak self] _ in
            self?.socketStatusPublisher.send(true)
        }
        roomListeners.append(connectedListener)
        
        // Closed
        let closedListener = channel.listen(eventName: "system:closed") { [weak self] _ in
            self?.socketStatusPublisher.send(false)
        }
        roomListeners.append(closedListener)
        
        // Message
        let messageListener = channel.listen(eventName: "system:message") { [weak self] event in
            guard let self = self else { return }
            let raw = event.getData()
            if let json = self.extractUnescapedDataPayload(from: raw),
               let jsonData = json.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let text = dict["text"] as? String,
               let senderId = dict["senderId"] as? String, let receiverId = dict["receiverId"] as? String {
                let payload = PublicMessagePayload(text: text, senderId: senderId, receiverId: receiverId)
                self.messagePublisher.send(payload)
            }
        }
        roomListeners.append(messageListener)
        
        listeners[roomId] = roomListeners
    }
    
    func publish(to roomId: String, payload: PublicMessagePayload) {
        guard let channel = channels[roomId] else { return }
        guard let encoded = try? JSONEncoder().encode(payload),
              let jsonString = String(data: encoded, encoding: .utf8) else {
            return
        }
        
        let event = PieSocketEvent(event: "new-message")
        event.setData(data: jsonString)
        channel.publish(event: event)
    }
    
    func reconnect(roomId: String) {
        guard let channel = channels[roomId] else {
            return
        }
        channel.reconnect()
    }

    func reconnectAll() {
        for (_, channel) in channels {
            channel.reconnect()
        }
    }

    func disconnect(roomId: String) {
        guard let channel = channels[roomId] else { return }
        listeners[roomId]?.forEach { listenerId in
            channel.removeListener(eventName: "system:connected", callbackId: listenerId)
            channel.removeListener(eventName: "system:closed", callbackId: listenerId)
            channel.removeListener(eventName: "system:message", callbackId: listenerId)
        }
        channel.disconnect()
        channels.removeValue(forKey: roomId)
        listeners.removeValue(forKey: roomId)
    }
    
    func disconnectAll() {
        for roomId in channels.keys {
            disconnect(roomId: roomId)
        }
        piesocket = nil
        socketStatusPublisher.send(false)
    }
    
    private func extractUnescapedDataPayload(from raw: String) -> String? {
        guard let dataKeyRange = raw.range(of: "\"data\"") else { return nil }
        guard let startBrace = raw[dataKeyRange.upperBound...].firstIndex(of: "{") else { return nil }
        
        var braceCount = 0
        var endIndex: String.Index? = nil
        for index in raw[startBrace...].indices {
            let char = raw[index]
            if char == "{" { braceCount += 1 }
            if char == "}" { braceCount -= 1 }
            if braceCount == 0 {
                endIndex = index
                break
            }
        }
        guard let end = endIndex else { return nil }
        let innerJSON = raw[startBrace...end]
        return String(innerJSON)
    }
}
