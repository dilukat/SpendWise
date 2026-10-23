//
//  NetworkMonitor.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-23.
//

import Foundation
import Network
internal import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(
        label: "SpendWise.NetworkMonitor"
    )

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied

            Task { @MainActor [weak self] in
                self?.isConnected = connected
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

