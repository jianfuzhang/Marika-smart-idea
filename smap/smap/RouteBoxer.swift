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
    
    final let EarthRadiusKm: Int = 6371
    
    public class LatLng {
        public var lat: Double
        public var lng: Double
        
        var _lat : Double {
            get {
                return self.lat
            }
            
            set {
                self.lat = _lat
            }
        }
        
        var _lng : Double {
            get {
                return self.lng
            }
            
            set {
                self.lng = _lng
            }
        }
        
        init() {
            lat = 0
            lng = 0
        }
        
        init(lat2: Double, lng2: Double) {
            lat = lat2
            lng = lng2
        }
        
        public func latRad() -> Double {
            return RouteBoxer().toRad(lat)
        }
        
        public func lngRad() -> Double {
            return RouteBoxer().toRad(lng)
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
            let q: Double = (dPhi != 0) ? dLat/dPhi : cos(lat1)
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
        private var southwest: LatLng?
        private var northeast: LatLng?
        
        init(){
        }
        
        init(southwest: LatLng, northeast: LatLng) {
            self.southwest = southwest
            self.northeast = northeast
        }
        
        public func getSouthWest() -> LatLng{
            return southwest!
        }
        
        public func setSouthWest(southwest: LatLng) -> Void {
            self.southwest! = southwest
        }
        
        public func getNorthEast() -> LatLng {
            return northeast!
        }
        
        public func setNorthEast(northeast: LatLng) -> Void {
            self.northeast = northeast
        }
        
//        public func equals(o: NSObject) -> Bool {
//            if self == o {
//                return true
//            }
//            if o == nil || getClass()
//        }
        
        public func extend(latLng: LatLng) -> Void {
            if southwest == nil {
                southwest = latLng.clone()
                
                if northeast == nil {
                    northeast = latLng.clone()
                    return
                }
            }
            if northeast == nil {
                northeast = latLng.clone()
                return
            }
            
            if latLng.lat < southwest?.lat {
                southwest!.lat = latLng.lat
            } else if (latLng.lat > northeast!.lat) {
                northeast!.lat = latLng.lat
            }
            if (latLng.lng < southwest!.lng) {
                southwest!.lng = latLng.lng
            }
            else if (latLng.lng>northeast!.lng) {
                northeast!.lng=latLng.lng
            }
        }
        
        public func contains(latLng: LatLng) -> Bool {
            if (southwest == nil || northeast == nil) { //fix
                return false
            }
            if (latLng.lat < southwest!.lat) {
                return false;
                
            } else if (latLng.lat > northeast!.lat) {
                return false
            } else if (latLng.lng < southwest!.lng) {
                return false
            } else if (latLng.lng > northeast!.lng) {
                return false
            }
            return true
            
        }
        
        public func getCenter() -> LatLng {
            let a: Double = southwest!.lat+(northeast!.lat-southwest!.lat)/2
            let b: Double = southwest!.lng+(northeast!.lng-southwest!.lng)/2
            return LatLng.init(lat2: a, lng2: b)

        }
        
        public func hashCode() -> Int { //fix
            //let result: Int = southwest != null ? southwest.hash
            return 0
        }
        
        public func toString() -> String {
            return northeast!.toString()+"|"+southwest!.toString()
        }
    }
    
    private var grid_:[[Int]] = [[]]
    private var latGrid_: [Double] = []
    private var lngGrid_: [Double] = []
    private var boxesX_: [LatLngBounds] = []
    private var boxesY_: [LatLngBounds] = []
    
    
    public func decodePath(encodedPoints: String) -> [LatLng] {
        var poly: [LatLng]? = nil
        var index: Int = 0
        let len: Int = encodedPoints.characters.count
        let lat: Int = 0
        let lng: Int = 0
        
        while (index < len) {
            let b: Int = 0
            let shift: Int = 0
            let result: Int = 0
            
            repeat {
                let b = Int(Array(arrayLiteral: encodedPoints)[index++])! - 63
                let result: Int = (b & 0x1f) << shift
                let shift = shift + 5
                
            } while (b >= 0x20)
            
            
            let dlat: Int = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            let lat = lat + dlat
            
            repeat {
                let b = Int(Array(arrayLiteral: encodedPoints)[index++])! - 63
                let result: Int = (b & 0x1f) << shift;
                let shift = shift + 5;
            } while (b >= 0x20)
            let dlng: Int = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            let lng = lng + dlng
            let p: LatLng = LatLng.init(lat2: Double(lat)/1E5, lng2: Double(lng)/1E5)
            poly!.append(p)
        }
        
        return poly!
    }
    
    public func box(path: [LatLng], range: Double) -> [LatLngBounds] {
        self.grid_ = [[]]
        self.latGrid_ = []
        self.lngGrid_ = []
        self.boxesX_ = []
        self.boxesY_ = []
        let vertices: [LatLng] = path
        
        buildGrid_(vertices, range: range)
        findIntersectingCells_(vertices)
        mergeIntersectingCells_()
        
        let t: [RouteBoxer.LatLngBounds] = self.boxesX_.count <= self.boxesY_.count ? self.boxesX_ : self.boxesY_
        
        return t
        
    }
    
    public func buildGrid_(vertices: [LatLng], range: Double) -> Void{
        let routeBounds: RouteBoxer.LatLngBounds = RouteBoxer.LatLngBounds()
        
        
        for var i=0; i<vertices.count; i++ {
            routeBounds.extend(vertices[i])
        }
        
        let routeBoundsCenter: LatLng = routeBounds.getCenter()

        latGrid_.append(routeBoundsCenter.lat)
        let rhumb: LatLng = routeBoundsCenter.rhumbDestinationPoint(0, dist: range)
        
        latGrid_.append(rhumb.lat)
        

        for (var i = 2; latGrid_[i-2] < routeBounds.getNorthEast().lat; i += 1) {
            latGrid_.append(routeBoundsCenter.rhumbDestinationPoint(0, dist: range * Double(i)).lat);
        }
        
        for var i1 = 2; latGrid_[i1-2] < routeBounds.getNorthEast().lat; i1 += 1 {
            latGrid_.append(routeBoundsCenter.rhumbDestinationPoint(270, dist: range * Double(i1)).lng)
        }
        
        lngGrid_.append(routeBoundsCenter.lng)
        lngGrid_.append(routeBoundsCenter.rhumbDestinationPoint(90, dist: range).lng)
        
        for var i2 = 2; lngGrid_[i2 - 2] < routeBounds.getNorthEast().lng; i2++ {
            lngGrid_.append(routeBoundsCenter.rhumbDestinationPoint(90, dist: range * Double(i2)).lng);
        }
   
        for var i3 = 1; lngGrid_[1] > routeBounds.getSouthWest().lng; i3 += 1 {
            lngGrid_.insert(routeBoundsCenter.rhumbDestinationPoint(270, dist: range * Double(i3)).lng, atIndex: 0)
        }
    
        var rows = lngGrid_.count, cols = latGrid_.count

        //TODO: did a fix around. fix later
        for var i=0; i<cols+1; i++ {
                self.grid_.insert([Int](count: rows, repeatedValue:Int()), atIndex: i)
         }
        self.grid_.removeAtIndex(cols+1)
    }
    
    private func mergeIntersectingCells_() -> Void {
        let x: Int
        let y: Int
        
        let box: LatLngBounds
        
        var currentBox: RouteBoxer.LatLngBounds? = nil
        
        
        //traverse the grid a row at a time
        for var y = 0; y < self.grid_[0].count; y+=1 {
            for var x = 0; x < self.grid_.count; x+=1 {
                if (self.grid_[x][y]==1) {
                    let cell: [Int] = [x,y]
                    let box = self.getCellBounds_(cell)
                    
                    if currentBox != nil {
                        currentBox!.extend(box.getNorthEast())
                    } else {
                        currentBox = box
                    }
                }
                else {
                    self.mergeBoxesY_(currentBox)
                    currentBox = nil
                }
            }
            self.mergeBoxesY_(currentBox)
            currentBox = nil
        }
        
        //traverse the grid a column at a time
        for var x = 0; x < self.grid_[0].count; x+=1 {
            for var y = 0; y < self.grid_[0].count; y+=1 {
                if (self.grid_[x][y] == 1) {
                    let cell: [Int] = [x,y]
                    if (currentBox != nil) {
                        let box = self.getCellBounds_(cell)
                        currentBox?.extend(box.getNorthEast())
                    } else {
                        currentBox = self.getCellBounds_(cell)
                    }
                } else {
                    self.mergeBoxesX_(currentBox)
                    currentBox = nil
                }
            }
            self.mergeBoxesX_(currentBox)
            currentBox = nil

      }
    }
    
    public func mergeBoxesX_(box: LatLngBounds?) -> Void {
        if (box != nil) {
            for var i = 1; i<self.boxesX_.count; i++ {
                if (abs(self.boxesX_[i].getNorthEast().lng - box!.getSouthWest().lng)<0.001 &&
                    abs(self.boxesX_[i].getSouthWest().lat - box!.getSouthWest().lat)<0.001 &&
                    abs(self.boxesX_[i].getNorthEast().lat - box!.getNorthEast().lat)<0.001) {
                    self.boxesX_[i].extend(box!.getNorthEast());
                    return;
                }
                
            }
            self.boxesX_.append(box!)
        }
    }
    public func mergeBoxesY_(box: LatLngBounds?) -> Void {
        if (box != nil) {
            for var i = 0; i < self.boxesY_.count; i+=1 {
                if (abs(self.boxesY_[i].getNorthEast().lat - (box?.getSouthWest().lat)!) < 0.001 && abs(self.boxesY_[i].getSouthWest().lng) < 0.001 && abs(self.boxesY_[i].getNorthEast().lng - (box?.getNorthEast().lng)!) < 0.001) {
                    self.boxesY_[i].extend((box?.getNorthEast())!)
                    return
                }
            }
            self.boxesY_.append(box!)
        }
    }
    
    func getCellBounds_(cell: [Int]) -> LatLngBounds {
        return LatLngBounds.init(southwest: LatLng.init(lat2: self.latGrid_[cell[1]], lng2: self.lngGrid_[cell[0]]), northeast: LatLng.init(lat2: self.latGrid_[cell[1]+1], lng2: self.lngGrid_[cell[0]+1]))
    }
    
    private func getGridCoordsFromHint_(latlng: LatLng, hintlatlng: LatLng, hint: [Int]) -> [Int]{
        let x: Int = 0
        let y: Int = 0
        
        var xCount: Int = 0
        var yCount: Int = 0
        
        //try {
        if (latlng.lng > hintlatlng.lng) {
            for var x = hint[0]; self.lngGrid_[x+1] < latlng.lng; x += 1 {
                xCount++
            }
        } else {
            for var x = hint[0]; self.lngGrid_[x] > latlng.lng; x -= 1 {
                xCount++
            }
        }
        
        if (latlng.lat > hintlatlng.lat) {
            for var y = hint[1]; self.latGrid_[y+1] < latlng.lat; y += 1 {
                yCount++
            }
        } else {
            for var y = hint[1]; self.latGrid_[y] > latlng.lat; y -= 1 {
                yCount++
            }
        }
        //}catch ()
        let result: [Int] = [xCount, yCount]
        return result
    }
    
    private func findIntersectingCells_(vertices: [LatLng]) {
        let hintXY: [Int] = getCellCoords_(vertices[0])
        markCell_(hintXY)
        
        //fix: supposed to just be vertices.count
        for var i = 1; i < vertices.count-1; i++ {
            let gridXY: [Int] = getGridCoordsFromHint_(vertices[i], hintlatlng: vertices[i-1], hint: hintXY)
            
            if (gridXY[0] == hintXY[0] && gridXY[1] == hintXY[1]) {
                continue
            } else if ((abs(hintXY[0] - gridXY[0]) == 1 && hintXY[1] == gridXY[1]) || hintXY[0] == gridXY[0] &&  abs(hintXY[1] - gridXY[1]) == 1) {
               self.markCell_(gridXY)
            } else {
                self.getGridIntersects_(vertices[i - 1], end: vertices[i], startXY: hintXY, endXY: gridXY)
            }
            let hintXY = gridXY;
        }
    }
    
    private func getGridIntersects_(start: LatLng, end: LatLng, startXY: [Int], endXY: [Int]) {
        let edgePoint: LatLng
        let edgeXY: [Int]
        let i: Int? = nil
        let brng: Double = start.rhumbBearingTo(end)
        
        let hint: LatLng = start
        let hintXY: [Int] = startXY
        
        if (end.lat > start.lat) {
            for var i = startXY[1]; i <= endXY[1]; i++ {
                let edgePoint = getGridIntersect_(start, brng: brng, gridLineLat: latGrid_[i])
                let edgeXY = getGridCoordsFromHint_(edgePoint, hintlatlng: hint, hint: hintXY)
                
                fillInGridSquares_(hintXY[0], endx: edgeXY[0], y: i-1)
                let hint = edgePoint
                let hintXY = edgeXY
            }
            
            fillInGridSquares_(hintXY[0], endx: endXY[0], y: i!-1)
        }
    }
    
    private func fillInGridSquares_(startx: Int, endx: Int, y: Int) -> Void {
        let x: Int
        if (startx < endx) {
            for var x = startx; x <= endx; x++ {
                let cell: [Int] = [x,y]
                markCell_(cell)
            }
        } else {
            for var x = startx; x >= endx; x-- {
                let cell: [Int] = [x,y]
                markCell_(cell)
            }
        }
    }
    private func getGridIntersect_(start: LatLng, brng: Double, gridLineLat: Double) -> LatLng {
        let d: Double = Double(EarthRadiusKm) * ((toRad(gridLineLat) - start.latRad()) / cos(toRad(brng)))
        return start.rhumbDestinationPoint(brng, dist: d)
    }
    
    private func getCellCoords_(latlng: LatLng) -> [Int]{
        var xCount: Int = 0
        var yCount: Int = 0
        for var x = 0; self.lngGrid_[x] < latlng.lng; x++ {
            xCount++
        }
        
        
        for var y = 0; self.latGrid_[y] < latlng.lat; y++ {
            yCount++
        }
        
        let result: [Int] = [xCount-1, yCount-1]
        
        return result
    }
    
    private func markCell_(cell: [Int]) -> Void {
        let x: Int = cell[0]
        let y: Int = cell[1]
        //--> try {
        self.grid_[x - 1][y - 1] = 1;
        self.grid_[x][y - 1] = 1;
        self.grid_[x + 1][y - 1] = 1;
        self.grid_[x - 1][y] = 1;
        self.grid_[x][y] = 1;
        self.grid_[x + 1][y] = 1;
        self.grid_[x - 1][y + 1] = 1;
        self.grid_[x][y + 1] = 1;
        self.grid_[x + 1][y + 1] = 1;
        // --> catch ()
        
        
        
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
