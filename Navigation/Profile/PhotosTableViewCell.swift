import UIKit

class PhotosTableViewCell: UITableViewCell {
   
    static let reuseId = "PhotosTableViewCell"
    
    private lazy var photoTableView = PhotoTableView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    private func setupView() {
        contentView.addSubview(photoTableView)
        photoTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate(
            [
                photoTableView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor
                ),
                photoTableView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor
                ),
                photoTableView.topAnchor.constraint(
                    equalTo: contentView.topAnchor
                ),
                photoTableView.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor
                )
            ]
        )
    }
}

