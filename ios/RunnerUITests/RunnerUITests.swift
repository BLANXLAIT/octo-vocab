//
//  RunnerUITests.swift
//  RunnerUITests
//
//  Created by Ryan William Niemes on 9/2/25.
//

import XCTest

final class RunnerUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
        
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    func testScreenshots() throws {
        // Launch screen
        snapshot("01_Launch")
        
        // Wait for app to load
        sleep(2)
        
        // Main menu/home screen
        snapshot("02_Home")
        
        // Navigate to language selection if available
        // This is a basic example - you'll need to adapt based on your actual app flow
        if app.buttons["Latin"].exists {
            app.buttons["Latin"].tap()
            sleep(1)
            snapshot("03_Latin_Selection")
        }
        
        // If there's a vocabulary list or study mode
        if app.buttons["Study"].exists || app.buttons["Flashcards"].exists {
            if app.buttons["Study"].exists {
                app.buttons["Study"].tap()
            } else {
                app.buttons["Flashcards"].tap()
            }
            sleep(2)
            snapshot("04_Study_Mode")
        }
        
        // If there's a quiz mode
        if app.buttons["Quiz"].exists {
            app.buttons["Quiz"].tap()
            sleep(2)
            snapshot("05_Quiz_Mode")
        }
        
        // Settings or about screen
        if app.buttons["Settings"].exists {
            app.buttons["Settings"].tap()
            sleep(1)
            snapshot("06_Settings")
        }
    }
}
