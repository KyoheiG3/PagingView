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
    
    func visible(_ rect: CGRect) -> Bool {
        return rect.intersects(frame)
    }
    
    var position: Position?
    
    var cell: Cell? {
        return subviews.first as? Cell
    }
    
    func addContentCell(_ cell: Cell, indexPath: IndexPath) {
        cell.frame = CGRect(origin: CGPoint.zero, size: bounds.size)
        cell.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(cell)
        cell.position = position
        cell.indexPath = indexPath
        cell.isHidden = false
    }
    
    func contentMoveFrom(_ contentView: ContentView?) {
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
