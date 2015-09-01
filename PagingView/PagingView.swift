//
//  PagingView.swift
//  PagingView
//
//  Created by Kyohei Ito on 2015/09/02.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit

@objc protocol PagingViewDataSource: class {
    func pagingView(pagingView: PagingView, numberOfItemsInSection section: Int) -> Int
    func pagingView(pagingView: PagingView, cellForItemAtIndexPath indexPath: NSIndexPath) -> PagingViewCell
    
    optional func numberOfSectionsInPagingView(pagingView: PagingView) -> Int
    optional func indexPathOfStartingInPagingView(pagingView: PagingView) -> NSIndexPath
}

@objc protocol PagingViewDelegate: UIScrollViewDelegate {
    optional func pagingView(pagingView: PagingView, willDisplayCell cell: PagingViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    optional func pagingView(pagingView: PagingView, didEndDisplayingCell cell: PagingViewCell, forItemAtIndexPath indexPath: NSIndexPath)
}

class PagingViewCell: UIView {
    private struct ReuseQueue {
        private var queue: [String: [PagingViewCell]] = [:]
        
        func dequeue(identifier: String) -> PagingViewCell? {
            return queue[identifier]?.filter { $0.superview == nil }.first
        }
        
        mutating func append(view: PagingViewCell, forQueueIdentifier identifier: String) {
            if queue[identifier] == nil {
                queue[identifier] = []
            }
            
            queue[identifier]?.append(view)
        }
        
        mutating func remove(identifier: String) {
            queue[identifier] = nil
        }
        
        func count(identifier: String) -> Int {
            return queue[identifier]?.count ?? 0
        }
    }
    
    private(set) var indexPath = NSIndexPath(forItem: 0, inSection: 0)
    private(set) var reuseIdentifier: String?
    
    func prepareForReuse() {
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
    }
}

class PagingView: UIScrollView {
    typealias Cell = PagingViewCell
    
    private class ContentView: UIView {
        var cell: Cell? {
            return subviews.first as? Cell
        }
        
        private func addContentCell(cell: Cell, indexPath: NSIndexPath) {
            cell.frame = CGRect(origin: CGPoint.zero, size: bounds.size)
            cell.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            addSubview(cell)
            cell.indexPath = indexPath
        }
        
        private func contentMoveFrom(contentView: ContentView) {
            removeContentCell()
            
            if let cell = contentView.cell {
                addSubview(cell)
            }
        }
        
        private func removeContentCell() {
            for view in subviews {
                view.removeFromSuperview()
            }
        }
    }
    
    enum Position {
        case Left
        case Center
        case Right
        case Same
        
        private func numberOfPages() -> Int {
            switch self {
            case Left:
                return 0
            case Center, Same:
                return 1
            case Right:
                return 2
            }
        }
        
        private func pagingPosition(ratio: CGFloat) -> Position {
            if ratio < CGFloat(Center.numberOfPages()) {
                return self == .Left ? .Same : .Left
            } else if ratio > CGFloat(Center.numberOfPages()) {
                return self == .Right ? .Same : .Right
            } else {
                return .Center
            }
        }
    }
    
    private var sectionCount = 1
    private var itemCountInSection: [Int: Int] = [:]
    private var pagingReuseQueue = PagingViewCell.ReuseQueue()
    private var registeredObject: [String: AnyObject] = [:]
    private var pagingContents: [ContentView] = []
    private var currentPosition = Position.Center
    private var toScrollIndexPath: NSIndexPath?
    
    private var leftContentView: ContentView {
        return pagingContentAtPosition(.Left)
    }
    private var centerContentView: ContentView {
        return pagingContentAtPosition(.Center)
    }
    private var rightContentView: ContentView {
        return pagingContentAtPosition(.Right)
    }
    
    var contentWidth: CGFloat {
        let scale = UIScreen.mainScreen().scale
        return round(contentSize.width / 3 * scale) / scale
    }
    
    private var infiniteOffset: CGPoint {
        return CGPoint(x: contentWidth * 2, y: contentSize.height - bounds.height)
    }
    
    weak var dataSource: PagingViewDataSource?
    
    private var pagingViewDelegate: PagingViewDelegate? {
        return delegate as? PagingViewDelegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        pagingEnabled = true
        scrollsToTop = false
        
        setupPagingContentView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        pagingEnabled = true
        scrollsToTop = false
        
        setupPagingContentView()
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        if let count = dataSource?.numberOfSectionsInPagingView?(self) {
            sectionCount = count
        }
        
        for section in 0..<sectionCount {
            if let count = dataSource?.pagingView(self, numberOfItemsInSection: section) {
                itemCountInSection[section] = count
            }
        }
        
        guard itemCountInSection.count >= 2 || (itemCountInSection.count >= 1 && itemCountInSection[0] >= 1) else {
            return
        }
        
        let indexPath = dataSource?.indexPathOfStartingInPagingView?(self) ?? NSIndexPath(forItem: 0, inSection: 0)
        if let cell = dataSource?.pagingView(self, cellForItemAtIndexPath: indexPath) {
            centerContentView.addContentCell(cell, indexPath: indexPath)
            pagingViewDelegate?.pagingView?(self, willDisplayCell: cell, forItemAtIndexPath: indexPath)
        }
    }
    
    override func layoutSubviews() {
        let beforeSize = contentSize
        super.layoutSubviews()
        
        if beforeSize != contentSize {
            setContentOffset(CGPoint(x: contentWidth * CGFloat(Position.Center.numberOfPages()), y: contentOffset.y), animated: false)
        } else {
            infiniteIfNeeded()
        }
        
        guard let _ = dataSource else {
            return
        }
        
        let position = currentPosition.pagingPosition(ceil(contentOffset.x) / ceil(contentWidth))
        guard position != .Same else {
            return
        }
        
        if position != .Center {
            configureNextContentAtPosition(position)
        }
        
        if currentPosition != .Center {
            let contentView = pagingContentAtPosition(currentPosition)
            didEndDisplayingView(contentView)
        }
        
        if position != .Center {
            let contentView = pagingContentAtPosition(position)
            willDisplayView(contentView)
        }
        
        currentPosition = position
    }
    
    func dequeueReusableCellWithReuseIdentifier(identifier: String) -> Cell {
        if let view = pagingReuseQueue.dequeue(identifier) {
            view.reuseIdentifier = identifier
            view.prepareForReuse()
            return view
        }
        
        var reuseContent: Cell!
        if let nib = registeredObject[identifier] as? UINib, instance = nib.instantiateWithOwner(nil, options: nil).first as? Cell {
            reuseContent = instance
        } else if let T = registeredObject[identifier] as? Cell.Type {
            reuseContent = T.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 600, height: 600)))
        } else {
            fatalError("could not dequeue a view of kind: UIView with identifier \(identifier) - must register a nib or a class for the identifier")
        }
        
        pagingReuseQueue.append(reuseContent, forQueueIdentifier: identifier)
        
        return reuseContent
    }
    
    func registerNib(nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        registeredObject[identifier] = nib
    }
    
    func registerClass<T: UIView>(viewClass: T.Type, forCellWithReuseIdentifier identifier: String) {
        registeredObject[identifier] = viewClass
    }
    
    func setContentPosition(position: Position, indexPath: NSIndexPath? = nil, animated: Bool = false) {
        toScrollIndexPath = indexPath
        if position == .Center || position == .Same {
            configureNextContentAtPosition(position)
        } else {
            setContentOffset(CGPoint(x: contentWidth * CGFloat(position.numberOfPages()), y: contentOffset.y), animated: animated)
        }
    }
    
    func reloadData() {
        leftContentView.removeContentCell()
        centerContentView.removeContentCell()
        rightContentView.removeContentCell()
        
        setNeedsDisplay()
    }
    
    func numberOfSections() -> Int {
        return sectionCount
    }
    
    func numberOfItemsInSection(section: Int) -> Int {
        return itemCountInSection[section] ?? 0
    }
    
    private func willPagingScrollToPrev() {
        rightContentView.contentMoveFrom(centerContentView)
        centerContentView.contentMoveFrom(leftContentView)
        didEndDisplayingView(rightContentView)
        
        currentPosition = .Center
    }
    
    private func willPagingScrollToPrevNext() {
        leftContentView.contentMoveFrom(centerContentView)
        centerContentView.contentMoveFrom(rightContentView)
        didEndDisplayingView(leftContentView)
        
        currentPosition = .Center
    }
    
    private func infiniteIfNeeded() {
        let offset = contentOffsetInfiniteIfNeeded(contentOffset)
        if contentOffset != offset {
            if offset.x > contentOffset.x {
                willPagingScrollToPrev()
            } else if offset.x < contentOffset.x {
                willPagingScrollToPrevNext()
            }
            contentOffset = offset
        }
    }
    
    private func contentOffsetInfiniteIfNeeded(offset: CGPoint) -> CGPoint {
        func xOffset() -> CGFloat? {
            if offset.x <= 0 {
                return offset.x + contentWidth
            } else if infiniteOffset.x < offset.x {
                return offset.x - contentWidth
            } else if infiniteOffset.x == offset.x {
                return contentWidth
            }
            return nil
        }
        
        let x = xOffset()
        
        return CGPoint(x: x ?? offset.x, y: offset.y)
    }
    
    private func pagingContentAtPosition(position: Position) -> ContentView {
        return pagingContents[position.numberOfPages()]
    }
    
    private func configureNextContentAtPosition(position: Position) {
        guard let centerCell = centerContentView.cell else {
            return
        }
        
        let indexPath = toScrollIndexPath ?? indexPathAtPosition(position, indexPath: centerCell.indexPath)
        toScrollIndexPath = nil
        
        let contentView = pagingContentAtPosition(position)
        if contentView.cell?.indexPath != indexPath {
            configureView(contentView, indexPath: indexPath)
        }
    }
    
    private func configureView(contentView: ContentView, indexPath: NSIndexPath) {
        if let cell = dataSource?.pagingView(self, cellForItemAtIndexPath: indexPath) {
            contentView.removeContentCell()
            contentView.addContentCell(cell, indexPath: indexPath)
        }
    }
    
    private func willDisplayView(contentView: ContentView) {
        if let cell = contentView.cell {
            pagingViewDelegate?.pagingView?(self, willDisplayCell: cell, forItemAtIndexPath: cell.indexPath)
        }
    }
    
    private func didEndDisplayingView(contentView: ContentView) {
        if let cell = contentView.cell {
            pagingViewDelegate?.pagingView?(self, didEndDisplayingCell: cell, forItemAtIndexPath: cell.indexPath)
        }
    }
    
    private func indexPathAtPosition(position: Position, indexPath: NSIndexPath) -> NSIndexPath {
        var section = indexPath.section
        var item = indexPath.item
        
        switch position {
        case .Left:
            if --item < 0 {
                if --section < 0 {
                    section = sectionCount - 1
                }
                item = itemCountInSection[section]! - 1
            }
            
            return NSIndexPath(forItem: item, inSection: section)
        case .Right:
            if ++item >= itemCountInSection[section] {
                if ++section >= sectionCount {
                    section = 0
                }
                item = 0
            }
            
            return NSIndexPath(forItem: item, inSection: section)
        case .Center, .Same:
            return indexPath
        }
    }
    
    private func setupPagingContentView() {
        let pageCount = 3
        
        for _ in 0..<pageCount {
            let contentView = ContentView(frame: bounds)
            layoutPagingViewContent(contentView)
            
            let constraints: [NSLayoutConstraint]
            if let lastContent = pagingContents.last {
                constraints = NSLayoutConstraint.constraintsWithVisualFormat("[leftView][rightView]", options: [], metrics: nil, views: ["leftView": lastContent, "rightView": contentView])
            } else {
                constraints = NSLayoutConstraint.constraintsWithVisualFormat("|[subview]", options: [], metrics: nil, views: ["subview": contentView])
            }
            addConstraints(constraints)
            
            pagingContents.append(contentView)
        }
        
        if let lastContent = pagingContents.last {
            let constraints = NSLayoutConstraint.constraintsWithVisualFormat("[subview]|", options: [], metrics: nil, views: ["subview": lastContent])
            addConstraints(constraints)
        }
    }
    
    private func layoutPagingViewContent(contentView: ContentView) {
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        let horizontal = NSLayoutConstraint.constraintsWithVisualFormat("[subview(==superview)]", options: [], metrics: nil, views: ["superview": self, "subview": contentView])
        let vertical = NSLayoutConstraint.constraintsWithVisualFormat("V:|[subview(==superview)]|", options: [], metrics: nil, views: ["superview": self, "subview": contentView])
        addConstraints(horizontal + vertical)
    }
}

extension PagingView {
    private func visibleContents() -> [UIView] {
        let visibleRect = CGRect(origin: contentOffset, size: bounds.size)
        
        return pagingContents.filter {
            CGRectIntersectsRect(visibleRect, $0.frame)
        }
    }
    
    private func visibleContents<T>() -> [T] {
        return visibleContents().filter { $0 is T }.map { $0 as! T }
    }
    
    func visibleCells() -> [Cell] {
        let views = visibleContents().map { ($0 as? ContentView)?.cell }
        
        return views.filter { $0 != nil }.map { $0! }
    }
    
    func visibleCells<T>() -> [T] {
        return visibleCells().filter { $0 is T }.map { $0 as! T }
    }
    
    func visibleCenterCell() -> PagingViewCell? {
        return centerContentView.cell
    }
    
    func visibleCenterCell<T>() -> T? {
        return centerContentView.cell as? T
    }
}
