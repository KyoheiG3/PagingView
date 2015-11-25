//
//  PagingViewExampleUITests.swift
//  PagingViewExampleUITests
//
//  Created by Kyohei Ito on 2015/09/03.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import XCTest

@available(iOS 9.0, *)
class PagingViewExampleUITests: XCTestCase {
    let pagingView = XCUIApplication().scrollViews["PagingView"]
    let configureLabel = XCUIApplication().staticTexts["ConfigureLabel"]
    let willDisplayLabel = XCUIApplication().staticTexts["WillDisplayLabel"]
    let didEndDisplayLabel = XCUIApplication().staticTexts["DidEndDisplayLabel"]
    let reloadLabel = XCUIApplication().staticTexts["ReloadLabel"]
    let toLeftButton = XCUIApplication().buttons["ToLeftButton"]
    let toCenterButton = XCUIApplication().buttons["ToCenterButton"]
    let toRightButton = XCUIApplication().buttons["ToRightButton"]
    let reloadButton = XCUIApplication().buttons["ReloadButton"]
    
    var centerContentView: XCUIElement {
        let query = pagingView.childrenMatchingType(.Other)
        return query.elementBoundByIndex(query.count <= 1 ? 0 : 1)
    }
    
    var centerCell: XCUIElement {
        return centerContentView.childrenMatchingType(.Other).element
    }
    
    var centerCellLabel: XCUIElement {
        return centerCell.childrenMatchingType(.StaticText).element
    }
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRotate() {
        XCUIDevice.sharedDevice().orientation = .Portrait
        
        var lastConfigureText = configureLabel.label
        var lastWillDisplayText = willDisplayLabel.label
        var lastDidEndDisplayText = didEndDisplayLabel.label
        var lastCenterCellText = centerCellLabel.label
        
        XCUIDevice.sharedDevice().orientation = .LandscapeRight
        XCTAssertEqual(configureLabel.label, lastConfigureText)
        XCTAssertEqual(willDisplayLabel.label, lastWillDisplayText)
        XCTAssertEqual(didEndDisplayLabel.label, lastDidEndDisplayText)
        XCTAssertEqual(centerCellLabel.label, lastCenterCellText)
        
        pagingView.swipeLeft()
        lastConfigureText = configureLabel.label
        lastWillDisplayText = willDisplayLabel.label
        lastDidEndDisplayText = didEndDisplayLabel.label
        lastCenterCellText = centerCellLabel.label
        
        XCUIDevice.sharedDevice().orientation = .Portrait
        XCTAssertEqual(configureLabel.label, lastConfigureText)
        XCTAssertEqual(willDisplayLabel.label, lastWillDisplayText)
        XCTAssertEqual(didEndDisplayLabel.label, lastDidEndDisplayText)
        XCTAssertEqual(centerCellLabel.label, lastCenterCellText)
    }
    
    func testScrollToLeft() {
        toLeftButton.tap()
        XCTAssertEqual(centerCellLabel.label, "2 - 0")
        XCTAssertEqual(configureLabel.label, "0 - 9")
        XCTAssertEqual(willDisplayLabel.label, "0 - 9")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 3")
        
        toLeftButton.tap()
        XCTAssertEqual(centerCellLabel.label, "2 - 0")
        XCTAssertEqual(configureLabel.label, "0 - 9")
        XCTAssertEqual(willDisplayLabel.label, "0 - 9")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 2")
        
        toLeftButton.tap()
        XCTAssertEqual(centerCellLabel.label, "2 - 0")
        XCTAssertEqual(configureLabel.label, "0 - 9")
        XCTAssertEqual(willDisplayLabel.label, "0 - 9")
        XCTAssertEqual(didEndDisplayLabel.label, centerCellLabel.label)
    }
    
    func testScrollToCenter() {
        var lastWillDisplayText = willDisplayLabel.label
        var lastDidEndDisplayText = didEndDisplayLabel.label
        
        toCenterButton.tap()
        XCTAssertEqual(willDisplayLabel.label, lastWillDisplayText)
        XCTAssertEqual(didEndDisplayLabel.label, lastDidEndDisplayText)
        XCTAssertEqual(centerCellLabel.label, configureLabel.label)
        
        pagingView.swipeLeft()
        lastWillDisplayText = willDisplayLabel.label
        lastDidEndDisplayText = didEndDisplayLabel.label
        
        toCenterButton.tap()
        XCTAssertEqual(willDisplayLabel.label, lastWillDisplayText)
        XCTAssertEqual(didEndDisplayLabel.label, lastDidEndDisplayText)
        XCTAssertEqual(centerCellLabel.label, configureLabel.label)
        
        pagingView.swipeRight()
        pagingView.swipeRight()
        lastWillDisplayText = willDisplayLabel.label
        lastDidEndDisplayText = didEndDisplayLabel.label
        
        toCenterButton.tap()
        XCTAssertEqual(willDisplayLabel.label, lastWillDisplayText)
        XCTAssertEqual(didEndDisplayLabel.label, lastDidEndDisplayText)
        XCTAssertEqual(centerCellLabel.label, configureLabel.label)
    }
    
    func testScrollToRight() {
        toRightButton.tap()
        XCTAssertEqual(centerCellLabel.label, "2 - 7")
        XCTAssertEqual(configureLabel.label, "2 - 8")
        XCTAssertEqual(willDisplayLabel.label, "2 - 8")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 1")
        
        toRightButton.tap()
        XCTAssertEqual(centerCellLabel.label, "2 - 7")
        XCTAssertEqual(configureLabel.label, "2 - 8")
        XCTAssertEqual(willDisplayLabel.label, "2 - 8")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 2")
        
        toRightButton.tap()
        XCTAssertEqual(centerCellLabel.label, "2 - 7")
        XCTAssertEqual(configureLabel.label, "2 - 8")
        XCTAssertEqual(willDisplayLabel.label, "2 - 8")
        XCTAssertEqual(didEndDisplayLabel.label, centerCellLabel.label)
        
    }
    
    func testReload() {
        let lastDidEndDisplayText = didEndDisplayLabel.label
        
        reloadButton.tap()
        
        XCTAssertEqual(didEndDisplayLabel.label, lastDidEndDisplayText)
        XCTAssertEqual(centerCellLabel.label, reloadLabel.label)
    }
    
    func testPagingLeft() {
        XCTAssertEqual(configureLabel.label, "2 - 3")
        XCTAssertEqual(willDisplayLabel.label, "2 - 3")
        XCTAssertEqual(didEndDisplayLabel.label, "")
        
        pagingView.swipeLeft()
        XCTAssertEqual(configureLabel.label, "2 - 4")
        XCTAssertEqual(willDisplayLabel.label, "2 - 4")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 1")
        
        pagingView.swipeRight()
        XCTAssertEqual(configureLabel.label, "2 - 1")
        XCTAssertEqual(willDisplayLabel.label, "2 - 1")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 4")
        
        pagingView.swipeLeft()
        XCTAssertEqual(configureLabel.label, "2 - 4")
        XCTAssertEqual(willDisplayLabel.label, "2 - 4")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 1")
        
        pagingView.swipeRight()
        XCTAssertEqual(configureLabel.label, "2 - 1")
        XCTAssertEqual(willDisplayLabel.label, "2 - 1")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 4")
        
        pagingView.swipeRight()
        XCTAssertEqual(configureLabel.label, "2 - 0")
        XCTAssertEqual(willDisplayLabel.label, "2 - 0")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 3")
        
        pagingView.swipeRight()
        XCTAssertEqual(configureLabel.label, "0 - 9")
        XCTAssertEqual(willDisplayLabel.label, "0 - 9")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 2")
        
        pagingView.swipeRight()
        XCTAssertEqual(configureLabel.label, "0 - 8")
        XCTAssertEqual(willDisplayLabel.label, "0 - 8")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 1")
        
        pagingView.swipeRight()
        XCTAssertEqual(configureLabel.label, "0 - 7")
        XCTAssertEqual(willDisplayLabel.label, "0 - 7")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 0")
        
        pagingView.swipeRight()
        XCTAssertEqual(configureLabel.label, "0 - 6")
        XCTAssertEqual(willDisplayLabel.label, "0 - 6")
        XCTAssertEqual(didEndDisplayLabel.label, "0 - 9")
    }
    
    func testPagingRight() {
        XCTAssertEqual(configureLabel.label, "2 - 3")
        XCTAssertEqual(willDisplayLabel.label, "2 - 3")
        XCTAssertEqual(didEndDisplayLabel.label, "")
        
        pagingView.swipeRight()
        XCTAssertEqual(configureLabel.label, "2 - 0")
        XCTAssertEqual(willDisplayLabel.label, "2 - 0")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 3")
        
        pagingView.swipeLeft()
        XCTAssertEqual(configureLabel.label, "2 - 3")
        XCTAssertEqual(willDisplayLabel.label, "2 - 3")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 0")
        
        pagingView.swipeRight()
        XCTAssertEqual(configureLabel.label, "2 - 0")
        XCTAssertEqual(willDisplayLabel.label, "2 - 0")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 3")
        
        pagingView.swipeLeft()
        XCTAssertEqual(configureLabel.label, "2 - 3")
        XCTAssertEqual(willDisplayLabel.label, "2 - 3")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 0")
        
        pagingView.swipeLeft()
        XCTAssertEqual(configureLabel.label, "2 - 4")
        XCTAssertEqual(willDisplayLabel.label, "2 - 4")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 1")
        
        pagingView.swipeLeft()
        pagingView.swipeLeft()
        pagingView.swipeLeft()
        pagingView.swipeLeft()
        pagingView.swipeLeft()
        XCTAssertEqual(configureLabel.label, "2 - 9")
        XCTAssertEqual(willDisplayLabel.label, "2 - 9")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 6")
        
        pagingView.swipeLeft()
        XCTAssertEqual(configureLabel.label, "0 - 0")
        XCTAssertEqual(willDisplayLabel.label, "0 - 0")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 7")
        
        pagingView.swipeLeft()
        XCTAssertEqual(configureLabel.label, "0 - 1")
        XCTAssertEqual(willDisplayLabel.label, "0 - 1")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 8")
        
        pagingView.swipeLeft()
        XCTAssertEqual(configureLabel.label, "0 - 2")
        XCTAssertEqual(willDisplayLabel.label, "0 - 2")
        XCTAssertEqual(didEndDisplayLabel.label, "2 - 9")
        
        pagingView.swipeLeft()
        XCTAssertEqual(configureLabel.label, "0 - 3")
        XCTAssertEqual(willDisplayLabel.label, "0 - 3")
        XCTAssertEqual(didEndDisplayLabel.label, "0 - 0")
        
        pagingView.swipeLeft()
        XCTAssertEqual(configureLabel.label, "0 - 4")
        XCTAssertEqual(willDisplayLabel.label, "0 - 4")
        XCTAssertEqual(didEndDisplayLabel.label, "0 - 1")
    }
}
