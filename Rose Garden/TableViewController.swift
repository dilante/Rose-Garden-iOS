//
//  TableViewController.swift
//  Rose Garden
//
//  Created by Zhelin  Cao on 5/23/20.
//  Copyright © 2020 Rose-Hulman. All rights reserved.
//
import UIKit
import Firebase

class TableViewController: UITableViewController {
  let taskCellIdentifier = "TableCell"
  let detailSegueIdentifier = "DetailSegue"
  var taskRef: CollectionReference!
  var taskListener: ListenerRegistration!
  var authStateListenerHandle: AuthStateDidChangeListenerHandle!
  var isShowingAllTasks = true
  var tasks = [Task]()

    override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.leftBarButtonItem = editButtonItem
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "☰",
                                                           style: UIBarButtonItem.Style.plain,
                                                           target: self,
                                                           action: #selector(showMenu))
    
    taskRef = Firestore.firestore().collection("Task")
  }
    
    @objc func showMenu() {
       let alertController = UIAlertController(title: nil,
                                               message: nil,
                                               preferredStyle: .actionSheet)
       alertController.addAction(UIAlertAction(title: "Create Task",
                                               style: UIAlertAction.Style.default) { (action) in
                                                 self.showAddTaskDialog()
       })

       alertController.addAction(UIAlertAction(title: self.isShowingAllTasks ? "Show only my tasks" : "Show all tasks",
                                               style: UIAlertAction.Style.default) { (action) in
                                                 // Toggle the show all vs show mine mode.
                                                 self.isShowingAllTasks = !self.isShowingAllTasks
                                                 // Update the list
                                                 self.startListening()
       })
       alertController.addAction(UIAlertAction(title: "Sign Out",
                                               style: UIAlertAction.Style.default) { (action) in
                                                 do {
                                                   try Auth.auth().signOut()
                                                 } catch {
                                                   print("Sign out error")
                                                 }
       })

       alertController.addAction(UIAlertAction(title: "Cancel",
                                               style: .cancel,
                                               handler: nil))
       present(alertController, animated: true, completion: nil)
     }
    
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    authStateListenerHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
         if (Auth.auth().currentUser == nil) {
           print("There is no user.  Go back to the login page")
           self.navigationController?.popViewController(animated: true)
         } else {
           print("You are signed in.  Stay on this page")
         }
        }
        //tableView.reloadData()
        startListening()
  }
    
  func startListening() {
    if (taskListener != nil) {
      taskListener.remove()
    }
    var query = taskRef.order(by: "created", descending: true).limit(to: 50)
    query = query.whereField("day", isEqualTo: Auth.auth().currentUser!.uid)
    if (!isShowingAllTasks) {
        query = query.whereField("author", isEqualTo: Auth.auth().currentUser!.uid)
    }
    taskListener = query.addSnapshotListener({ (querySnapshot, error) in
      if let querySnapshot = querySnapshot {
        self.tasks.removeAll()
        querySnapshot.documents.forEach { (documentSnapshot) in
          //          print(documentSnapshot.documentID)
          //          print(documentSnapshot.data())
            self.tasks.append(Task(documentSnapshot: documentSnapshot))
        }
        self.tableView.reloadData()
      } else {
        print("Error getting tasks \(error!)")
        return
      }
    })
  }
    
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    taskListener.remove()
    Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
  }
  
  
  @objc func showAddTaskDialog() {
    let alertController = UIAlertController(title: "Create a new task",
                                            message: "",
                                            preferredStyle: .alert)
    // Configure
    alertController.addTextField { (textField) in
      textField.placeholder = "Task Name"
    }
    alertController.addTextField { (textField) in
      textField.placeholder = "Task Day"
    }
    alertController.addTextField { (textField) in
       textField.placeholder = "Task Time"
     }
    alertController.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
    alertController.addAction(UIAlertAction(title: "Create",
                                            style: UIAlertAction.Style.default) { (action) in
                                              let nameTextField = alertController.textFields![0] as UITextField
                                              let dayTextField = alertController.textFields![1] as UITextField
                                              let timeTextField = alertController.textFields![2] as UITextField
                                                
                                              self.taskRef.addDocument(data: [
                                                "name": nameTextField.text!,
                                                "day": Int(dayTextField.text!) ?? 1,
                                                "time": Int(timeTextField.text!) ?? 10,
                                                "created": Timestamp.init(),
                                                "author": Auth.auth().currentUser!.uid
                                              ])
    })
    present(alertController, animated: true, completion: nil)
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tasks.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: taskCellIdentifier, for: indexPath)
    cell.textLabel?.text = tasks[indexPath.row].name
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    let Task = tasks[indexPath.row]
    return Auth.auth().currentUser!.uid == Task.author
  }
    
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let photoBucketToDelete = tasks[indexPath.row]
      taskRef.document(photoBucketToDelete.id!).delete()
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == detailSegueIdentifier {
      if let indexPath = tableView.indexPathForSelectedRow {
        (segue.destination as! DetailViewController).taskRef = taskRef.document(tasks[indexPath.row].id!)
      }
    }
  }
}
