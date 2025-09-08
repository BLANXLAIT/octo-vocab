//
//  RunnerUITests.swift
//  RunnerUITests
//
//  Created by Ryan William Niemes on 9/2/25.
//

import XCTest

final class RunnerUITests: XCTestCase {
    var app: XCUIApplication!
    
    @MainActor
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
        
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    @MainActor
    func testScreenshots() throws {
        // Launch screen - show the app loading
        snapshot("01_Launch")
        
        // Wait for app to load and animations to complete
        sleep(3)
        
        // Debug: Print accessibility tree to help troubleshoot
        printAccessibilityTree()
        
        // The first screen after launch is Learn, so capture it
        snapshot("02_Learn")
        
        // Tab 1: Quiz
        navigateToTabByIndex(1, screenshotName: "03_Quiz")
        
        // Tab 2: Settings
        navigateToTabByIndex(2, screenshotName: "04_Settings")
    }
    
    @MainActor
    private func navigateToTabByIndex(_ index: Int, screenshotName: String) {
        print("Attempting to navigate to tab \(index) for screenshot: \(screenshotName)")
        
        // Strategy 1: Try coordinate-based approach first (most reliable for Flutter)
        navigateByCoordinates(index: index, screenshotName: screenshotName)
        
        // If coordinate approach worked, we're done
        return
    }
    
    @MainActor
    private func navigateByCoordinates(index: Int, screenshotName: String) {
        let screenWidth = app.frame.width
        let screenHeight = app.frame.height
        
        print("Screen dimensions: \(screenWidth) x \(screenHeight)")
        
        // Bottom navigation bar coordinates - more precise positioning
        let tabCount: CGFloat = 3 // 3 tabs: Learn, Quiz, Settings
        let tabWidth = screenWidth / tabCount
        let xPosition = (CGFloat(index) * tabWidth) + (tabWidth / 2) // Center of each tab
        
        // Bottom navigation is typically around 80-100 points from bottom
        // Using 90 points from bottom to hit the center of the nav bar
        let yPosition = screenHeight - 90
        
        print("Attempting to tap tab \(index) at coordinates: (\(xPosition), \(yPosition))")
        
        // Create coordinate and tap
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: xPosition, dy: yPosition))
        
        coordinate.tap()
        
        // Wait for navigation animation
        sleep(3)
        
        // Take screenshot
        snapshot(screenshotName)
        
        // Brief pause before next navigation
        sleep(1)
    }
    
    @MainActor
    private func printAccessibilityTree() {
        print("\n=== ACCESSIBILITY TREE DEBUG ===")
        print("TabBars count: \(app.tabBars.count)")
        print("NavigationBars count: \(app.navigationBars.count)")
        print("Buttons count: \(app.buttons.count)")
        
        print("\nAll buttons:")
        for i in 0..<min(app.buttons.count, 10) { // Limit to first 10
            let button = app.buttons.element(boundBy: i)
            if button.exists {
                print("Button \(i): identifier='\(button.identifier)', label='\(button.label)', isHittable=\(button.isHittable)")
            }
        }
        
        print("\nTabBar buttons:")
        if app.tabBars.count > 0 {
            let tabBar = app.tabBars.firstMatch
            for i in 0..<min(tabBar.buttons.count, 10) {
                let button = tabBar.buttons.element(boundBy: i)
                if button.exists {
                    print("TabBar Button \(i): identifier='\(button.identifier)', label='\(button.label)', isHittable=\(button.isHittable)")
                }
            }
        }
        
        print("=== END ACCESSIBILITY TREE ===\n")
    }
}
