import Foundation

struct Folder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    let createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ImageEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let folderId: UUID
    let assetIdentifier: String?
    let storedFileName: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        folderId: UUID,
        assetIdentifier: String?,
        storedFileName: String?,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.folderId = folderId
        self.assetIdentifier = assetIdentifier
        self.storedFileName = storedFileName
        self.createdAt = createdAt
    }
}

struct GalleryState: Codable {
    var folders: [Folder]
    var images: [ImageEntry]

    init(folders: [Folder] = [], images: [ImageEntry] = []) {
        self.folders = folders
        self.images = images
    }
}
