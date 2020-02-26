//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Роман Елфимов on 26.02.2020.
//  Copyright © 2020 Рома. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
    let locationManager = CLLocationManager()
    let regionInMeters = 10_000.0
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        setupPlaceMark()
        checkLocationServices()
    }
    
    //при нажатии на кнопку mapview фокусируется на текущей геолокации
    @IBAction func centerViewInUserLocation() {
        
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
        
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
    
    //проверяем, включены ли службы геолокации
    private func checkLocationServices() {
        
        //если службы доступны
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Location Services are Disables",
                               message: "To enable it go: Settings -> Privacy -> Location Services and turn on")
            }
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        //определяем точное местоположение пользователя
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    //проверка статуса запроса на проверку пользователя
    private func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            //включено во время использования
            mapView.showsUserLocation = true
            break
        case .denied:
            //отклонено
            //alert
            break
        case .notDetermined:
            //статус не определен, просим разрешение в момент использования
            locationManager.requestWhenInUseAuthorization()
            break
        case . restricted:
            //прилложение не авторизовано для служб гелокации
            //alert
            break
        case .authorizedAlways:
            //разрешено использовать геолокацию всегда
            break
        @unknown default:
            print("New case is available")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ок", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

//MKMapViewDelegate - позволяет более расширенно работать с аннотациями - доб. картинку
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        //если аннотация не является текущей локацией пользователя
        guard !(annotation is MKUserLocation) else { return nil}
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView
        //если на карте нет ни одного представления с анотацией, которое можно переиспользовать
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            //для отображения аннотации в виде баннера
            annotationView?.canShowCallout = true
        }
        
        //картинка для баннера
        if let imageData = place.imageData {
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            
            //помещаем картинку справа на баннере
            annotationView?.rightCalloutAccessoryView = imageView
        }
        
        return annotationView
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}
