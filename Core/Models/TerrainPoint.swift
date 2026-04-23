//
//  TerrainPoint.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import Foundation

struct TerrainPoint: Identifiable, Codable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let elevation: Double
    let name: String
    
    init(id: UUID = UUID(), latitude: Double, longitude: Double, elevation: Double, name: String) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.name = name
    }
}
