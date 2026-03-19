import UIKit

final class InfoViewController: UIViewController {

    weak var coordinator: InfoCoordinator?
    private let viewModel: TodoViewModelProtocol
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18.0, weight: .medium)
        label.textColor = .systemPurple
        label.numberOfLines = 0
        label.textAlignment = .left
        
        return label
    }()
    
    private lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .systemPurple
        
        return indicator
    }()
    
    private lazy var updateButton = CustomButton(
        title: "Обновить",
        backgroundColor: .systemPurple
    )
    
    init(viewModel: TodoViewModelProtocol = TodoViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupConstraint()
        bindingViewModel()
        updateButtonAction()
        viewModel.viewDidLoad()
    }

    private func setupConstraint() {
        [titleLabel, indicator, updateButton].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
      
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 20.0),
                titleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20.0),
                titleLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20.0),
                titleLabel.heightAnchor.constraint(equalToConstant: 80.0),
                
                indicator.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
                indicator.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
                updateButton.heightAnchor.constraint(equalToConstant: 50.0),
                updateButton.widthAnchor.constraint(equalToConstant: 150.0),
                updateButton.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
                updateButton.topAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -250.0),
                updateButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -200.0)
        ])
    }
    
    private func bindingViewModel() {
        viewModel.title.binding { [weak self] string in
            DispatchQueue.main.async {
                self?.titleLabel.text = string
            }
        }
        
        viewModel.isLoading.binding { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.indicator.startAnimating()
                    self?.updateButton.isEnabled = false
                    self?.updateButton.alpha = 0.7
                } else {
                    self?.indicator.stopAnimating()
                    self?.updateButton.isEnabled = true
                    self?.updateButton.alpha = 1.0
                }
            }
        }
    }
    
    private func updateButtonAction() {
        updateButton.setActionButton { [weak self] in
            self?.viewModel.update()
        }
    }
}
