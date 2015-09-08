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
        
        let nib = UINib(nibName: "DemoViewCell", bundle: nil)
        pagingView.registerNib(nib, forCellWithReuseIdentifier: "DemoViewCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ context in
            if size.width <= size.height {
                self.pagingView.pagingMargin = 0
                self.pagingView.pagingInset = 0
            } else {
                self.pagingView.pagingMargin = 20
                self.pagingView.pagingInset = 40
            }
        }, completion: nil)
    }
}

extension DemoViewController: PagingViewDataSource, PagingViewDelegate, UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if let centerCell = pagingView.visibleCenterCell() {
            let imageName = imageNames[centerCell.indexPath.item]
            title = imageName
        }
    }
    
    func pagingView(pagingView: PagingView, numberOfItemsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func pagingView(pagingView: PagingView, cellForItemAtIndexPath indexPath: NSIndexPath) -> PagingViewCell {
        let cell = pagingView.dequeueReusableCellWithReuseIdentifier("DemoViewCell")
        if let cell = cell as? DemoViewCell {
            let imageName = imageNames[indexPath.item]
            cell.imageView.image = UIImage(named: imageName)
        }
        
        return cell
    }
}
