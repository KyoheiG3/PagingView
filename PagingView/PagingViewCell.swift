//
//  PagingViewCell.swift
//  PagingView
//
//  Created by Kyohei Ito on 2015/09/02.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit

open class PagingViewCell: UIView {
    open internal(set) var indexPath = IndexPath(item: 0, section: 0)
    open internal(set) var reuseIdentifier: String?
    /// Position of contents
    open internal(set) var position: Position?
    
    open func prepareForReuse() {
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isHidden = true
    }
    
    public required override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
    }
}
