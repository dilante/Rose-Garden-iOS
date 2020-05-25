//
//  Task.swift
//  Rose Garden
//
//  Created by Zhelin  Cao on 5/23/20.
//  Copyright © 2020 Rose-Hulman. All rights reserved.
//

import Foundation
import Firebase

class Task {
  var name: String
  var day: Int
  var time: Int
  var id: String?
  var author: String?
  var stage : Int? = 0


  init(documentSnapshot: DocumentSnapshot) {
    self.id = documentSnapshot.documentID
    let data = documentSnapshot.data()!
    self.name = data["name"] as! String
    self.day = data["day"] as! Int
    self.time = data["time"] as! Int
    self.stage = data["stage"] as? Int
    self.author = data["author"] as? String
    
  }
}
