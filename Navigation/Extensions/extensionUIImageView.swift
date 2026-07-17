import UIKit

extension UIImageView {
    /// Загружает картинку по строке: URL или имя ассета.
    /// Возвращает Task, чтобы можно было отменять в prepareForReuse.
    func setImage(
        from path: String?,
        placeholder: UIImage? = nil
    ) -> Task<Void, Never>? {
        // плейсхолдер сразу
        self.image = placeholder
        
        guard
            let path,
            !path.isEmpty
        else { return nil }

        // локальный ассет
        if !path.hasPrefix("http") {
            self.image = UIImage(named: path) ?? placeholder
            return nil
        }

        // URL
        guard let url = URL(string: path) else {
            self.image = placeholder
            return nil
        }

        let task = Task { [weak self] in
            guard let self else { return }
            let image = await ImageLoader.shared.loadImage(from: url)
            await MainActor.run {
                self.image = image ?? placeholder
            }
        }

        return task
    }
}
