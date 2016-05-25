//
//  RouteBoxer2.swift
//  smap
//
//  Created by Jianfu Zhang on 5/8/16.
//  Copyright © 2016 Lee, Marika. All rights reserved.
//

import Foundation
import GoogleMaps

class RouteBoxer2 {
    let R:Double = 6371
    var grid_ : [[Int]]
    var latGrid_ : [Number]
    var lngGrid_ : [Number]
    var boxesX_ : [LatLngBounds]
    var boxesY_ : [LatLngBounds]
    var vertices : [LatLng]
    init(){
        grid_ = []
        latGrid_ = []
        lngGrid_ = []
        boxesX_ = []
        boxesY_ = []
        vertices = []
    }
    
    func box(path: [LatLng], range: Double) -> [LatLngBounds] {
        
        self.vertices = path
        
        buildGrid_(vertices, range: range)
        findIntersectingCells_(vertices)
        mergeIntersectingCells_()
        
        return self.boxesX_.count <= self.boxesY_.count ? self.boxesX_ : self.boxesY_
        
    }
    
    func buildGrid_(vertices:[LatLng], range: Double) -> Void{
        var routeBounds :LatLngBounds = LatLngBounds(coordinate: vertices[0].coordinate, coordinate: vertices[0].coordinate)
        for var i=0; i<vertices.count; i++ {
            routeBounds = routeBounds.extend(vertices[i])
        }
        //Find the center of the bounding box of the path
        let routeBoundsCenter = routeBounds.getCenter();
        
        //Starting from the center define grid lines outwards vertically until they
        // extend beyond the edge of the bounding box by more than one cell
        self.latGrid_.append(Number(number:routeBoundsCenter.coordinate.latitude))
        
        //Add lines from the center out to the north
        self.latGrid_.append(Number(number: routeBoundsCenter.rhumbDestinationPoint(Number(number:0), dist: Number(number:range)).coordinate.latitude))
        for (var i = 2; self.latGrid_[i-2].num < routeBounds.northEast.latitude; i++) {
            self.latGrid_.append(Number(number:routeBoundsCenter.rhumbDestinationPoint(Number(number:0), dist: Number(number:range * Double(i))).coordinate.latitude))
        }
        
        //Add lines from the center out to the south
        for (var i = 1; self.latGrid_[1].num > routeBounds.southWest.latitude; i++) {
            self.latGrid_.insert(Number(number:routeBoundsCenter.rhumbDestinationPoint(Number(number:180), dist: Number(number:range * Double(i))).coordinate.latitude), atIndex: 0)
        }
        
        //Starting from the center define grid lines outwards horizontally until they 
        //extend beyond the edge of the bounding box by more than one cell
        self.lngGrid_.append(Number(number:routeBoundsCenter.coordinate.longitude))
        
        //Add lines from the center out to the east
        self.lngGrid_.append(Number(number:routeBoundsCenter.rhumbDestinationPoint(Number(number:90), dist: Number(number:range)).coordinate.longitude))
        for (var i = 2; self.lngGrid_[i-2].num < routeBounds.northEast.longitude; i++) {
            self.lngGrid_.append(Number(number:routeBoundsCenter.rhumbDestinationPoint(Number(number:90),dist: Number(number:range * Double(i))).coordinate.longitude))
        }
        
        //Add lines from the center out to the west
        for (var i = 1; self.lngGrid_[1].num > routeBounds.southWest.longitude; i++) {
            self.lngGrid_.insert(Number(number: routeBoundsCenter.rhumbDestinationPoint(Number(number:270), dist: Number(number:range * Double(i))).coordinate.longitude), atIndex: 0)
        }
        
        // Create a two dimensional array representing this grid
        let rows = lngGrid_.count, cols = latGrid_.count
        
        self.grid_ = Array(count: rows, repeatedValue: Array(count: cols, repeatedValue: 0))
    }
    
    // Find all of the cells in the overlaid grid that the path intersects
    //
    //@param [LatLng] vertices , The vertices of the path
    //
    func findIntersectingCells_(vertices:[LatLng]) -> Void{
        // Find the cell where the path begins
        var hintXY = self.getCellCoords_(vertices[0])
        
        //Mark that cell and it's neighbours for inclusion in the boxes
        self.markCell_(hintXY)
        
        // Work through each vertex on the path indentifying which grid cell it is in
        for (var i = 1; i < vertices.count; i++) {
            var gridXY = self.getGridCoordsFromHint_(vertices[i], hintlatlng: vertices[i-1], hint: hintXY)
            
            if (gridXY[0] == hintXY[0] && gridXY[1] == hintXY[1]) {
                continue
            } else if (abs(hintXY[0]-gridXY[0]) == 1 && hintXY[1] == gridXY[1]) || (hintXY[0] == gridXY[0] && abs(hintXY[1]-gridXY[1]) == 1) {
                
                self.markCell_(gridXY)
            } else {
                self.getGridIntersects_(vertices[i-1], end: vertices[i], startXY: hintXY, endXY: gridXY)
            }
            
            hintXY = gridXY
        }
        
    }

    func getCellCoords_(latlng: LatLng) -> [Int] {
        var x = 0
        var y = 0
        for (x = 0; self.lngGrid_[x].num < latlng.coordinate.longitude ; x++){}
        for (y = 0; self.latGrid_[y].num < latlng.coordinate.latitude ; y++) {}
        return [x-1, y-1]
    }
    
    func getGridCoordsFromHint_(latlng:LatLng, hintlatlng:LatLng, hint:[Int]) -> [Int] {
        var x: Int, y:Int;
        if (latlng.coordinate.longitude > hintlatlng.coordinate.longitude) {
            for (x = hint[0]; self.lngGrid_[x+1].num < latlng.coordinate.longitude; x++) {}
        } else {
            for (x = hint[0]; self.lngGrid_[x].num > latlng.coordinate.longitude; x--) {}
        }
        
        if (latlng.coordinate.latitude > hintlatlng.coordinate.latitude) {
            for(y = hint[1]; self.latGrid_[y+1].num < latlng.coordinate.latitude; y++) {}
        } else {
            for (y = hint[1]; self.latGrid_[y].num > latlng.coordinate.latitude; y--) {}
        }
        
        return [x,y]
    }
    
    /**
    * Identify the grid squares that a path segment between two vertices
    * intersects with by:
    * 1. Finding the bearing between the start and end of the segment
    * 2. Using the delta between the lat of the start and the lat of each
    *    latGrid boundary to find the distance to each latGrid boundary
    * 3. Finding the lng of the intersection of the line with each latGrid
    *     boundary using the distance to the intersection and bearing of the line
    * 4. Determining the x-coord on the grid of the point of intersection
    * 5. Filling in all squares between the x-coord of the previous intersection
    *     (or start) and the current one (or end) at the current y coordinate,
    *     which is known for the grid line being intersected
    */
    func getGridIntersects_(start:LatLng, end:LatLng, startXY:[Int], endXY:[Int]) -> Void {
        var edgePoint: LatLng
        var edgeXY: [Int]
        var i : Int
        
        var brng = start.rhumbBearingTo(end)
        
        var hint = start;
        var hintXY = startXY;
        
        //Handle a line segment that travels south first
        if (end.coordinate.latitude > start.coordinate.latitude) {
            for(i = startXY[1]+1; i <= endXY[1]; i++) {
                //Find the latlng of the point where the path segment intersects with 
                //this grid line (step 2&3)
                edgePoint = self.getGridIntersect_(start, brng: brng, gridLineLat: self.latGrid_[i])
                
                //Find the cell containing this intersect point (step 4)
                edgeXY = self.getGridCoordsFromHint_(edgePoint, hintlatlng: hint, hint: hintXY)
                
                //Mark every cell the path has crossed between this grid and the start,
                // or the previous east to west grid line it crossed (step 5)
                self.fillInGridSquares_(hintXY[0], endx: edgeXY[0], y: i-1)
                
                //use the point where it crossed this grid line as the reference for the 
                //next iteration
                hint = edgePoint
                hintXY = edgeXY
            }
            
            //Mark every cell the path has crossed between the last east to west grid
            // line it crossed and the end(step 5)
            self.fillInGridSquares_(hintXY[0], endx: endXY[0], y: i-1)
        } else {
            //Iterate over the east to west grid lines between the start and end cells
            for (i = startXY[1]; i > endXY[1]; i--) {
                //Find the latlng of the point where the path segment intersects with
                // this grid line (step 2&3)
                edgePoint = self.getGridIntersect_(start, brng: brng, gridLineLat: self.latGrid_[i])
                
                //Find the cell containing this intersect point (step 4)
                edgeXY = self.getGridCoordsFromHint_(edgePoint, hintlatlng: hint, hint: hintXY)
                
                //Mark every cell the path has crossed between this grid and the start,
                // or the previous east to west grid line it crossed (step 5)
                self.fillInGridSquares_(hintXY[0], endx: edgeXY[0], y: i)
                
                //Use the point where it crossed this grid line as the reference for the 
                //next iteration
                hint = edgePoint
                hintXY = edgeXY
            }
            
            //Mark every cell the path has crossed between the last east to west grid
            // line it crossed and the end (step 5)
            self.fillInGridSquares_(hintXY[0], endx: endXY[0], y: i)
        }
    }
    
    
    /*
     * Find the latlng at which a path segment intersects with a given
     *   line of latitude
    */
    func getGridIntersect_(start:LatLng, brng: Number, gridLineLat: Number) -> LatLng {
        var d = self.R * ((gridLineLat.toRad().num - Number(number:start.coordinate.latitude).toRad().num)/cos(brng.toRad().num))
        return start.rhumbDestinationPoint(brng, dist: Number(number:d))
    }
    
    /*
     * Mark all cells in a given row of the grid that lie between two columns
     *   for inclusion in the boxes
    */
    func fillInGridSquares_(startx: Int, endx: Int, y: Int) -> Void {
        var x : Int
        if startx < endx {
            for (x = startx; x <= endx; x++) {
                self.markCell_([x,y])
            }
        } else {
            for (x = startx; x >= endx; x--) {
                self.markCell_([x,y])
            }
        }
    }
    
    func markCell_(cell:[Int]) -> Void {
        let x = cell[0]
        let y = cell[1]
        self.grid_[x - 1][y - 1] = 1
        self.grid_[x][y-1] = 1
        self.grid_[x+1][y-1] = 1
        self.grid_[x-1][y] = 1
        self.grid_[x][y] = 1
        self.grid_[x+1][y] = 1
        self.grid_[x-1][y+1] = 1
        self.grid_[x][y+1] = 1
        self.grid_[x+1][y+1] = 1

    }
    
    /*
     * Create two sets of bounding boxes, both of which cover all of the cells that
     *   have been marked for inclusion.
     *
     * The first set is created by combining adjacent cells in the same column into
     *   a set of vertical rectangular boxes, and then combining boxes of the same
     *   height that are adjacent horizontally.
     *
     * The second set is created by combining adjacent cells in the same row into
     *   a set of horizontal rectangular boxes, and then combining boxes of the same
     *   width that are adjacent vertically.
    */
    func mergeIntersectingCells_() -> Void {
        var x : Int
        var y : Int
        var box : LatLngBounds
        
        //the box we are currently expanding with new cells
        var currentBox : LatLngBounds?
        
        //Traverse the grid a raw at a time
        for (y = 0; y < self.grid_[0].count; y++) {
            for (x = 0; x < self.grid_.count; x++) {
                
                if (self.grid_[x][y] == 1) {
                    // This cell is marked for inclusion. If the previous cell in this
                    // row was also marked for inclusion, merge this cell into it's box.
                    // Otherwise start a new box.
                    box = self.getCellBounds_([x,y])
                    if (currentBox != nil) {
                        currentBox = currentBox!.extend(LatLng(point:box.northEast))
                    } else {
                        currentBox = box
                    }
                } else {
                    // This cell is not marked for inclusion. If the previous cell was
                    // marked for inclusion, merge it's box with a box that spans the same
                    // colums from the row below if possible.
                    self.mergeBoxesY_(currentBox)
                    currentBox = nil
                }
                
            }
            
            // If the last cell was marked for inclusion, merge it's box with a matching
            // box from the row below if possible.
            self.mergeBoxesY_(currentBox)
            currentBox = nil
        }
        
        // Traverse the grid a column at a time
        for (x = 0; x < self.grid_.count; x++) {
            for (y = 0; y < self.grid_[0].count; y++) {
                if (self.grid_[x][y] == 1) {
                    // This cell is marked for inclusion. If the previous cell in this
                    // column was also marked for inclusion, merge this cell into it's box. 
                    // Otherwise start a new box.
                    if (currentBox != nil) {
                        box = self.getCellBounds_([x,y])
                        currentBox = currentBox!.extend(LatLng(point: box.northEast))
                    } else {
                        currentBox = self.getCellBounds_([x,y])
                    }
                    
                } else {
                    // This cell is not marked for inclusion. If the previous cell was
                    // marked for inclusion, merge it's box with a box that spans the same 
                    // rows from the column to the left if possible.
                    self.mergeBoxesX_(currentBox)
                    currentBox = nil
                }
            }
            // If the last cell was marked for inclusion, merge it's box with a matching
            // box from the column to the left if possible.
            self.mergeBoxesX_(currentBox)
            currentBox = nil
        }
        
    }
    
    /**
     * Search for an existing box in an adjacent row to the given box that spans the
     * same set of columns and if one is found merge the given box into it. If one
     * is not found, append this box to the list of existing boxes.
     *
     * @param {LatLngBounds}  The box to merge
     */
    func mergeBoxesX_ (box:LatLngBounds?) -> Void {
        if (box != nil) {
            for (var i = 0; i < self.boxesX_.count; i++) {
                if (self.boxesX_[i].northEast.longitude == box!.southWest.longitude &&
                    self.boxesX_[i].southWest.latitude == box!.southWest.latitude &&
                    self.boxesX_[i].northEast.latitude == box!.northEast.latitude) {
                    self.boxesX_[i] = self.boxesX_[i].extend(LatLng(point:box!.northEast))
                    return
                }
            }
            self.boxesX_.append(box!)
        }
    }
    
    /**
     * Search for an existing box in an adjacent column to the given box that spans
     * the same set of rows and if one is found merge the given box into it. If one
     * is not found, append this box to the list of existing boxes.
     *
     * @param {LatLngBounds}  The box to merge
     */
    func mergeBoxesY_ (box: LatLngBounds?) -> Void {
        if (box != nil) {
            for (var i = 0; i < self.boxesY_.count; i++) {
                if (self.boxesY_[i].northEast.latitude == box!.southWest.latitude &&
                    self.boxesY_[i].southWest.longitude == box!.southWest.longitude &&
                    self.boxesY_[i].northEast.longitude == box!.northEast.longitude) {
                    self.boxesY_[i] = self.boxesY_[i].extend(LatLng(point:box!.northEast))
                    return
                }
            }
            self.boxesY_.append(box!)
        }
    }
    
    /**
     * Obtain the LatLng of the origin of a cell on the grid
     *
     * @param {Number[]} cell The cell to lookup.
     * @return {LatLng} The latlng of the origin of the cell.
     */
    func getCellBounds_ (cell:[Int]) -> LatLngBounds{
        return LatLngBounds.init(coordinate: CLLocationCoordinate2D(latitude: self.latGrid_[cell[1]].num, longitude: self.lngGrid_[cell[0]].num), coordinate: CLLocationCoordinate2D(latitude: self.latGrid_[cell[1]+1].num, longitude: self.lngGrid_[cell[0]+1].num))
    }
    
}

class LatLng {
    var coordinate : CLLocationCoordinate2D
    init(point:CLLocationCoordinate2D){
        coordinate = point
    }
    func rhumbDestinationPoint(var brng:Number,dist:Number) -> LatLng{
        let R:Double = 6371;
        let d = dist.num/R
        
        let lat1 = Number(number: coordinate.latitude).toRad()
        let lon1 = Number(number: coordinate.longitude).toRad()
        
        brng = brng.toRad()
        
        var lat2 = Number(number:lat1.num + d * cos(brng.num))
        let dLat = Number(number:lat2.num-lat1.num)
        
        let dPhi = Number(number:log(tan(lat2.num/2+M_PI/4)/tan(lat1.num/2+M_PI/4)))
        
        let q = Number(number:(dPhi.num != 0) ? dLat.num/dPhi.num : cos(lat1.num))
        
        let dLon = Number(number: d*sin(brng.num) / q.num)
        // check for going past the pole
        if abs(dLat.num) > M_PI/2 {
            lat2 = Number(number: lat2.num > 0 ? M_PI-lat2.num : -M_PI+lat2.num)
        }
        let lon2 = Number(number:(lon1.num + dLon.num + M_PI)%(2*M_PI) - M_PI)

        if (lat2.num.isNaN || lon2.num.isNaN) {
            return LatLng(point:CLLocationCoordinate2D.init())
        }
        
        return LatLng(point: CLLocationCoordinate2D.init(latitude: lat2.toDeg().num, longitude: lon2.toDeg().num))
    }
    
    func rhumbBearingTo(dest:LatLng) -> Number {
        var dLon = Number(number:(dest.coordinate.longitude - coordinate.longitude)).toRad()
        let dPhi = log(tan(Number(number:dest.coordinate.latitude).toRad().num/2 + M_PI/4)/tan(Number(number:coordinate.latitude).toRad().num/2 + M_PI/4))
        if abs(dLon.num) > M_PI {
            dLon = Number(number:dLon.num > 0 ? -(2*M_PI-dLon.num) : (2*M_PI+dLon.num))
        }
        return Number(number:atan2(dLon.num, dPhi)).toBrng()
    }
    
}

class LatLngBounds:GMSCoordinateBounds {

func extend(point:LatLng) -> LatLngBounds{
        let new_bounds = super.includingCoordinate(point.coordinate)
        return LatLngBounds(coordinate: new_bounds.northEast,coordinate: new_bounds.southWest)
    }
    
    func getCenter() -> LatLng {
        let lat = (self.northEast.latitude + self.southWest.latitude)/2
        let lon = (self.northEast.longitude + self.southWest.longitude)/2
        let point = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        return LatLng(point: point)
    }
}

class Number {
    var num : Double
    init(number:Double){
        num=number
    }
    func toRad()->Number {
        return Number(number: num*M_PI/180)
    }
    
    func toDeg() -> Number{
        return Number(number: num*180/M_PI)
    }
    
    func toBrng() -> Number{
        return Number(number: (toDeg().num+360)%360)
    }
}