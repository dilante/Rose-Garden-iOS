//
//  TaskViewController.swift
//  Rose Garden
//
//  Created by Zhelin  Cao on 5/24/20.
//  Copyright © 2020 Rose-Hulman. All rights reserved.
//

import UIKit
import Firebase

class TaskViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    let collentionCellIdentifier = "CollectionCell"
    let tableCellIdentifier = "TableCell"
    let detailSegueIdentifier = "DetailSegue"
    var taskRef: CollectionReference!
    var taskListener: ListenerRegistration!
    var authStateListenerHandle: AuthStateDidChangeListenerHandle!
    //var isShowingAllTasks = false
    var tasks = [Task]()

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Sign Out",
        style: UIBarButtonItem.Style.plain,
        target: self,
        action: #selector(signOut))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "☰",
                                                               style: UIBarButtonItem.Style.plain,
                                                               target: self,
                                                               action: #selector(showMenu))
        taskRef = Firestore.firestore().collection("Task")
        update()
    }
    
    @objc func showMenu() {
      let alertController = UIAlertController(title: nil,
                                              message: nil,
                                              preferredStyle: .actionSheet)
      alertController.addAction(UIAlertAction(title: "Create Task",
                                              style: UIAlertAction.Style.default) { (action) in
                                                self.showAddTaskDialog()
      })

//      alertController.addAction(UIAlertAction(title: self.isShowingAllTasks ? "Show only my tasks" : "Show all tasks",
//                                              style: UIAlertAction.Style.default) { (action) in
//                                                // Toggle the show all vs show mine mode.
//                                                self.isShowingAllTasks = !self.isShowingAllTasks
//                                                // Update the list
//                                                self.startListening()
//                                                self.update()
//     })
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
    
    
    @objc func signOut(){
        do {
          try Auth.auth().signOut()
        } catch {
          print("Sign out error")
        }
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
        update()
    }
    func update(){
        for index in collectionView.indexPathsForVisibleItems{
            let cell = collectionView.cellForItem(at: index as IndexPath) as! CollectionViewCell
            cell.startListening()
        }
    }
    
    func startListening() {
      if (taskListener != nil) {
        taskListener.remove()
      }
      var query = taskRef.order(by: "created", descending: true).limit(to: 50)
     // if (!isShowingAllTasks) {
          query = query.whereField("author", isEqualTo: Auth.auth().currentUser!.uid)
      //}
      taskListener = query.addSnapshotListener({ (querySnapshot, error) in
        if let querySnapshot = querySnapshot {
          self.tasks.removeAll()
          querySnapshot.documents.forEach { (documentSnapshot) in
            //          print(documentSnapshot.documentID)
            //          print(documentSnapshot.data())
              self.tasks.append(Task(documentSnapshot: documentSnapshot))
          }
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
                                                  "stage": 0,
                                                  "created": Timestamp.init(),
                                                  "author": Auth.auth().currentUser!.uid
                                                ])
                                                self.update()
      })
      present(alertController, animated: true, completion: nil)
    
    }
    
    @IBAction func pressedAdd(_ sender: Any) {
        self.showAddTaskDialog()
    }
    
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
      override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if segue.identifier == detailSegueIdentifier {
        var id = ""
         for index in collectionView.indexPathsForVisibleItems{
                   let cell = collectionView.cellForItem(at: index as IndexPath) as! CollectionViewCell
            if(cell.getId() != nil){
                id = cell.getId()!
                    }
            
               }
    (segue.destination as! DetailViewController).taskRef = taskRef.document(id)
            
      }
    }


}

extension TaskViewController: UICollectionViewDataSource,UICollectionViewDelegate{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
    }
    
  
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collentionCellIdentifier, for: indexPath) as! CollectionViewCell
        cell.TitleLabel.text="Day \(indexPath.item+1)"
        cell.startListening(indexPath.item+1)
        return cell
    }
    
    
    
    
}
