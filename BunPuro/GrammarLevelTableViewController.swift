//
//  GrammarLevelTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import BunPuroKit

class GrammarLevelTableViewController: UITableViewController {

    var level: Int = 5
    
    private var lessons: [Lesson] = []
    
    private lazy var grammarPoints: [GrammarPoint] = {
        return Server.grammarPointResponse?.grammarPoints ?? []
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        lessons = Server.lessonResponse?.lessons.filter({ $0.level == self.level }) ?? []
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lessons.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath)

        let lesson = lessons[indexPath.row]
        
        cell.textLabel?.text = "\(indexPath.row + 1)"
        cell.detailTextLabel?.text = "\(lesson.grammarPointIds.count)"

        return cell
    }
}

extension GrammarLevelTableViewController: SegueHandler {
    
    enum SegueIdentifier: String {
        case showGrammarLevel
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showGrammarLevel:
            guard let indexPath = tableView.indexPathForSelectedRow else { fatalError("An index path is needed.") }
            
            let destination = segue.destination.content as? GrammarPointsTableViewController
            destination?.title = "\(indexPath.row + 1)"
            destination?.grammarPoints = self.grammarPoints(for: lessons[indexPath.row].grammarPointIds)
        }
    }
    
    private func grammarPoints(for ids: [String]) -> [GrammarPoint] {
        return grammarPoints.filter({ ids.contains($0.id) })
    }
}
