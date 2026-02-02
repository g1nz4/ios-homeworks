import UIKit

final class InfoViewController: UIViewController {

    private lazy var actionButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle("Посмотреть", for: .normal)
    button.setTitleColor(.systemIndigo, for: .normal)

    return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .lightGray
        title = "info"
        
        setupButton()
    }

    private func setupButton() {
        view.addSubview(actionButton)
      
        let safeAreaLayoutGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate(
            [
                actionButton.leadingAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.leadingAnchor,
                    constant: 20.0
                ),
                actionButton.trailingAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.trailingAnchor,
                    constant: -20.0
                ),
                actionButton.centerYAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.centerYAnchor)
                ,
                actionButton.heightAnchor.constraint(
                    equalToConstant: 44.0
                )
            ]
        )
        
        actionButton.addTarget(
            self,
            action: #selector(buttonPressed(_:)),
            for: .touchUpInside
        )
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Info",
            message: "Hello World!",
            preferredStyle: .alert
        )
        let alertActionOne = UIAlertAction(
            title: "OK",
            style: .default
        ){
            (alert) in print("OK")
        }
        let alertActionTwo = UIAlertAction(
            title: "Hello World!",
            style: .default
        ){
            (alert) in print("Hello World!")
        }
        let alertActions = [alertActionOne, alertActionTwo]
        alertActions.forEach {
            alertController.addAction($0)
        }
        present(alertController, animated: true)
    }
}
