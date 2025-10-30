import Foundation

final class APIClient {
    
    static let shared = APIClient()
    
    private let _baseURL = URL(string: "https://dev.api.klockmate.com/api/")!
    private var _bearerToken: String?
  
   var baseURL: URL {
          return _baseURL
      }

      var bearerToken: String? {
          return _bearerToken
      }
  
   func setBearerToken(_ token: String) {
         _bearerToken = token
     }

     func clearBearerToken() {
         _bearerToken = nil
     }
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        
        // Add default headers
        config.httpAdditionalHeaders = [
            "Accept": "application/json"
        ]
        
        self.session = URLSession(configuration: config)
    }
    
    
    // MARK: - Generic API Call
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add authorization header if token exists
        if let token = bearerToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add JSON body
        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ API Error:", error.localizedDescription)
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "InvalidResponse", code: 0)))
                return
            }
            
            print("📥 API Response (\(httpResponse.statusCode))")
            
            guard let data = data else {
                completion(.failure(NSError(domain: "EmptyResponse", code: 0)))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(responseType, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("⚠️ JSON Decode Error:", error)
                print("Response Body:", String(data: data, encoding: .utf8) ?? "No body")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

