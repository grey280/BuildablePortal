//
//  UserDefault.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 1/18/20.
//  Copyright © 2020 Grey Patterson. All rights reserved.
//

import Foundation

@propertyWrapper
struct UserDefault<T: Codable> {
    let key: String
    let defaultValue: T

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            let result = UserDefaults.standard.object(forKey: key)
            if let object = result as? T{ // base case: object was a PropertyList type
                return object
            } else if let data = result as? Data { // if it's data, it was Codable
                let decoder = JSONDecoder()
                let unwrapped = try? decoder.decode(T.self, from: data)
                return unwrapped ?? defaultValue
            }
            return defaultValue
        }
        set {
            if (newValue is NSData || newValue is NSString || newValue is NSNumber || newValue is NSDate || newValue is NSArray || newValue is NSDictionary){
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                let encoder = JSONEncoder()
                let data = try? encoder.encode(newValue)
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }
}
