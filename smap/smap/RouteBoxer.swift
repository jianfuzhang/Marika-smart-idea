//
//  RouteBoxer.swift
//  smap
//
//  Created by Lee, Marika on 4/19/16.
//  Copyright © 2016 Lee, Marika. All rights reserved.
//

/*
 Translation of RouteBoxer.java to swift.
 */

import Foundation
import Darwin

public class RouteBoxer {
    
    public class LatLng {
        public var _lat: Double
        public var _lng: Double
        
        var lat : Double {
            get {
                return self._lat
            }
            
            set {
                self.lat = _lat
            }
        }
        
        var lng : Double {
            get {
                return self._lng
            }
            
            set {
                self.lng = _lng
            }
        }
        
        init() {
            _lat = 0
            _lng = 0
        }
        
        init(lat2: Double, lng2: Double) {
            _lat = lat2
            _lng = lng2
        }
        
        public func latRad() -> Double {
            return RouteBoxer().toRad(_lat)
        }
        
        public func lngRad() -> Double {
            return RouteBoxer().toRad(_lng)
        }
        
        public func rhumbDestinationPoint( brng: Double, dist: Double) -> LatLng {
            
            let R: Double = 6378137
            let d: Double = dist / R
            let lat1: Double = latRad()
            let lon1: Double = lngRad()
            let brng = RouteBoxer().toRad(brng)
            
            let dLat: Double = d*cos(brng)
            
            if abs(dLat) < 1e-10 {
                let dLat = 0
            }
            
            var lat2: Double = lat1 + dLat
            let dPhi: Double = log2(tan(lat2/2+M_PI/4)/tan(lat1/2+M_PI/4))
            let q: Double = dPhi != 0 ? dLat/dPhi : cos(lat1)
            let dLon: Double = d*sin(brng)/q
            
            if (abs(lat2) > M_PI/2) {
                lat2 = lat2 > 0 ? M_PI-lat2 : -M_PI - lat2
            }
            
            let lon2: Double = (lon1+dLon+3*M_PI) % (2*M_PI) - M_PI
            
            return LatLng.init(lat2: RouteBoxer().toDeg(lat2), lng2: RouteBoxer().toDeg(lon2))
        }
        
        public func rhumbBearingTo (dest: LatLng) -> Double {
            var dLon: Double = RouteBoxer().toRad(dest.lng - self.lng)
            let dPhi: Double = log(tan(dest.latRad()) / 2 + M_PI / 4) / tan(self.latRad() / 2 + M_PI / 4)
            
            if (abs(dLon) > M_PI) {
                dLon = dLon > 0 ? (2 * M_PI - dLon) : (2 * M_PI + dLon)
            }
            
            return RouteBoxer().toBrng(atan2(dLon, dPhi))
        }
        
        public func toString() -> String {
            return formatLatOrLong(lat) + ","+formatLatOrLong(lng)
        }
        
        public func formatLatOrLong(latOrLng: Double) -> String { //fix this
            return NSString(format: "%.6f", latOrLng) as String
        }
        
        public func toJSONArray() -> NSMutableArray { //fix
            let latLngArray = NSMutableArray()
            
            do {
                latLngArray.addObject(String(format:"%f", lat))
                latLngArray.addObject(String(format:"%f", lng))
            } catch  {
                
            }
            return latLngArray
        }
        
        public func clone() -> LatLng {
            return LatLng.init(lat2: lat, lng2: lng)
        }
        
        public func distanceFrom(otherLatLng: LatLng) -> Double {
            let b: Double = lat * M_PI / 180
            let c: Double = otherLatLng.lat * M_PI / 180
            let d: Double = b - c
            let e: Double = lng * M_PI / 180 - otherLatLng.lng * M_PI / 180
            let f: Double = 2 * asin(sqrt(pow(sin(d/2), 2) + cos(b) * cos(c) * pow(sin(e/2),2)))
            
            return f * 6378137
        }
    }
    
    public class LatLngBounds {
        private var southwest: LatLng
        private var northeast: LatLng
        
        init(southwest: LatLng, northeast: LatLng) {
            self.southwest = southwest
            self.northeast = northeast
        }
        
        public func getSouthWest() -> LatLng{
            return southwest
        }
        
        public func setSouthWest(southwest: LatLng) -> Void {
            self.southwest = southwest
        }
        
        public func getNorthEast() -> LatLng {
            return northeast
        }
        
        public func setNorthEast(northeast: LatLng) -> Void {
            self.northeast = northeast
        }
        
        public func equals(o: NSObject) -> Bool { //fix
            return true
        }
        
        public func extend(latLng: LatLng) -> Void { //fix
        }
        
        public func contains(latLng: LatLng) -> Bool {
//            if (southwest == nil || northeast == nil) { //fix
//                return false
//            }
            if (latLng.lat < southwest.lat) {
                return false;
                
            } else if (latLng.lat > northeast.lat) {
                return false
            } else if (latLng.lng < southwest.lng) {
                return false
            } else if (latLng.lng > northeast.lng) {
                return false
            }
            return true
            
        }
        
        public func getCenter() -> LatLng {
            return LatLng.init(lat2: southwest.lat + (northeast.lat - southwest.lat)/2, lng2: southwest.lng+(northeast.lng-southwest.lng)/2)
        }
        
        public func hashCode() -> Int { //fix
            return 0
        }
        
        public func toString() -> String {
            return northeast.toString()+"|"+southwest.toString()
        }
     
        //Finish from line 232 in RouteBoxer.java file//
    }
    
    /**
     * Normalize a heading in degrees to between 0 and +360
     *
     * @return {Number} Return
     * @ignore
     */
    public func toBrng(value: Double) -> Double {
        return (toDeg(value) + 360) % 360;
    }
    /**
     
     * Extend the Number object to convert radians to degrees
     *
     * @return {Number} Bearing in degrees
     * @ignore
     */
    public func toDeg(value: Double) -> Double {
        return value * 180 / M_PI
    }
    
    /**
     * Extend the Number object to convert degrees to radians
     *
     * @return {Number} Bearing in radians
     * @ignore
     */
    public func toRad(value: Double) -> Double {
        return value * M_PI / 180
    }
    
}