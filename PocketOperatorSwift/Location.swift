//
//  Location.swift
//  TtSynth - Standalone Plugin
//
//  Created by Edwin Nwosu on 20/02/2024.
//

import Foundation
import CoreLocation

class UserLocationService : NSObject, CLLocationManagerDelegate
{
  var locationManager: CLLocationManager = CLLocationManager()

  public func UpdateLocation()
  {
    
    self.locationManager.requestAlwaysAuthorization()

    self.locationManager.requestWhenInUseAuthorization()

    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    
    }
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) 
  {
    guard let first = locations.first
            
    else
    {
      return
    }
    
  }
  
  public func getManager() -> CLLocationManager
  {
    return locationManager
  }
  
  public func getSpeed() -> Double
  {
    if let currentLocation = locationManager.location {
        // Get the speed in meters per second
        let speed = currentLocation.speed
        // Convert the speed to kilometers per hour
        let speedInKmPerHour = speed * 3.6
      
      return speedInKmPerHour
    }
    
    
    return 0
  }
  
  
  public func getHeading() -> Double
  {
    if let currentHeading = locationManager.heading {
        // Get the speed in meters per second
      let heading = currentHeading.magneticHeading
        // Convert the speed to kilometers per hour
      
      return heading
    }
    
    
    return 0
  }
}

