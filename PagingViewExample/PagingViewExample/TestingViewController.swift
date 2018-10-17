//
//  TestingViewController.swift
//  PagingViewExample
//
//  Created by Kyohei Ito on 2015/09/03.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import PagingView

class TestingViewController: UIViewController {
    @IBOutlet weak var pagingView: PagingView!
    @IBOutlet weak var willDisplayLabel: UILabel!
    @IBOutlet weak var didEndDisplayLabel: UILabel!
    @IBOutlet weak var configureLabel: UILabel!
    @IBOutlet weak var reloadLabel: UILabel!
    
    var firstIndexPath = IndexPath(item: 2, section: 2)
    let items = [10, 0, 10]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        willDisplayLabel.text = nil
        didEndDisplayLabel.text = nil
        reloadLabel.text = nil
        
        pagingView.dataSource = self
        pagingView.delegate = self
        pagingView.pagingMargin = 20
        pagingView.pagingInset = 40
        
        let nib = UINib(nibName: "TestingViewCell", bundle: nil)
        pagingView.registerNib(nib, forCellWithReuseIdentifier: "RegisterNibCell")
        pagingView.registerClass(TestingViewCell.self, forCellWithReuseIdentifier: "RegisterClassCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { context in
            guard let pagingView = self.pagingView else {
                return
            }
            
            if size.width <= size.height {
                pagingView.pagingMargin = 20
                pagingView.pagingInset = 40
            } else {
                pagingView.pagingMargin = 10
                pagingView.pagingInset = 20
            }
            
            UIView.animate(withDuration: context.transitionDuration,
                delay: 0,
                options: UIView.AnimationOptions(rawValue: UInt(context.completionCurve.rawValue << 16)),
                animations: pagingView.layoutIfNeeded,
                completion: nil)
        }, completion: nil)
    }
}

extension TestingViewController: PagingViewDataSource, PagingViewDelegate {
    func pagingView(_ pagingView: PagingView, willDisplayCell cell: PagingViewCell, forItemAtIndexPath indexPath: IndexPath) {
        willDisplayLabel.text = "\(indexPath.section) - \(indexPath.item)"
    }
    
    func pagingView(_ pagingView: PagingView, didEndDisplayingCell cell: PagingViewCell, forItemAtIndexPath indexPath: IndexPath) {
        didEndDisplayLabel.text = "\(indexPath.section) - \(indexPath.item)"
    }
    
    func pagingView(_ pagingView: PagingView, numberOfItemsInSection section: Int) -> Int {
        return items[section]
    }
    
    func numberOfSectionsInPagingView(_ pagingView: PagingView) -> Int {
        return items.count
    }
    
    func indexPathOfStartingInPagingView(_ pagingView: PagingView) -> IndexPath? {
        return firstIndexPath
    }
    
    func pagingView(_ pagingView: PagingView, cellForItemAtIndexPath indexPath: IndexPath) -> PagingViewCell {
        configureLabel.text = "\(indexPath.section) - \(indexPath.item)"
        
        let identifier: String
        if indexPath.item % 2 == 0 {
            identifier = "RegisterClassCell"
        } else {
            identifier = "RegisterNibCell"
        }
        
        let cell = pagingView.dequeueReusableCellWithReuseIdentifier(identifier)
        if let cell = cell as? TestingViewCell {
            cell.label.text = "\(indexPath.section) - \(indexPath.item)"
        }
        
        return cell
    }
}

extension TestingViewController {
    @IBAction func toLeftButtonDidTap() {
        pagingView.scrollToPosition(.left, indexPath: IndexPath(item: 0, section: 2), animated: true)
    }
    
    @IBAction func toCenterButtonDidTap() {
        pagingView.scrollToPosition(.center, indexPath: IndexPath(item: 3, section: 0), animated: true)
    }
    
    @IBAction func toRightButtonDidTap() {
        pagingView.scrollToPosition(.right, indexPath: IndexPath(item: 7, section: 2), animated: true)
    }
    
    @IBAction func reloadButtonDidTap() {
        pagingView.pagingMargin = UInt(arc4random_uniform(3)) * 10
        pagingView.pagingInset = UInt(arc4random_uniform(3)) * 10
        
        firstIndexPath = IndexPath(item: Int(arc4random_uniform(10)), section: [0,2][Int(arc4random_uniform(2))])
        reloadLabel.text = "\(firstIndexPath.section) - \(firstIndexPath.item)"
        pagingView.reloadData()
    }
    
}
