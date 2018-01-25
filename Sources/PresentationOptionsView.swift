//
//  PresentationOptionsView.swift
//  VLC-iOS
//
//  Created by Carola Nitz on 12/3/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

import Foundation

public enum SortOption:Int {
    case alphabetically
    case insertonDate
    case size

    static let mapper: [SortOption: String] = [
        .alphabetically: NSLocalizedString("Name", comment: ""),
        .insertonDate: NSLocalizedString("Date", comment: ""),
        .size: NSLocalizedString("Size", comment: "")
    ]
    var string: String {
        return SortOption.mapper[self]!
    }
}

public protocol PresentationViewDelegate: class {
    func presentationOptionsViewSelectedCreateFolder(presentationOptionsView:PresentationOptionsView)
    func presentationOptionsViewSelectedTableViewPresentation(presentationOptionsView:PresentationOptionsView, showAsTableView:Bool)
    func presentationOptionsViewChangeSorting(presentationOptionsView:PresentationOptionsView, to:SortOption)
}

public class PresentationOptionsView: UICollectionReusableView {

    public weak var delegate:PresentationViewDelegate?
    var sortOptionsControl: UISegmentedControl!
    var folderButton:UIButton!
    var tableViewButton:UIButton!
    static let reuseIdentifier = "PresentationOptionsView"

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        let sortAlphabetically = SortOption.alphabetically.string
        let sortByInsertionDate = SortOption.insertonDate.string
        let sortBySize = SortOption.size.string

        sortOptionsControl = UISegmentedControl(items: [sortAlphabetically, sortByInsertionDate, sortBySize])
        sortOptionsControl.translatesAutoresizingMaskIntoConstraints = false
        sortOptionsControl.addTarget(self, action: #selector(changeSorting), for: UIControlEvents.touchUpInside)

        folderButton = UIButton(type: UIButtonType.contactAdd)
        folderButton.translatesAutoresizingMaskIntoConstraints = false
        folderButton.addTarget(self, action: #selector(createNewFolder), for: .touchUpInside)

        tableViewButton = UIButton(type: .detailDisclosure)
        tableViewButton.imageView?.image = #imageLiteral(resourceName: "tableViewIcon")
        tableViewButton.translatesAutoresizingMaskIntoConstraints = false
        tableViewButton.addTarget(self, action: #selector(tableViewSelected), for: .touchUpInside)

        let stackview = UIStackView(arrangedSubviews: [folderButton, sortOptionsControl, tableViewButton])
        stackview.translatesAutoresizingMaskIntoConstraints = false
        stackview.distribution = .equalSpacing
        stackview.isLayoutMarginsRelativeArrangement = true
        stackview.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        addSubview(stackview)

        NSLayoutConstraint.activate([
            sortOptionsControl.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.5, constant: 0),
            stackview.leftAnchor.constraint(equalTo: self.leftAnchor),
            stackview.rightAnchor.constraint(equalTo: self.rightAnchor),
            stackview.topAnchor.constraint(equalTo: self.topAnchor),
            stackview.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    @objc private func createNewFolder() {
        delegate?.presentationOptionsViewSelectedCreateFolder(presentationOptionsView:self)
    }

    @objc private func tableViewSelected() {
        delegate?.presentationOptionsViewSelectedTableViewPresentation(presentationOptionsView: self, showAsTableView: tableViewButton.isSelected)
        tableViewButton.isSelected = !tableViewButton.isSelected
    }

    @objc private func changeSorting() {
        delegate?.presentationOptionsViewChangeSorting(presentationOptionsView:self, to: SortOption(rawValue: sortOptionsControl.selectedSegmentIndex)!)
    }
}
