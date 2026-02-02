import UIKit

class ProfileTableHeaderView: UITableViewHeaderFooterView {
    
    static let headerReuseId = "HeaderReuseId"
    
    let profileHeaderView: ProfileHeaderView = {
        let profileHeader = ProfileHeaderView()
        profileHeader.translatesAutoresizingMaskIntoConstraints = false
        profileHeader.backgroundColor = UIColor(named: "Color")
        
        return profileHeader
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        addSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviews() {
        contentView.addSubview(profileHeaderView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate(
            [
                profileHeaderView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor
                ),
                profileHeaderView.trailingAnchor.constraint(
                    equalTo:contentView.trailingAnchor
                ),
                profileHeaderView.heightAnchor.constraint(
                    equalToConstant: 220.0
                ),
                profileHeaderView.centerXAnchor.constraint(
                    equalTo: contentView.centerXAnchor
                )
            ]
        )
    }
}
    

