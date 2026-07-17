import UIKit

/// Header с поисковой строкой.
final class SearchHeaderView: UICollectionReusableView {
   
    static let reuseId = "SearchHeaderView"
    
    /// Колбэк, который вызывается при изменении текста поиска.
    var onSearchTextChanged: ((String) -> Void)?
    
    private lazy var searchField: UISearchTextField = {
        let field = UISearchTextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = NSLocalizedString("search_header_view", comment: "Плейсхолдер поиска")
        field.clearButtonMode = .never
        field.returnKeyType = .search
        field.delegate = self
        field.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        
        return field
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
       
        setupSearchField()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSearchField() {
        addSubview(searchField)
        
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            searchField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            searchField.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    @objc private func textChanged() {
        onSearchTextChanged?(searchField.text ?? "")
    }
}

extension SearchHeaderView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onSearchTextChanged?(searchField.text ?? "")
        textField.resignFirstResponder()
        
        return true
    }
}
