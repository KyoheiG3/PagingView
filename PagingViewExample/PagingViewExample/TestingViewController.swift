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
    
    var firstIndexPath = NSIndexPath(forItem: 2, inSection: 2)
    let items = [10, 0, 10]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        willDisplayLabel.text = nil
        didEndDisplayLabel.text = nil
        reloadLabel.text = nil
        
        pagingView.dataSource = self
        pagingView.delegate = self
        pagingView.pagingMargin = 10
        pagingView.pagingInset = 30
        
        let nib = UINib(nibName: "TestingViewCell", bundle: nil)
        pagingView.registerNib(nib, forCellWithReuseIdentifier: "RegisterNibCell")
        pagingView.registerClass(TestingViewCell.self, forCellWithReuseIdentifier: "RegisterClassCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ context in
            self.pagingView.pagingMargin = UInt(arc4random_uniform(3)) * 10
            self.pagingView.pagingInset = UInt(arc4random_uniform(3)) * 10
        }, completion: nil)
    }
}

extension TestingViewController: PagingViewDataSource, PagingViewDelegate {
    func pagingView(pagingView: PagingView, willDisplayCell cell: PagingViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        willDisplayLabel.text = "\(indexPath.section) - \(indexPath.item)"
    }
    
    func pagingView(pagingView: PagingView, didEndDisplayingCell cell: PagingViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        didEndDisplayLabel.text = "\(indexPath.section) - \(indexPath.item)"
    }
    
    func pagingView(pagingView: PagingView, numberOfItemsInSection section: Int) -> Int {
        return items[section]
    }
    
    func numberOfSectionsInPagingView(pagingView: PagingView) -> Int {
        return items.count
    }
    
    func indexPathOfStartingInPagingView(pagingView: PagingView) -> NSIndexPath? {
        return firstIndexPath
    }
    
    func pagingView(pagingView: PagingView, cellForItemAtIndexPath indexPath: NSIndexPath) -> PagingViewCell {
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
        pagingView.scrollToPosition(.Left, indexPath: NSIndexPath(forItem: 0, inSection: 2), animated: true)
    }
    
    @IBAction func toCenterButtonDidTap() {
        pagingView.scrollToPosition(.Center, indexPath: NSIndexPath(forItem: 3, inSection: 0), animated: true)
    }
    
    @IBAction func toRightButtonDidTap() {
        pagingView.scrollToPosition(.Right, indexPath: NSIndexPath(forItem: 7, inSection: 2), animated: true)
    }
    
    @IBAction func reloadButtonDidTap() {
        pagingView.pagingMargin = UInt(arc4random_uniform(3)) * 10
        pagingView.pagingInset = UInt(arc4random_uniform(3)) * 10
        
        firstIndexPath = NSIndexPath(forItem: Int(arc4random_uniform(10)), inSection: [0,2][Int(arc4random_uniform(2))])
        reloadLabel.text = "\(firstIndexPath.section) - \(firstIndexPath.item)"
        pagingView.reloadData()
    }
    
}