# PV Kompass

Native SwiftUI iPhone app, iOS 17+. Source of truth for the project generator is project.yml; regenerate using xcodegen after changes. Test with scheme PVKompass on an iPhone simulator. Use existing Apple distribution identities; never revoke certificates or put signing keys in the repo. Release scope is TestFlight, not public App Store submission.

Measurement correctness is critical: use panel surface normal, not handset top-edge heading. Physical world coordinate tests must be right-handed ENU. Distinguish geographic/magnetic north, undefined flat-panel bearing, and real/simulator measurements. Never invent sensor/GPS measurements. All user-facing copy is German, VoiceOver-first, no color-only status. Keep CSV values numeric, quote correctly, protect user-provided names against spreadsheet formulas.

Do not claim physical sensor or VoiceOver-user verification from simulator tests alone. Preserve corrupt archives rather than silently replacing them. Document actual tests and TestFlight processing state.
