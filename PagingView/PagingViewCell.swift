//
//  PagingViewCell.swift
//  PagingView
//
//  Created by Kyohei Ito on 2015/09/02.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit

public class PagingViewCell: UIView {
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
