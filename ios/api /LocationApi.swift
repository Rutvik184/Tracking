import Foundation

struct LocationRequest: Codable {
    let employee_id: Int
    let lat_loc: Double
    let long_loc: Double
}

struct ApiResponse: Codable {
    let id: Int
    let employee_id: Int
    let lat_loc: String
    let long_loc: String
    let timestamp: String
    let created_at: String
    let db_save: Bool
}

final class LocationApi {
    
    static let shared = LocationApi()
    private init() {}
    
    // ✅ Send location update
    func requestSendLocation(
        request: LocationRequest,
        completion: @escaping (Result<ApiResponse, Error>) -> Void
    ) {
        let endpoint = "employee-live-tracking/dummy-track-location"
        let url = APIClient.shared.baseURL.appendingPathComponent(endpoint)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        if let token = APIClient.shared.bearerToken {
            urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        print("📤 Sending location: \(request)")
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "InvalidResponse", code: 0)))
                return
            }
            
            print("📥 Response status: \(httpResponse.statusCode)")
            
            guard let data = data else {
                completion(.failure(NSError(domain: "EmptyResponse", code: 0)))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(ApiResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                print("⚠️ Decode error:", error)
                print("Response body:", String(data: data, encoding: .utf8) ?? "No body")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

