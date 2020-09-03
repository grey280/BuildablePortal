//
//  SearchOptions.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

class SearchOptions: Codable {
    // inherited from base
    var pageNumber: Int? = 0
    var pageSize: Int? = 20
    var pagingDisabled: Bool?
    var filterText: String?
    var useDefaultReport: Bool?
    
    // just this one
    var sortBy: String?
    var isSortAscending: Bool?
    var pagerLetter: String?
    var columnSelection: [String]? = []
    var filters: [[SearchFilter]]? = []
    var fields: SearchFields?
}
