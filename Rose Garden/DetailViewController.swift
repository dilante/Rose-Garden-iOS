//
//  DetailViewController.swift
//  Rose Garden
//
//  Created by Zhelin  Cao on 5/23/20.
//  Copyright © 2020 Rose-Hulman. All rights reserved.
//

import UIKit
import Firebase

class DetailViewController: UIViewController {

   
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    var task: Task?
    var taskRef: DocumentReference!
    var taskListener: ListenerRegistration!
    
    
  override func viewDidLoad() {
    super.viewDidLoad()
//    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.edit,
//                                                        target: self,
//                                                        action: #selector(showEditDialog))

    }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    //updateView()
    taskListener = taskRef.addSnapshotListener { (documentSnapshot, error) in
      if let error = error {
        print("Error getting task \(error)")
        return
      }
      if !documentSnapshot!.exists {
        print("Might go back to the list since someone else deleted this document.")
        return
      }
      self.task = Task(documentSnapshot: documentSnapshot!)
      // Decide if we can edit or not!
        if (Auth.auth().currentUser!.uid == self.task?.author) {
          self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.edit,
                                                              target: self,
                                                              action: #selector(self.showEditDialog))
        } else {
          self.navigationItem.rightBarButtonItem = nil
        }
        self.updateView()
      }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    taskListener.remove()
  }

  @objc func showEditDialog() {
        let alertController = UIAlertController(title: "Task Name",
                                                message: "",
                                                preferredStyle: .alert)

       // Configure
       alertController.addTextField { (textField) in
         textField.placeholder = "Task Name"
         textField.text = self.task?.name
       }
       alertController.addTextField { (textField) in
         textField.placeholder = "Task Day"
         textField.text = String(self.task!.day)
       }
       alertController.addTextField { (textField) in
          textField.placeholder = "Task Time"
          textField.text = String(self.task!.time)
        }
        alertController.addAction(UIAlertAction(title: "Cancel",
                                                style: .cancel,
                                                handler: nil))
        alertController.addAction(UIAlertAction(title: "Update",
                                                style: UIAlertAction.Style.default) { (action) in
                                                  let nameTextField = alertController.textFields![0] as UITextField
                                                  let dayTextField = alertController.textFields![1] as UITextField
                                                  let timeTextField = alertController.textFields![2] as UITextField
                                                  self.taskRef.updateData([
                                                    "name": nameTextField.text!,
                                                    "day": Int(dayTextField.text!) ?? 1,
                                                    "time": Int(timeTextField.text!) ?? 10
                                                  ])
        })
        present(alertController, animated: true, completion: nil)
  }


  func updateView() {
    nameLabel.text = task?.name
    timeLabel.text = "\(task!.time) Mins"
  }
}

