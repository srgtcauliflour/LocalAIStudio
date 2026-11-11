import SwiftUI

struct SettingsHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    Label("Local-first processing", systemImage: "iphone")
                    Label("No prompt telemetry", systemImage: "hand.raised")
                    Label("Network only for model discovery and downloads", systemImage: "wifi")
                }
                Section("Performance") {
                    Label("Memory-aware model loading", systemImage: "memorychip")
                    Label("Thermal-aware generation", systemImage: "thermometer.medium")
                    Label("Independent chat and image runtimes", systemImage: "cpu")
                }
                Section("About") {
                    LabeledContent("Version", value: "0.1.0-dev")
                    LabeledContent("Target", value: "iPhone 17 Pro Max")
                    LabeledContent("Minimum iOS", value: "18.0")
                }
            }.scrollContentBackground(.hidden).background(Color.studioBackground).navigationTitle("Settings")
        }
    }
}
