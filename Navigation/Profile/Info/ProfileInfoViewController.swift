import UIKit

/// Нижний лист с подробной информацией о пользователе. Появляется поверх текущего экрана с затемнением фона.
final class ProfileInfoViewController: BottomSheetViewController {
    
    private let viewModel: ProfileInfoViewModel
    
    init(viewModel: ProfileInfoViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Наполнение стека контентом на основе данных ViewModel.
    override func configureContent() {
        super.configureContent()
        
        let info = viewModel.data
        
        // Header через фабрику
        let header = ProfileInfoViewFactory.header { [weak self] in
            self?.dismissSheet()
        }
        contentStackView.addArrangedSubview(header)
        contentStackView.addArrangedSubview(ProfileInfoViewFactory.separator())
        
        // Статус
        if let status = info.status, !status.isEmpty {
            contentStackView.addArrangedSubview(
                ProfileInfoViewFactory.row(icon: "bubble", text: status, tint: .secondaryLabel)
            )
        }
        
        // Ник
        if let nick = info.nickname, !nick.isEmpty {
            contentStackView.addArrangedSubview(
                ProfileInfoViewFactory.row(icon: "at", text: nick, tint: .secondaryLabel)
            )
        }
        
        // ДР
        if let birthday = info.birthday, !birthday.isEmpty {
            contentStackView.addArrangedSubview(
                ProfileInfoViewFactory.row(icon: "gift", text: "День рождения: \(birthday)")
            )
        }
        
        // Город
        if let city = info.city, !city.isEmpty {
            contentStackView.addArrangedSubview(
                ProfileInfoViewFactory.row(icon: "house", text: "Город: \(city)")
            )
        }
        
        // Подписчики
        if let subs = info.subscribersCount {
            contentStackView.addArrangedSubview(
                ProfileInfoViewFactory.row(icon: "dot.radiowaves.up.forward", text: subs)
            )
        }
        
        contentStackView.addArrangedSubview(ProfileInfoViewFactory.separator())
        
        // Друзья / подписки
        let friendsFollowingStack = UIStackView()
        friendsFollowingStack.axis = .vertical
        friendsFollowingStack.spacing = 8
        friendsFollowingStack.translatesAutoresizingMaskIntoConstraints = false
        
        if let friends = info.friendsCount {
            friendsFollowingStack.addArrangedSubview(
                ProfileInfoViewFactory.navigationRow(icon: "person", title: "Друзья", value: friends)
            )
        }
        
        if let following = info.followingCount {
            friendsFollowingStack.addArrangedSubview(
                ProfileInfoViewFactory.navigationRow(icon: "person.2", title: "Подписки", value: following)
            )
        }
        
        contentStackView.addArrangedSubview(friendsFollowingStack)
        
        // О себе
        if let about = info.about, !about.isEmpty {
            contentStackView.addArrangedSubview(ProfileInfoViewFactory.separator())
            
            let aboutContainer = UIStackView()
            aboutContainer.axis = .vertical
            aboutContainer.spacing = 8
            aboutContainer.translatesAutoresizingMaskIntoConstraints = false
            
            let sectionTitle = UILabel()
            sectionTitle.text = "Основная информация"
            sectionTitle.font = .systemFont(ofSize: 17, weight: .semibold)
            sectionTitle.textColor = .appPrimaryText
            
            let aboutTitle = UILabel()
            aboutTitle.text = "О себе"
            aboutTitle.font = .systemFont(ofSize: 13)
            aboutTitle.textColor = .appSecondaryText
            
            let aboutLabel = UILabel()
            aboutLabel.text = about
            aboutLabel.font = .systemFont(ofSize: 15)
            aboutLabel.textColor = .appPrimaryText
            aboutLabel.numberOfLines = 0
            
            aboutContainer.addArrangedSubview(sectionTitle)
            aboutContainer.addArrangedSubview(aboutTitle)
            aboutContainer.addArrangedSubview(aboutLabel)
            
            contentStackView.addArrangedSubview(aboutContainer)
        }
    }
}
