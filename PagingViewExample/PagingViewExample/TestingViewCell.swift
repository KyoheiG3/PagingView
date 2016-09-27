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
        
        backgroundColor = UIColor.red
        
        let label = UILabel(frame: CGRect.zero)
        label.frame = bounds
        label.font = UIFont.systemFont(ofSize: 32)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        self.label = label
        
        var constraints: [NSLayoutConstraint] = []
        constraints.append(NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        addConstraints(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
