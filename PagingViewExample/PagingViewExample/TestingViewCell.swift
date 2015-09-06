//
//  TestingViewCell.swift
//  PagingViewExample
//
//  Created by Kyohei Ito on 2015/09/03.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import PagingView

class TestingViewCell: PagingViewCell {
    @IBOutlet weak var label: UILabel!
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.redColor()
        
        let label = UILabel(frame: CGRect.zero)
        label.frame = bounds
        label.font = UIFont.systemFontOfSize(32)
        label.textAlignment = .Center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        self.label = label
        
        var constraints: [NSLayoutConstraint] = []
        constraints.append(NSLayoutConstraint(item: label, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: label, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0))
        addConstraints(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
