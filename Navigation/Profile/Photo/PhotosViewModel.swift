import Foundation

enum PhotosScreenMode {
    case main
    case album(PhotoAlbum)
}

/// ViewModel для экрана фотографий / альбомов.
@MainActor
final class PhotosViewModel {

    private let user: User
    private let photosRepository: PhotosRepositoryProtocol
    private let albumCoversService: AlbumCoversLoadingProtocol

    let mode: PhotosScreenMode

    /// В режиме `.main` - список альбомов пользователя.
    private(set) var albums: [PhotoAlbum] = []

    /// В режиме `.main` - фото без альбома; в `.album` - фото выбранного альбома.
    private(set) var photos: [Photo] = []

    /// Обложки альбомов: `albumId -> URL`.
    private var albumCovers: [String: URL] = [:]

    private var isLoaded = false

    var onChanged: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onAvatarChanged: (() -> Void)?
    var onCoverChanged: (() -> Void)?

    init(
        user: User,
        photosRepository: PhotosRepositoryProtocol,
        albumCoversService: AlbumCoversLoadingProtocol,
        mode: PhotosScreenMode
    ) {
        self.user = user
        self.photosRepository = photosRepository
        self.albumCoversService = albumCoversService
        self.mode = mode
    }

    /// Загрузка данных для текущего экрана.
    /// - force: если `true` - перезагружает данные, даже если уже были загружены.
    func load(force: Bool = false) async {
        if isLoaded && !force {
            AppLogger.debug("[PHOTOS VM] load() skipped, already loaded, mode=\(mode)")
            return
        }

        do {
            switch mode {
            case .main:
                // Загрузка альбомов
                let albums = try await photosRepository.loadAlbums(for: user.id)
                // Загрузка обложек альбомов
                let albumCovers: [String: URL]
                do {
                    albumCovers = try await albumCoversService.loadAlbumCovers(
                        userId: user.id,
                        albums: albums
                    )
                } catch {
                    AppLogger.error("[PHOTOS] loadAlbumCovers failed: \(error)")
                    albumCovers = [:]
                }
                // Загрузка фото без альбомов
                let otherPhotos = try await photosRepository.loadPhotos(
                    userId: user.id,
                    albumId: nil
                )

                self.albums = albums
                self.albumCovers = albumCovers
                self.photos = otherPhotos
                self.isLoaded = true
                self.onChanged?()

            case .album(let album):
                // Загрузка фото конкретного альбома
                let albumPhotos = try await photosRepository.loadPhotos(
                    userId: user.id,
                    albumId: album.id
                )

                self.photos = albumPhotos
                self.albums = []
                self.albumCovers = [:]
                self.isLoaded = true
                self.onChanged?()
            }

        } catch {
            AppLogger.error("[PHOTOS] load() error: \(error)")
            self.onError?(error)
        }
    }

    /// URL обложки для альбома по индексу (используется в коллекции).
    func coverURL(forAlbumAt index: Int) -> URL? {
        guard albums.indices.contains(index) else { return nil }
        let album = albums[index]
        return albumCovers[album.id]
    }

    /// Индекс фото по id.
    func indexOfPhoto(id: String) -> Int? {
        photos.firstIndex { $0.id == id }
    }

    /// Удаляет фото из локального массива (без запроса к Supabase).
    func removePhoto(at index: Int) {
        photos.remove(at: index)
    }

    /// Все текущие фото.
    func allPhotos() -> [Photo] {
        photos
    }

    /// Удаление фото (из таблицы Supabase и из локального списка).
    func delete(photo: Photo) async {
        do {
            try await photosRepository.deletePhoto(id: photo.id)
            if let idx = photos.firstIndex(where: { $0.id == photo.id }) {
                photos.remove(at: idx)
            }
            onChanged?()
        } catch {
            AppLogger.error("PhotosVM.delete(photo:) error: \(error)")
            onError?(error)
        }
    }

    /// Установить фотографией профиля.
    func setAvatar(from photo: Photo) async {
        do {
            try await photosRepository.setAvatarFromPhoto(
                userId: user.id,
                photoURL: photo.url
            )
            onAvatarChanged?()
        } catch {
            AppLogger.error("PhotosVM.setAvatar(from:) error: \(error)")
            onError?(error)
        }
    }

    /// Сделать фото обложкой профиля.
    func setCover(from photo: Photo) async {
        do {
            try await photosRepository.setCoverFromPhoto(
                userId: user.id,
                photoURL: photo.url
            )
            onCoverChanged?()
        } catch {
            AppLogger.error("PhotosVM.setCover(from:) error: \(error)")
            onError?(error)
        }
    }

    /// Добавить в альбом `Сохранённые`.
    func addToSaved(photo: Photo) async {
        do {
            try await photosRepository.addPhotoToSaved(
                userId: user.id,
                photoURL: photo.url
            )
            await load(force: true)
        } catch {
            AppLogger.error("PhotosVM.addToSaved(photo:) error: \(error)")
            onError?(error)
        }
    }

    /// Загрузить все фото из альбома `Фото со станицы` (type == .profile).
    func loadProfileAlbumPhotos() async throws -> [Photo] {
        let loadedAlbums: [PhotoAlbum]

        if !albums.isEmpty {
            loadedAlbums = albums
        } else {
            loadedAlbums = try await photosRepository.loadAlbums(for: user.id)
        }

        guard let profileAlbum = loadedAlbums.first(where: { $0.type == .profile }) else {
            AppLogger.debug("[PHOTOS VM] profile album not found")
            return []
        }

        let profilePhotos = try await photosRepository.loadPhotos(
            userId: user.id,
            albumId: profileAlbum.id
        )

        return profilePhotos
    }
}
