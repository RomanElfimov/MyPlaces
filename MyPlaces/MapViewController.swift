//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Роман Елфимов on 26.02.2020.
//  Copyright © 2020 Рома. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    var place: Place!
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlaceMark()
    }
    
    //закрываем view controller
    @IBAction func closeVC() {
        dismiss(animated: true)
    }
    
    //маркер на карте
    private func setupPlaceMark() {
       
        //извлекаем адрес
        guard let location = place.location else { return }
        
        //класс преобразует широту и долготу в удобный вид - название города и т.д. и наоборот
        let geocoder = CLGeocoder()
        //позволяет определить местоположение по переданному адресу
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            
            if let error = error {
                //если содержит ошибку
                print(error)
                return
            }
            
            //если ошибки нет - массив меток
            guard let placemarks = placemarks else { return }
            //получаем метку на карте
            let placemark = placemarks.first
            //описываем точку на карте
            let annotation = MKPointAnnotation()
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            guard let placemarkLocation = placemark?.location else { return }
            //если получилось определить местоположение маркера
            annotation.coordinate = placemarkLocation.coordinate
            
            self.mapView.showAnnotations([annotation], animated: true)
            //добавляем аннотацию(название, тип) к маркеру
            self.mapView.selectAnnotation(annotation, animated: true)
            
            
        }
        
    }
}

//MKMapViewDelegate - позволяет более расширенно работать с аннотациями - доб. картинку
extension MapViewController: MKMapViewDelegate {
    
}
