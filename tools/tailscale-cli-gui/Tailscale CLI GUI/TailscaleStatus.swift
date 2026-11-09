//
//  TailscaleStatus.swift
//  Tailscale CLI GUI
//

import Foundation

enum ConnectionState: Equatable, CustomStringConvertible {
    case connected
    case disconnected
    case unknown

    var description: String {
        switch self {
        case .connected: return "connected"
        case .disconnected: return "disconnected"
        case .unknown: return "unknown"
        }
    }
}

struct TailnetAccount: Equatable {
    let id: String
    let tailnet: String
    let account: String
    let isCurrent: Bool
}

struct TailscaleUser: Equatable {
    let id: String
    let loginName: String
    let displayName: String

    var isTaggedDevices: Bool {
        loginName == "tagged-devices"
    }
}

struct Machine: Equatable {
    let hostname: String
    let dnsName: String
    let os: String?
    let userId: String
    let isOnline: Bool
    let ipAddress: String?

    /// Display name is the hostname without the domain suffix
    var displayName: String {
        hostname.components(separatedBy: ".").first ?? hostname
    }

    /// DNS name without trailing dot
    var tailscaleDomain: String {
        dnsName.hasSuffix(".") ? String(dnsName.dropLast()) : dnsName
    }
}

struct TailscaleInfo {
    let state: ConnectionState
    let ipAddress: String?
    let currentTailnet: String?
    let currentAccount: String?
    let tailnets: [TailnetAccount]
    let sshEnabled: Bool
    let machines: [Machine]
    let users: [String: TailscaleUser]

    static let disconnected = TailscaleInfo(state: .disconnected, ipAddress: nil, currentTailnet: nil, currentAccount: nil, tailnets: [], sshEnabled: false, machines: [], users: [:])
    static let unknown = TailscaleInfo(state: .unknown, ipAddress: nil, currentTailnet: nil, currentAccount: nil, tailnets: [], sshEnabled: false, machines: [], users: [:])
}

enum TailscaleBinaryError: Error {
    case notFound
    case executionFailed(String)
}

enum TailscaleSwitchError: Error, LocalizedError {
    case binaryNotFound
    case disconnectFailed(String)
    case switchFailed(String)
    case reconnectFailed(String)

    var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "Tailscale binary not found"
        case .disconnectFailed(let detail):
            return "Failed to disconnect: \(detail)"
        case .switchFailed(let detail):
            return "Failed to switch tailnet: \(detail)"
        case .reconnectFailed(let detail):
            return "Failed to reconnect after switch: \(detail)"
        }
    }
}
