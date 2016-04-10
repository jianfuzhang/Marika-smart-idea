//
//  ViewController.swift
//  smap
//
//  Created by Lee, Marika on 4/9/16.
//  Copyright © 2016 Lee, Marika. All rights reserved.
//

import UIKit
import GoogleMaps
import SwiftyJSON

class ViewController: UIViewController {
    var businesses: [Business]!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        Business.searchWithTerm("Thai", completion: { (businesses: [Business]!, error: NSError!) -> Void in
            self.businesses = businesses
            
            for business in businesses {
                print(business.name!)
                print(business.address!)
            }
        })
        
        //        super.viewDidLoad()
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
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

