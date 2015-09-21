//
//  Constraints.swift
//  PagingView
//
//  Created by Kyohei Ito on 2015/09/08.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit

func + (lhs: Constraints, rhs: Constraints) -> Constraints {
    var constraints = Constraints()
    constraints.append(lhs)
    constraints.append(rhs)
    return constraints
}

struct Constraints {
    private(set) var collection: [NSLayoutConstraint] = []
    
    mutating func append(constraints: Constraints) {
        collection.appendContentsOf(constraints.collection)
    }
    
    mutating func append(constraints: [NSLayoutConstraint]) {
        collection.appendContentsOf(constraints)
    }
    
    mutating func append(constraint: NSLayoutConstraint) {
        collection.append(constraint)
    }
    
    mutating func removeAll() {
        collection.removeAll()
    }
    
    var constant: CGFloat {
        get {
            return collection.reduce(0) { $0.0 + $0.1.constant } / CGFloat(collection.count)
        }
        set(constant) {
            for constraint in collection {
                constraint.constant = constant
            }
        }
    }
}
