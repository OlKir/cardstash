import Foundation

@MainActor
final class GalleryDataStore: ObservableObject {
    @Published private(set) var folders: [Folder] = []
    @Published private(set) var images: [ImageEntry] = []

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let fileURL: URL
    private let fileManager: FileManager
    private let imageDirectoryURL: URL

    init(fileURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
            self.fileURL = directory.appendingPathComponent("gallery-data.json")
        }
        let directoryURL = self.fileURL.deletingLastPathComponent()
        let imageDirectory = directoryURL.appendingPathComponent("StoredImages", isDirectory: true)
        if !fileManager.fileExists(atPath: imageDirectory.path) {
            try? fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        }
        self.imageDirectoryURL = imageDirectory
        loadFromDisk()
    }

    var allFolders: [Folder] {
        folders
    }

    func folder(with id: UUID) -> Folder? {
        folders.first { $0.id == id }
    }

    func images(for folderId: UUID) -> [ImageEntry] {
        images
            .filter { $0.folderId == folderId }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func createFolder(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var folder = Folder(name: trimmed)
        folder.updatedAt = folder.createdAt
        folders.append(folder)
        sortFolders()
        persist()
    }

    func renameFolder(id: UUID, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[index].name = trimmed
        folders[index].updatedAt = Date()
        sortFolders()
        persist()
    }

    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
        let entriesToRemove = images.filter { $0.folderId == id }
        entriesToRemove.forEach { entry in
            if let fileName = entry.storedFileName {
                deleteStoredImage(named: fileName)
            }
        }
        images.removeAll { $0.folderId == id }
        sortFolders()
        persist()
    }

    func addImages(_ payloads: [GalleryImagePayload], to folderId: UUID) {
        guard folder(with: folderId) != nil else { return }
        var newEntries: [ImageEntry] = []

        for payload in payloads {
            var storedFileName: String?
            if let data = payload.imageData {
                storedFileName = saveImageData(data)
            }

            if payload.assetIdentifier == nil && storedFileName == nil {
                continue
            }

            let entry = ImageEntry(
                folderId: folderId,
                assetIdentifier: payload.assetIdentifier,
                storedFileName: storedFileName
            )
            newEntries.append(entry)
        }

        guard !newEntries.isEmpty else { return }

        images.append(contentsOf: newEntries)
        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            folders[index].updatedAt = Date()
            sortFolders()
        }
        persist()
    }

    func removeImage(_ id: UUID) {
        guard let entry = images.first(where: { $0.id == id }) else { return }
        if let fileName = entry.storedFileName {
            deleteStoredImage(named: fileName)
        }
        images.removeAll { $0.id == id }
        persist()
    }

    func image(with id: UUID) -> ImageEntry? {
        images.first { $0.id == id }
    }

    private func loadFromDisk() {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            folders = []
            images = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let state = try decoder.decode(GalleryState.self, from: data)
            folders = state.folders
            images = state.images
            sortFolders()
        } catch {
            folders = []
            images = []
            print("Failed to load gallery data: \(error)")
        }
    }

    private func persist() {
        let state = GalleryState(folders: folders, images: images)
        do {
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to persist gallery data: \(error)")
        }
    }

    private func sortFolders() {
        folders.sort { lhs, rhs in
            if lhs.updatedAt != rhs.updatedAt {
                return lhs.updatedAt > rhs.updatedAt
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    func storedImageURL(for fileName: String) -> URL {
        imageDirectoryURL.appendingPathComponent(fileName)
    }

    private func saveImageData(_ data: Data) -> String? {
        let fileName = UUID().uuidString + ".dat"
        let destination = storedImageURL(for: fileName)
        do {
            try data.write(to: destination, options: .atomic)
            return fileName
        } catch {
            print("Failed to store image data: \(error)")
            return nil
        }
    }

    private func deleteStoredImage(named fileName: String) {
        let url = storedImageURL(for: fileName)
        try? fileManager.removeItem(at: url)
    }
}

extension GalleryDataStore {
    static let preview: GalleryDataStore = {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("preview-gallery.json")
        let store = GalleryDataStore(fileURL: tempURL)
        store.folders = [
            Folder(name: "Vacation"),
            Folder(name: "Family")
        ]
        store.images = []
        return store
    }()
}

struct GalleryImagePayload {
    let assetIdentifier: String?
    let imageData: Data?

    static func asset(_ identifier: String) -> GalleryImagePayload {
        GalleryImagePayload(assetIdentifier: identifier, imageData: nil)
    }

    static func data(_ data: Data) -> GalleryImagePayload {
        GalleryImagePayload(assetIdentifier: nil, imageData: data)
    }
}
