//
//  ScenicService.swift
//  ScenicRoutes
//
//  Created by Aditya Khavanekar on 6/21/26.
//

import Foundation
import CoreLocation

// Matches the backend's response shape
struct ScenicWaypoint: Codable, Identifiable {
    let name: String
    let state: String
    let waypoint_lat: Double
    let waypoint_lon: Double
    let detour_degrees: Double

    var id: String { name }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: waypoint_lat, longitude: waypoint_lon)
    }
}

struct ScenicResponse: Codable {
    let count: Int
    let waypoints: [ScenicWaypoint]
}

class ScenicService {
    static let shared = ScenicService()
    private let baseURL = "https://scenicroutes-backend.onrender.com"

    func fetchScenicWaypoints(
        sourceLat: Double, sourceLon: Double,
        destLat: Double, destLon: Double
    ) async throws -> [ScenicWaypoint] {
        guard let url = URL(string: "\(baseURL)/scenic-waypoints") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Double] = [
            "source_lat": sourceLat,
            "source_lon": sourceLon,
            "dest_lat": destLat,
            "dest_lon": destLon
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(ScenicResponse.self, from: data)
        return decoded.waypoints
    }
}
