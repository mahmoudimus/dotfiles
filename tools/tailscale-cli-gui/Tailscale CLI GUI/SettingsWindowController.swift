//
//  SettingsWindowController.swift
//  Tailscale CLI GUI
//

import Cocoa
import ServiceManagement

class SettingsWindowController: NSWindowController {

    private var launchAtLoginCheckbox: NSButton!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()

        self.init(window: window)
        setupUI()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // App icon
        let iconView = NSImageView()
        iconView.image = NSApp.applicationIconImage
        iconView.toolTip = "Tailscale CLI GUI"
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        // Version header
        let versionHeader = NSTextField(labelWithString: "Version")
        versionHeader.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        versionHeader.toolTip = "Current app version"
        versionHeader.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(versionHeader)

        // Version value
        let versionValue = NSTextField(labelWithString: appVersion)
        versionValue.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        versionValue.textColor = .secondaryLabelColor
        versionValue.toolTip = "Current app version"
        versionValue.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(versionValue)

        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        // Settings header
        let settingsHeader = NSTextField(labelWithString: "Settings")
        settingsHeader.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        settingsHeader.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(settingsHeader)

        // Launch at Login checkbox
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Open at Login", target: self, action: #selector(toggleLaunchAtLogin))
        launchAtLoginCheckbox.toolTip = "Automatically start when you log in"
        launchAtLoginCheckbox.translatesAutoresizingMaskIntoConstraints = false
        launchAtLoginCheckbox.state = isLaunchAtLoginEnabled ? .on : .off
        contentView.addSubview(launchAtLoginCheckbox)

        NSLayoutConstraint.activate([
            // Icon - centered at top
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),

            // Version header
            versionHeader.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 16),
            versionHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            // Version value
            versionValue.centerYAnchor.constraint(equalTo: versionHeader.centerYAnchor),
            versionValue.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Separator
            separator.topAnchor.constraint(equalTo: versionHeader.bottomAnchor, constant: 12),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Settings header
            settingsHeader.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12),
            settingsHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            // Checkbox
            launchAtLoginCheckbox.topAnchor.constraint(equalTo: settingsHeader.bottomAnchor, constant: 8),
            launchAtLoginCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
        ])
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    private var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        do {
            if sender.state == .on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Revert checkbox state on failure
            sender.state = isLaunchAtLoginEnabled ? .on : .off

            let alert = NSAlert()
            alert.messageText = "Failed to update login item"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
