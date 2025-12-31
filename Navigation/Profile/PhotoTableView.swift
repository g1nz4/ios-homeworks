import UIKit

class PhotoTableView: UIView {

    private lazy var image1: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.translatesAutoresizingMaskIntoConstraints = false
        image.layer.cornerRadius = 6.0
        image.image = UIImage(named: "supernaturalNewYear_1")
        
        return image
    }()

    private lazy var image2: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.translatesAutoresizingMaskIntoConstraints = false
        image.layer.cornerRadius = 6.0
        image.image = UIImage(named: "supernaturalNewYear_2")
        return image
    }()

    private lazy var image3: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.translatesAutoresizingMaskIntoConstraints = false
        image.layer.cornerRadius = 6.0
        image.image = UIImage(named: "supernaturalNewYear_3")
        return image
    }()

    private lazy var image4: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.translatesAutoresizingMaskIntoConstraints = false
        image.layer.cornerRadius = 6.0
        image.image = UIImage(named: "supernaturalNewYear_4")
        return image
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24.0, weight: .bold)
        label.text = "Photos"
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        
        
        return label
    }()

    private lazy var symbol: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "arrowshape.right")
        image.tintColor = .black
        image.translatesAutoresizingMaskIntoConstraints = false
        
        return image
    }()

    private lazy var photoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8.0
        stackView.distribution = .fillEqually
        
        stackView.addArrangedSubview(self.image1)
        stackView.addArrangedSubview(self.image2)
        stackView.addArrangedSubview(self.image3)
        stackView.addArrangedSubview(self.image4)
        
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview()
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubview() {
        addSubview(label)
        addSubview(symbol)
        addSubview(photoStackView)
    }

    private func setupView() {
        
        NSLayoutConstraint.activate(
            [
                label.leadingAnchor.constraint(
                    equalTo: leadingAnchor,
                    constant: 12.0
                ),
                label.topAnchor.constraint(
                    equalTo: topAnchor,
                    constant: 12.0
                ),
                symbol.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -12.0
                ),
                symbol.centerYAnchor.constraint(
                    equalTo: label.centerYAnchor
                ),
                symbol.widthAnchor.constraint(
                    equalToConstant: 24.0
                ),
                symbol.heightAnchor.constraint(
                    equalToConstant: 24.0
                ),
                photoStackView.topAnchor.constraint(
                    equalTo: label.bottomAnchor,
                    constant: 12.0
                ),
                photoStackView.leadingAnchor.constraint(
                    equalTo: leadingAnchor,
                    constant: 12.0
                ),
                photoStackView.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -12.0
                ),
                photoStackView.heightAnchor.constraint(
                    equalToConstant: 70.0
                ),
                photoStackView.bottomAnchor.constraint(
                    equalTo: bottomAnchor,
                    constant: -12.0
                )
            ]
        )
    }
}

