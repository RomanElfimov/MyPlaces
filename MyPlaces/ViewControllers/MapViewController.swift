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
    
 
    let mapManager = MapManager()
    
    //делегат класса MapViewController
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    
    let annotationIdentifier = "annotationIdentifier"
    var incomeSegueIdentifire = ""
    
    //свойство для хранения предыдущей локации пользователя
    var previousLocation: CLLocation? {
        didSet {
            mapManager.startingTrackingUserLocation(
                for: mapView,
                and: previousLocation) { (currentLocation) in
                    
                    self.previousLocation = currentLocation
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.mapManager.showUserLocation(mapView: self.mapView)
                    }
            }
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
    }
    
    //при нажатии на кнопку mapview фокусируется на текущей геолокации
    @IBAction func centerViewInUserLocation() {
      mapManager.showUserLocation(mapView: mapView)
    }
    
    @IBAction func goButtonPressed() {
        mapManager.getDirections(for: mapView) { (location) in
                   //closure возвращает текущие координаты
                   self.previousLocation = location
               }
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
            
            //видимая кнопка построения маршрута
            goButton.isHidden = true
            
            mapManager.checkLocationServices(mapView: mapView, segueIdentifier: incomeSegueIdentifire) {
                mapManager.locationManager.delegate = self
            }
            
            if incomeSegueIdentifire == "showPlace" {
                mapManager.setupPlaceMark(place: place, mapView: mapView)
                //прячем маркер на карте
                mapPinImage.isHidden = true
                //прячем надписи и кнопкпи на экране с картой
                addressLabel.isHidden = true
                doneButton.isHidden = true
                goButton.isHidden = false
            }
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
            
            let center = mapManager.getCenterLocation(for: mapView)
            let geocoder = CLGeocoder()
            
            if incomeSegueIdentifire == "showPlace" && previousLocation != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.mapManager.showUserLocation(mapView: self.mapView)
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
            mapManager.checkLocationAuthorization(mapView: mapView,
                                                  segueIdentifier: incomeSegueIdentifire)
        }
    }

