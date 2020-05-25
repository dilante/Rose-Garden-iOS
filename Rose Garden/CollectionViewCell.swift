//
//  CollectionViewCell.swift
//  Rose Garden
//
//  Created by Zhelin  Cao on 5/24/20.
//  Copyright © 2020 Rose-Hulman. All rights reserved.
//

import UIKit
import Firebase

class CollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var TitleLabel: UILabel!
    let taskCellIdentifier = "TableCell"
    let detailSegueIdentifier = "DetailSegue"
    var taskRef: CollectionReference!
    var taskListener: ListenerRegistration!
    var authStateListenerHandle: AuthStateDidChangeListenerHandle!
    var isShowingAllTasks = true
    var tasks = [Task]()
    var defaultIndex: Int  = 0
    let tableCellIdentifier = "TableCell"
    
    @IBOutlet weak var TableView: UITableView!

    

    

    override func awakeFromNib() {
        super.awakeFromNib()
        TableView.delegate = self
        TableView.dataSource = self
        taskRef = Firestore.firestore().collection("Task")
    }
    
    
    func startListening(_ index:Int = 0) {
        var dayNum = index
        if (dayNum != 0) {
            self.defaultIndex = dayNum
        }else{
            dayNum = self.defaultIndex
        }
        if (taskListener != nil) {
          taskListener.remove()
        }
        var query = taskRef.order(by: "created", descending: true).limit(to: 50)
         query = query.whereField("day", isEqualTo: dayNum)
        if (!isShowingAllTasks) {
            query = query.whereField("author", isEqualTo: Auth.auth().currentUser!.uid)
        }
        taskListener = query.addSnapshotListener({ (querySnapshot, error) in
          if let querySnapshot = querySnapshot {
            self.tasks.removeAll()
            querySnapshot.documents.forEach { (documentSnapshot) in
                self.tasks.append(Task(documentSnapshot: documentSnapshot))
            }
            self.TableView.reloadData()
          } else {
            print("Error getting tasks \(error!)")
            return
          }
        })
      }
    
    override func prepareForReuse() {
        self.tasks.removeAll()
        TableView.reloadData()
    }
    
    func getId() -> String? {
        if let indexPath = TableView.indexPathForSelectedRow{
            let cell = TableView.cellForRow(at: indexPath)!
            cell.isSelected = false
            return tasks[indexPath.row].id!
        }
        return nil
    }
    
}
extension CollectionViewCell:  UITableViewDelegate,UITableViewDataSource{
    

    func viewWillDisappear(_ animated: Bool) {
      
      taskListener.remove()
      Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return tasks.count
     }
     
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = tableView.dequeueReusableCell(withIdentifier: taskCellIdentifier, for: indexPath)
       cell.textLabel?.text = tasks[indexPath.row].name
       return cell
     }
     
     func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
       let Task = tasks[indexPath.row]
       return Auth.auth().currentUser!.uid == Task.author
     }
       
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
       if editingStyle == .delete {
         let photoBucketToDelete = tasks[indexPath.row]
         taskRef.document(photoBucketToDelete.id!).delete()
       }
     }
  
    

    
}
