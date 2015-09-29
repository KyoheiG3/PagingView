//
//  PagingViewCell.swift
//  PagingView
//
//  Created by Kyohei Ito on 2015/09/02.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit

public class PagingViewCell: UIView {
    struct ReuseQueue {
        private var queue: [String: [PagingViewCell]] = [:]
        
        func dequeue(identifier: String) -> PagingViewCell? {
            return queue[identifier]?.filter { $0.superview == nil }.first
        }
        
        mutating func append(view: PagingViewCell, forQueueIdentifier identifier: String) {
            if queue[identifier] == nil {
                queue[identifier] = []
            }
            
            queue[identifier]?.append(view)
        }
        
        mutating func remove(identifier: String) {
            queue[identifier] = nil
        }
        
        func count(identifier: String) -> Int {
            return queue[identifier]?.count ?? 0
        }
    }
    
    public internal(set) var indexPath = NSIndexPath(forItem: 0, inSection: 0)
    public internal(set) var reuseIdentifier: String?
    /// Position of contents
    public internal(set) var position: Position?
    
    public func prepareForReuse() {
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        hidden = true
    }
    
    public required override init(frame: CGRect) {
        super.init(frame: frame)
        hidden = true
    }
}
