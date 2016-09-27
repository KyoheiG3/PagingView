//
//  PagingView.swift
//  PagingView
//
//  Created by Kyohei Ito on 2015/09/02.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit

@objc public protocol PagingViewDataSource: class {
    func pagingView(_ pagingView: PagingView, numberOfItemsInSection section: Int) -> Int
    func pagingView(_ pagingView: PagingView, cellForItemAtIndexPath indexPath: IndexPath) -> PagingViewCell
    
    @objc optional func numberOfSectionsInPagingView(_ pagingView: PagingView) -> Int
    @objc optional func indexPathOfStartingInPagingView(_ pagingView: PagingView) -> IndexPath?
}

@objc public protocol PagingViewDelegate: UIScrollViewDelegate {
    @objc optional func pagingView(_ pagingView: PagingView, willDisplayCell cell: PagingViewCell, forItemAtIndexPath indexPath: IndexPath)
    @objc optional func pagingView(_ pagingView: PagingView, didEndDisplayingCell cell: PagingViewCell, forItemAtIndexPath indexPath: IndexPath)
}

open class PagingView: UIScrollView {
    typealias Cell = PagingViewCell
    
    private enum PagingViewError: Error {
        case indexPathRange(String)
    }
    
    fileprivate struct ConstraintGroup {
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
    
    fileprivate var sectionCount = 1
    fileprivate var itemCountInSection: [Int] = []
    fileprivate var cellReuseQueue = CellReuseQueue()
    fileprivate var registeredObject: [String: AnyObject] = [:]
    fileprivate var pagingContents: [ContentView] = []
    fileprivate var nextConfigurationIndexPath: IndexPath?
    fileprivate var needsReload: Bool = true
    fileprivate var needsLayout: Bool = false
    fileprivate var constraintGroup: ConstraintGroup = ConstraintGroup()
    
    fileprivate var allItemCount: Int {
        return itemCountInSection.reduce(0) { return $0.0 + $0.1 }
    }
    fileprivate var leftContentView: ContentView? {
        return contentViewAtPosition(.left)
    }
    fileprivate var centerContentView: ContentView? {
        return contentViewAtPosition(.center)
    }
    fileprivate var rightContentView: ContentView? {
        return contentViewAtPosition(.right)
    }
    fileprivate var pretenseCenterContentView: ContentView? {
        if leftPagingEdge {
            return leftContentView
        } else if rightPagingEdge {
            return rightContentView
        } else {
            return centerContentView
        }
    }
    
    fileprivate var pagingViewDelegate: PagingViewDelegate? {
        return delegate as? PagingViewDelegate
    }
    
    @IBOutlet open weak var dataSource: PagingViewDataSource?
    /// Margin between the content.
    @IBInspectable open var pagingMargin: UInt = 0 {
        didSet { invalidateLayout() }
    }
    /// Inset of content relative to size of PagingView. Value of two times than of pagingInset to set for the left and right of contentInset.
    @IBInspectable open var pagingInset: UInt = 0 {
        didSet { invalidateLayout() }
    }
    var pagingSpace: CGFloat {
        return CGFloat(pagingInset + pagingMargin)
    }
    /// Infinite looping enabled flag.
    @IBInspectable open var infinite: Bool = true
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
    
    func leftEdge(_ offset: CGPoint) -> Bool {
        guard let x = contentOffsetXAtPosition(.left) else {
            return false
        }
        return offset.x + (contentInset.left / 2) <= x
    }
    
    func rightEdge(_ offset: CGPoint) -> Bool {
        guard let contentOffsetCenter = contentOffsetXAtPosition(.center) else {
            return false
        }
        
        let contentOffsetRight = contentSize.width - contentOffsetCenter + contentInset.right
        return contentOffsetRight <= offset.x - (contentInset.right / 2)
    }
    
    func contentViewAtPosition(_ position: Position) -> ContentView? {
        let page = position.numberOfPages()
        if pagingContents.count > page {
            return pagingContents[page]
        }
        
        if pagingContents.count == 2 && position == .right {
            return pagingContents[1]
        }
        
        return nil
    }
    
    func contentOffsetXAtPosition(_ position: Position) -> CGFloat? {
        if let view = contentViewAtPosition(position) {
            return view.frame.origin.x - (constraintGroup.widths.constant / 2)
        }
        
        return nil
    }
    
    open func dequeueReusableCellWithReuseIdentifier(_ identifier: String) -> PagingViewCell {
        if let view = cellReuseQueue.dequeue(identifier) {
            view.reuseIdentifier = identifier
            view.prepareForReuse()
            return view
        }
        
        var reuseContent: Cell!
        if let nib = registeredObject[identifier] as? UINib, let instance = nib.instantiate(withOwner: nil, options: nil).first as? Cell {
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
    open func registerNib(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        registeredObject[identifier] = nib
    }
    
    open func registerClass<T: PagingViewCell>(_ viewClass: T.Type, forCellWithReuseIdentifier identifier: String) {
        registeredObject[identifier] = viewClass
    }
    
    /// Discard the dataSource and delegate data, also requery as necessary.
    open func reloadData() {
        constraintGroup.removeAll()
        removeContentView()
        
        needsReload = true
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    /// Relayout as necessary.
    open func invalidateLayout() {
        needsLayout = true
        setNeedsLayout()
    }
    
    /// Information about the current state of the paging view.
    
    open func numberOfSections() -> Int {
        return dataSource?.numberOfSectionsInPagingView?(self) ?? 1
    }
    
    open func numberOfItemsInSection(_ section: Int) -> Int {
        return dataSource?.pagingView(self, numberOfItemsInSection: section) ?? 0
    }
    
    /// To scroll at Position. Cell configure is performed at IndexPath.
    open func scrollToPosition(_ position: Position, indexPath: IndexPath? = nil, animated: Bool = false) {
        var scrollPosition = position
        if leftPagingEdge {
            switch position {
            case .left:
                infiniteForced()
            case .center:
                configureAtPosition(.left, toIndexPath: indexPath)
                infiniteIfNeeded()
            case .right:
                scrollPosition = .center
            }
        } else if rightPagingEdge {
            switch position {
            case .left:
                scrollPosition = .center
            case .center:
                configureAtPosition(.right, toIndexPath: indexPath)
                infiniteIfNeeded()
            case .right:
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
        
        if let contentView = contentViewAtPosition(scrollPosition), let cell = contentView.cell , cell.isHidden == false {
            configureAtPosition(scrollPosition, toIndexPath: indexPath)
        } else {
            nextConfigurationIndexPath = indexPath
        }
    }
    
    /// Configure cell of Position. IndexPath of cell in the center if indexPath is nil.
    open func configureAtPosition(_ position: Position, toIndexPath: IndexPath? = nil) {
        let indexPath: IndexPath
        
        if let toIndexPath = toIndexPath {
            do {
                try containsIndexPath(toIndexPath)
            } catch PagingViewError.indexPathRange(let message) {
                fatalError(message)
            } catch {
                fatalError("IndexPath is out of range")
            }
            indexPath = toIndexPath
        } else {
            let contentPosition: Position
            if leftPagingEdge {
                contentPosition = .right
            } else if rightPagingEdge {
                contentPosition = .left
            } else {
                contentPosition = position
            }
            guard let centerCell = pretenseCenterContentView?.cell else {
                return
            }
            
            indexPath = indexPathAtPosition(contentPosition, indexPath: centerCell.indexPath)
        }
        
        if let contentView = contentViewAtPosition(position) , contentView.cell?.indexPath != indexPath {
            contentView.removeContentCell()
            configureView(contentView, indexPath: indexPath)
        }
    }
    
    func indexPathAtPosition(_ position: Position, indexPath: IndexPath) -> IndexPath {
        var section = indexPath.section
        var item = indexPath.item
        let sections = forceSections()
        
        let sectionIndex = sections.index(of: indexPath.section)
        
        switch position {
        case .left:
            item -= 1
            if item < 0 {
                if var index = sectionIndex {
                    index -= 1
                    if index < 0, let last = sections.last {
                        section = last
                    } else {
                        section = sections[index]
                    }
                }
                item = itemCountInSection[section] - 1
            }
            
            return IndexPath(item: item, section: section)
        case .right:
            item += 1
            if item >= itemCountInSection[section] {
                if var index = sectionIndex {
                    index += 1
                    if index >= sections.count, let first = sections.first {
                        section = first
                    } else {
                        section = sections[index]
                    }
                }
                item = 0
            }
            
            return IndexPath(item: item, section: section)
        case .center:
            return indexPath
        }
    }
    
    func forceSections() -> [Int] {
        typealias Item = (index: Int, item: Int)
        
        return itemCountInSection.enumerated().reduce([]) { (acc: [Int], current: Item) -> [Int] in
            if current.item > 0 {
                return acc + [current.index]
            }
            
            return acc
        }
    }
    
    func firstForceIndexPath() -> IndexPath? {
        if let section = forceSections().first {
            return IndexPath(item: 0, section: section)
        } else {
            return nil
        }
    }
    
    func lastForceIndexPath() -> IndexPath? {
        if let section = forceSections().last {
            let item = itemCountInSection[section] - 1
            return IndexPath(item: item, section: section)
        } else {
            return nil
        }
    }
    
    func configureView(_ contentView: ContentView?, indexPath: IndexPath) {
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
        var configureIndexPath: IndexPath?
        if let indexPath = dataSource?.indexPathOfStartingInPagingView?(self) {
            do {
                try containsIndexPath(indexPath)
            } catch PagingViewError.indexPathRange(let message) {
                fatalError(message)
            } catch {
                fatalError("IndexPath is out of range")
            }
            configureIndexPath = indexPath
        } else {
            if let section = forceSections().first {
                configureIndexPath = IndexPath(item: 0, section: section)
            }
        }
        
        var position: Position = .center
        if let indexPath = configureIndexPath {
            if infinite == false {
                if indexPath == firstForceIndexPath() {
                    position = .left
                } else if indexPath == lastForceIndexPath() {
                    position = .right
                }
            } else {
                if pagingContents.count <= 1 {
                    position = .left
                }
            }
            
            configureView(contentViewAtPosition(position), indexPath: indexPath)
            willDisplayView(contentViewAtPosition(position))
        }
        
        return position
    }
    
    func containsIndexPath(_ indexPath: IndexPath) throws {
        if indexPath.section >= sectionCount || indexPath.item >= itemCountInSection[indexPath.section] {
            throw PagingViewError.indexPathRange("IndexPath is out of range: indexPath = \(indexPath), Section of upper limit = \(sectionCount), Section \(indexPath.section) of upper limit = \(itemCountInSection[indexPath.section])")
        }
    }
}

// MARK: - Layout and Display
extension PagingView {
    open override func layoutSubviews() {
        var reloadScrollPosition: Position?
        
        if needsReload || needsLayout {
            let horizontal = -CGFloat(pagingInset * 2)
            contentInset = UIEdgeInsets(top: 0, left: horizontal, bottom: 0, right: horizontal)
            isPagingEnabled = true
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
                        contentPosition = .left
                    } else if lastRightPagingEdge {
                        contentPosition = .right
                    } else {
                        contentPosition = .center
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
    
    func infiniteIfNeeded(forced: Bool = false) {
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
    
    func contentOffsetInfiniteIfNeeded(_ offset: CGPoint, forced: Bool) -> CGPoint {
        func xOffset() -> CGFloat? {
            guard let contentOffsetCenter = contentOffsetXAtPosition(.center) else {
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
        func viewVisible(_ view: ContentView) -> Bool {
            let rect = CGRect(origin: contentOffset, size: CGSize(width: view.bounds.width + constraintGroup.widths.constant, height: view.bounds.height))
            return view.visible(rect)
        }
        
        func endDisplayIfNeeded(_ view: ContentView, visible: Bool) {
            if visible == view.cell?.isHidden && visible == false {
                didEndDisplayingView(view)
                view.removeContentCell()
            }
        }
        
        func willDisplayIfNeeded(_ view: ContentView, visible: Bool, position: Position) {
            if (view.cell == nil || visible == view.cell?.isHidden) && visible == true {
                if view.cell == nil {
                    configureAtPosition(position, toIndexPath: nextConfigurationIndexPath)
                    nextConfigurationIndexPath = nil
                }
                
                willDisplayView(view)
            }
        }
        
        if leftPagingEdge || rightPagingEdge {
            if let view = contentViewAtPosition(.center) {
                let visible = viewVisible(view)
                
                endDisplayIfNeeded(view, visible: visible)
                willDisplayIfNeeded(view, visible: visible, position: .center)
            }
        }
        if let leftView = contentViewAtPosition(.left), let rightView = contentViewAtPosition(.right) {
            let leftVisible = viewVisible(leftView)
            let rightVisible = viewVisible(rightView)
            
            endDisplayIfNeeded(leftView, visible: leftVisible)
            endDisplayIfNeeded(rightView, visible: rightVisible)
            
            willDisplayIfNeeded(leftView, visible: leftVisible, position: .left)
            willDisplayIfNeeded(rightView, visible: rightVisible, position: .right)
        }
    }
    
    func willDisplayView(_ contentView: ContentView?) {
        if let cell = contentView?.cell {
            pagingViewDelegate?.pagingView?(self, willDisplayCell: cell, forItemAtIndexPath: cell.indexPath)
            cell.isHidden = false
        }
    }
    
    func didEndDisplayingView(_ contentView: ContentView?) {
        if let cell = contentView?.cell {
            cell.isHidden = true
            pagingViewDelegate?.pagingView?(self, didEndDisplayingCell: cell, forItemAtIndexPath: cell.indexPath)
        }
    }
    
    func setupPagingContentView() {
        let superKey = "superView"
        let contentKey = "contentView"
        let lastContentKey = "lastContentView"
        let spaceKey = "space"
        
        func constraintsWithFormat(_ format: String, metrics: [String : AnyObject]? = nil, views: [String : AnyObject]) -> [NSLayoutConstraint] {
            return NSLayoutConstraint.constraints(withVisualFormat: format, options: [], metrics: metrics, views: views)
        }
        
        func widthConstraints(_ contentView: ContentView) -> [NSLayoutConstraint] {
            return [NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 1, constant: pagingSpace * 2)]
        }
        
        func heightConstraints(_ contentView: ContentView) -> [NSLayoutConstraint] {
            return constraintsWithFormat("V:|[\(contentKey)(==\(superKey))]|", views: [contentKey: contentView, superKey: self])
        }
        
        func leftSpaceConstraints(_ contentView: ContentView) -> [NSLayoutConstraint] {
            return constraintsWithFormat("|-\(spaceKey)-[\(contentKey)]", metrics: [spaceKey: pagingSpace - contentInset.left as AnyObject], views: [contentKey: contentView])
        }
        
        func betweenSpaceConstraints(_ contentView: ContentView, lastContentView: ContentView) -> [NSLayoutConstraint] {
            return constraintsWithFormat("[\(lastContentKey)]-\(spaceKey)-[\(contentKey)]", metrics: [spaceKey: pagingMargin * 2 as AnyObject], views: [contentKey: contentView, lastContentKey: lastContentView])
        }
        
        func rightSpaceConstraints(_ lastContentView: ContentView) -> [NSLayoutConstraint] {
            return constraintsWithFormat("[\(lastContentKey)]-\(spaceKey)-|", metrics: [spaceKey: pagingSpace - contentInset.right as AnyObject], views: [lastContentKey: lastContentView])
        }
        
        func layoutPagingViewContent(_ contentView: ContentView?, lastContentView: ContentView?) {
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
        
        for index in 0..<(allItemCount > 1 && infinite ? Position.count : allItemCount) {
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
    
    private func addConstraints(_ group: ConstraintGroup) {
        addConstraints(group.allConstraints().collection)
    }
}

// MARK: - Visibility
extension PagingView {
    func visibleContents() -> [UIView] {
        let visibleRect = CGRect(origin: contentOffset, size: bounds.size)
        
        return pagingContents.filter {
            visibleRect.intersects($0.frame)
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
