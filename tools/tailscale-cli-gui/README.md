# Tailscale CLI GUI

A macOS menu-bar interface for an existing Homebrew `tailscaled` daemon. This
is a locally modified copy of [Flyclops/tailscale-cli-gui](https://github.com/Flyclops/tailscale-cli-gui)
at commit `0a4e566e6488976fa6fe7b3f95901fefdc9c544e`; its MIT license and
copyright notice are in `LICENSE` and the upstream documentation is in
`UPSTREAM-README.md`.

Local changes prefer `/opt/homebrew/bin/tailscale` over an obsolete GUI CLI
launcher, and treat nonzero command exit statuses as errors. If the Homebrew
binary is unavailable, the upstream search remains the fallback. The app can
connect, disconnect, toggle Tailscale SSH, and switch tailnets; those actions
can interrupt existing SSH or Tailscale Serve sessions. Commands have no
execution timeout. The app has not been audited as a security boundary.

## Build and install

Requires macOS, Xcode, and a running Homebrew Tailscale daemon. From this
directory:

```sh
xcodebuild -project 'Tailscale CLI GUI.xcodeproj' -scheme 'Tailscale CLI GUI' \
  -configuration Release -derivedDataPath /tmp/tailscale-cli-gui-build \
  CODE_SIGNING_ALLOWED=NO build
codesign --force --deep --sign - \
  '/tmp/tailscale-cli-gui-build/Build/Products/Release/Tailscale CLI GUI.app'
mkdir -p "$HOME/Applications"
ditto '/tmp/tailscale-cli-gui-build/Build/Products/Release/Tailscale CLI GUI.app' \
  "$HOME/Applications/Tailscale CLI GUI.app"
open "$HOME/Applications/Tailscale CLI GUI.app"
```

The app is ad-hoc signed, not notarized. Configure Open at Login in the app's
settings if desired. This GUI does not install or start the Tailscale daemon.
The build location under `/tmp` is disposable; source and tests live here.

## Test command exit handling

```sh
scratch=$(mktemp -d)
python3 -c 'from pathlib import Path; import sys; s=Path("Tailscale CLI GUI/TailscaleService.swift").read_text(); Path(sys.argv[1]).write_text(s.replace("private func runCommand(", "func runCommand("))' "$scratch/TailscaleService.swift"
swiftc "$scratch/TailscaleService.swift" 'Tailscale CLI GUI/TailscaleStatus.swift' \
  tests/command_probe.swift -o "$scratch/command_probe"
"$scratch/command_probe"
```
