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

//протокол для пердачи адреса на new place view controller
protocol MapViewControllerDelegate {
    func getAddress(_ address: String?)
}

class MapViewController: UIViewController {
    
    //делегат класса MapViewController
    var mapViewControllerDelegate: MapViewControllerDelegate?
    
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
    let locationManager = CLLocationManager()
    let regionInMeters = 1_000.0
    var incomeSegueIdentifire = ""
    //свойстово, принимающее координаты заведения
    var placeCoordinate: CLLocationCoordinate2D?
    var directionsArray: [MKDirections] = []
    //свойство для хранения предыдущей локации пользователя
    var previousLocation:CLLocation? {
        didSet {
            startingTrackingUserLocation()
        }
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLabel.text = ""
        mapView.delegate = self
        setupMapView()
        checkLocationServices()
    }
    
    //при нажатии на кнопку mapview фокусируется на текущей геолокации
    @IBAction func centerViewInUserLocation() {
        showUserLocation()
    }
    
    @IBAction func goButtonPressed() {
        getDirections()
    }
   
    //закрываем view controller
    @IBAction func closeVC() {
        dismiss(animated: true)
    }
    
    @IBAction func doneButtonPressed() {
        mapViewControllerDelegate?.getAddress(addressLabel.text)
        //по нажатию на кнопку закрываем контроллер
        dismiss(animated: true)
    }
    

    private func setupMapView() {
        
        //видимо кнопка построения маршрута
        goButton.isHidden = true
        
        if incomeSegueIdentifire == "showPlace" {
            setupPlaceMark()
            //прячем маркер на карте
            mapPinImage.isHidden = true
            //прячем надписи и кнопкпи на экране с картой
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
    
    private func resetMapView(withNew directions: MKDirections) {
        
        //удаляем старый маршрут
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        //у каждого эл вызываем метод cancel - отменяет все маршруты, удаляет их с карты
        let _ = directionsArray.map({ $0.cancel()} )
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
            self.placeCoordinate = placemarkLocation.coordinate
            
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
            if incomeSegueIdentifire == "getAddress" { showUserLocation() }
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
    
    private func showUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    //условия, при кот сабатывает didSet previousLocation
    private func startingTrackingUserLocation() {
        
        guard let previousLocation = previousLocation else { return }
        let center = getCenterLocation(for: mapView)
        
        //рассстояние до текузего центра от предыдущ точки
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUserLocation()
        }
    }
    
    //прокладка маршрута 
    private func getDirections() {
        
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Current location is not found")
            return
        }
        
        locationManager.startUpdatingLocation()
        previousLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        //запрос на прокладку маршрута
        guard let request = createDirectionRequest(from: location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
        
        let directions = MKDirections(request: request)
        //избавляемся от старого маршрута
        resetMapView(withNew: directions)
        
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
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                //расстояние, время в пути
                let distance = String(format: "%.1f", route.distance / 1000)
                let timeInterval = route.expectedTravelTime / 60
                
                print("Расстояние до места: \(distance) км")
                print("Время в пути составит \(timeInterval) мин")
            }
        }
    }
    
    //настройка запроса на прокладку маршрута
    private func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
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
        request.transportType = .automobile
        //позволить строить несколько маршрутов, если есть альтернативные варианты
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    
    //находим центр карты (там где стоит маркер)
    private func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
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
    
    //получаем адрес по указанной отметке
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifire == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showUserLocation()
            }
        }
        
        //отмена отложенного запроса
        geocoder.cancelGeocode()
        
        //координаты преобразуем в адрес
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            //объект core location placemark
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {

                //т.к. эти переменные опциональны
                if streetName != nil && buildNumber != nil {
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        //линия для маршрута
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        //красим линию
        renderer.strokeColor = .blue
        
        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}
