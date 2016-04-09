//
//  ViewController.swift
//  SuperTopSecretProj
//
//  Created by Lee, Marika on 4/8/16.
//  Copyright © 2016 Lee, Marika. All rights reserved.
//

import UIKit
import GoogleMaps


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let camera = GMSCameraPosition.cameraWithLatitude(-33.86,
            longitude: 151.20, zoom: 6)
        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView.myLocationEnabled = true
        self.view = mapView
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(-33.86, 151.20)
        marker.title = "Sydney"
        marker.snippet = "Australia"
        marker.map = mapView
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

