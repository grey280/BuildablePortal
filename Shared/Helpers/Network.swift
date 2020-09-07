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
    
    private static func parseClientResponse(_ response: Int) throws {
        if (response < 400){
            return
        }
        switch (response){
        case 400:
            throw NetworkError.badRequest
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500:
            throw NetworkError.internalServerError
        case 501:
            throw NetworkError.notImplemented
        case 502:
            throw NetworkError.badGateway
        case 503:
            throw NetworkError.serviceUnavailable
        case 504:
            throw NetworkError.gatewayTimeout
        default:
            throw NetworkError.unknown
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
                    throw NetworkError.unknown
                }
                try Network.parseClientResponse(httpResponse.statusCode)
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError({ (originalError) -> NetworkError in
                if let orig = originalError as? NetworkError {
                    return orig
                }
                return NetworkError.unableToDecode
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
            return Fail(outputType: T.self, failure: NetworkError.unableToEncode).eraseToAnyPublisher()
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
                    throw NetworkError.unknown
                }
                try Network.parseClientResponse(httpResponse.statusCode)
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { (originalError) -> NetworkError in
                if let orig = originalError as? NetworkError {
                    return orig
                }
                return NetworkError.unableToDecode
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
                    throw NetworkError.unknown
                }
                try Network.parseClientResponse(httpResponse.statusCode)
                return data
            }
            .mapError { (originalError) -> NetworkError in
                if let orig = originalError as? NetworkError {
                    return orig
                }
                return NetworkError.unableToDecode
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    static func deleteBulk<T: Identifiable>(_ items: [T], route: URL) -> AnyPublisher<Any, NetworkError> where T.ID: Encodable {
        let ids = items.map { $0.id }
        var request = URLRequest(url: route)
        request.httpMethod = "POST"
        guard let body = try? JSONEncoder().encode(ids) else {
            return Fail(outputType: (Any).self, failure: NetworkError.unableToEncode).eraseToAnyPublisher()
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
                    throw NetworkError.unknown
                }
                try Network.parseClientResponse(httpResponse.statusCode)
                return data
            }
            .mapError { (originalError) -> NetworkError in
                if let orig = originalError as? NetworkError {
                    return orig
                }
                return NetworkError.unableToDecode
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
                    throw NetworkError.unknown
                }
                try Network.parseClientResponse(httpResponse.statusCode)
                return data
            }
            .decode(type: [ListResultItem].self, decoder: decoder)
            .mapError({ (originalError) -> NetworkError in
                if let orig = originalError as? NetworkError {
                    return orig
                }
                return NetworkError.unableToDecode
            })
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

struct DefaultStorage {
    @UserDefault("signin_token", defaultValue: "") var token: String
}

enum NetworkError: Error {
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


// struct NetworkError: Error { let errorType: NetworkErrorType; enum NetworkErrortype { /* from above */}; let errorMessage: String }
