import Foundation

/// Хранилище состояния на диске: один JSON-файл в Application Support.
/// Пишем атомарно и в фоне, читаем один раз при запуске.
final class StateFileStore {
    static let shared = StateFileStore()

    private let queue = DispatchQueue(label: "app.kopilka.state", qos: .utility)
    private let fileManager = FileManager.default

    private lazy var directoryURL: URL = {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base.appendingPathComponent("Kopilka", isDirectory: true)
    }()

    private var fileURL: URL {
        directoryURL.appendingPathComponent("state.json")
    }

    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func load() -> AppState {
        guard let data = try? Data(contentsOf: fileURL) else { return .empty }
        do {
            return try decoder.decode(AppState.self, from: data)
        } catch {
            // Файл повреждён — отводим его в сторону, чтобы приложение
            // запустилось, но данные пользователя не исчезли безвозвратно.
            let backup = directoryURL.appendingPathComponent("state-corrupted-\(Int(Date.now.timeIntervalSince1970)).json")
            try? fileManager.moveItem(at: fileURL, to: backup)
            return .empty
        }
    }

    func save(_ state: AppState) {
        guard let data = try? encoder.encode(state) else { return }
        let folder = directoryURL
        let destination = fileURL
        let manager = fileManager
        queue.async {
            if !manager.fileExists(atPath: folder.path) {
                try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
            }
            try? data.write(to: destination, options: .atomic)
        }
    }

    func reset() {
        let destination = fileURL
        let manager = fileManager
        queue.async {
            try? manager.removeItem(at: destination)
        }
    }
}
