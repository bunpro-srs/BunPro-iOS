//
//  KanjiTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 19.02.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

class KanjiTableViewController: UITableViewController {

    var furigana = [Furigana]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return furigana.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath)

        let info = furigana[indexPath.row]
        
        cell.textLabel?.text = "\(info.original)（\(info.text)）"

        return cell
    }
    
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: super.preferredContentSize.width, height: 63 * CGFloat(furigana.count))
        }
        set { super.preferredContentSize = newValue }
    }
}
