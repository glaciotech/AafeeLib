//
//  TweetPostingTool.swift
//
//
//  Created by Peter Liddle on 5/12/25.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Foundation




enum XAPIError: Error {
    case invalidResponse
    case postingFailed
    case other(Error)
}

struct XAPI {
    
    let apiBaseURL = "https://api.twitter.com/"
    let apiVersion = "2"
    let postTweetEndpoint = "/tweets"
    let bearerToken = "YOUR_BEARER_TOKEN"  // Replace with your actual Bearer Token
    
    func postTweet(tweetContent: String) async throws {
        // Define the URL and request
        guard let url = URL(string: "https://api.twitter.com/2/tweets") else {
            throw XAPIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonPayload: [String: Any] = ["text": tweetContent]
        
        do {
            // Encode the JSON payload
            let jsonData = try JSONSerialization.data(withJSONObject: jsonPayload, options: [])
            request.httpBody = jsonData
        } catch {
            throw XAPIError.other(error)
        }
        
        // Perform the network request asynchronously
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the HTTP response
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw XAPIError.postingFailed
        }
        
        // Optionally handle response data (for debugging)
        if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
            print("Response JSON: \(jsonResponse)")
        }
    }
}

struct TweetPostingTool: FlowStage {
    
    let xAPI = XAPI()
    
    func execute(_ input: InOutType?) async throws -> InOutType {
        try await xAPI.postTweet(tweetContent: "")
        return input ?? .none
    }
}


//// Usage:
//postTweet(status: "Hello, Twitter!") { result in
//   switch result {
//   case .success:
//       print("Tweet posted successfully!")
//   case .failure(let error):
//       print("Failed to post tweet: \(error.localizedDescription)")
//   }
//}

