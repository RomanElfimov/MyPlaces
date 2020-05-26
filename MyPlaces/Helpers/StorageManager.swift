//
//  StorageManager.swift
//  MyPlaces
//
//  Created by Рома on 20.02.2020.
//  Copyright © 2020 Рома. All rights reserved.
//

//Файл-менеджер для работы с базой / сохранение

import RealmSwift

let realm = try! Realm()

class StorageManager {
    
    static func saveObject(_ place: Place) {
        try! realm.write {
            realm.add(place)
        }
    }
    
    static func deleteObject(_ place: Place) {
        try! realm.write {
            realm.delete(place)
        }
    }
    
    
}
