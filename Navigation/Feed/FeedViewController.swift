import UIKit

final class FeedViewController: UIViewController {
    
    weak var coordinator: FeedCoordinator?
    
    private var feedViewModel: (FeedViewModelInput & FeedViewModelOutput)
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(FeedPostTableViewCell.self, forCellReuseIdentifier: FeedPostTableViewCell.reuseId)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 200
        
        return table
    }()
    
    init(feedViewModel: FeedViewModelInput & FeedViewModelOutput = FeedViewModel()){
        self.feedViewModel = feedViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindingViewModel()
        feedViewModel.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
        #if DEBUG
            view.backgroundColor = UIColor.systemYellow
        #else
            view.backgroundColor = UIColor.systemCyan
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        feedViewModel.viewWillAppear()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        feedViewModel.viewWillDisappear()
    }
    
    private func setupUI() {
        navigationItem.title = "Feed"
        view.addSubview(tableView)
        
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor)
        ])
    }
    
    private func bindingViewModel() {
        feedViewModel.postsUpdated = { [weak self] in
            self?.tableView.reloadData()
        }
        feedViewModel.postInsertedAtTop = { [weak self] index in
            guard let self = self else { return }
            
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        feedViewModel.onError = { [weak self] error in
            guard let self = self else { return }
            
            let message = error.rawValue
            let alert = UIAlertController(
                title: "Ошибка",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

extension FeedViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        feedViewModel.numberOfPosts
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FeedPostTableViewCell.reuseId,
            for: indexPath
        ) as? FeedPostTableViewCell else {
            return UITableViewCell()
        }
        let post = feedViewModel.post(at: indexPath.row)
        cell.configure(with: post)
        
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        coordinator?.present(.post)
    }
}
