//
//  TestTableView.swift
//  TapUIKit-iOS
//
//  Created by Osama Rabie on 02/03/2023.
//

import UIKit
import SnapKit
import TapThemeManager2020
/// A custom UIView that shows a separator between different cells/lines/sections, Theme path : "tapSeparationLine"
@objc public class TestTableView: UIView {
    
    /// The container view that holds everything from the XIB
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var expanded:Bool = false
    
    // Mark:- Init methods
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    /// Used as a consolidated method to do all the needed steps upon creating the view
    private func commonInit() {
        self.containerView = setupXIB()
        applyTheme()
        let bundle = Bundle(for: MyTableViewCell.self)
        tableView.register(UINib(nibName: "MyTableViewCell", bundle: bundle), forCellReuseIdentifier: "MyTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.containerView.frame = bounds
    }
    
    // Mark:- Interface methods
    
}

// Mark:- Theme methods
extension TestTableView {
    /// Consolidated one point to apply all needed theme methods
    public func applyTheme() {
        matchThemeAttributes()
    }
    
    /// Match the UI attributes with the correct theming entries
    private func matchThemeAttributes() {
        layoutIfNeeded()
    }
    
    /// Listen to light/dark mde changes and apply the correct theme based on the new style
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        TapThemeManager.changeThemeDisplay(for: self.traitCollection.userInterfaceStyle)
        applyTheme()
    }
}



extension TestTableView: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expanded ? 10 : 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:MyTableViewCell = tableView.dequeueReusableCell(withIdentifier: "MyTableViewCell", for: indexPath) as! MyTableViewCell
        return cell
    }
    
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let number = 1..<10
            expanded = !expanded
            var height = expanded ? 480 : 48
            
            if height == 480 {
                self.tableView.snp.updateConstraints { make in
                    make.height.equalTo(height)
                }
                self.tableView.layoutIfNeeded()
            }
            
            if expanded {
                tableView.insertRows(at: number.map{ IndexPath(row: $0, section: 0) }, with: .fade)
                height = 480
            }else{
                tableView.deleteRows(at: number.map{ IndexPath(row: $0, section: 0) }, with: .fade)
                height = 48
            }
            
            if height == 48 {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.tableView.snp.updateConstraints { make in
                        make.height.equalTo(height)
                    }
                    self.tableView.layoutIfNeeded()
                }
            }
        }
    }
    
}

