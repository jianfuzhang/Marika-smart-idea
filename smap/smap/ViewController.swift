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
    
    @IBOutlet var _originAddr: UITextField!
    @IBOutlet var _destAddr: UITextField!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func setDefaultDestination(sender: UIButton) {
        
        let service = "https://maps.googleapis.com/maps/api/directions/json"
        
        let originAddr = _originAddr.text!
        let destAddr = _destAddr.text!
        
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=800_Concar+Ave+San+Mateo,+CA&destination=1622+Palm+Ave+San+Mateo,+CA&key=AIzaSyC-LflNZIou4Lzdk8Wg_RM-MfvaWpqVdng"
        
        //      let urlString = "\(service)?origin=\(originAddr)&destination=\(destAddr)&mode=driving&units=metric&sensor=true&key=AIzaSyC-LflNZIou4Lzdk8Wg_RM-MfvaWpqVdng"
        
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
                    
                    let origin = routes[0]["bounds"]!["northeast"] as? NSDictionary
                    
                    let originLat = origin!["lat"] as? Double
                    let originLong = origin!["lng"] as? Double
                    
                    
                    if let lines = routes[0]["overview_polyline"] as? NSDictionary {
                        if let points = lines["points"] as? String {
                            
                            let path = GMSPath(fromEncodedPath: points)
                            let distance = GMSGeometryLength(path!)
                            
                            let camera = GMSCameraPosition.cameraWithLatitude(originLat!, longitude: originLong!, zoom: 15)
                            
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