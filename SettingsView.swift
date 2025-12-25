import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject private var engine: ClashImposterEngine

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Hints")) {
                    Toggle(isOn: $engine.hintsEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable hint words for Imposter")
                            Text("Subtle one-word hints to assist the Imposter.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    AppSettingsView().environmentObject(ClashImposterEngine())
}
