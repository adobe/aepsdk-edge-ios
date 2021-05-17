//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPEdge
import XCTest

class ScreenOrientationTests: XCTestCase {

    func testFromDeviceOrientationPortrait() {
        XCTAssertEqual(ScreenOrientation.portrait, ScreenOrientation.from(deviceOrientation: .PORTRAIT))
    }

    func testFromDeviceOrientationLandscape() {
        XCTAssertEqual(ScreenOrientation.landscape, ScreenOrientation.from(deviceOrientation: .LANDSCAPE))
    }

    func testFromDeviceOrientationUnknown() {
        XCTAssertNil(ScreenOrientation.from(deviceOrientation: .UNKNOWN))
    }

    // MARK: Encodable Tests

    func testEncodePortrait() throws {
        // setup
        let orientation = ScreenOrientation.portrait

        // test
        let data = try XCTUnwrap(JSONEncoder().encode(orientation))
        let dataStr = String(data: data, encoding: .utf8)

        // verify
        XCTAssertEqual("\"portrait\"", dataStr)
    }

    func testEncodeLandscape() throws {
        // setup
        let orientation = ScreenOrientation.landscape

        // test
        let data = try XCTUnwrap(JSONEncoder().encode(orientation))
        let dataStr = String(data: data, encoding: .utf8)

        // verify
        XCTAssertEqual("\"landscape\"", dataStr)
    }

}
