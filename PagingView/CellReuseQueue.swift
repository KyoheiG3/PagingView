//
//  CellReuseQueue.swift
//  Pods
//
//  Created by Kyohei Ito on 2015/10/09.
//
//

struct CellReuseQueue {
    private var queue: [String: [PagingViewCell]] = [:]
    
    func dequeue(_ identifier: String) -> PagingViewCell? {
        return queue[identifier]?.filter { $0.superview == nil }.first
    }
    
    mutating func append(_ view: PagingViewCell, forQueueIdentifier identifier: String) {
        if queue[identifier] == nil {
            queue[identifier] = []
        }
        
        queue[identifier]?.append(view)
    }
    
    mutating func remove(_ identifier: String) {
        queue[identifier] = nil
    }
    
    func count(_ identifier: String) -> Int {
        return queue[identifier]?.count ?? 0
    }
}
