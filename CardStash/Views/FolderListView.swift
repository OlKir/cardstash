import SwiftUI

struct FolderListView: View {
    @EnvironmentObject private var store: GalleryDataStore

    @State private var isPresentingFolderForm = false
    @State private var folderName: String = ""
    @State private var editingFolder: Folder?
    @State private var folderPendingDeletion: Folder?

    var body: some View {
        Group {
            if store.allFolders.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.allFolders) { folder in
                        let folderImages = store.images(for: folder.id)
                        NavigationLink(destination: FolderDetailView(folderId: folder.id)) {
                            FolderRowView(
                                folder: folder,
                                imageCount: folderImages.count,
                                coverEntry: folderImages.first
                            )
                        }
                        .contextMenu {
                            Button("Rename") {
                                presentRename(for: folder)
                            }
                            Button(role: .destructive) {
                                folderPendingDeletion = folder
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Rename") {
                                presentRename(for: folder)
                            }
                            .tint(.blue)

                            Button(role: .destructive) {
                                folderPendingDeletion = folder
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    presentNewFolder()
                } label: {
                    Label("Add Folder", systemImage: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingFolderForm) {
            FolderEditorSheet(
                title: editingFolder == nil ? "New Folder" : "Rename Folder",
                folderName: $folderName,
                onSave: handleFolderSave,
                onCancel: dismissFolderSheet
            )
        }
        .confirmationDialog(
            "Delete Folder?",
            isPresented: Binding(
                get: { folderPendingDeletion != nil },
                set: { newValue in
                    if !newValue {
                        folderPendingDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let folder = folderPendingDeletion {
                    store.deleteFolder(id: folder.id)
                }
                folderPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                folderPendingDeletion = nil
            }
        } message: {
            Text("Deleting a folder will remove all images inside it. This action cannot be undone.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No folders yet")
                .font(.title2)
                .bold()
            Text("Tap the + button to create your first folder and start organizing your gallery.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func presentNewFolder() {
        editingFolder = nil
        folderName = ""
        isPresentingFolderForm = true
    }

    private func presentRename(for folder: Folder) {
        editingFolder = folder
        folderName = folder.name
        isPresentingFolderForm = true
    }

    private func handleFolderSave() {
        if let folder = editingFolder {
            store.renameFolder(id: folder.id, to: folderName)
        } else {
            store.createFolder(named: folderName)
        }
        dismissFolderSheet()
    }

    private func dismissFolderSheet() {
        isPresentingFolderForm = false
        folderName = ""
        editingFolder = nil
    }
}

struct FolderRowView: View {
    let folder: Folder
    let imageCount: Int
    let coverEntry: ImageEntry?

    var body: some View {
        HStack(spacing: 16) {
            if let coverEntry {
                AssetThumbnailView(entry: coverEntry, thumbnailLength: 70, cornerRadius: 10)
                    .frame(width: 70, height: 70)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.headline)
                Text("\(imageCount) image\(imageCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct FolderEditorSheet: View {
    let title: String
    @Binding var folderName: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Folder Name")) {
                    TextField("Name", text: $folderName)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
