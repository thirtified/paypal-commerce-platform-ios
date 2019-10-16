//
//  UnitTests.swift
//  UnitTests
//
//  Created by Merino, David on 10/16/19.
//  Copyright © 2019 Braintree Payments. All rights reserved.
//

import XCTest

class UnitTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = BTPayPalValidatorClient(accessToken: "", orderId: "")
        XCTAssertNil(client)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
