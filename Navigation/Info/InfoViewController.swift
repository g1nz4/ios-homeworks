import UIKit

final class InfoViewController: UIViewController {

    weak var coordinator: InfoCoordinator?
    private let viewModel: ResidentsViewModelProtocol
    
    private lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .systemPurple
        
        return indicator
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "ResidentCell")
        table.dataSource = self
        table.delegate = self
        
        return table
    }()
    
    init(viewModel: ResidentsViewModelProtocol = ResidentsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = "Жители планеты Татуин"
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
        view.addSubview(tableView)
        view.addSubview(indicator)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),

                indicator.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
                indicator.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
        ])
    }
    
    private func bindingViewModel() {
        viewModel.residentNames.binding { [weak self] _ in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        
        viewModel.isLoading.binding { [weak self] isLoading in
            DispatchQueue.main.async {
                isLoading ? self?.indicator.startAnimating() : self?.indicator.stopAnimating()
            }
        }
        
        viewModel.textError.binding { [weak self] text in
            guard let text, !text.isEmpty else { return }
            DispatchQueue.main.async {
                self?.showErrorAlert(message: text)
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension InfoViewController: UITableViewDataSource, UITableViewDelegate {
   
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        viewModel.residentNames.value.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResidentCell", for: indexPath)
        let name = viewModel.residentNames.value[indexPath.row]
        cell.textLabel?.text = name
        
        return cell
    }
}
