//
//  SearchFilter.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

class SearchFilter: Codable {
    enum CompareType: Int, Codable {
        case String = 1, Number, DateTime, TableEnum, Boolean, Enum = 8
    }
    
    enum Operator: Int, Codable {
        case Is = 1, IsNot, Contain, NotContain, GreaterThan, LessThan, Before, After
    }
    
    var property: String?
    var relatedEntityIDPropertyName: String? // from relatedEntityIdPropertyName
    var value: String?
    var compareType: CompareType?
    var operatorType: Operator?
    
    enum CodingKeys: String, CodingKey {
        case property, relatedEntityIDPropertyName = "relatedEntityIdPropertyName", value, compareType, operatorType
    }
}
