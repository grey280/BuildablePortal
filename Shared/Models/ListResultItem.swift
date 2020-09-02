//
//  ListResultItem.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

class ListResultItem: Codable{
    var selected: Bool = false
    var editing: Bool = false
    var pager: Pager?
    var label: String = ""
    var value: Any
    var checked: Bool = false
    var group: String?
    
    // MARK: Codable
    enum CodingKeys: String, CodingKey{
        case selected, editing, pager, label, value, checked, group
    }
    
    typealias AttachmentDecoder = (KeyedDecodingContainer<CodingKeys>) throws -> Any
    typealias AttachmentEncoder = (Any, inout KeyedEncodingContainer<CodingKeys>) throws -> Void
    
    // TODO: Finish setting up this decoders/encoders list to include all the system default ones
    // Maybe in the AppDelegate, just do for thing in [Int.self, String.self, Double.self, Boolean.self, etc...] { ListResultItem.register(thing) } ?
    
    private static var decoders: [AttachmentDecoder] = [
        { (container) -> Any in
            // Integer
            try container.decode(Int.self, forKey: .value)
        },
        { (container) -> Any in
            // String
            try container.decode(String.self, forKey: .value)
        }
    ]
    private static var encoders: [AttachmentEncoder] = [
        { (payload, container) in
            // Integer
            try container.encode(payload as! Int, forKey: .value)
        },
        { (payload, container) in
            // String
            try container.encode(payload as! String, forKey: .value)
        }
    ]
    
    
    /// Register a type as something to try converting to/from for the `value`.
    /// - Parameter type: i.e. `Int.self`
    static func register<A: Codable>(_ type: A.Type){
        decoders.append { (container) -> Any in
            try container.decode(A.self, forKey: .value)
        }
        encoders.append { (payload, container) in
            try container.encode(payload as! A, forKey: .value)
        }
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selected = (try? values.decode(Bool.self, forKey: .selected)) ?? false
        editing = (try? values.decode(Bool.self, forKey: .editing)) ?? false
        pager = try values.decode(Pager?.self, forKey: .pager)
        label = (try? values.decode(String.self, forKey: .label)) ?? ""
        
        value = ListResultItem.decoders.compactMap({ (decoder) -> Any? in
            try? decoder(values)
        }).first!
        
        checked = (try? values.decode(Bool.self, forKey: .checked)) ?? false
        group = try? values.decode(String.self, forKey: .group)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(selected, forKey: .selected)
        try container.encode(editing, forKey: .editing)
        try container.encode(pager, forKey: .pager)
        try container.encode(label, forKey: .label)
        try container.encode(checked, forKey: .checked)
        try container.encode(group, forKey: .group)
        for encoder in ListResultItem.encoders {
            do{
                try encoder(value, &container)
                break // if it worked, it encoded and we're done
            } catch { }
        }
    }
}

extension ListResultItem{
    var valueInt: Int?{
        return value as? Int
    }
}
