import SwiftUI
import Photos

@main
struct CardsStashApp: App {
    @StateObject private var photoLibrary = PhotoLibraryViewModel()
    @StateObject private var galleryStore = GalleryDataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoLibrary)
                .environmentObject(galleryStore)
        }
    }
}
