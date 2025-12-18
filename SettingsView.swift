import SwiftUI

struct SettingsView: View {
    @AppStorage("timedFlipEnabled") private var timedFlipEnabled: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Role Card")) {
                    Toggle(isOn: $timedFlipEnabled) {
                        VStack(alignment: .leading) {
                            Text("Timed Flip")
                                .fontWeight(.bold)
                            Text("Automatically flip your role card back after 5 seconds, so others don't see it!")
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
    SettingsView()
}
