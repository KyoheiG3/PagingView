//
//  Position.swift
//  Pods
//
//  Created by Kyohei Ito on 2015/09/29.
//
//

/// Position of contents of PagingView.
public enum Position: Int {
    case left = 0
    case center
    case right
    
    static let count = 3
    
    func numberOfPages() -> Int {
        return rawValue
    }
}
