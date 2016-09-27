//
//  DemoViewController.swift
//  PagingViewExample
//
//  Created by Kyohei Ito on 2015/09/03.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import PagingView

class DemoViewController: UIViewController {
    @IBOutlet weak var pagingView: PagingView!
    
    let imageNames: [String] = ["1", "2", "3", "4", "5"]

    override func viewDidLoad() {
        super.viewDidLoad()

        pagingView.dataSource = self
        pagingView.delegate = self
        pagingView.pagingMargin = 10
        pagingView.pagingInset = 30
        
        let nib = UINib(nibName: "DemoViewCell", bundle: nil)
        pagingView.registerNib(nib, forCellWithReuseIdentifier: "DemoViewCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension DemoViewController: PagingViewDataSource, PagingViewDelegate, UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let centerCell = pagingView.visibleCenterCell() {
            let imageName = imageNames[centerCell.indexPath.item]
            title = imageName
        }
    }
    
    func pagingView(_ pagingView: PagingView, numberOfItemsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func pagingView(_ pagingView: PagingView, cellForItemAtIndexPath indexPath: IndexPath) -> PagingViewCell {
        let cell = pagingView.dequeueReusableCellWithReuseIdentifier("DemoViewCell")
        if let cell = cell as? DemoViewCell {
            let imageName = imageNames[indexPath.item]
            cell.imageView.image = UIImage(named: imageName)
        }
        
        return cell
    }
}
