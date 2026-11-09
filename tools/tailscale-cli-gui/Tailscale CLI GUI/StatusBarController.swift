//
//  StatusBarController.swift
//  Tailscale CLI GUI
//

import Cocoa
import Network
import os

@MainActor
class StatusBarController: NSObject, NSMenuDelegate {
    private let logger = Logger(subsystem: "com.flyclops.tailscale-cli-gui", category: "StatusBarController")

    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var refreshTimer: Timer?
    private var networkMonitor: NWPathMonitor?

    private let tailscaleService = TailscaleService()
    private var currentInfo: TailscaleInfo = .unknown
    private var previousState: ConnectionState?

    // Menu item references for updating
    private var statusMenuItem: NSMenuItem!
    private var ipMenuItem: NSMenuItem!
    private var tailnetMenuItem: NSMenuItem!
    private var tailnetsMenuItem: NSMenuItem!
    private var tailnetsSubmenu: NSMenu!
    private var connectMenuItem: NSMenuItem!
    private var disconnectMenuItem: NSMenuItem!
    private var sshMenuItem: NSMenuItem!
    private var refreshMenuItem: NSMenuItem!
    private var machinesMenuItem: NSMenuItem!
    private var machinesSubmenu: NSMenu!

    private let refreshInterval: TimeInterval = 300.0

    // Working animation
    private var workingAnimationTimer: Timer?
    private var workingAnimationFrame: Int = 0
    private let workingFrames = ["icon-working-1", "icon-working-2", "icon-working-3"]

    // Settings window
    private var settingsWindowController: SettingsWindowController?

    override init() {
        super.init()
        setupStatusItem()
        setupMenu()
        startRefreshTimer()

        // Initial refresh, then start network monitor
        Task {
            await initializeAndRefresh()
            startNetworkMonitor()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(named: "icon-disconnected")
        }
    }

    private func setupMenu() {
        menu = NSMenu()
        menu.delegate = self

        // Status line (no action = full brightness, not clickable)
        statusMenuItem = NSMenuItem(title: "Checking status...", action: nil, keyEquivalent: "")
        statusMenuItem.toolTip = "Current Tailscale connection status"
        menu.addItem(statusMenuItem)

        // IP Address (click to copy)
        ipMenuItem = NSMenuItem(title: "IP: --", action: #selector(copyIPAddress), keyEquivalent: "")
        ipMenuItem.target = self
        ipMenuItem.toolTip = "Click to copy IP address"
        ipMenuItem.isEnabled = false
        menu.addItem(ipMenuItem)

        // Tailnet (click to copy)
        tailnetMenuItem = NSMenuItem(title: "Tailnet: --", action: #selector(copyTailnet), keyEquivalent: "")
        tailnetMenuItem.target = self
        tailnetMenuItem.toolTip = "Click to copy tailnet name"
        tailnetMenuItem.isEnabled = false
        menu.addItem(tailnetMenuItem)

        // SSH toggle
        sshMenuItem = NSMenuItem(title: "Enable SSH", action: #selector(toggleSSH), keyEquivalent: "")
        sshMenuItem.target = self
        sshMenuItem.toolTip = "Enable or disable Tailscale SSH server"
        menu.addItem(sshMenuItem)

        // Machines submenu (hidden initially until we have machines)
        machinesMenuItem = NSMenuItem(title: "Machines", action: nil, keyEquivalent: "")
        machinesMenuItem.toolTip = "Other machines on your tailnet"
        machinesMenuItem.isHidden = true
        machinesSubmenu = NSMenu()
        machinesMenuItem.submenu = machinesSubmenu
        menu.addItem(machinesMenuItem)

        // Connect
        connectMenuItem = NSMenuItem(title: "Connect", action: #selector(connectTailscale), keyEquivalent: "")
        connectMenuItem.target = self
        connectMenuItem.toolTip = "Connect to Tailscale"
        connectMenuItem.isHidden = true
        menu.addItem(connectMenuItem)

        // Disconnect
        disconnectMenuItem = NSMenuItem(title: "Disconnect", action: #selector(disconnectTailscale), keyEquivalent: "")
        disconnectMenuItem.target = self
        disconnectMenuItem.toolTip = "Disconnect from Tailscale"
        disconnectMenuItem.isHidden = true
        menu.addItem(disconnectMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Tailnets submenu (hidden initially until we have multiple tailnets)
        tailnetsMenuItem = NSMenuItem(title: "Tailnets", action: nil, keyEquivalent: "")
        tailnetsMenuItem.toolTip = "Switch between tailnets"
        tailnetsMenuItem.isHidden = true
        tailnetsSubmenu = NSMenu()
        tailnetsMenuItem.submenu = tailnetsSubmenu
        menu.addItem(tailnetsMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Refresh (hidden unless Option key held)
        refreshMenuItem = NSMenuItem(title: "Refresh", action: #selector(refreshNow), keyEquivalent: "r")
        refreshMenuItem.target = self
        refreshMenuItem.toolTip = "Manually refresh status"
        refreshMenuItem.isHidden = true
        menu.addItem(refreshMenuItem)

        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.toolTip = "Open settings"
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.toolTip = "Quit Tailscale CLI GUI"
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    nonisolated func menuWillOpen(_ menu: NSMenu) {
        // Show Refresh option only when Option key is held
        let optionHeld = NSEvent.modifierFlags.contains(.option)

        // Dispatch to next run loop to avoid layout recursion
        DispatchQueue.main.async {
            Task { @MainActor in
                self.refreshMenuItem.isHidden = !optionHeld

                guard await self.tailscaleService.hasBinary else { return }
                await self.performRefresh(reason: "menu opened")
            }
        }
    }

    private func initializeAndRefresh() async {
        logger.info("Initializing StatusBarController")
        let found = await tailscaleService.findBinary()

        if !found {
            updateUIForMissingBinary()
            return
        }

        // Small delay to let status bar finish initial layout
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        await performRefresh(reason: "initial")
    }

    private func startRefreshTimer() {
        logger.info("Starting refresh timer with interval: \(self.refreshInterval)s")
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard await self.tailscaleService.hasBinary else { return }
                await self.performRefresh(reason: "timer")
            }
        }
    }

    private func startNetworkMonitor() {
        logger.info("Starting network path monitor")
        networkMonitor = NWPathMonitor()

        networkMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard await self.tailscaleService.hasBinary else { return }

                let status = path.status == .satisfied ? "satisfied" : "unsatisfied"
                let interfaces = path.availableInterfaces.map { $0.name }.joined(separator: ", ")
                await self.performRefresh(reason: "network change: \(status), interfaces: \(interfaces)")
            }
        }

        let queue = DispatchQueue(label: "com.flyclops.tailscale-cli-gui.NetworkMonitor")
        networkMonitor?.start(queue: queue)
    }

    @objc private func refreshNow() {
        Task {
            if await !tailscaleService.hasBinary {
                // Try to find binary again
                let found = await tailscaleService.findBinary()
                if found {
                    await performRefresh(reason: "manual")
                } else {
                    updateUIForMissingBinary()
                }
            } else {
                await performRefresh(reason: "manual")
            }
        }
    }

    @objc private func copyIPAddress() {
        guard let ip = currentInfo.ipAddress else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(ip, forType: .string)
    }

    @objc private func copyTailnet() {
        guard let tailnet = currentInfo.currentTailnet else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(tailnet, forType: .string)
    }

    @objc private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func tailnetItemClicked(_ sender: NSMenuItem) {
        guard let tailnet = sender.representedObject as? TailnetAccount else { return }

        // Don't switch if already on this tailnet
        if tailnet.isCurrent {
            logger.debug("Already on tailnet \(tailnet.tailnet), ignoring")
            return
        }

        let wasConnected = currentInfo.state == .connected

        // Show working indicator
        setWorkingIcon()

        Task {
            logger.info("Switching to tailnet: \(tailnet.tailnet) (id: \(tailnet.id))")

            let result = await tailscaleService.switchTailnet(id: tailnet.id, wasConnected: wasConnected)

            switch result {
            case .success:
                await performRefresh(reason: "after tailnet switch")
            case .failure(let error):
                showErrorAlert(title: "Switch Failed", message: error.localizedDescription)
                // Refresh anyway to show current state
                await performRefresh(reason: "after failed tailnet switch")
            }
        }
    }

    private func setWorkingIcon() {
        workingAnimationFrame = 0
        statusItem.button?.image = NSImage(named: workingFrames[0])

        // Start animation timer
        workingAnimationTimer?.invalidate()
        workingAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.workingAnimationFrame = (self.workingAnimationFrame + 1) % self.workingFrames.count
                self.statusItem.button?.image = NSImage(named: self.workingFrames[self.workingAnimationFrame])
            }
        }
    }

    private func stopWorkingAnimation() {
        workingAnimationTimer?.invalidate()
        workingAnimationTimer = nil
    }

    private func showErrorAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func connectTailscale() {
        setWorkingIcon()
        Task {
            let success = await tailscaleService.connect()
            if success {
                await performRefresh(reason: "after connect")
            } else {
                await performRefresh(reason: "after failed connect")
            }
        }
    }

    @objc private func disconnectTailscale() {
        setWorkingIcon()
        Task {
            let success = await tailscaleService.disconnect()
            if success {
                await performRefresh(reason: "after disconnect")
            } else {
                await performRefresh(reason: "after failed disconnect")
            }
        }
    }

    @objc private func toggleSSH() {
        let newState = !currentInfo.sshEnabled
        setWorkingIcon()
        Task {
            let success = await tailscaleService.setSSH(enabled: newState)
            if success {
                await performRefresh(reason: "after SSH toggle")
            } else {
                await performRefresh(reason: "after failed SSH toggle")
                showErrorAlert(title: "SSH Toggle Failed", message: "Failed to \(newState ? "enable" : "disable") SSH")
            }
        }
    }

    private func performRefresh(reason: String) async {
        logger.info("Performing refresh (\(reason))")

        guard let info = await tailscaleService.refresh() else {
            logger.debug("Refresh skipped (already in progress)")
            return
        }

        currentInfo = info

        // Log state change if it occurred
        if previousState != info.state {
            let fromState = previousState?.description ?? "nil"
            logger.info("State changed: \(fromState) -> \(info.state.description)")
            previousState = info.state
        }

        updateUI(with: info)
        logger.debug("Refresh complete")
    }

    private func updateUI(with info: TailscaleInfo) {
        stopWorkingAnimation()

        switch info.state {
        case .connected:
            statusItem.button?.image = NSImage(named: "icon-connected")
            statusMenuItem.title = "Connected"

            if let ip = info.ipAddress {
                ipMenuItem.title = "IP: \(ip)"
                ipMenuItem.isEnabled = true
            } else {
                ipMenuItem.title = "IP: --"
                ipMenuItem.isEnabled = false
            }

            if let tailnet = info.currentTailnet {
                tailnetMenuItem.title = "Tailnet: \(tailnet)"
                tailnetMenuItem.isEnabled = true
            } else {
                tailnetMenuItem.title = "Tailnet: --"
                tailnetMenuItem.isEnabled = false
            }

            connectMenuItem.isHidden = true
            disconnectMenuItem.isHidden = false

        case .disconnected:
            statusItem.button?.image = NSImage(named: "icon-disconnected")
            statusMenuItem.title = "Disconnected"
            ipMenuItem.title = "IP: --"
            ipMenuItem.isEnabled = false

            if let tailnet = info.currentTailnet {
                tailnetMenuItem.title = "Tailnet: \(tailnet)"
                tailnetMenuItem.isEnabled = true
            } else {
                tailnetMenuItem.title = "Tailnet: --"
                tailnetMenuItem.isEnabled = false
            }

            connectMenuItem.isHidden = false
            disconnectMenuItem.isHidden = true

        case .unknown:
            statusItem.button?.image = NSImage(named: "icon-unknown")
            statusMenuItem.title = "Status Unknown"
            ipMenuItem.title = "IP: --"
            ipMenuItem.isEnabled = false

            if let tailnet = info.currentTailnet {
                tailnetMenuItem.title = "Tailnet: \(tailnet)"
                tailnetMenuItem.isEnabled = true
            } else {
                tailnetMenuItem.title = "Tailnet: --"
                tailnetMenuItem.isEnabled = false
            }

            // Hide both when state is unknown
            connectMenuItem.isHidden = true
            disconnectMenuItem.isHidden = true
        }

        // Update status bar button tooltip
        if let tailnet = info.currentTailnet {
            let statusText: String
            switch info.state {
            case .connected: statusText = "Connected"
            case .disconnected: statusText = "Disconnected"
            case .unknown: statusText = "Unknown"
            }
            statusItem.button?.toolTip = "\(tailnet): \(statusText)"
        } else {
            statusItem.button?.toolTip = "Logged out"
        }

        // Update tailnets submenu
        updateTailnetsSubmenu(with: info.tailnets)

        // Update machines submenu
        updateMachinesSubmenu(with: info.machines, users: info.users)

        // Update SSH menu item
        sshMenuItem.title = info.sshEnabled ? "Disable SSH" : "Enable SSH"
    }

    private func updateTailnetsSubmenu(with tailnets: [TailnetAccount]) {
        tailnetsSubmenu.removeAllItems()

        // Only show submenu if there's more than one tailnet
        if tailnets.count <= 1 {
            tailnetsMenuItem.isHidden = true
            return
        }

        tailnetsMenuItem.isHidden = false

        for tailnet in tailnets {
            let item = NSMenuItem(
                title: tailnet.tailnet,
                action: #selector(tailnetItemClicked(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = tailnet

            // Mark current tailnet with a checkmark
            if tailnet.isCurrent {
                item.state = .on
                item.toolTip = "Current tailnet"
            } else {
                item.toolTip = "Switch to \(tailnet.tailnet)"
            }

            tailnetsSubmenu.addItem(item)
        }
    }

    private func updateMachinesSubmenu(with machines: [Machine], users: [String: TailscaleUser]) {
        machinesSubmenu.removeAllItems()

        // Hide if no machines
        if machines.isEmpty {
            machinesMenuItem.isHidden = true
            return
        }

        machinesMenuItem.isHidden = false

        // Separate machines into tagged devices vs user-owned
        var taggedMachines: [Machine] = []
        var machinesByUser: [String: [Machine]] = [:]  // keyed by userId

        for machine in machines {
            if let user = users[machine.userId], user.isTaggedDevices {
                taggedMachines.append(machine)
            } else {
                machinesByUser[machine.userId, default: []].append(machine)
            }
        }

        // Add "Tagged" submenu if there are tagged machines
        if !taggedMachines.isEmpty {
            let taggedItem = NSMenuItem(title: "Tagged", action: nil, keyEquivalent: "")
            let taggedSubmenu = NSMenu()

            for machine in taggedMachines {
                let item = createMachineMenuItem(machine)
                taggedSubmenu.addItem(item)
            }

            taggedItem.submenu = taggedSubmenu
            machinesSubmenu.addItem(taggedItem)
        }

        // Add user submenus
        // Sort users by display name
        let sortedUserIds = machinesByUser.keys.sorted { userId1, userId2 in
            let name1 = users[userId1]?.displayName ?? ""
            let name2 = users[userId2]?.displayName ?? ""
            return name1.lowercased() < name2.lowercased()
        }

        for userId in sortedUserIds {
            guard let userMachines = machinesByUser[userId] else { continue }
            let user = users[userId]
            let displayName = user?.displayName ?? user?.loginName ?? "Unknown"

            let userItem = NSMenuItem(title: displayName, action: nil, keyEquivalent: "")
            let userSubmenu = NSMenu()

            for machine in userMachines {
                let item = createMachineMenuItem(machine)
                userSubmenu.addItem(item)
            }

            userItem.submenu = userSubmenu
            machinesSubmenu.addItem(userItem)
        }
    }

    private func createMachineMenuItem(_ machine: Machine) -> NSMenuItem {
        let title = machine.displayName
        let item = NSMenuItem(title: title, action: #selector(machineItemClicked(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = machine

        // Show online status with a dot prefix
        if machine.isOnline {
            item.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Online")
            item.image?.isTemplate = true
        } else {
            item.image = NSImage(systemSymbolName: "circle", accessibilityDescription: "Offline")
            item.image?.isTemplate = true
        }

        // Tooltip with more details
        var tooltip = "Click to copy IP"
        if machine.ipAddress != nil {
            tooltip += " • Option-click for domain"
        }
        item.toolTip = tooltip

        return item
    }

    @objc private func machineItemClicked(_ sender: NSMenuItem) {
        guard let machine = sender.representedObject as? Machine else { return }

        let optionHeld = NSEvent.modifierFlags.contains(.option)

        let textToCopy: String?
        if optionHeld {
            textToCopy = machine.tailscaleDomain
        } else {
            textToCopy = machine.ipAddress
        }

        if let text = textToCopy {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
    }

    private func updateUIForMissingBinary() {
        stopWorkingAnimation()
        statusItem.button?.image = NSImage(named: "icon-error")
        statusItem.button?.toolTip = "Tailscale CLI not found"
        statusMenuItem.title = "Tailscale CLI Not Found"
        ipMenuItem.title = "Install: brew install tailscale"
        ipMenuItem.isEnabled = false
        tailnetMenuItem.isHidden = true

        // Show alert
        let alert = NSAlert()
        alert.messageText = "Tailscale CLI Not Found"
        alert.informativeText = "The tailscale command-line tool could not be found. Please install it using:\n\nbrew install tailscale\n\nThen click 'Refresh Now' in the menu."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    deinit {
        refreshTimer?.invalidate()
        networkMonitor?.cancel()
        workingAnimationTimer?.invalidate()
    }
}
