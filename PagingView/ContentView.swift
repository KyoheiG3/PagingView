//
//  ContentView.swift
//  Pods
//
//  Created by Kyohei Ito on 2015/10/09.
//
//

import UIKit

class ContentView: UIView {
    typealias Cell = PagingViewCell
    
    func visible(rect: CGRect) -> Bool {
        return CGRectIntersectsRect(rect, frame)
    }
    
    var position: Position?
    
    var cell: Cell? {
        return subviews.first as? Cell
    }
    
    func addContentCell(cell: Cell, indexPath: NSIndexPath) {
        cell.frame = CGRect(origin: CGPoint.zero, size: bounds.size)
        cell.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        addSubview(cell)
        cell.position = position
        cell.indexPath = indexPath
        cell.hidden = false
    }
    
    func contentMoveFrom(contentView: ContentView?) {
        removeContentCell()
        
        if let cell = contentView?.cell {
            addSubview(cell)
            cell.position = position
        }
    }
    
    func removeContentCell() {
        while let view = subviews.last {
            view.removeFromSuperview()
        }
    }
}
