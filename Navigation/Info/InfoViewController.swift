import UIKit

final class InfoViewController: UIViewController {

    weak var coordinator: InfoCoordinator?
    private let viewModel: PlanetViewModelProtocol
    
    private lazy var orbitalPeriodLabel: UILabel = {
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
    
    init(viewModel: PlanetViewModelProtocol = PlanetViewModel()) {
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
        viewModel.viewDidLoad()
    }

    private func setupConstraint() {
        [orbitalPeriodLabel, indicator].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
      
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
                orbitalPeriodLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 20.0),
                orbitalPeriodLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20.0),
                orbitalPeriodLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20.0),
                orbitalPeriodLabel.heightAnchor.constraint(equalToConstant: 80.0),
                
                indicator.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
                indicator.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor)
        ])
    }
    
    private func bindingViewModel() {
        viewModel.orbitalPeriod.binding { [weak self] string in
            DispatchQueue.main.async {
                self?.orbitalPeriodLabel.text = string
            }
        }
        
        viewModel.isLoading.binding { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.indicator.startAnimating()
                } else {
                    self?.indicator.stopAnimating()
                }
            }
        }
    }
}
