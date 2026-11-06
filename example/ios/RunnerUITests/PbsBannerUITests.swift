import XCTest

final class PbsBannerUITests: XCTestCase {
    private let auditURL = URL(string: "http://127.0.0.1:8000")!

    func testTapDspBanner() {
        resetAudit()

        let app = XCUIApplication()
        app.launch()

        let creativeLink = app.links.matching(identifier: "DSP E2E banner").firstMatch
        XCTAssertTrue(creativeLink.waitForExistence(timeout: 90))
        XCTAssertTrue(waitForMetric("ready", minimum: 1, timeout: 90), "Flutter did not finish showing the banner")
        XCTAssertTrue(waitForMetric("bid_found", minimum: 1, timeout: 10), "Local DSP bid was not returned")

        let bannerScreenshot = XCTAttachment(screenshot: app.screenshot())
        bannerScreenshot.name = "ios-dsp-banner"
        bannerScreenshot.lifetime = .keepAlways
        add(bannerScreenshot)

        // The fixture centers the 300x250 creative in the app viewport.
        // Tap its center: the link's accessibility frame covers only its text.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(waitForMetric("landing_hits", minimum: 1, timeout: 30), "DSP landing page was not opened")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "ios-dsp-banner-after-tap"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func resetAudit() {
        var request = URLRequest(url: auditURL.appendingPathComponent("__e2e/reset"))
        request.httpMethod = "POST"
        let expectation = expectation(description: "Reset PBS audit")
        URLSession.shared.dataTask(with: request) { _, response, error in
            XCTAssertNil(error)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            expectation.fulfill()
        }.resume()
        wait(for: [expectation], timeout: 10)
    }

    private func waitForMetric(_ name: String, minimum: Int, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let url = auditURL.appendingPathComponent("__e2e/metrics")
        while Date() < deadline {
            let response = expectation(description: "Read PBS audit metrics")
            var value = 0
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data,
                   let metrics = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    value = metrics[name] as? Int ?? 0
                }
                response.fulfill()
            }.resume()
            wait(for: [response], timeout: 5)
            if value >= minimum {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(1))
        }
        return false
    }
}
