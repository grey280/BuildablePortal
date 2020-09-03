//
//  NetworkHelpers.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/18/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation
import Combine

class NetworkHelpers{
    static func parseClientResponse(_ response: Int) throws {
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
}

struct DefaultStorage {
    @UserDefault("signin_token", defaultValue: "") var token: String
}

class CacheService: ObservableObject {
    public static var shared = CacheService()
    private init(){
        self.reloadCacheAll()
        // allows auto-refresh when signin happens
        signinSubscription = AuthService.shared.objectWillChange.print("objectWillChange").sink(receiveValue: { (_) in
            if (AuthService.shared.loggedIn){
                self.reloadCacheAll()
            }
        })
    }
    
    private var signinSubscription: AnyCancellable!
    private var subscriptions: [AnyCancellable] = []
    
    func reloadCacheAll(){
        print("reloadCacheAll()")
        for sub in subscriptions{
            sub.cancel()
        }
        let accounts = CacheService.getResultItems(nil, route: URL(string: "https://portal.buildableworks.com/api/Account/Accounts/getResultItems")!)
            .print("reloadCacheAll.accounts")
            .replaceError(with: [])
            .assign(to: \.cachedAccounts, on: self)
        let activities = CacheService.getResultItems(nil, route: URL(string: "https://portal.buildableworks.com/api/Finance/TimesheetActivities/getResultItems")!)
            .print("reloadCacheAll.activities")
            .replaceError(with: [])
            .assign(to: \.cachedActivities, on: self)
        let options = SearchOptions()
        options.pagingDisabled = true
        let accountProjects = CacheService.getItems(options, route: URL(string: "https://portal.buildableworks.com/api/Account/AccountProjects/getItems")!)
            .print("reloadCacheAll.accountProjects")
            .replaceError(with: [])
            .assign(to: \.cachedAccountProjects, on: self)
        subscriptions = [accounts, activities, accountProjects]
    }
    
    @Published private(set) var cachedAccounts: [ListResultItem] = []
    @Published private(set) var cachedActivities: [ListResultItem] = []
    
    @Published private(set) var cachedAccountProjects: [AccountProject] = []
    
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
                try NetworkHelpers.parseClientResponse(httpResponse.statusCode)
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
                try NetworkHelpers.parseClientResponse(httpResponse.statusCode)
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
                try NetworkHelpers.parseClientResponse(httpResponse.statusCode)
                return data
            }
//          .decode(type: T.self, decoder: decoder)
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
                try NetworkHelpers.parseClientResponse(httpResponse.statusCode)
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
                try NetworkHelpers.parseClientResponse(httpResponse.statusCode)
                return data
            }
            //            .map{ (data) -> [ListResultItem] in
            //                do{
            //                    return try decoder.decode([ListResultItem].self, from: data)
            //                }catch let err{
            //                    print(err)
            //                }
            //                return []
            //            }
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

class AuthService: ObservableObject {
    public static var shared = AuthService()
    // only so we can mark it as private
    private init(){
        
    }
    
    public var loggedIn = false {
        willSet{
            needsLogin = !newValue
            objectWillChange.send()
        }
    }
    @Published public var needsLogin = true
    @Published public var authInfo: AuthResult? = nil
    
    private let formatter: DateFormatter = {
        // we want local time, but fortunately, DateFormatter does that by default
        let f = DateFormatter()
        // localTime syntax: "8/15/2019 11:44:50" based on en-US, and 24 hour clock
        f.dateFormat = "MM/dd/yyyy HH:mm:ss"
        return f
    }()
    
    private let decoder = JSONDecoder()
    
    private let loginURL = URL(string: "https://portal.buildableworks.com/api/auth/Login")!
    private let loginToAccountURL = URL(string: "https://portal.buildableworks.com/api/auth/LoginToAccount")!
    
    private var loginHolder: AnyCancellable?
    private var loginToAccountHolder: AnyCancellable?
    
    func login(username: String, password: String){
        let user = AuthUser()
        user.login = username
        user.password = password
        
        user.localTime = formatter.string(from: Date())
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(user)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        loginHolder = URLSession.shared.dataTaskPublisher(for: request)
            .tryMap{ data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.unknown
                }
                try NetworkHelpers.parseClientResponse(httpResponse.statusCode)
                return data
        }
        .decode(type: AuthResult.self, decoder: decoder)
        .mapError({ (originalError) -> NetworkError in
            if let orig = originalError as? NetworkError {
                return orig
            }
            return NetworkError.unableToDecode
        })
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { (completion) in
                // TODO: Actual error handling
                self.loginHolder = nil
            }) { (result) in
                print("login complete with \(result)")
                // go right on to log in to the first account, because the Portal doesn't support multiple identities
                self.loginToAccount(result.userIdentities![0])
        }
    }
    
    func loginToAccount(_ identity: AuthUserIdentity){
        var request = URLRequest(url: loginToAccountURL)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(identity)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        loginToAccountHolder = URLSession.shared.dataTaskPublisher(for: request)
            //            .print()
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.unknown
                }
                try NetworkHelpers.parseClientResponse(httpResponse.statusCode)
                return data
        }
        .decode(type: AuthResult.self, decoder: decoder)
        .mapError({ (originalError) -> NetworkError in
            if let orig = originalError as? NetworkError {
                return orig
            }
            return NetworkError.unableToDecode
        })
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { (completion) in
                print(completion)
                // TODO: Actual error handling
                self.loginToAccountHolder = nil
            }, receiveValue: { (result) in
                print("loginToAccount complete with \(result)")
                self.authInfo = result
                self.loggedIn = true
            })
    }
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


// make all of the network things return, not [Thing], but (items: [Thing], pager: Pager)
