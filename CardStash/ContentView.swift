import SwiftUI
import Photos

struct ContentView: View {
    @EnvironmentObject private var photoLibrary: PhotoLibraryViewModel
    @EnvironmentObject private var galleryStore: GalleryDataStore

    var body: some View {
        NavigationStack {
            Group {
                switch photoLibrary.authorizationStatus {
                case .authorized, .limited:
                    FolderListView()
                case .notDetermined:
                    PermissionPromptView(requestAccess: photoLibrary.requestAuthorizationIfNeeded)
                default:
                    PermissionDeniedView()
                }
            }
            .navigationTitle("Folders")
        }
        .onAppear {
            photoLibrary.requestAuthorizationIfNeeded()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PhotoLibraryViewModel())
        .environmentObject(GalleryDataStore.preview)
}
