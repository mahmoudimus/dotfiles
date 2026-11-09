import Foundation
@main struct Probe {
 static func main() async {
  let s = TailscaleService()
  do { _ = try await s.runCommand("/usr/bin/false", arguments: []); print("FAIL: nonzero accepted"); exit(1) }
  catch { print("PASS: nonzero rejected") }
  do { _ = try await s.runCommand("/usr/bin/true", arguments: []); print("PASS: zero accepted") }
  catch { print("FAIL: zero rejected"); exit(1) }
 }
}
