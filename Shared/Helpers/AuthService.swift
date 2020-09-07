//
//  AuthService.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 9/7/20.
//

import Foundation
import Combine

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
                    throw NetworkError(errorType: .unknown, statusText: "Could not parse response")
                }
                try Network.parseClientResponse(code: httpResponse.statusCode, data: data)
                return data
        }
        .decode(type: AuthResult.self, decoder: decoder)
        .mapError({ (originalError) -> NetworkError in
            if let orig = originalError as? NetworkError {
                return orig
            }
            return NetworkError(errorType: .unableToDecode, statusText: "Unable to parse.")
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
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError(errorType: .unknown, statusText: "Could not parse response")
                }
                try Network.parseClientResponse(code: httpResponse.statusCode, data: data)
                return data
        }
        .decode(type: AuthResult.self, decoder: decoder)
        .mapError({ (originalError) -> NetworkError in
            if let orig = originalError as? NetworkError {
                return orig
            }
            return NetworkError(errorType: .unableToDecode, statusText: "Unable to parse.")
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
