//
//  KanjiTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 19.02.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

class KanjiTableViewController: UITableViewController {

    var japanese: String?
    var english: String?
    var furigana = [Furigana]()
    
    var showEnglish: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 2 // Japanese and English Translation
        }
        
        return furigana.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(for: indexPath)
        
        if indexPath.section == 0 {
            
            if indexPath.row == 0 {
                
                cell.textLabel?.attributedText = japanese?.htmlAttributedString(font: cell.textLabel?.font)
            } else {
                cell.textLabel?.text = showEnglish ? english : NSLocalizedString("kanji.english.show", comment: "")
                cell.textLabel?.textColor = showEnglish ? UIColor.black : view.tintColor
            }
        } else {
            let info = furigana[indexPath.row]
            
            cell.textLabel?.text = "\(info.original)（\(info.text)）"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return NSLocalizedString("kanji.header.readings", comment: "")
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0, indexPath.row > 0 {
            
            showEnglish = !showEnglish
            
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}
