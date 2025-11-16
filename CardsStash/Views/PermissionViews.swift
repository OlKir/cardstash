import SwiftUI
import UIKit

struct PermissionPromptView: View {
    let requestAccess: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Access Your Photos")
                .font(.title2)
                .bold()

            Text("We need access to your photo library to show your gallery.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button(action: requestAccess) {
                Text("Allow Photo Access")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.slash")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Photo Access Disabled")
                .font(.title2)
                .bold()

            Text("Enable photo access in Settings to view your gallery.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Open Settings") {
                openSettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
