//import UIKit
//
//final class MusicViewController: UIViewController {
//
//  //  private let viewModel: MusicViewModelProtocol
//    private var currentSelectedIndex: Int = 0
//    
//    private lazy var titleLabel: UILabel = {
//        let label = UILabel()
//        label.textAlignment = .center
//        label.textColor = .red
//        label.font = .systemFont(ofSize: 20.0, weight: .semibold)
//        label.numberOfLines = 0
//        label.text = "Нет трека"
//        
//        return label
//    }()
//
//    private lazy var prevButton: UIButton = {
//        let button = UIButton(type: .system)
//        let image = UIImage(systemName: "backward.fill")
//        button.setImage(image, for: .normal)
//        button.tintColor = .white
//        button.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
//        button.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
//        
//        return button
//    }()
//
//    private lazy var playPauseButton: UIButton = {
//        let button = UIButton(type: .system)
//        let image = UIImage(systemName: "play.fill")
//        button.setImage(image, for: .normal)
//        button.tintColor = .white
//        button.imageView?.contentMode = .scaleAspectFit
//        button.contentHorizontalAlignment = .center
//        button.contentVerticalAlignment = .center
//        button.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
//        button.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
//        
//        return button
//    }()
//
//    private lazy var stopButton: UIButton = {
//        let button = UIButton(type: .system)
//        let image = UIImage(systemName: "stop.fill")
//        button.setImage(image, for: .normal)
//        button.tintColor = .systemRed
//        button.imageView?.contentMode = .scaleAspectFit
//        button.contentHorizontalAlignment = .center
//        button.contentVerticalAlignment = .center
//        button.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
//        button.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
//        
//        return button
//    }()
//
//    private lazy var nextButton: UIButton = {
//        let button = UIButton(type: .system)
//        let image = UIImage(systemName: "forward.fill")
//        button.setImage(image, for: .normal)
//        button.tintColor = .white
//        button.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
//        button.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
//        
//        return button
//    }()
//
//    private lazy var buttonsStack = {
//        let stack = UIStackView()
//        stack.axis = .horizontal
//        stack.alignment = .fill
//        stack.distribution = .fillEqually
//        stack.spacing = 24.0
//        stack.backgroundColor = .black
//        stack.layer.cornerRadius = 8.0
//        stack.addArrangedSubview(self.prevButton)
//        stack.addArrangedSubview(self.playPauseButton)
//        stack.addArrangedSubview(self.stopButton)
//        stack.addArrangedSubview(self.nextButton)
//        
//        return stack
//    }()
//
//    private lazy var tableView: UITableView = {
//        let table = UITableView(frame: .zero, style: .plain)
//        table.register(UITableViewCell.self, forCellReuseIdentifier: "TrackCell")
//        table.dataSource = self
//        table.delegate = self
//        
//        return table
//    }()
//
//    init() {
//        
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        bindingViewModel()
//        ///viewModel.viewDidLoad()
//    }
//
//    private func setupUI() {
//        [titleLabel, buttonsStack, tableView].forEach() {
//            $0.translatesAutoresizingMaskIntoConstraints = false
//            view.addSubview($0)
//        }
//        
//        let safeArea = view.safeAreaLayoutGuide
//        NSLayoutConstraint.activate([
//            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 30),
//            titleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
//            titleLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
//
//            buttonsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
//            buttonsStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
//            buttonsStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
//            buttonsStack.heightAnchor.constraint(equalToConstant: 50),
//
//            tableView.topAnchor.constraint(equalTo: buttonsStack.bottomAnchor, constant: 20),
//            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
//        ])
//    }
//
//    private func showErrorAlert(message: String) {
//        let alert = UIAlertController(
//            title: "Ошибка",
//            message: message,
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//    
////    private func bindingViewModel() {
////        viewModel.bindCurrentTrackName { [weak self] name in
////            DispatchQueue.main.async {
////                self?.titleLabel.text = name
////            }
////        }
////        viewModel.bindIsPlayingChanged { [weak self] isPlaying in
////            DispatchQueue.main.async {
////                let imageName = isPlaying ? "pause.fill" : "play.fill"
////                self?.playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
////            }
////        }
////        viewModel.bindError { [weak self] message in
////            DispatchQueue.main.async {
////                self?.showErrorAlert(message: message)
////            }
////        }
////    }
////
////    private func selectTrack(at index: Int) {
////        currentSelectedIndex = index
////        viewModel.selectTrack(at: index)
////
////        let indexPath = IndexPath(row: index, section: 0)
////        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
////    }
////
////    @objc private func playPauseTapped() {
////        viewModel.playPauseTapped()
////    }
////
////    @objc private func stopTapped() {
////        viewModel.stopTapped()
////    }
////
////    @objc private func prevTapped() {
////        guard viewModel.numberOfTracks > 0 else { return }
////        let newIndex = (viewModel.numberOfTracks + currentSelectedIndex - 1) % viewModel.numberOfTracks
////        selectTrack(at: newIndex)
////    }
////
////    @objc private func nextTapped() {
////        guard viewModel.numberOfTracks > 0 else { return }
////        let newIndex = (currentSelectedIndex + 1) % viewModel.numberOfTracks
////        selectTrack(at: newIndex)
////    }
//}
//
////extension MusicViewController: UITableViewDataSource, UITableViewDelegate {
////
////    func tableView(
////        _ tableView: UITableView,
////        numberOfRowsInSection section: Int
////    ) -> Int {
////        viewModel.numberOfTracks
////    }
////
////    func tableView(
////        _ tableView: UITableView,
////        cellForRowAt indexPath: IndexPath
////    ) -> UITableViewCell {
////        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath)
////        cell.textLabel?.text = viewModel.titleForTrack(at: indexPath.row)
////        cell.accessoryType = .none
////        
////        return cell
////    }
////
////    func tableView(
////        _ tableView: UITableView,
////        didSelectRowAt indexPath: IndexPath
////    ) {
////        selectTrack(at: indexPath.row)
////    }
////}
