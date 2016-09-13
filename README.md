<img src="https://raw.githubusercontent.com/KyoheiG3/assets/master/PagingView/logo.png" alt="LOGO" width="300" />

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/PagingView.svg?style=flat)](http://cocoadocs.org/docsets/PagingView)
[![License](https://img.shields.io/cocoapods/l/PagingView.svg?style=flat)](http://cocoadocs.org/docsets/PagingView)
[![Platform](https://img.shields.io/cocoapods/p/PagingView.svg?style=flat)](http://cocoadocs.org/docsets/PagingView)

Infinite paging, Smart auto layout, Interface of similar to UIKit.

#### [Appetize's Demo](https://appetize.io/app/030jqrt4nkm60rc0qu1wrvg4v8)

![Demo](https://raw.githubusercontent.com/KyoheiG3/assets/master/PagingView/image_demo.gif)

## Requirements

- Swift 3.0
- iOS 7.0 or later

## How to Install PagingView

### iOS 8+

#### Cocoapods

Add the following to your `Podfile`:

```Ruby
use_frameworks!
pod "PagingView"
```
Note: the `use_frameworks!` is required for pods made in Swift.

#### Carthage

Add the following to your `Cartfile`:

```Ruby
github "KyoheiG3/PagingView"
```

### iOS 7

Just add everything in the `PagingView.swift`, `PagingViewCell.swift` and `Constraints.swift` file to your project.

## Usage

### import

If target is ios8.0 or later, please import the `PagingView`.

```swift
import PagingView
```

### PagingView Variable

```swift
weak var dataSource: PagingViewDataSource?
```
* DataSource of `PagingView`. Same as `dataSource` of `UICollectionView`.

```swift
var pagingMargin: UInt
```
* Margin between the content.
* Default is `0`.

```swift
var pagingInset: UInt
```
* Inset of content relative to size of `PagingView`.
* Value of two times than of `pagingInset` to set for the left and right of `contentInset`.
* Default is `0`.

```swift
var infinite: Bool
```
* Infinite looping enabled flag.
* Default is `true`.

### PagingView Function

```swift
func dequeueReusableCellWithReuseIdentifier(identifier: String) -> PagingView.PagingViewCell
```
* Used by the `delegate` to acquire an already allocated cell, in lieu of allocating a new one.

```swift
func registerNib(nib: UINib?, forCellWithReuseIdentifier identifier: String)
```
* If a nib is registered, it must contain exactly 1 top level object which is a `PagingViewCell`.

```swift
func registerClass<T : PagingView.PagingViewCell>(viewClass: T.Type, forCellWithReuseIdentifier identifier: String)
```
* If a class is registered, it will be instantiated via `init(frame: CGRect)`.

```swift
func reloadData()
```
* Requery the `dataSource` and `delegate` as necessary.

```swift
func invalidateLayout()
```
* Relayout as necessary.

```swift
func numberOfSections() -> Int
func numberOfItemsInSection(section: Int) -> Int
```
* Information about the current state of the `PagingView`.

```swift
func scrollToPosition(position: PagingView.PagingView.Position, indexPath: IndexPath? = default, animated: Bool = default)
```
* To scroll at `Position`.
* Cell configure is performed at `IndexPath`.

```swift
func configureAtPosition(position: PagingView.PagingView.Position, toIndexPath: IndexPath? = default)
```
* Configure cell of `Position`.
* IndexPath of cell in the center if indexPath is `nil`.

### PagingViewDataSource Function

```swift
func pagingView(pagingView: PagingView.PagingView, numberOfItemsInSection section: Int) -> Int
```
* Paging count number of paging item in section.

```swift
func pagingView(pagingView: PagingView.PagingView, cellForItemAtIndexPath indexPath: IndexPath) -> PagingView.PagingViewCell
```
* Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with `dequeueReusableCellWithReuseIdentifier:`.

```swift
optional func numberOfSectionsInPagingView(pagingView: PagingView.PagingView) -> Int
```
* Paging count number of paging item section in `PagingView`.
* Default return value is `1`.

```swift
optional func indexPathOfStartingInPagingView(pagingView: PagingView.PagingView) -> IndexPath?
```
* IndexPath when `pagingView:cellForItemAtIndexPath:` is first called
* Default return value is `0 - 0` of `IndexPath` instance.

### PagingViewDelegate Function

```swift
optional func pagingView(pagingView: PagingView.PagingView, willDisplayCell cell: PagingView.PagingViewCell, forItemAtIndexPath indexPath: IndexPath)
optional func pagingView(pagingView: PagingView.PagingView, didEndDisplayingCell cell: PagingView.PagingViewCell, forItemAtIndexPath indexPath: IndexPath)
```
* Called at the display and end-display of.

### PagingViewCell Function

```swift
func prepareForReuse()
```
* if the cell is reusable (has a reuse identifier), this is called just before the cell is returned from the paging view method `dequeueReusableCellWithReuseIdentifier:`.

## LICENSE

Under the MIT license. See LICENSE file for details.
