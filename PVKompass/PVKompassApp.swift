import SwiftUI

@main struct PVKompassApp: App {
    @StateObject private var store = MeasurementStore()
    @StateObject private var sensor = SensorService()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store).environmentObject(sensor)
                .tint(Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 1, green: 0.72, blue: 0.32, alpha: 1) : UIColor(red: 0.52, green: 0.26, blue: 0.01, alpha: 1) }))
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { sensor.interrupt() }
                }
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { MeasurementView() }
                .tabItem { Label("Messung", systemImage: "sun.max") }
            NavigationStack { HistoryView() }
                .tabItem { Label("Verlauf", systemImage: "clock.arrow.circlepath") }
        }
    }
}
