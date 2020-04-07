//
//  CoEpiNetworkingV3Tests.swift
//  CoEpiNetworkingTests
//
//  Created by Dusko Ojdanic on 4/7/20.
//  Copyright © 2020 org.coepi. All rights reserved.
//

import XCTest
import Foundation
import Alamofire
import RxBlocking
//@testable import CoEpi

final class AlamofireLogger: EventMonitor {
    func requestDidResume(_ request: Request) {
        let body = request.request.flatMap { $0.httpBody.map { String(decoding: $0, as: UTF8.self) } } ?? "None"
        let message = """
        ⚡️ Request Started: \(request)
        ⚡️ Body Data: \(body)
        """
        NSLog(message)
    }

    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, Error>) {
        NSLog("⚡️ Response Received: \(response.debugDescription)")
    }
}

class CoEpiNetworkingV3Tests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        //https://q69c4m2myb.execute-api.us-west-2.amazonaws.com/v3
        /**
         curl -X POST https://q69c4m2myb.execute-api.us-west-2.amazonaws.com/v3/cenreport -d '{ "report": "dWlyZSBhdXRob3JgdsF0aW9uLgo=", "cenKeys": [ "baz", "das" ]}'

         curl -X GET https://q69c4m2myb.execute-api.us-west-2.amazonaws.com/v3/cenreport
         [{"did":"2020-04-06","reportTimestamp":1586157667433,"report":"dWlyZSBhdXRob3JpemF0aW9uLgo=","cenKeys":["bar","foo"]},{"did":"2020-04-06","reportTimestamp":1586158348099,"report":"dWlyZSBhdXRob3JpemF0aW9uLgo=","cenKeys":["bar","foo"]},{"did":"2020-04-06","reportTimestamp":1586158404001,"report":"dWlyZSBhdXRob3JgdsF0aW9uLgo=","cenKeys":["baz","das"]}]
         TO DO
         */
    }
    
    func testV3getCenReport() {
        
        let url: String = "https://q69c4m2myb.execute-api.us-west-2.amazonaws.com/v3/cenreport"
        let expect = expectation(description: "request complete")
        
        let session = Session(eventMonitors: [ AlamofireLogger() ])
        
        let request = session.request(url).responseJSON { response in
            expect.fulfill()
            guard let data = response.data else { return }
            do {
                print(data)
//                let decoder = JSONDecoder()

            } catch let error {
                print("Couldn't parse reponse: \(error), " +
                        "data: \(String(describing: String(data: data, encoding: .utf8)))")
            }
        }
        
        waitForExpectations(timeout: 5)

               // Then
//               XCTAssertNotNil(data)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
