import SwiftUI
import PhotosUI

struct FolderDetailView: View {
    let folderId: UUID

    @EnvironmentObject private var store: GalleryDataStore
    @EnvironmentObject private var photoLibrary: PhotoLibraryViewModel

    @State private var pickerSelection: [PhotosPickerItem] = []
    @State private var fullscreenSelection: FullscreenPresentation?
    @State private var isShowingPicker = false

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        Group {
            if folder != nil {
                VStack(spacing: 16) {
                    if images.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(Array(images.enumerated()), id: \.element.id) { index, entry in
                                    AssetThumbnailView(entry: entry)
                                        .onTapGesture {
                                            fullscreenSelection = FullscreenPresentation(entries: images, startIndex: index)
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                store.removeImage(entry.id)
                                            } label: {
                                                Label("Remove", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
                .padding()
            } else {
                Text("Folder no longer exists")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(folder?.name ?? "Folder")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: pickerSelection) { _, items in
            Task { await handlePickerItems(items) }
        }
        .fullScreenCover(item: $fullscreenSelection) { selection in
            FullscreenGalleryView(entries: selection.entries, startIndex: selection.startIndex)
        }
        .toolbar {
            if let folder {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add images to \(folder.name)")
                }
            }
        }
        .photosPicker(
            isPresented: $isShowingPicker,
            selection: $pickerSelection,
            maxSelectionCount: 0,
            matching: .images,
            preferredItemEncoding: .automatic
        )
    }

    private var folder: Folder? {
        store.folder(with: folderId)
    }

    private var images: [ImageEntry] {
        store.images(for: folderId)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No images yet")
                .font(.headline)
            Text("Use Add Images to pick from your gallery.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }

    private func handlePickerItems(_ items: [PhotosPickerItem]) async {
        guard let folder else { return }
        var payloads: [GalleryImagePayload] = []

        for item in items {
            if let identifier = item.itemIdentifier,
               photoLibrary.asset(for: identifier) != nil {
                payloads.append(.asset(identifier))
                continue
            }

            if let data = try? await item.loadTransferable(type: Data.self) {
                payloads.append(.data(data))
            }
        }

        guard !payloads.isEmpty else {
            await MainActor.run { pickerSelection = [] }
            return
        }

        await MainActor.run {
            store.addImages(payloads, to: folder.id)
            pickerSelection = []
        }
    }
}

private struct FullscreenPresentation: Identifiable {
    let entries: [ImageEntry]
    let startIndex: Int

    var id: UUID {
        entries[startIndex].id
    }
}
