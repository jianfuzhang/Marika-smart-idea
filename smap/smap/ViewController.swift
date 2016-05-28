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
import Polyline
import WebKit
import JavaScriptCore


class ViewController: UIViewController {

    
    @IBOutlet var mapView: GMSMapView!
    var london: GMSMarker!
    var londonView:UIImageView!
    
    var directions = GoogleDirectionsRoute()
    var placesClient: GMSPlacesClient?
    
    var businesses: [Business]!
    
    //Mark: properties
    @IBOutlet var _originAddr: UITextField!
    @IBOutlet var _destAddr: UITextField!
    @IBOutlet var _searchBusiness: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placesClient = GMSPlacesClient()
        
        loadView()
    }
    
    func mapView(mapView: GMSMapView, idleAtCameraPosition position: GMSCameraPosition) {
        UIView.animateWithDuration(5.0, animations: { () -> Void in
            self.londonView.tintColor = UIColor.blueColor()
            }, completion: {(finished: Bool) -> Void in
                // Stop tracking view changes to allow CPU to idle.
                self.london.tracksViewChanges = false
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Back button
    func buttonAction(sender:UIButton!)
    {
        viewDidLoad()
        
    }
    
    @IBAction func setDefaultDestination(sender: UIButton) {
        
        let service = "https://maps.googleapis.com/maps/api/directions/json"
        
        let originAddr = _originAddr.text!
        let destAddr = _destAddr.text!
        
        let searchBusiness = _searchBusiness.text!
        
        let urlString = ("\(service)?origin=\(originAddr)&destination=\(destAddr)&mode=driving&units=metric&sensor=true&key=AIzaSyC-LflNZIou4Lzdk8Wg_RM-MfvaWpqVdng").stringByReplacingOccurrencesOfString(" ", withString: "+")
        
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
                    
                    let routesJson = JSON(routes)
                    let points = routesJson[0]["overview_polyline"]["points"].stringValue
                    
                    let path = GMSPath(fromEncodedPath: points)
                    
                    let camera = GMSCameraPosition.cameraWithLatitude(
                        (path?.coordinateAtIndex(0).latitude)!,
                        longitude: (path?.coordinateAtIndex(0).longitude)!,
                        zoom: 15)
                    
                    let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
                    mapView.myLocationEnabled = true
                    mapView.settings.compassButton = true
                    mapView.settings.myLocationButton = true
                    mapView.settings.indoorPicker = true

                    
                    
                    let polyline = Polyline(encodedPolyline: points)
                    let decodedCoordinates: [CLLocationCoordinate2D]? = polyline.coordinates
                    
                    var route: [LatLng] = []
                    
                    
                    for var i = 0; i < decodedCoordinates?.count; i += 1 {
                        let p: LatLng = LatLng(point:decodedCoordinates![i])
                            route.append(p)
                    }
                    
                    let RouteBoxer = RouteBoxer2()
                    let boxes: [LatLngBounds] = RouteBoxer.box(route, range: 1)
                    
                    
                    let pathBoxes = GMSMutablePath()
                    for (var i = 0; i < boxes.count; i++) {
                        let bound_northeast_lat = boxes[i].northEast.latitude
                        let bound_northeast_lng = boxes[i].northEast.longitude
                        let bound_southwest_lat = boxes[i].southWest.latitude
                        let bound_southwest_lng = boxes[i].southWest.longitude
                        
                        pathBoxes.addCoordinate(CLLocationCoordinate2D(latitude: bound_southwest_lat, longitude: bound_southwest_lng))
                        pathBoxes.addCoordinate(CLLocationCoordinate2D(latitude: bound_southwest_lat, longitude: bound_northeast_lng))
                        pathBoxes.addCoordinate(CLLocationCoordinate2D(latitude: bound_northeast_lat, longitude: bound_northeast_lng))
                        pathBoxes.addCoordinate(CLLocationCoordinate2D(latitude: bound_northeast_lat, longitude: bound_southwest_lng))
                        pathBoxes.addCoordinate(CLLocationCoordinate2D(latitude: bound_southwest_lat, longitude: bound_southwest_lng))

                        let bounds:String? = String(bound_northeast_lat)+","+String(bound_northeast_lng)+"|"+String(bound_southwest_lat)+","+String(bound_southwest_lng)
                        
                        Business.searchWithTerm(searchBusiness, bounds: bounds!, sort: nil, categories: nil, deals: nil, completion: { (businesses: [Business]!, error: NSError!) -> Void in
                            self.businesses = businesses
                            
                            for business in businesses {
                                let lat = business.lat
                                let lng = business.lng
                                let coordinate = CLLocationCoordinate2D(latitude: lat!,longitude: lng!)
                                
                                self.directions.drawMarkerWithCoordinates(UIColor.blueColor(), title: business.name!, address: business.address!, coordinates: coordinate,onMap: mapView)
                            }
                        })
                    }

                    
                    let rectangle = GMSPolyline(path: pathBoxes)
                    
                    rectangle.map = mapView
                    
                    let originAddress = routesJson[0]["legs"][0]["start_address"].stringValue
                    let destinationAddress = routesJson[0]["legs"][0]["end_address"].stringValue
                    
                    self.view = mapView
                    
                    self.directions.drawOnMap(mapView, path: path)
                    self.directions.drawOriginMarkerOnMap(UIColor.greenColor(), title: "Origin", address: originAddress, map: mapView, path: path)
                    self.directions.drawDestinationMarkerOnMap(UIColor.redColor(), title: "Destination", address: destinationAddress, map: mapView, path: path)
                    
                }
            }
            
            let button   = UIButton(type: UIButtonType.System) as UIButton
            button.frame = CGRectMake(10, 10, 50, 50)
            button.setTitle("Back", forState: UIControlState.Normal)
            button.addTarget(self, action: "buttonAction:", forControlEvents: UIControlEvents.TouchUpInside)
            
            self.view.addSubview(button)
            
        }) { (operation: AFHTTPRequestOperation!, error: NSError!)  -> Void in
            print("\(error)")
        }
        operation.start()
    }
    
    
    @IBAction func GetCurrentLocation(sender: UIButton) {
        placesClient?.currentPlaceWithCallback({
            (placeLikelihoodList: GMSPlaceLikelihoodList?, error: NSError?) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            self._originAddr.text = "No current place"
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    self._originAddr.text = place.formattedAddress!.componentsSeparatedByString(", ")
                        .joinWithSeparator("\n")
                }
            }
        })
    }
    
    var fill_which: String?
    
    @IBAction func autofill_address(sender: UITextField) {
//        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
//        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("AddressSuggestion") as! AddressSuggestion
        
//        self.presentViewController(nextViewController, animated:true, completion:nil)
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        if sender.tag == 1 {
            fill_which = "origin"
        }
        else if sender.tag == 2 {
            fill_which = "destination"
        }
        self.presentViewController(autocompleteController, animated: true, completion: nil)
        
    }
    
}

extension ViewController: GMSAutocompleteViewControllerDelegate {

    // Handle the user's selection.
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
    //    print("Place name: ", place.name)
    //    print("Place address: ", place.formattedAddress)
    //    print("Place attributions: ", place.attributions)
        if fill_which != nil{
            if fill_which! == "origin" {
                _originAddr.text = place.formattedAddress
            }
            if fill_which! == "destination" {
                _destAddr.text = place.formattedAddress
            }
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func viewController(viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        // TODO: handle the error.
        print("Error: ", error.description)
    }
    
    // User canceled the operation.
    func wasCancelled(viewController: GMSAutocompleteViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(viewController: GMSAutocompleteViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(viewController: GMSAutocompleteViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
}