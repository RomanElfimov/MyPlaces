//
//  MainViewController.swift
//  MyPlaces
//
//  Created by Рома on 19.02.2020.
//  Copyright © 2020 Рома. All rights reserved.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    //коллекция Results (default для Realm) с типом Place
    private var places: Results<Place>!
    //массив для отфильтрованных записей
    private var filteredPlaces: Results<Place>!
    //сортировка по возрастанию
    private var ascendingSorting = true
    //строка поиска путая или нет
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var reversedSortingButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        places = realm.objects(Place.self)
        
        //Setup the search controller
        searchController.searchResultsUpdater = self
        //позволяем контроллеру взаимодействовать с отображаемым контентом
        searchController.obscuresBackgroundDuringPresentation = false
        //название для строки поиска
        searchController.searchBar.placeholder = "Search"
        //строка поиска интегрирована в navigation bar
        navigationItem.searchController = searchController
        //отпустить строку поиска при переходе на другой экран
        definesPresentationContext = true
        
        navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    

    // MARK: - Table view data source

     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredPlaces.count
        }
        return places.count
    }

    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell

        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]

        cell.nameLabel.text = place.name
        cell.lacationLabel.text = place.location
        cell.typeLabel.text = place.type
        //тарелка по дефолту
        cell.imageOfPlace.image = UIImage(data: place.imageData!)
    
        //cell.rateControl.
        cell.rateControl.rating = Int(place.rating)
        

        return cell
    }
    
    //MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let place = places[indexPath.row]
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (_, _) in
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
        }
        return [deleteAction]
    }
    

    
    // MARK: - Navigation
    //передачва данных на detail view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            
            let place = isFiltering ? filteredPlaces[indexPath.row] : places [indexPath.row]
            
            let newPlaceVC = segue.destination as! NewPlaceViewController
            newPlaceVC.currentPlace = place
        }
    
    }
    
    
    @IBAction func unwindSegue(_ segue:  UIStoryboardSegue) {
        
        guard let newPlaceVC = segue.source as? NewPlaceViewController else { return }
        
        newPlaceVC.savePlace()
        
        tableView.reloadData()
    }
    
    // Segmented Control
    @IBAction func sotrSelection(_ sender: UISegmentedControl) {
        sorting()
    }
    
    @IBAction func reversedSorting(_ sender: Any) {
        
        //меняем значение на противополжное - toggle()
        ascendingSorting.toggle()
        
        //меняем картинку на кнопке
        if ascendingSorting {
            reversedSortingButton.image = #imageLiteral(resourceName: "AZ")
        } else {
            reversedSortingButton.image = #imageLiteral(resourceName: "ZA")
        }
        
        sorting()
    }
    
    //метод для сортировки
    private func sorting() {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            places = places.sorted(byKeyPath: "date", ascending: ascendingSorting)
        } else {
            places = places.sorted(byKeyPath: "name", ascending: ascendingSorting)
        }
        
        tableView.reloadData()
    }
    
    

}


extension MainViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        //будем производить поиск по поялм name и location, фильтровать данные по значению из параметра searchText вне зависимости от регистра
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText)
        
        tableView.reloadData()
    }
    
    
}
