//
//  ViewController.swift
//  smap
//
//  Created by Lee, Marika on 4/9/16.
//  Copyright © 2016 Lee, Marika. All rights reserved.
//

import UIKit
import SwiftyJSON
import AFNetworking
import GoogleMaps

class ViewController: UIViewController {
    
    var businesses: [Business]!
    var directions = GoogleDirectionsRoute()
    
    //Mark: properties
    
    
    @IBOutlet var _originLat: UITextField!
    @IBOutlet var _originLong: UITextField!
    @IBOutlet var _destLat: UITextField!
    @IBOutlet var _destLong: UITextField!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //        Business.searchWithTerm("Thai", completion: { (businesses: [Business]!, error: NSError!) -> Void in
        //            self.businesses = businesses
        //
        //            for business in businesses {
        //                print(business.name!)
        //                print(business.address!)
        //            }
        //        })
        //
        //
        //        let camera = GMSCameraPosition.cameraWithLatitude(-33.86,
        //            longitude: 151.20, zoom: 6)
        //        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        //        mapView.myLocationEnabled = true
        //        self.view = mapView
        //
        //        let marker = GMSMarker()
        //        marker.position = CLLocationCoordinate2DMake(-33.86, 151.20)
        //        marker.title = "Sydney"
        //        marker.snippet = "Australia"
        //        marker.map = mapView
        //
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func setDefaultDestination(sender: UIButton) {
        
        
        let service = "https://maps.googleapis.com/maps/api/directions/json"

        let originLat = _originLat.text!
        let originLong = _originLong.text!
        
        let destLat = _destLat.text!
        let destLong = _destLong.text!
        
        let urlString = "\(service)?origin=\(originLat),\(originLong)&destination=\(destLat),\(destLong)&mode=driving&units=metric&sensor=true&key=AIzaSyC-LflNZIou4Lzdk8Wg_RM-MfvaWpqVdng"
        
        
        let directionsURL = NSURL(string: urlString)
        
        let request = NSMutableURLRequest(URL: directionsURL!)
        
        request.HTTPMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let operation = AFHTTPRequestOperation(request: request)
        operation.responseSerializer = AFJSONResponseSerializer()
        
        operation.setCompletionBlockWithSuccess({ (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            
            if let result = responseObject as? NSDictionary {
                if let routes = result["routes"] as? [NSDictionary] {
                    if let lines = routes[0]["overview_polyline"] as? NSDictionary {
                        if let points = lines["points"] as? String {
                            let path = GMSPath(fromEncodedPath: points)
                            let distance = GMSGeometryLength(path!)
                            
                            let camera = GMSCameraPosition.cameraWithLatitude(Double(originLat)!, longitude: Double(originLong)!, zoom: 15)
                            
                            let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
                            mapView.myLocationEnabled = true
                            self.view = mapView
                            
                            self.directions.drawOnMap(mapView, path: path)
                            self.directions.drawOriginMarkerOnMap(mapView, path: path)
                            self.directions.drawDestinationMarkerOnMap(mapView, path: path)
                            
                            print("wow \(distance / 1000) KM")
                            
                        }
                    }
                    
                }
            }
            }) { (operation: AFHTTPRequestOperation!, error: NSError!)  -> Void in
                print("\(error)")
        }
        
        operation.start()
        
        
    }
   }