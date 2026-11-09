<p align="center">
  <img style="vertical-align: middle;" width="100" height="100" alt="icon_1024" src="https://github.com/user-attachments/assets/eb5d171d-e51c-4151-b806-615d0942fef3" />
</p>
<h1 align="center">Tailscale CLI GUI</h1>

<p align="center">
  <img width="257" height="311" alt="tailscale-cli-gui-ss1" src="https://github.com/user-attachments/assets/b6f73437-ee47-483c-8bd9-8c792bf73418" />
</p>

---

A macOS menu bar app for the [open-source/Homebrew Tailscale installation](https://github.com/tailscale/tailscale/wiki/Tailscaled-on-macOS).

The Mac App Store version of Tailscale includes a GUI, but the open-source CLI version (which [supports certain features](https://tailscale.com/kb/1065/macos-variants#comparison-table) like SSH hosting) does not. This app bridges that gap.

## ⚠️ PLEASE NOTE

This project is 99% vibe-coded. We let Claude Opus 4.5 write this utility (with supervision) while attending to other, more important work. Please audit the code before running.

For those interested, total cost of the project was $55.79.

## ©️ Disclaimer and Acknowledgements

"Tailscale" is a registered trademark of Tailscale Inc. This project is not
affiliated with, endorsed by, or sponsored by Tailscale Inc. All Tailscale
references, logos, and visual likenesses are the property of Tailscale Inc.

WireGuard is a registered trademark of Jason A. Donenfeld.

## 📝 Features

- Connection status with menu bar icon
- Connect/disconnect
- View/copy Tailscale IP address
- View/copy current tailnet
- Toggle SSH server
- Switch between multiple tailnets
- Auto-refresh + network change detection
- Machines list with ip/hostname copy
- Run at login

## ☑️ Requirements

- macOS 13.0+
- Tailscale CLI installed (`brew install tailscale`)

## 🧑‍💻 Build

```bash
xcodebuild -scheme "Tailscale CLI GUI" -configuration Release build
```

Or open `Tailscale CLI GUI.xcodeproj` in Xcode and build.

**Note:** You'll need to set your own Development Team in Xcode before building. Go to the project settings, select the "Tailscale CLI GUI" target, and under "Signing & Capabilities" choose your team from the dropdown.

## 🤝 Contributing

Contributions are welcome! When submitting a PR, please ensure your `DEVELOPMENT_TEAM` is removed from `project.pbxproj` to avoid committing your personal Apple Developer Team ID.

## 💾 Install

Copy `Tailscale CLI GUI.app` to `/Applications`.

The app runs as a menu bar agent (no Dock icon).

## 🪪 License

See [LICENSE](LICENSE)
