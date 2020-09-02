//
//  Pager.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import Foundation

class Pager: Codable {
    var pageSize: Int? = 100
    var pageNumber: Int? = 1
    var totalItems: Int? = 0
    var totalPages: Int? = 1
    var pages: [Int]? = []
    var itemStart: Int? = 1
    var itemEnd: Int? = 1
    var sortColumn: String? = ""
    var sortAscending: Bool? = false
    var pagerLetter: String? = ""
    var queryLetters: [String]? = []
    
    var loading: Bool? = false
    
//    func update(_ from: Pager, items: [Any]){
//        pageNumber = from.pageNumber
//        pageSize = from.pageSize
//        totalItems = from.totalItems
//        totalPages = Int(ceil(Float(totalItems) / Float(pageSize)))
//        queryLetters = from.queryLetters
//        pagerLetter = from.pagerLetter
//        setPages()
//        itemStart = (pageNumber - 1) * pageSize + 1
//        itemEnd = itemStart + items.count - 1
//    }
//
//    func setPages(){
//        pages = [];
//        // If we have fewer than 5 pages, show links to all
//        if (totalPages <= 5){
//            for i in 1...totalPages {
//                pages.append(i)
//            }
//        }else{
//            // Figure out which 5 pages links we show
//            // leftmost
//            if (pageNumber <= 3){
//                pages = [1, 2, 3, 4, 5]
//            } else if (totalPages - pageNumber < 3){
//                for i in (totalPages - 4)...totalPages {
//                    pages.append(i)
//                }
//            } else {
//                // keep current in middle
//                pages = [pageNumber - 2, pageNumber - 1, pageNumber, pageNumber + 1, pageNumber + 2]
//            }
//        }
//    }
}
