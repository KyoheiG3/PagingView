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
    
    private enum PagingViewError: ErrorType {
        case IndexPathRange(String)
    }
    
    private struct ConstraintGroup {
        var heights: Constraints = Constraints()
        var widths: Constraints = Constraints()
        var betweenSpaces: Constraints = Constraints()
        var leftSpaces: Constraints = Constraints()
        var rightSpaces: Constraints = Constraints()
        
        func allConstraints() -> Constraints {
            return heights + widths + betweenSpaces + leftSpaces + rightSpaces
        }
        
        mutating func removeAll() {
            heights.removeAll()
            widths.removeAll()
            betweenSpaces.removeAll()
            leftSpaces.removeAll()
            rightSpaces.removeAll()
        }
    }
    
    private var sectionCount = 1
    private var itemCountInSection: [Int] = []
    private var cellReuseQueue = CellReuseQueue()
    private var registeredObject: [String: AnyObject] = [:]
    private var pagingContents: [ContentView] = []
    private var nextConfigurationIndexPath: NSIndexPath?
    private var needsReload: Bool = true
    private var needsLayout: Bool = false
    private var constraintGroup: ConstraintGroup = ConstraintGroup()
    
    private var allItemCount: Int {
        return itemCountInSection.reduce(0) { return $0.0 + $0.1 }
    }
    private var leftContentView: ContentView? {
        return contentViewAtPosition(.Left)
    }
    private var centerContentView: ContentView? {
        return contentViewAtPosition(.Center)
    }
    private var rightContentView: ContentView? {
        return contentViewAtPosition(.Right)
    }
    private var pretenseCenterContentView: ContentView? {
        if leftPagingEdge {
            return leftContentView
        } else if rightPagingEdge {
            return rightContentView
        } else {
            return centerContentView
        }
    }
    
    private var pagingViewDelegate: PagingViewDelegate? {
        return delegate as? PagingViewDelegate
    }
    
    @IBOutlet public weak var dataSource: PagingViewDataSource?
    /// Margin between the content.
    public var pagingMargin: UInt = 0 {
        didSet { invalidateLayout() }
    }
    /// Inset of content relative to size of PagingView. Value of two times than of pagingInset to set for the left and right of contentInset.
    public var pagingInset: UInt = 0 {
        didSet { invalidateLayout() }
    }
    var pagingSpace: CGFloat {
        return CGFloat(pagingInset + pagingMargin)
    }
    /// Infinite looping enabled flag.
    public var infinite: Bool = true
    var infiniteLeftScroll: Bool {
        return infinite || leftContentView?.cell?.indexPath != firstForceIndexPath()
    }
    var infiniteRightScroll: Bool {
        return infinite || rightContentView?.cell?.indexPath != lastForceIndexPath()
    }
    var leftPagingEdge: Bool {
        return infiniteLeftScroll == false && (leftEdge(contentOffset) || centerContentView?.cell == nil)
    }
    var rightPagingEdge: Bool {
        return infiniteRightScroll == false && (rightEdge(contentOffset) || centerContentView?.cell == nil)
    }
    lazy var lastLeftPagingEdge: Bool = self.leftPagingEdge
    lazy var lastRightPagingEdge: Bool = self.rightPagingEdge
    
    func leftEdge(offset: CGPoint) -> Bool {
        return offset.x + (contentInset.left / 2) <= contentOffsetXAtPosition(.Left)
    }
    
    func rightEdge(offset: CGPoint) -> Bool {
        guard let contentOffsetCenter = contentOffsetXAtPosition(.Center) else {
            return false
        }
        
        let contentOffsetRight = contentSize.width - contentOffsetCenter + contentInset.right
        return contentOffsetRight <= offset.x - (contentInset.right / 2)
    }
    
    func contentViewAtPosition(position: Position) -> ContentView? {
        let page = position.numberOfPages()
        if pagingContents.count > page {
            return pagingContents[page]
        }
        
        return nil
    }
    
    func contentOffsetXAtPosition(position: Position) -> CGFloat? {
        if let view = contentViewAtPosition(position) {
            return view.frame.origin.x - (constraintGroup.widths.constant / 2)
        }
        
        return nil
    }
    
    public func dequeueReusableCellWithReuseIdentifier(identifier: String) -> PagingViewCell {
        if let view = cellReuseQueue.dequeue(identifier) {
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
        
        cellReuseQueue.append(reuseContent, forQueueIdentifier: identifier)
        
        return reuseContent
    }
    
    /// For each reuse identifier that the paging view will use, register either a class or a nib from which to instantiate a cell.
    /// If a nib is registered, it must contain exactly 1 top level object which is a PagingViewCell.
    /// If a class is registered, it will be instantiated via alloc/initWithFrame:
    public func registerNib(nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        registeredObject[identifier] = nib
    }
    
    public func registerClass<T: PagingViewCell>(viewClass: T.Type, forCellWithReuseIdentifier identifier: String) {
        registeredObject[identifier] = viewClass
    }
    
    /// Discard the dataSource and delegate data, also requery as necessary.
    public func reloadData() {
        constraintGroup.removeAll()
        removeContentView()
        
        needsReload = true
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    /// Relayout as necessary.
    public func invalidateLayout() {
        needsLayout = true
        setNeedsLayout()
    }
    
    /// Information about the current state of the paging view.
    
    public func numberOfSections() -> Int {
        return dataSource?.numberOfSectionsInPagingView?(self) ?? 1
    }
    
    public func numberOfItemsInSection(section: Int) -> Int {
        return dataSource?.pagingView(self, numberOfItemsInSection: section) ?? 0
    }
    
    /// To scroll at Position. Cell configure is performed at NSIndexPath.
    public func scrollToPosition(position: Position, indexPath: NSIndexPath? = nil, animated: Bool = false) {
        var scrollPosition = position
        if leftPagingEdge {
            switch position {
            case .Left:
                infiniteForced()
            case .Center:
                configureAtPosition(.Left, toIndexPath: indexPath)
                infiniteIfNeeded()
            case .Right:
                scrollPosition = .Center
            }
        } else if rightPagingEdge {
            switch position {
            case .Left:
                scrollPosition = .Center
            case .Center:
                configureAtPosition(.Right, toIndexPath: indexPath)
                infiniteIfNeeded()
            case .Right:
                infiniteForced()
            }
        }
        
        defer {
            if let offsetX = contentOffsetXAtPosition(scrollPosition) {
                setContentOffset(CGPoint(x: offsetX, y: contentOffset.y), animated: animated)
            }
        }
        
        guard let indexPath = indexPath else {
            return
        }
        
        if let contentView = contentViewAtPosition(scrollPosition), cell = contentView.cell where cell.hidden == false {
            configureAtPosition(scrollPosition, toIndexPath: indexPath)
        } else {
            nextConfigurationIndexPath = indexPath
        }
    }
    
    /// Configure cell of Position. IndexPath of cell in the center if indexPath is nil.
    public func configureAtPosition(position: Position, toIndexPath: NSIndexPath? = nil) {
        let indexPath: NSIndexPath
        
        if let toIndexPath = toIndexPath {
            do {
                try containsIndexPath(toIndexPath)
            } catch PagingViewError.IndexPathRange(let message) {
                fatalError(message)
            } catch {
                fatalError("IndexPath is out of range")
            }
            indexPath = toIndexPath
        } else {
            let contentPosition: Position
            if leftPagingEdge {
                contentPosition = .Right
            } else if rightPagingEdge {
                contentPosition = .Left
            } else {
                contentPosition = position
            }
            guard let centerCell = pretenseCenterContentView?.cell else {
                return
            }
            
            indexPath = indexPathAtPosition(contentPosition, indexPath: centerCell.indexPath)
        }
        
        if let contentView = contentViewAtPosition(position) where contentView.cell?.indexPath != indexPath {
            contentView.removeContentCell()
            configureView(contentView, indexPath: indexPath)
        }
    }
    
    func indexPathAtPosition(position: Position, indexPath: NSIndexPath) -> NSIndexPath {
        var section = indexPath.section
        var item = indexPath.item
        let sections = forceSections()
        
        let sectionIndex = sections.indexOf(indexPath.section)
        
        switch position {
        case .Left:
            if --item < 0 {
                if var index = sectionIndex {
                    if --index < 0, let last = sections.last {
                        section = last
                    } else {
                        section = sections[index]
                    }
                }
                item = itemCountInSection[section] - 1
            }
            
            return NSIndexPath(forItem: item, inSection: section)
        case .Right:
            if ++item >= itemCountInSection[section] {
                if var index = sectionIndex {
                    if ++index >= sections.count, let first = sections.first {
                        section = first
                    } else {
                        section = sections[index]
                    }
                }
                item = 0
            }
            
            return NSIndexPath(forItem: item, inSection: section)
        case .Center:
            return indexPath
        }
    }
    
    func forceSections() -> [Int] {
        typealias Item = (index: Int, item: Int)
        
        return itemCountInSection.enumerate().reduce([]) { (acc: [Int], current: Item) -> [Int] in
            if current.item > 0 {
                return acc + [current.index]
            }
            
            return acc
        }
    }
    
    func firstForceIndexPath() -> NSIndexPath? {
        if let section = forceSections().first {
            return NSIndexPath(forItem: 0, inSection: section)
        } else {
            return nil
        }
    }
    
    func lastForceIndexPath() -> NSIndexPath? {
        if let section = forceSections().last {
            let item = itemCountInSection[section] - 1
            return NSIndexPath(forItem: item, inSection: section)
        } else {
            return nil
        }
    }
    
    func configureView(contentView: ContentView?, indexPath: NSIndexPath) {
        if let cell = dataSource?.pagingView(self, cellForItemAtIndexPath: indexPath) {
            contentView?.addContentCell(cell, indexPath: indexPath)
        }
    }
    
    func removeContentView() {
        while let view = pagingContents.popLast() {
            view.removeContentCell()
            view.removeFromSuperview()
        }
    }
    
    func reloadSectionData() {
        sectionCount = numberOfSections()
        itemCountInSection = [Int](0..<sectionCount).map {
            self.numberOfItemsInSection($0)
        }
    }
    
    func reloadContentView() -> Position {
        var configureIndexPath: NSIndexPath?
        if let indexPath = dataSource?.indexPathOfStartingInPagingView?(self) {
            do {
                try containsIndexPath(indexPath)
            } catch PagingViewError.IndexPathRange(let message) {
                fatalError(message)
            } catch {
                fatalError("IndexPath is out of range")
            }
            configureIndexPath = indexPath
        } else {
            if let section = forceSections().first {
                configureIndexPath = NSIndexPath(forItem: 0, inSection: section)
            }
        }
        
        var position: Position = .Center
        if let indexPath = configureIndexPath {
            if infinite == false {
                if indexPath == firstForceIndexPath() {
                    position = .Left
                } else if indexPath == lastForceIndexPath() {
                    position = .Right
                }
            }
            
            configureView(contentViewAtPosition(position), indexPath: indexPath)
            willDisplayView(contentViewAtPosition(position))
        }
        
        return position
    }
    
    func containsIndexPath(indexPath: NSIndexPath) throws {
        if indexPath.section >= sectionCount || indexPath.item >= itemCountInSection[indexPath.section] {
            throw PagingViewError.IndexPathRange("IndexPath is out of range: indexPath = \(indexPath), Section of upper limit = \(sectionCount), Section \(indexPath.section) of upper limit = \(itemCountInSection[indexPath.section])")
        }
    }
}

// MARK: - Layout and Display
extension PagingView {
    public override func layoutSubviews() {
        var reloadScrollPosition: Position?
        
        if needsReload || needsLayout {
            let horizontal = -CGFloat(pagingInset * 2)
            contentInset = UIEdgeInsets(top: 0, left: horizontal, bottom: 0, right: horizontal)
            pagingEnabled = true
            scrollsToTop = false
            
            if needsReload {
                reloadSectionData()
                setupPagingContentView()
                reloadScrollPosition = reloadContentView()
            } else if needsLayout {
                layoutPagingContentView()
            }
        }
        
        let beforeSize = contentSize
        super.layoutSubviews()
        
        if pagingContents.count > 0 {
            if beforeSize != contentSize || needsReload || needsLayout {
                contentSize = CGSize(width: floor(contentSize.width), height: floor(contentSize.height))
                let contentPosition: Position
                if let position = reloadScrollPosition {
                    contentPosition = position
                } else {
                    if lastLeftPagingEdge {
                        contentPosition = .Left
                    } else if lastRightPagingEdge {
                        contentPosition = .Right
                    } else {
                        contentPosition = .Center
                    }
                }
                
                if let offsetX = contentOffsetXAtPosition(contentPosition) {
                    setContentOffset(CGPoint(x: offsetX, y: contentOffset.y), animated: false)
                }
            } else {
                infiniteIfNeeded()
            }
            
            if dataSource != nil {
                changeDisplayStatusForCell()
            }
        }
        
        lastLeftPagingEdge = leftPagingEdge
        lastRightPagingEdge = rightPagingEdge
        
        needsLayout = false
        needsReload = false
    }
    
    func infiniteForced() {
        infiniteIfNeeded(forced: true)
    }
    
    func infiniteIfNeeded(forced forced: Bool = false) {
        let offset = contentOffsetInfiniteIfNeeded(contentOffset, forced: forced)
        if contentOffset != offset {
            if offset.x > contentOffset.x {
                willPagingScrollToPrev()
            } else if offset.x < contentOffset.x {
                willPagingScrollToPrevNext()
            }
            contentOffset = offset
        }
    }
    
    func contentOffsetInfiniteIfNeeded(offset: CGPoint, forced: Bool) -> CGPoint {
        func xOffset() -> CGFloat? {
            guard let contentOffsetCenter = contentOffsetXAtPosition(.Center) else {
                return nil
            }
            
            let contentOffsetRight = contentSize.width - contentOffsetCenter + contentInset.right
            if leftEdge(offset) {
                if infiniteLeftScroll || forced {
                    return offset.x + contentOffsetCenter + contentInset.left
                }
            } else if rightEdge(offset) {
                if infiniteRightScroll || forced {
                    return contentOffsetCenter + (offset.x - contentOffsetRight)
                }
            }
            
            return nil
        }
        
        let x = xOffset()
        
        return CGPoint(x: x ?? offset.x, y: offset.y)
    }
    
    func willPagingScrollToPrev() {
        rightContentView?.contentMoveFrom(centerContentView)
        centerContentView?.contentMoveFrom(leftContentView)
    }
    
    func willPagingScrollToPrevNext() {
        leftContentView?.contentMoveFrom(centerContentView)
        centerContentView?.contentMoveFrom(rightContentView)
    }
    
    func changeDisplayStatusForCell() {
        func viewVisible(view: ContentView) -> Bool {
            let rect = CGRect(origin: contentOffset, size: CGSize(width: view.bounds.width + constraintGroup.widths.constant, height: view.bounds.height))
            return view.visible(rect)
        }
        
        func endDisplayIfNeeded(view: ContentView, visible: Bool) {
            if visible == view.cell?.hidden && visible == false {
                didEndDisplayingView(view)
                view.removeContentCell()
            }
        }
        
        func willDisplayIfNeeded(view: ContentView, visible: Bool, position: Position) {
            if (view.cell == nil || visible == view.cell?.hidden) && visible == true {
                if view.cell == nil {
                    configureAtPosition(position, toIndexPath: nextConfigurationIndexPath)
                    nextConfigurationIndexPath = nil
                }
                
                willDisplayView(view)
            }
        }
        
        if leftPagingEdge || rightPagingEdge {
            if let view = contentViewAtPosition(.Center) {
                let visible = viewVisible(view)
                
                endDisplayIfNeeded(view, visible: visible)
                willDisplayIfNeeded(view, visible: visible, position: .Center)
            }
        } else {
            if let leftView = contentViewAtPosition(.Left), rightView = contentViewAtPosition(.Right) {
                let leftVisible = viewVisible(leftView)
                let rightVisible = viewVisible(rightView)
                
                endDisplayIfNeeded(leftView, visible: leftVisible)
                endDisplayIfNeeded(rightView, visible: rightVisible)
                
                willDisplayIfNeeded(leftView, visible: leftVisible, position: .Left)
                willDisplayIfNeeded(rightView, visible: rightVisible, position: .Right)
            }
        }
    }
    
    func willDisplayView(contentView: ContentView?) {
        if let cell = contentView?.cell {
            pagingViewDelegate?.pagingView?(self, willDisplayCell: cell, forItemAtIndexPath: cell.indexPath)
            cell.hidden = false
        }
    }
    
    func didEndDisplayingView(contentView: ContentView?) {
        if let cell = contentView?.cell {
            cell.hidden = true
            pagingViewDelegate?.pagingView?(self, didEndDisplayingCell: cell, forItemAtIndexPath: cell.indexPath)
        }
    }
    
    func setupPagingContentView() {
        let superKey = "superView"
        let contentKey = "contentView"
        let lastContentKey = "lastContentView"
        let spaceKey = "space"
        
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
        
        func layoutPagingViewContent(contentView: ContentView?, lastContentView: ContentView?) {
            if let contentView = contentView {
                constraintGroup.widths.append(widthConstraints(contentView))
                constraintGroup.heights.append(heightConstraints(contentView))
                
                if let lastContentView = lastContentView {
                    constraintGroup.betweenSpaces.append(betweenSpaceConstraints(contentView, lastContentView: lastContentView))
                } else {
                    constraintGroup.leftSpaces.append(leftSpaceConstraints(contentView))
                }
            } else if let lastContentView = lastContentView {
                constraintGroup.rightSpaces.append(rightSpaceConstraints(lastContentView))
            }
        }
        
        for index in 0..<min(Position.count, allItemCount) {
            let contentView = ContentView(frame: bounds)
            contentView.position = Position(rawValue: index)
            contentView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(contentView)
            
            layoutPagingViewContent(contentView, lastContentView: pagingContents.last)
            pagingContents.append(contentView)
        }
        
        layoutPagingViewContent(nil, lastContentView: pagingContents.last)
        addConstraints(constraintGroup)
    }
    
    func layoutPagingContentView() {
        constraintGroup.widths.constant = pagingSpace * 2
        constraintGroup.betweenSpaces.constant = CGFloat(pagingMargin * 2)
        constraintGroup.leftSpaces.constant = pagingSpace - contentInset.left
        constraintGroup.rightSpaces.constant = pagingSpace - contentInset.right
    }
    
    private func addConstraints(group: ConstraintGroup) {
        addConstraints(group.allConstraints().collection)
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
        return pretenseCenterContentView?.cell
    }
    
    public func visibleCenterCell<T>() -> T? {
        return pretenseCenterContentView?.cell as? T
    }
}
