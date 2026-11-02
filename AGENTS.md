# PV Kompass

Native SwiftUI iPhone app, iOS 17+. Source of truth for the project generator is project.yml; regenerate using xcodegen after changes. Test with scheme PVKompass on an iPhone simulator. Use existing Apple distribution identities; never revoke certificates or put signing keys in the repo. Release scope includes App Store submission and automatic release after approval, explicitly authorized by Niklas on 2026-10-27. App availability is confirmed; Niklas authorized public GitHub visibility on 2026-11-02 after a privacy/secret review. Keep credentials, signing material and real user measurements out of both files and history.

Measurement correctness is critical: use panel surface normal, not handset top-edge heading. Physical world coordinate tests must be right-handed ENU. Distinguish geographic/magnetic north, undefined flat-panel bearing, and real/simulator measurements. Never invent sensor/GPS measurements. All user-facing copy is German, VoiceOver-first, no color-only status. Keep CSV values numeric, quote correctly, protect user-provided names against spreadsheet formulas.

Do not claim physical sensor or VoiceOver-user verification from simulator tests alone. Preserve corrupt archives rather than silently replacing them. Document actual tests and TestFlight processing state.
