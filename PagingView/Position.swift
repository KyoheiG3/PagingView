//
//  Position.swift
//  Pods
//
//  Created by Kyohei Ito on 2015/09/29.
//
//

/// Position of contents of PagingView.
public enum Position: Int {
    case Left = 0
    case Center
    case Right
    
    static let count = 3
    
    func numberOfPages() -> Int {
        return rawValue
    }
}
