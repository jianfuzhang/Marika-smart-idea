//
//  GoogleDirectionsRoute.swift
//  smap
//
//  Created by Lee, Marika on 4/11/16.
//  Copyright © 2016 Lee, Marika. All rights reserved.
//

import Foundation
import GoogleMaps


//A route computed by the Google Directions API, following a directions request
public class GoogleDirectionsRoute: NSObject {
    
    
    //Draw line from origin to destination
    public func drawOnMap(mapView: GMSMapView, path: GMSPath!) -> GMSPolyline? {
        let polyline: GMSPolyline? = nil
        if let p = path {
            let polyline = GMSPolyline(path: p)
            polyline.map = mapView
        }
        return polyline
    }
    
    //Draw origin marker
    public func drawOriginMarkerOnMap(color: UIColor, title: String, map: GMSMapView, path: GMSPath!) -> GMSMarker? {
        var marker: GMSMarker?
        if let p = path {
            if p.count() > 1 {
                marker = drawMarkerWithCoordinates(color, title: title, coordinates: p.coordinateAtIndex(0), onMap: map)
            }
        }
        return marker
    }
    
    //Draw destination marker
    public func drawDestinationMarkerOnMap(color: UIColor, title: String, map: GMSMapView, path: GMSPath!) -> GMSMarker? {
        var marker: GMSMarker?
        if let p = path {
            if p.count() > 1 {
                marker = drawMarkerWithCoordinates(color, title: title, coordinates: p.coordinateAtIndex(p.count() - 1), onMap: map)
            }
        }
        return marker
    }
    
    //Draw marker helper
    public func drawMarkerWithCoordinates(color: UIColor, title: String, coordinates: CLLocationCoordinate2D, onMap map: GMSMapView) -> GMSMarker {
        let marker = GMSMarker(position: coordinates)
        marker.title = title
        marker.map = map
        marker.icon = GMSMarker.markerImageWithColor(color)
        return marker
    }
    
}