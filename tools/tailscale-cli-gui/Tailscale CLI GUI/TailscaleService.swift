//
//  TailscaleService.swift
//  Tailscale CLI GUI
//

import Foundation
import os

actor TailscaleService {
    private let logger = Logger(subsystem: "com.flyclops.tailscale-cli-gui", category: "TailscaleService")

    private var binaryPath: String?
    private var isRefreshing = false

    private let searchPaths = [
        "/usr/local/bin/tailscale",
        "/opt/homebrew/bin/tailscale",
        "/usr/bin/tailscale",
        "/bin/tailscale"
    ]

    var hasBinary: Bool {
        binaryPath != nil
    }

    func connect() async -> Bool {
        guard let binary = binaryPath else {
            logger.error("Cannot connect: binary not found")
            return false
        }

        logger.info("Connecting to Tailscale...")
        do {
            let output = try await runCommand(binary, arguments: ["up"])
            logger.info("Connect command completed: \(output)")
            return true
        } catch {
            logger.error("Connect failed: \(error.localizedDescription)")
            return false
        }
    }

    func disconnect() async -> Bool {
        guard let binary = binaryPath else {
            logger.error("Cannot disconnect: binary not found")
            return false
        }

        logger.info("Disconnecting from Tailscale...")
        do {
            let output = try await runCommand(binary, arguments: ["down"])
            logger.info("Disconnect command completed: \(output)")
            return true
        } catch {
            logger.error("Disconnect failed: \(error.localizedDescription)")
            return false
        }
    }

    func setSSH(enabled: Bool) async -> Bool {
        guard let binary = binaryPath else {
            logger.error("Cannot set SSH: binary not found")
            return false
        }

        logger.info("Setting SSH to \(enabled)...")
        do {
            let output = try await runCommand(binary, arguments: ["set", "--ssh=\(enabled)"])
            logger.info("SSH set command completed: \(output)")
            return true
        } catch {
            logger.error("SSH set failed: \(error.localizedDescription)")
            return false
        }
    }

    func switchTailnet(id: String, wasConnected: Bool) async -> Result<Void, TailscaleSwitchError> {
        guard let binary = binaryPath else {
            logger.error("Cannot switch: binary not found")
            return .failure(.binaryNotFound)
        }

        logger.info("Switching to tailnet ID: \(id), wasConnected: \(wasConnected)")

        // If connected, disconnect first
        if wasConnected {
            logger.info("Disconnecting before switch...")
            do {
                _ = try await runCommand(binary, arguments: ["down"])
            } catch {
                logger.error("Failed to disconnect before switch: \(error.localizedDescription)")
                return .failure(.disconnectFailed(error.localizedDescription))
            }
        }

        // Perform the switch
        logger.info("Performing switch...")
        do {
            _ = try await runCommand(binary, arguments: ["switch", id])
        } catch {
            logger.error("Switch failed: \(error.localizedDescription)")
            return .failure(.switchFailed(error.localizedDescription))
        }

        // If was connected, reconnect
        if wasConnected {
            logger.info("Reconnecting after switch...")
            do {
                _ = try await runCommand(binary, arguments: ["up"])
            } catch {
                logger.error("Failed to reconnect after switch: \(error.localizedDescription)")
                return .failure(.reconnectFailed(error.localizedDescription))
            }
        }

        logger.info("Switch completed successfully")
        return .success(())
    }

    func findBinary() async -> Bool {
        logger.info("Searching for tailscale binary...")

        // Prefer the Homebrew CLI over a leftover GUI launcher in PATH.
        let homebrew = "/opt/homebrew/bin/tailscale"
        if let resolved = resolveSymlink(homebrew) {
            binaryPath = resolved
            return true
        }

        // First, try to find via PATH using 'which'
        if let pathResult = try? await runCommand("/usr/bin/which", arguments: ["tailscale"]),
           !pathResult.isEmpty {
            let path = pathResult.trimmingCharacters(in: .whitespacesAndNewlines)
            if let resolved = resolveSymlink(path) {
                binaryPath = resolved
                logger.info("Found tailscale binary via PATH: \(resolved)")
                return true
            }
        }

        // Fall back to checking known locations
        let fileManager = FileManager.default
        for path in searchPaths {
            if fileManager.isExecutableFile(atPath: path) {
                if let resolved = resolveSymlink(path) {
                    binaryPath = resolved
                    logger.info("Found tailscale binary at: \(resolved)")
                    return true
                }
            }
        }

        binaryPath = nil
        logger.warning("Tailscale binary not found")
        return false
    }

    private func resolveSymlink(_ path: String) -> String? {
        let fileManager = FileManager.default
        var resolvedPath = path

        // Follow symlinks until we get to the actual binary
        while let destination = try? fileManager.destinationOfSymbolicLink(atPath: resolvedPath) {
            // Handle relative symlinks
            if destination.hasPrefix("/") {
                resolvedPath = destination
            } else {
                let directory = (resolvedPath as NSString).deletingLastPathComponent
                resolvedPath = (directory as NSString).appendingPathComponent(destination)
            }
        }

        // Verify the resolved path exists and is executable
        if fileManager.isExecutableFile(atPath: resolvedPath) {
            return resolvedPath
        }

        // If resolution failed, return original if it's executable
        if fileManager.isExecutableFile(atPath: path) {
            return path
        }

        return nil
    }

    func refresh() async -> TailscaleInfo? {
        // Mutex: prevent concurrent refreshes
        guard !isRefreshing else {
            logger.debug("Refresh already in progress, skipping")
            return nil
        }
        isRefreshing = true
        defer { isRefreshing = false }

        guard let binary = binaryPath else {
            return .unknown
        }

        async let statusTask = getConnectionStatus(binary: binary)
        async let tailnetTask = getTailnets(binary: binary)
        async let sshTask = getSSHEnabled(binary: binary)
        async let machinesTask = getMachines(binary: binary)

        let (statusResult, tailnetResult, sshEnabled, machinesResult) = await (statusTask, tailnetTask, sshTask, machinesTask)

        // Find current tailnet from the list (for account info)
        let current = tailnetResult.first { $0.isCurrent }

        return TailscaleInfo(
            state: statusResult.state,
            ipAddress: statusResult.ip,
            currentTailnet: statusResult.tailnet ?? current?.tailnet,
            currentAccount: current?.account,
            tailnets: tailnetResult,
            sshEnabled: sshEnabled,
            machines: machinesResult.machines,
            users: machinesResult.users
        )
    }

    private func getConnectionStatus(binary: String) async -> (state: ConnectionState, ip: String?, tailnet: String?) {
        guard let output = try? await runCommand(binary, arguments: ["status", "--json", "--active"]) else {
            logger.error("Failed to run tailscale status --json command")
            return (.unknown, nil, nil)
        }

        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("Failed to parse tailscale status JSON")
            return (.unknown, nil, nil)
        }

        // Check BackendState for connection status
        let backendState = json["BackendState"] as? String ?? ""

        // Get Self info
        let selfInfo = json["Self"] as? [String: Any]
        let isOnline = selfInfo?["Online"] as? Bool ?? false
        let tailscaleIPs = selfInfo?["TailscaleIPs"] as? [String] ?? []

        // Get current tailnet name
        let currentTailnet = json["CurrentTailnet"] as? [String: Any]
        let tailnetName = currentTailnet?["Name"] as? String

        // Find IPv4 address (starts with 100.)
        let ipv4 = tailscaleIPs.first { $0.hasPrefix("100.") }

        // Determine state
        let state: ConnectionState
        if backendState == "Running" && isOnline {
            state = .connected
            logger.info("Connection status: connected, IP: \(ipv4 ?? "none"), tailnet: \(tailnetName ?? "none")")
        } else if backendState == "Stopped" || backendState == "NoState" {
            state = .disconnected
            logger.info("Connection status: disconnected (backend: \(backendState))")
        } else if backendState == "Running" && !isOnline {
            // Running but not online - still connecting or temporarily offline
            state = .disconnected
            logger.info("Connection status: disconnected (running but not online)")
        } else {
            state = .unknown
            logger.warning("Connection status: unknown (backend: \(backendState), online: \(isOnline))")
        }

        return (state, ipv4, tailnetName)
    }

    private func getTailnets(binary: String) async -> [TailnetAccount] {
        guard let output = try? await runCommand(binary, arguments: ["switch", "--list"]) else {
            logger.error("Failed to run tailscale switch --list command")
            return []
        }

        // Parse the output to get all tailnets
        // Format:
        // ID    Tailnet                 Account
        // 3fd9  example-corp.com        user@example-corp.com*
        // 835d  example.com             user@example.com
        var tailnets: [TailnetAccount] = []
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            // Skip header line and empty lines
            if line.contains("Tailnet") && line.contains("Account") {
                continue
            }
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }

            // Split by whitespace
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
                .map { String($0) }

            // We expect at least 3 columns: ID, Tailnet, Account
            if components.count >= 3 {
                let id = components[0]
                let tailnet = components[1]
                var account = components[2]
                let isCurrent = account.hasSuffix("*")

                // Remove trailing asterisk from account
                if isCurrent {
                    account = String(account.dropLast())
                }

                tailnets.append(TailnetAccount(id: id, tailnet: tailnet, account: account, isCurrent: isCurrent))
            }
        }

        if let current = tailnets.first(where: { $0.isCurrent }) {
            logger.info("Found \(tailnets.count) tailnets, current: \(current.tailnet)")
        } else {
            logger.info("Found \(tailnets.count) tailnets, none selected")
        }

        return tailnets
    }

    private func getSSHEnabled(binary: String) async -> Bool {
        guard let output = try? await runCommand(binary, arguments: ["debug", "prefs"]) else {
            logger.error("Failed to run tailscale debug prefs command")
            return false
        }

        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("Failed to parse tailscale debug prefs JSON")
            return false
        }

        let sshEnabled = json["RunSSH"] as? Bool ?? false
        logger.info("Preferences: SSH enabled: \(sshEnabled)")

        return sshEnabled
    }

    private func getMachines(binary: String) async -> (machines: [Machine], users: [String: TailscaleUser]) {
        guard let output = try? await runCommand(binary, arguments: ["status", "--json", "--self=false"]) else {
            logger.error("Failed to run tailscale status --json --self=false command")
            return ([], [:])
        }

        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("Failed to parse tailscale status JSON for machines")
            return ([], [:])
        }

        // Parse users first
        var users: [String: TailscaleUser] = [:]
        if let userDict = json["User"] as? [String: [String: Any]] {
            for (userId, userInfo) in userDict {
                let loginName = userInfo["LoginName"] as? String ?? ""
                let displayName = userInfo["DisplayName"] as? String ?? loginName
                users[userId] = TailscaleUser(id: userId, loginName: loginName, displayName: displayName)
            }
        }

        // Parse peers (machines)
        var machines: [Machine] = []
        if let peerDict = json["Peer"] as? [String: [String: Any]] {
            for (_, peerInfo) in peerDict {
                // Skip Mullvad exit nodes
                if let tags = peerInfo["Tags"] as? [String],
                   tags.contains("tag:mullvad-exit-node") {
                    continue
                }

                let hostname = peerInfo["HostName"] as? String ?? ""
                let dnsName = peerInfo["DNSName"] as? String ?? ""

                // Also skip if DNSName contains mullvad (backup check)
                if dnsName.contains(".mullvad.ts.net") {
                    continue
                }

                // Only include online machines
                let isOnline = peerInfo["Online"] as? Bool ?? false
                if !isOnline {
                    continue
                }

                let os = peerInfo["OS"] as? String
                let userId: String
                if let userIdInt = peerInfo["UserID"] as? Int64 {
                    userId = String(userIdInt)
                } else if let userIdNum = peerInfo["UserID"] as? NSNumber {
                    userId = userIdNum.stringValue
                } else {
                    userId = ""
                }

                // Get IPv4 address (100.x.x.x)
                let tailscaleIPs = peerInfo["TailscaleIPs"] as? [String] ?? []
                let ipv4 = tailscaleIPs.first { $0.hasPrefix("100.") }

                machines.append(Machine(
                    hostname: hostname,
                    dnsName: dnsName,
                    os: os,
                    userId: userId,
                    isOnline: isOnline,
                    ipAddress: ipv4
                ))
            }
        }

        // Sort machines by hostname
        machines.sort { $0.hostname.lowercased() < $1.hostname.lowercased() }

        logger.info("Found \(machines.count) machines (excluding Mullvad nodes)")
        return (machines, users)
    }

    private func runCommand(_ command: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = pipe

            // Set up environment to include common paths
            var environment = ProcessInfo.processInfo.environment
            let existingPath = environment["PATH"] ?? ""
            environment["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:" + existingPath
            process.environment = environment

            do {
                try process.run()

                // Read data BEFORE waitUntilExit to avoid deadlock
                // (pipe buffer fills up, process blocks, waitUntilExit never returns)
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                guard process.terminationStatus == 0 else {
                    let output = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(throwing: TailscaleBinaryError.executionFailed(output))
                    return
                }

                if let output = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: TailscaleBinaryError.executionFailed("Failed to decode output"))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
