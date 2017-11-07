//
//  GrammarPointsTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import BunPuroKit

class GrammarPointsTableViewController: UITableViewController {

    var grammarPoints: [GrammarPoint] = []
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return grammarPoints.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath)
        
        let point = grammarPoints[indexPath.row]
        
        cell.textLabel?.text = point.title
        cell.detailTextLabel?.text = point.meaning

        return cell
    }
}
