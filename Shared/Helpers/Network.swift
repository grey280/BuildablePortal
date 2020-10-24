//
//  NetworkHelpers.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/18/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation
import Combine

class Network {
    public static var appBase: String {
        "https://portal.buildableworks.com"
//        "http://192.168.0.19:5000"
    }
    
    private static func getCookieHeaders(for route: URL) -> [String: String]{
        var storage = DefaultStorage()
        if let cookies = HTTPCookieStorage.shared.cookies(for: route), cookies.count > 0 {
            print("got cookies")
            if let index = cookies.firstIndex(where: { (cookie) -> Bool in
                cookie.name == "access_token"
            }) {
                print("storing access token")
                storage.token = cookies[index].value
            }
            let headers = HTTPCookie.requestHeaderFields(with: cookies)
            return headers
        } else {
            print("failed to get cookies from storage, falling back on stored token")
            var result: [String: String] = [:]
            if (storage.token != ""){
                result["Cookie"] = "access_token=\(storage.token)"
            }
            return result
        }
    }
    
    static func parseClientResponse(code response: Int, data: Data) throws {
        if (response < 400){
            return
        }
        let decoder = JSONDecoder()
        guard let errorObject = try? decoder.decode(ErrorResult.self, from: data) else {
            throw NetworkError(errorType: .unableToDecode, statusText: "Could not decode error object!")
        }
        switch (response){
        case 400:
            throw NetworkError(errorType: .notFound, statusText: errorObject.statusText)
        case 401:
            throw NetworkError(errorType: .unauthorized, statusText: errorObject.statusText)
        case 403:
            throw NetworkError(errorType: .forbidden, statusText: errorObject.statusText)
        case 404:
            throw NetworkError(errorType: .notFound, statusText: errorObject.statusText)
        case 500:
            throw NetworkError(errorType: .internalServerError, statusText: errorObject.statusText)
        case 501:
            throw NetworkError(errorType: .notImplemented, statusText: errorObject.statusText)
        case 502:
            throw NetworkError(errorType: .badGateway, statusText: errorObject.statusText)
        case 503:
            throw NetworkError(errorType: .serviceUnavailable, statusText: errorObject.statusText)
        case 504:
            throw NetworkError(errorType: .gatewayTimeout, statusText: errorObject.statusText)
        default:
            throw NetworkError(errorType: .unknown, statusText: errorObject.statusText)
        }
    }
    
    static func getItems<T: Decodable>(_ options: SearchOptions?, route: URL) -> AnyPublisher<T, NetworkError>{
        print("getItems(\(String(describing: options)), \(route))")
        var request = URLRequest(url: route)
        request.httpMethod = "POST"
        if let so = options{
            request.httpBody = try? JSONEncoder().encode(so)
        }
        request.allHTTPHeaderFields = getCookieHeaders(for: route)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.buildableDate)
        return URLSession.shared.dataTaskPublisher(for: request)
            .print("getItems()")
            .tryMap{ data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError(errorType: .unknown, statusText: "Could not parse response")
                }
                try Network.parseClientResponse(code: httpResponse.statusCode, data: data)
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError({ (originalError) -> NetworkError in
                if let orig = originalError as? NetworkError {
                    return orig
                }
                return NetworkError(errorType: .unableToDecode, statusText: "Unable to parse.")
            })
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    static func post<T: Codable>(_ item: T, route: URL) -> AnyPublisher<T, NetworkError>{
        print("post(\(String(describing: item)), \(route))")
        return upsert(item, route: route, create: true)
    }
    
    static func put<T: Codable>(_ item: T, route: URL) -> AnyPublisher<T, NetworkError>{
        print("put(\(String(describing: item)), \(route))")
        return upsert(item, route: route, create: false)
    }
    
    private static func upsert<T: Codable>(_ item: T, route: URL, create: Bool) -> AnyPublisher<T, NetworkError> {
        print("upsert(\(String(describing: item)), \(route), \(create))")
        var request = URLRequest(url: route)
        request.httpMethod = create ? "POST" : "PUT"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(.buildableDate)
        guard let body = try? encoder.encode(item) else {
            return Fail(outputType: T.self, failure: NetworkError(errorType: .unableToDecode, statusText: "Could not decode result")).eraseToAnyPublisher()
        }
        request.httpBody = body
        request.allHTTPHeaderFields = getCookieHeaders(for: route)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.buildableDate)
        return URLSession.shared.dataTaskPublisher(for: request)
            .print("post()")
            .tryMap{ data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError(errorType: .unknown, statusText: "Could not parse response")
                }
                try Network.parseClientResponse(code: httpResponse.statusCode, data: data)
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { (originalError) -> NetworkError in
                if let orig = originalError as? NetworkError {
                    return orig
                }
                return NetworkError(errorType: .unableToDecode, statusText: "Unable to parse.")
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    static func delete(route: URL) -> AnyPublisher<Any, NetworkError> {
        print("delete(\(route))")
        var request = URLRequest(url: route)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getCookieHeaders(for: route)
        // TODO: Do we need the application/json bit?
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return URLSession.shared.dataTaskPublisher(for: request)
            .print("post()")
            .tryMap{ data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError(errorType: .unknown, statusText: "Could not parse response")
                }
                try Network.parseClientResponse(code: httpResponse.statusCode, data: data)
                return data
            }
            .mapError { (originalError) -> NetworkError in
                if let orig = originalError as? NetworkError {
                    return orig
                }
                return NetworkError(errorType: .unableToDecode, statusText: "Unable to parse.")
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    static func deleteBulk<T: Identifiable>(_ items: [T], route: URL) -> AnyPublisher<Any, NetworkError> where T.ID: Encodable {
        let ids = items.map { $0.id }
        var request = URLRequest(url: route)
        request.httpMethod = "POST"
        guard let body = try? JSONEncoder().encode(ids) else {
            return Fail(outputType: (Any).self, failure: NetworkError(errorType: .unableToDecode, statusText: "Could not decode result")).eraseToAnyPublisher()
        }
        request.httpBody = body
        request.allHTTPHeaderFields = getCookieHeaders(for: route)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.buildableDate)
        return URLSession.shared.dataTaskPublisher(for: request)
            .print("post()")
            .tryMap{ data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError(errorType: .unknown, statusText: "Could not parse response")
                }
                try Network.parseClientResponse(code: httpResponse.statusCode, data: data)
                return data
            }
            .mapError { (originalError) -> NetworkError in
                if let orig = originalError as? NetworkError {
                    return orig
                }
                return NetworkError(errorType: .unableToDecode, statusText: "Unable to parse.")
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    static func getResultItems(_ options: SearchOptions?, route: URL) -> AnyPublisher<[ListResultItem], NetworkError>{
        print("getResultItems(\(String(describing: options)), \(route))")
        var request = URLRequest(url: route)
        request.httpMethod = "POST"
        if let so = options{
            request.httpBody = try? JSONEncoder().encode(so)
        }
        request.allHTTPHeaderFields = getCookieHeaders(for: route)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.buildableDate)
        return URLSession.shared.dataTaskPublisher(for: request)
            .print("getResultItems()")
            .tryMap{ data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError(errorType: .unknown, statusText: "Unknown error")
                }
                try Network.parseClientResponse(code: httpResponse.statusCode, data: data)
                return data
            }
            .decode(type: [ListResultItem].self, decoder: decoder)
            .mapError({ (originalError) -> NetworkError in
                if let orig = originalError as? NetworkError {
                    return orig
                }
                return NetworkError(errorType: .unableToDecode, statusText: nil)
            })
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

struct DefaultStorage {
    @UserDefault("signin_token", defaultValue: "") var token: String
}

struct NetworkError: Error {
    
    enum NetworkErrorType: Error {
        // Errors occurring in non-network level
        case unknown, unableToDecode, unableToEncode
        // 400 block
        case badRequest, unauthorized, forbidden, notFound
        // 500 block
        case internalServerError, notImplemented, badGateway, serviceUnavailable, gatewayTimeout
        
        var localizedDescription: String {
            switch self {
            case .unableToDecode:
                return "Could not decode result"
            case .unableToEncode:
                return "Could not encode data"
            case .badRequest:
                return "Bad Request"
            case .unauthorized:
                return "Unauthorized"
            case .forbidden:
                return "Forbidden"
            case .notFound:
                return "Not Found"
            case .internalServerError:
                return "Internal Server Error"
            case .notImplemented:
                return "Not Implemented"
            case .badGateway:
                return "Bad Gateway"
            case .serviceUnavailable:
                return "Service Unavailable"
            case .gatewayTimeout:
                return "Gateway Timeout"
            default:
                return "Unknown"
            }
        }
    }
    
    let errorType: NetworkErrorType
    let statusText: String?
}




// struct NetworkError: Error { let errorType: NetworkErrorType; enum NetworkErrortype { /* from above */}; let errorMessage: String }
