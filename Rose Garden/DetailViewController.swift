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
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    
    var task: Task?
    var taskRef: DocumentReference!
    var taskListener: ListenerRegistration!
    var time = 0
    var remain = 0
    var timer = Timer()
    var isStart = false
    
  override func viewDidLoad() {
    super.viewDidLoad()


    }
    @IBAction func pressedStart(_ sender: Any) {
        self.taskRef.updateData([
          "stage": 1
        ])
        updateView()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(action), userInfo: nil, repeats: true)
        
        
    }
    
    @IBAction func pressedDone(_ sender: Any) {
    self.taskRef.updateData([
      "stage": 2
    ])
       self.task?.stage = 2
        timer.invalidate()
        updateView()
    }
    
    @objc func action()
    {
        time += 1
        progressBar.progress = Float(time)/Float(self.task!.time*60)
        remain -= 1
        timeLabel.text = "\(Int(remain/60)) min \(remain%60) sec"
        if(remain == 0 ){
            self.taskRef.updateData([
              "stage": 2
            ])
               self.task?.stage = 2
                timer.invalidate()
                updateView()
            
        }
    }
    
    func updateStage(){
        switch (self.task?.stage){
        case 0:
             self.doneButton.isEnabled = false
             self.progressBar.isHidden = true
            self.startButton.isEnabled = true
        case 1:
            self.doneButton.isEnabled = true
            self.progressBar.isHidden = false
            self.startButton.isEnabled = false
        case 2:
            self.doneButton.isEnabled = false
             self.progressBar.isHidden = false
            self.startButton.isEnabled = true
            self.progressBar.progress = 1
            self.startButton.setTitle("Redo", for: .normal)
        default:
            self.doneButton.isEnabled = false
        }
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
          self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "☰",
          style: UIBarButtonItem.Style.plain,
          target: self,
          action: #selector(self.showMenu))
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
    @objc func showMenu() {
      let alertController = UIAlertController(title: nil,
                                              message: nil,
                                              preferredStyle: .actionSheet)
      alertController.addAction(UIAlertAction(title: "Edit Task",
                                              style: UIAlertAction.Style.default) { (action) in
                                                self.showEditDialog()
      })

      alertController.addAction(UIAlertAction(title: "Delete",
                                              style: UIAlertAction.Style.default) { (action) in
                                                self.taskRef.delete()
                                                self.navigationController?.popViewController(animated: true)
      })

      alertController.addAction(UIAlertAction(title: "Cancel",
                                              style: .cancel,
                                              handler: nil))
      present(alertController, animated: true, completion: nil)
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
    updateStage()
    remain = task!.time*60
    time = 0
  }
}

