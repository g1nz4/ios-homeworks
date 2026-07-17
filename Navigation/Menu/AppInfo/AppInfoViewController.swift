import UIKit

/// Нижний лист с информацией о приложении.
final class AppInfoViewController: BottomSheetViewController {

    private let viewModel: AppInfoViewModel

    init(viewModel: AppInfoViewModel = AppInfoViewModel()) {
        self.viewModel = viewModel
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureContent() {
        super.configureContent()

        let data = viewModel.data

        // Header
        let header = ProfileInfoViewFactory.header { [weak self] in
            self?.dismissSheet()
        }
        if let titleLabel = header.subviews.compactMap({ $0 as? UILabel }).first {
            titleLabel.text = "О приложении"
        }
        contentStackView.addArrangedSubview(header)
        contentStackView.addArrangedSubview(ProfileInfoViewFactory.separator())

        // Основные строки
        contentStackView.addArrangedSubview(
            ProfileInfoViewFactory.row(icon: "app", text: data.appName)
        )

        contentStackView.addArrangedSubview(
            ProfileInfoViewFactory.row(icon: "number", text: "Версия: \(data.version)")
        )

        contentStackView.addArrangedSubview(
            ProfileInfoViewFactory.row(icon: "person", text: "Автор: \(data.author)")
        )

        if let year = data.year, !year.isEmpty {
            contentStackView.addArrangedSubview(
                ProfileInfoViewFactory.row(icon: "calendar", text: "Год: \(year)")
            )
        }

        contentStackView.addArrangedSubview(ProfileInfoViewFactory.separator())

        // Блок цель / технологии
        if (data.goal?.isEmpty == false) || (data.technologies?.isEmpty == false) {
            let infoContainer = UIStackView()
            infoContainer.axis = .vertical
            infoContainer.spacing = 8
            infoContainer.translatesAutoresizingMaskIntoConstraints = false

            let sectionTitle = UILabel()
            sectionTitle.text = "Информация о проекте"
            sectionTitle.font = .systemFont(ofSize: 17, weight: .semibold)
            sectionTitle.textColor = .appPrimaryText
            infoContainer.addArrangedSubview(sectionTitle)

            if let goal = data.goal, !goal.isEmpty {
                let goalTitle = UILabel()
                goalTitle.text = "Цель работы"
                goalTitle.font = .systemFont(ofSize: 13)
                goalTitle.textColor = .appSecondaryText

                let goalLabel = UILabel()
                goalLabel.text = goal
                goalLabel.font = .systemFont(ofSize: 15)
                goalLabel.textColor = .appPrimaryText
                goalLabel.numberOfLines = 0

                infoContainer.addArrangedSubview(goalTitle)
                infoContainer.addArrangedSubview(goalLabel)
            }

            if let technologies = data.technologies, !technologies.isEmpty {
                let techTitle = UILabel()
                techTitle.text = "Технологии"
                techTitle.font = .systemFont(ofSize: 13)
                techTitle.textColor = .appSecondaryText

                let techLabel = UILabel()
                techLabel.text = technologies
                techLabel.font = .systemFont(ofSize: 15)
                techLabel.textColor = .appPrimaryText
                techLabel.numberOfLines = 0

                infoContainer.addArrangedSubview(techTitle)
                infoContainer.addArrangedSubview(techLabel)
            }

            contentStackView.addArrangedSubview(infoContainer)
        }
    }
}
