//
//  MapManager.swift
//  MyPlaces
//
//  Created by Роман Елфимов on 28.02.2020.
//  Copyright © 2020 Рома. All rights reserved.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager()
    
    private let regionInMeters = 1_000.0
    private var directionsArray: [MKDirections] = []
    //свойстово, принимающее координаты заведения
    private var placeCoordinate: CLLocationCoordinate2D?
    
 
         //Маркер заведения
        func setupPlaceMark(place: Place, mapView: MKMapView) {
            
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
                annotation.title = place.name
                annotation.subtitle = place.type
                
                guard let placemarkLocation = placemark?.location else { return }
                //если получилось определить местоположение маркера
                annotation.coordinate = placemarkLocation.coordinate
                self.placeCoordinate = placemarkLocation.coordinate
                
                mapView.showAnnotations([annotation], animated: true)
                //добавляем аннотацию(название, тип) к маркеру
                mapView.selectAnnotation(annotation, animated: true)
            }
        }
        
        
        //Проверка доступности сервисов геолокации
        func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
            
            //если службы доступны
            if CLLocationManager.locationServicesEnabled() {
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                checkLocationAuthorization(mapView: mapView, segueIdentifier: segueIdentifier)
                //внутри closure назначаем делегата
                closure()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showAlert(title: "Location Services are Disables",
                                   message: "To enable it go: Settings -> Privacy -> Location Services and turn on")
                }
            }
        }

        
        //проверка статуса запроса на проверку пользователя
        func checkLocationAuthorization(mapView: MKMapView, segueIdentifier: String) {
            switch CLLocationManager.authorizationStatus() {
            case .authorizedWhenInUse:
                //включено во время использования
                mapView.showsUserLocation = true
                if segueIdentifier == "getAddress" { showUserLocation(mapView: mapView) }
                break
            case .denied:
                //отклонено
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showAlert(
                        title: "Your Location is not Available",
                        message: "To enable your location tracking: Settings -> MyPlaces -> Location")
                }
                break
            case .notDetermined:
                //статус не определен, просим разрешение в момент использования
                locationManager.requestWhenInUseAuthorization()
                break
            case . restricted:
                //прилложение не авторизовано для служб гелокации
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showAlert(
                        title: "Your Location is not Available",
                        message: "To enable your location tracking: Settings -> MyPlaces -> Location")
                }
                break
            case .authorizedAlways:
                //разрешено использовать геолокацию всегда
                break
            @unknown default:
                print("New case is available")
            }
        }
        
        
        // Фокус карты на местоположении пользователя
        func showUserLocation(mapView: MKMapView) {
            if let location = locationManager.location?.coordinate {
                let region = MKCoordinateRegion(center: location,
                                                latitudinalMeters: regionInMeters,
                                                longitudinalMeters: regionInMeters)
                mapView.setRegion(region, animated: true)
            }
        }
        
        //Меняем отображаемую зону области карты в соответствии с перемщением пользователя
        func startingTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
            
            guard let location = location else { return }
            let center = getCenterLocation(for: mapView)
            
            //рассстояние до текузего центра от предыдущ точки
            guard center.distance(from: location) > 50 else { return }
            
            closure(center)
            
        }
        
        //Строим маршрут от местоположения пользователя до заведения
        func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) -> ()) {
            
            guard let location = locationManager.location?.coordinate else {
                showAlert(title: "Error", message: "Current location is not found")
                return
            }
            
            locationManager.startUpdatingLocation()
            previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
            
            //запрос на прокладку маршрута
            guard let request = createDirectionRequest(from: location) else {
                showAlert(title: "Error", message: "Destination is not found")
                return
            }
            
            let directions = MKDirections(request: request)
            //избавляемся от старого маршрута
            resetMapView(withNew: directions, mapView: mapView)
            
            directions.calculate { (response, error) in
                
                if let error = error {
                    print(error)
                    return
                }
                
                guard let response = response else {
                    self.showAlert(title: "Error", message: "Direction is not available")
                    return
                }
                
                //перебор массива маршрутов
                for route in response.routes {
                    mapView.addOverlay(route.polyline)
                    mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                    
                    //расстояние, время в пути
                    let distance = String(format: "%.1f", route.distance / 1000)
                    let timeInterval = route.expectedTravelTime / 60
                    
                    print("Расстояние до места: \(distance) км")
                    print("Время в пути составит \(timeInterval) мин")
                }
            }
        }
        
        //Настройка запроса для расчета маршрута
        func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
            
            guard let destinationCoordinate = placeCoordinate else { return nil }
            //местоположение точки для начала маршрута
            let startingLocation = MKPlacemark(coordinate: coordinate)
            //точка пункта назначения
            let destination = MKPlacemark(coordinate: destinationCoordinate)
            
            //запрос на построение маршрута
            let request = MKDirections.Request()
            //указыавем начальную точку
            request.source = MKMapItem(placemark: startingLocation)
            //ук. конечную точку
            request.destination = MKMapItem(placemark: destination)
            //тип транспорта
            request.transportType = .walking
            //позволить строить несколько маршрутов, если есть альтернативные варианты
            request.requestsAlternateRoutes = true
            
            return request
        }
        
        
        //Определение центра отображаемой области карты
        func getCenterLocation(for mapView: MKMapView) -> CLLocation {
            
            let latitude = mapView.centerCoordinate.latitude
            let longitude = mapView.centerCoordinate.longitude
            
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        
        
        //Сброс всех ранее построенных маршрутов перед построением нового
        func resetMapView(withNew directions: MKDirections, mapView: MKMapView) {
            
            //удаляем старый маршрут
            mapView.removeOverlays(mapView.overlays)
            directionsArray.append(directions)
            //у каждого эл вызываем метод cancel - отменяет все маршруты, удаляет их с карты
            let _ = directionsArray.map { $0.cancel() }
            directionsArray.removeAll()
        }
        
        
        private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ок", style: .default, handler: nil)
            
            alert.addAction(okAction)
            
            //т.к. MapManager не наследуется от UIViewController, нужно создать окно
            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow.rootViewController = UIViewController()
            //позиционирование поверх других окон
            alertWindow.windowLevel = UIWindow.Level.alert + 1
            alertWindow.makeKeyAndVisible()
            alertWindow.rootViewController?.present(alert, animated: true)
        }
        
        
    }
