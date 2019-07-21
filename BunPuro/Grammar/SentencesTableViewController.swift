//
//  Created by Andreas Braun on 21.07.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import CoreData
import Protocols
import UIKit

class SentencesTableViewController: CoreDataFetchedResultsTableViewController<Sentence> {

////    var grammar: Grammar?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        setupFetchedResultsController()
//    }
//
//    private func setupFetchedResultsController() {
//        let fetchRequest: NSFetchRequest<Sentence> = Sentence.fetchRequest()
////        fetchRequest.predicate = NSPredicate
//        
//        let sort = NSSortDescriptor(key: #keyPath(Sentence.identifier), ascending: true)
//        fetchRequest.sortDescriptors = [sort]
//
//        fetchedResultsController = NSFetchedResultsController<Sentence>(
//            fetchRequest: fetchRequest,
//            managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
//            sectionNameKeyPath: nil,
//            cacheName: nil
//        )
//    }
//
//    // MARK: - Table view data source
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(for: indexPath) as DetailCell
//
//        // Configure the cell...
//
//        return cell
//    }
//
//    /*
//    // Override to support conditional editing of the table view.
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        // Return false if you do not want the specified item to be editable.
//        return true
//    }
//    */
//
//    /*
//    // Override to support editing the table view.
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            // Delete the row from the data source
//            tableView.deleteRows(at: [indexPath], with: .fade)
//        } else if editingStyle == .insert {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//        }    
//    }
//    */
//
//    /*
//    // Override to support rearranging the table view.
//    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
//
//    }
//    */
//
//    /*
//    // Override to support conditional rearranging of the table view.
//    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
//        // Return false if you do not want the item to be re-orderable.
//        return true
//    }
//    */
//
//    /*
//    // MARK: - Navigation
//
//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destination.
//        // Pass the selected object to the new view controller.
//    }
//    */
//
}
