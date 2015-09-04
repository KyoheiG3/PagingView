//
//  PagingView.swift
//  PagingView
//
//  Created by Kyohei Ito on 2015/09/02.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit

@objc public protocol PagingViewDataSource: class {
    func pagingView(pagingView: PagingView, numberOfItemsInSection section: Int) -> Int
    func pagingView(pagingView: PagingView, cellForItemAtIndexPath indexPath: NSIndexPath) -> PagingViewCell
    
    optional func numberOfSectionsInPagingView(pagingView: PagingView) -> Int
    optional func indexPathOfStartingInPagingView(pagingView: PagingView) -> NSIndexPath?
}

@objc public protocol PagingViewDelegate: UIScrollViewDelegate {
    optional func pagingView(pagingView: PagingView, willDisplayCell cell: PagingViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    optional func pagingView(pagingView: PagingView, didEndDisplayingCell cell: PagingViewCell, forItemAtIndexPath indexPath: NSIndexPath)
}

public class PagingView: UIScrollView {
    typealias Cell = PagingViewCell
    
    class ContentView: UIView {
        func visible(rect: CGRect) -> Bool {
            return CGRectIntersectsRect(rect, frame)
        }
        
        var cell: Cell? {
            return subviews.first as? Cell
        }
        
        func addContentCell(cell: Cell, indexPath: NSIndexPath) {
            cell.frame = CGRect(origin: CGPoint.zero, size: bounds.size)
            cell.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            addSubview(cell)
            cell.indexPath = indexPath
            cell.hidden = false
        }
        
        func contentMoveFrom(contentView: ContentView) {
            removeContentCell()
            
            if let cell = contentView.cell {
                addSubview(cell)
            }
        }
        
        func removeContentCell() {
            while let view = subviews.last {
                view.removeFromSuperview()
            }
        }
    }
    
    /// Position of contents of PagingView.
    public enum Position {
        case Left
        case Center
        case Right
        
        func numberOfPages() -> Int {
            switch self {
            case Left:
                return 0
            case Center:
                return 1
            case Right:
                return 2
            }
        }
    }
    
    private let pagingContentCount = 3
    private var sectionCount = 1
    private var itemCountInSection: [Int: Int] = [:]
    private var pagingReuseQueue = PagingViewCell.ReuseQueue()
    private var registeredObject: [String: AnyObject] = [:]
    private var pagingContents: [ContentView] = []
    private var reloadingIndexPath: NSIndexPath?
    
    private var leftContentView: ContentView {
        return contentViewAtPosition(.Left)
    }
    private var centerContentView: ContentView {
        return contentViewAtPosition(.Center)
    }
    private var rightContentView: ContentView {
        return contentViewAtPosition(.Right)
    }
    
    private var pagingViewDelegate: PagingViewDelegate? {
        return delegate as? PagingViewDelegate
    }
    
    @IBOutlet public weak var dataSource: PagingViewDataSource?
    /// Margin between the content.
    public var pagingMargin: UInt = 0
    /// Inset of content relative to size of PagingView. Value of two times than of pagingInset to set for the left and right of contentInset.
    public var pagingInset: UInt = 0
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        pagingEnabled = true
        scrollsToTop = false
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        pagingEnabled = true
        scrollsToTop = false
    }
    
    func contentViewAtPosition(position: Position) -> ContentView {
        return pagingContents[position.numberOfPages()]
    }
    
    func contentOffsetXAtPosition(position: Position) -> CGFloat {
        let view = contentViewAtPosition(position)
        let pagingSpace = CGFloat(pagingInset + pagingMargin)
        return view.frame.origin.x - pagingSpace
    }
    
    public func dequeueReusableCellWithReuseIdentifier(identifier: String) -> PagingViewCell {
        if let view = pagingReuseQueue.dequeue(identifier) {
            view.reuseIdentifier = identifier
            view.prepareForReuse()
            return view
        }
        
        var reuseContent: Cell!
        if let nib = registeredObject[identifier] as? UINib, instance = nib.instantiateWithOwner(nil, options: nil).first as? Cell {
            reuseContent = instance
        } else if let T = registeredObject[identifier] as? Cell.Type {
            reuseContent = T.init(frame: bounds)
        } else {
            fatalError("could not dequeue a view of kind: UIView with identifier \(identifier) - must register a nib or a class for the identifier")
        }
        
        pagingReuseQueue.append(reuseContent, forQueueIdentifier: identifier)
        
        return reuseContent
    }
    
    /// For each reuse identifier that the paging view will use, register either a class or a nib from which to instantiate a cell.
    /// If a nib is registered, it must contain exactly 1 top level object which is a PagingViewCell.
    /// If a class is registered, it will be instantiated via alloc/initWithFrame:
    public func registerNib(nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        registeredObject[identifier] = nib
    }
    
    public func registerClass<T: UIView>(viewClass: T.Type, forCellWithReuseIdentifier identifier: String) {
        registeredObject[identifier] = viewClass
    }
    
    /// discard the dataSource and delegate data and requery as necessary.
    public func reloadData() {
        reloadingIndexPath = centerContentView.cell?.indexPath
        leftContentView.removeContentCell()
        centerContentView.removeContentCell()
        rightContentView.removeContentCell()
        
        setNeedsDisplay()
    }
    
    /// Information about the current state of the paging view.
    
    public func numberOfSections() -> Int {
        return sectionCount
    }
    
    public func numberOfItemsInSection(section: Int) -> Int {
        return itemCountInSection[section] ?? 0
    }
    
    /// To scroll at Position. Cell configure is performed at NSIndexPath.
    public func scrollToPosition(position: Position, indexPath: NSIndexPath? = nil, animated: Bool = false) {
        guard position != .Center else {
            configureAtPosition(.Center, toIndexPath: indexPath)
            return
        }
        
        defer {
            let offsetX = contentOffsetXAtPosition(position)
            setContentOffset(CGPoint(x: offsetX, y: contentOffset.y), animated: animated)
        }
        
        guard let indexPath = indexPath else {
            return
        }
        
        configureAtPosition(position, toIndexPath: indexPath)
    }
    
    /// Configure cell of Position. IndexPath of cell in the center if indexPath is nil.
    public func configureAtPosition(position: Position, toIndexPath: NSIndexPath? = nil) {
        let indexPath: NSIndexPath
        
        if let toIndexPath = toIndexPath {
            indexPath = toIndexPath
        } else {
            guard let centerCell = centerContentView.cell else {
                return
            }
            
            indexPath = indexPathAtPosition(position, indexPath: centerCell.indexPath)
        }
        
        let contentView = contentViewAtPosition(position)
        if contentView.cell?.indexPath != indexPath {
            configureView(contentView, indexPath: indexPath)
        }
    }
    
    func indexPathAtPosition(position: Position, indexPath: NSIndexPath) -> NSIndexPath {
        var section = indexPath.section
        var item = indexPath.item
        
        switch position {
        case .Left:
            if --item < 0 {
                if --section < 0 {
                    section = sectionCount - 1
                }
                item = numberOfItemsInSection(section) - 1
            }
            
            return NSIndexPath(forItem: item, inSection: section)
        case .Right:
            if ++item >= numberOfItemsInSection(section) {
                if ++section >= sectionCount {
                    section = 0
                }
                item = 0
            }
            
            return NSIndexPath(forItem: item, inSection: section)
        case .Center:
            return indexPath
        }
    }
    
    func configureView(contentView: ContentView, indexPath: NSIndexPath) {
        contentView.removeContentCell()
        if let cell = dataSource?.pagingView(self, cellForItemAtIndexPath: indexPath) {
            contentView.addContentCell(cell, indexPath: indexPath)
        }
    }
}

// MARK: - Layout and Display
extension PagingView {
    public override func layoutSubviews() {
        let beforeSize = contentSize
        super.layoutSubviews()
        
        guard pagingContents.count > 0 else {
            return
        }
        
        if beforeSize != contentSize {
            contentSize = CGSize(width: floor(contentSize.width), height: floor(contentSize.height))
            let offsetX = contentOffsetXAtPosition(.Center)
            setContentOffset(CGPoint(x: offsetX, y: contentOffset.y), animated: false)
        } else {
            infiniteIfNeeded()
        }
        
        guard dataSource != nil else {
            return
        }
        
        changeDisplayStatusForCell()
    }
    
    func infiniteIfNeeded() {
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
    
    func contentOffsetInfiniteIfNeeded(offset: CGPoint) -> CGPoint {
        func xOffset() -> CGFloat? {
            let contentOffsetLeft = contentOffsetXAtPosition(.Left)
            let contentOffsetCenter = contentOffsetXAtPosition(.Center)
            let contentOffsetRight = contentOffsetXAtPosition(.Right)
            
            if offset.x - CGFloat(pagingInset) <= contentOffsetLeft {
                return offset.x + contentOffsetCenter + contentInset.left
            } else if contentOffsetRight < offset.x + CGFloat(pagingInset) {
                return offset.x - contentOffsetCenter - contentInset.right
            } else if contentOffsetRight == offset.x + CGFloat(pagingInset) {
                return contentOffsetCenter - CGFloat(pagingInset)
            }
            
            return nil
        }
        
        let x = xOffset()
        
        return CGPoint(x: x ?? offset.x, y: offset.y)
    }
    
    func willPagingScrollToPrev() {
        rightContentView.contentMoveFrom(centerContentView)
        centerContentView.contentMoveFrom(leftContentView)
    }
    
    func willPagingScrollToPrevNext() {
        leftContentView.contentMoveFrom(centerContentView)
        centerContentView.contentMoveFrom(rightContentView)
    }
    
    func changeDisplayStatusForCell() {
        let visibleOffset = CGRect(origin: contentOffset, size: bounds.size)
        
        func endDisplay(position: Position) {
            let view = contentViewAtPosition(position)
            let visible = view.visible(visibleOffset)
            
            guard let cell = view.cell where visible == cell.hidden && visible == false else {
                return
            }
            
            didEndDisplayingView(view)
        }
        
        func willDisplay(position: Position) {
            let view = contentViewAtPosition(position)
            let visible = view.visible(visibleOffset)
            
            guard (view.cell == nil || visible == view.cell?.hidden) && visible == true else {
                return
            }
            
            if view.cell == nil {
                configureAtPosition(position)
            }
            
            willDisplayView(view)
        }
        
        endDisplay(.Left)
        endDisplay(.Right)
        
        willDisplay(.Left)
        willDisplay(.Right)
    }
    
    func willDisplayView(contentView: ContentView) {
        if let cell = contentView.cell {
            pagingViewDelegate?.pagingView?(self, willDisplayCell: cell, forItemAtIndexPath: cell.indexPath)
            cell.hidden = false
        }
    }
    
    func didEndDisplayingView(contentView: ContentView) {
        if let cell = contentView.cell {
            cell.hidden = true
            pagingViewDelegate?.pagingView?(self, didEndDisplayingCell: cell, forItemAtIndexPath: cell.indexPath)
        }
    }
    
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        if let count = dataSource?.numberOfSectionsInPagingView?(self) {
            sectionCount = count
        }
        
        for section in 0..<sectionCount {
            if let count = dataSource?.pagingView(self, numberOfItemsInSection: section) {
                itemCountInSection[section] = count
            }
        }
        
        contentInset.left = -CGFloat(pagingInset * 2)
        contentInset.right = -CGFloat(pagingInset * 2)
        
        removeContentView()
        setupPagingContentView()
        
        guard itemCountInSection.count >= 2 || (itemCountInSection.count >= 1 && numberOfItemsInSection(0) >= 1) else {
            return
        }
        
        let indexPath = dataSource?.indexPathOfStartingInPagingView?(self) ?? reloadingIndexPath ?? NSIndexPath(forItem: 0, inSection: 0)
        reloadingIndexPath = nil
        
        configureView(centerContentView, indexPath: indexPath)
        willDisplayView(centerContentView)
    }
    
    func setupPagingContentView() {
        let superKey = "superView"
        let contentKey = "contentView"
        let lastContentKey = "lastContentView"
        let spaceKey = "space"
        let pagingSpace = CGFloat(pagingInset + pagingMargin)
        
        func constraintsWithFormat(format: String, metrics: [String : AnyObject]? = nil, views: [String : AnyObject]) -> [NSLayoutConstraint] {
            return NSLayoutConstraint.constraintsWithVisualFormat(format, options: [], metrics: metrics, views: views)
        }
        
        func widthConstraints(contentView: ContentView) -> [NSLayoutConstraint] {
            return [NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: contentView, attribute: .Width, multiplier: 1, constant: pagingSpace * 2)]
        }
        
        func heightConstraints(contentView: ContentView) -> [NSLayoutConstraint] {
            return constraintsWithFormat("V:|[\(contentKey)(==\(superKey))]|", views: [contentKey: contentView, superKey: self])
        }
        
        func leftSpaceConstraints(contentView: ContentView) -> [NSLayoutConstraint] {
            return constraintsWithFormat("|-\(spaceKey)-[\(contentKey)]", metrics: [spaceKey: pagingSpace - contentInset.left], views: [contentKey: contentView])
        }
        
        func betweenSpaceConstraints(contentView: ContentView, lastContentView: ContentView) -> [NSLayoutConstraint] {
            return constraintsWithFormat("[\(lastContentKey)]-\(spaceKey)-[\(contentKey)]", metrics: [spaceKey: pagingMargin * 2], views: [contentKey: contentView, lastContentKey: lastContentView])
        }
        
        func rightSpaceConstraints(lastContentView: ContentView) -> [NSLayoutConstraint] {
            return constraintsWithFormat("[\(lastContentKey)]-\(spaceKey)-|", metrics: [spaceKey: pagingSpace - contentInset.right], views: [lastContentKey: lastContentView])
        }
        
        var constraints: [NSLayoutConstraint] = []
        func layoutPagingViewContent(contentView: ContentView?, lastContentView: ContentView?) {
            if let contentView = contentView {
                constraints.appendContentsOf(widthConstraints(contentView))
                constraints.appendContentsOf(heightConstraints(contentView))
                
                if let lastContentView = lastContentView {
                    constraints.appendContentsOf(betweenSpaceConstraints(contentView, lastContentView: lastContentView))
                } else {
                    constraints.appendContentsOf(leftSpaceConstraints(contentView))
                }
            } else if let lastContentView = lastContentView {
                constraints.appendContentsOf(rightSpaceConstraints(lastContentView))
            }
        }
        
        for _ in 0..<pagingContentCount {
            let contentView = ContentView(frame: bounds)
            contentView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(contentView)
            
            layoutPagingViewContent(contentView, lastContentView: pagingContents.last)
            pagingContents.append(contentView)
        }
        
        layoutPagingViewContent(nil, lastContentView: pagingContents.last)
        addConstraints(constraints)
    }
    
    func removeContentView() {
        while let view = pagingContents.popLast() {
            view.removeFromSuperview()
        }
    }
}

// MARK: - Visibility
extension PagingView {
    func visibleContents() -> [UIView] {
        let visibleRect = CGRect(origin: contentOffset, size: bounds.size)
        
        return pagingContents.filter {
            CGRectIntersectsRect(visibleRect, $0.frame)
        }
    }
    
    func visibleContents<T>() -> [T] {
        return visibleContents().filter { $0 is T }.map { $0 as! T }
    }
    
    public func visibleCells() -> [PagingViewCell] {
        let views = visibleContents().map { ($0 as? ContentView)?.cell }
        
        return views.filter { $0 != nil }.map { $0! }
    }
    
    public func visibleCells<T>() -> [T] {
        return visibleCells().filter { $0 is T }.map { $0 as! T }
    }
    
    public func visibleCenterCell() -> PagingViewCell? {
        return centerContentView.cell
    }
    
    public func visibleCenterCell<T>() -> T? {
        return centerContentView.cell as? T
    }
}
