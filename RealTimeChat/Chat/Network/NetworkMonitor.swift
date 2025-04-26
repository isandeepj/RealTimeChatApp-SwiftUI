//
//  NetworkMonitor.swift
//  RealTimeChat
//
//  Created by Sandeep on 26/04/25.
//

import Foundation
import Network
import Combine

class NetworkStatusMonitor: ObservableObject {
    
    static let shared = NetworkStatusMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "App.NetworkStatusMonitorQueue")
    
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var isExpensive: Bool = false
    @Published private(set) var connectionQuality: ConnectionQuality = .none
    private var debounceWorkItem: DispatchWorkItem?
    private let networkSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = 3
        config.timeoutIntervalForResource = 3
        return URLSession(configuration: config)
    }()
    let statusPublisher = PassthroughSubject<(Bool, ConnectionQuality), Never>()
    
    enum ConnectionQuality: String {
        case good = "Good"
        case poor = "Poor"
        case bad = "Bad"
        case none = "None"
    }
    
    var enableDeepCheck: Bool = true
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        let reachable = path.status == .satisfied
        isExpensive = path.isExpensive
        
        if reachable {
            performDeepInternetCheck()
        } else {
            updateStatus(isConnected: false, quality: .none)
        }
    }
    
    private func debounceDeepCheck(delay: TimeInterval = 1) {
        debounceWorkItem?.cancel()
        guard enableDeepCheck else { return }

        let workItem = DispatchWorkItem { [weak self] in
            self?.performDeepInternetCheck()
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    private func performDeepInternetCheck() {
        guard enableDeepCheck else {
            updateStatus(isConnected: true, quality: .good)
            return
        }
        
        guard let url = URL(string: "https://www.apple.com") else {
            updateStatus(isConnected: false, quality: .none)
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: 3)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let startTime = Date()
        
        networkSession.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error as? URLError {
                    if error.code == .notConnectedToInternet || error.code == .timedOut {
                        self.updateStatus(isConnected: false, quality: .none)
                        self.debounceDeepCheck(delay: 5.0)
                        return
                    }
                }
                if let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode {
                    let duration = Date().timeIntervalSince(startTime)
                    let quality: ConnectionQuality
                    switch duration {
                    case ..<1.2: quality = .good
                    case ..<3: quality = .poor
                    default: quality = .bad
                    }
                    
                    self.updateStatus(isConnected: true, quality: quality)
                } else {
                    self.updateStatus(isConnected: false, quality: .none)
                }
            }
        }.resume()
    }
    
    private func updateStatus(isConnected: Bool, quality: ConnectionQuality) {
        self.isConnected = isConnected
        self.connectionQuality = quality
        
        // Notify via Combine publisher
        statusPublisher.send((isConnected, quality))
    }
    
    deinit {
        monitor.cancel()
    }
}
