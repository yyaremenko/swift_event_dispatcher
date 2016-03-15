//
//  DBEventDispatcherTests.swift
//  DBEventDispatcherTests
//
//  Created by Yaroslav Yaremenko on 3/16/16.
//  Copyright © 2016 DigitBrains. All rights reserved.
//

import XCTest

class DBEventDispatcherTests: XCTestCase {
    
    struct MyCustomData {
        var a: String
        var b: String
    }
    
    enum EventType {
        enum CustomData: String {
            case customDataCreated
            case customDataChanged
        }
    }
    
    enum EventParcel: DBEventParcelProtocol {
        case CustomDataEventParcel(EventType.CustomData, CustomDataEvent)
        
        func unpack() -> (String, DBEventProtocol) {
            switch self {
            case .CustomDataEventParcel(let eventType, let event):
                return (eventType.rawValue, event)
            }
        }
    }
    
    class CustomDataEvent: DBEventProtocol {
        var propagate = true
        var data: MyCustomData
        
        init(data: MyCustomData) {
            self.data = data
        }
    }

    let eventType = EventType.CustomData.customDataChanged
    
    class EventSubscriber: DBEventDrivenProtocol {
        var handle: DBEventHandle?
        var handleCallTime: CFTimeInterval?
        var numberOfHandleCalls = 0
        
        init(stopPropagation: Bool = false) {
            handle = {
                [unowned self]
                (var event: DBEventProtocol) -> Void in
                
                self.handleCallTime = CACurrentMediaTime()
                self.numberOfHandleCalls++
                
                if stopPropagation {
                    event.propagate = false
                }
            }
        }
    }
    
    override func setUp() {
        super.setUp()
        DBEventDispatcher.clearAll()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        DBEventDispatcher.clearAll()
    }
    
    private func dataProvider() -> [(weightA: Int, weightB: Int, testExecutionOrder: Bool)] {
        return [
            (0, 0, false),
            (-7, -7, false),
            (10, 10, false),
            (-1, 3, true),
            (7, 12, true),
        ]
    }
    
    func testStoreAndClearAll() {
        let subscriberA = EventSubscriber()
        let subscriberB = EventSubscriber()
        
        doSubscribe(subscriberA, 100)
        doSubscribe(subscriberB, 200)
        
        XCTAssertEqual(DBEventDispatcher.subscribers[eventType.rawValue]!.count, 2, "Invalid number of subscribers")
        
        DBEventDispatcher.clearAll()
        
        XCTAssertEqual(DBEventDispatcher.subscribers.count, 0, "Clear does not work as expected")
    }
    
    func testHandlersAreProperlyCalled() {
        for dataTuple in dataProvider() {
            let (weightA, weightB, testExecutionOrder) = dataTuple
            
            let subscriberA = EventSubscriber()
            let subscriberB = EventSubscriber()
            
            doSubscribe(subscriberA, weightA)
            doSubscribe(subscriberB, weightB)
            
            doDispatch()
            
            XCTAssertEqual(DBEventDispatcher.subscribers[eventType.rawValue]!.count, 2, "Number of expected subscribers for this event does not match")
            
            // test that target methods were called
            XCTAssertNotNil(subscriberA.handleCallTime, "No expected handler was called for subscriber A")
            XCTAssertNotNil(subscriberB.handleCallTime, "No expected handler was called for subscriber B")
            
            // test that subscribers were called in proper order (if required)
            if !testExecutionOrder {
                return
            }
            XCTAssertTrue(subscriberA.handleCallTime < subscriberB.handleCallTime, "The order in which subsribers were called is broken")
            
            // a must, as we're in loop
            DBEventDispatcher.clearAll()
        }
    }
    
    func testStopPropagation() {
        let subscriberA = EventSubscriber(stopPropagation: true)
        let subscriberB = EventSubscriber()
        
        doSubscribe(subscriberA, -2)
        doSubscribe(subscriberB, 3)
        
        doDispatch()
        
        XCTAssertNotNil(subscriberA.handleCallTime, "No expected handler was called for subscriber A")
        if subscriberB.handleCallTime != nil {
            XCTFail("Event propagation did not stop")
        }
    }
    
    func testMultipleSubscriptionsToSameEventDifferentWeights() {
        let subscriber = EventSubscriber()
        
        doSubscribe(subscriber, -9)
        doSubscribe(subscriber, 7)
        
        doDispatch()
        
        XCTAssertEqual(subscriber.numberOfHandleCalls, 2, "Subscriber was not called expected number of times")
    }
    
    func testMultipleSubscriptionsToSameEventSameWeights() {
        let subscriber = EventSubscriber()
        
        doSubscribe(subscriber, 1)
        doSubscribe(subscriber, 1)
        
        doDispatch()
        
        XCTAssertEqual(subscriber.numberOfHandleCalls, 1, "Subscriber was not called expected number of times")
    }
    
    func testSbuscriptionsClearedOnSubscriberDeinit() {
        var subscriberA: EventSubscriber?
        var subscriberB: EventSubscriber?
        var subscriberC: EventSubscriber?
        
        subscriberA = EventSubscriber()
        subscriberB = EventSubscriber()
        subscriberC = EventSubscriber()
        
        doSubscribe(subscriberA!, 4)
        doSubscribe(subscriberB!, 6)
        doSubscribe(subscriberC!, -1)
        
        // make sure subscriptions are properly written
        XCTAssertEqual(DBEventDispatcher.subscribers[eventType.rawValue]!.count, 3, "Invalid number of subscribers")
        
        subscriberA = nil
        subscriberB = nil
        
        doDispatch()
        
        XCTAssertEqual(DBEventDispatcher.subscribers[eventType.rawValue]!.count, 1, "Invalid number of subscribers")
        XCTAssertNotNil(subscriberC?.handleCallTime, "Proper subscriber was not called")
    }
    
    private func doSubscribe(subscriber: EventSubscriber, _ weight: Int) {
        DBEventDispatcher.subscribe(subscriber, toEventName: eventType.rawValue, weight: weight, handle: subscriber.handle!)
    }
    
    private func doDispatch() {
        DBEventDispatcher.dispatch(EventParcel.CustomDataEventParcel(eventType, CustomDataEvent(data: MyCustomData(a: "aaa", b: "bbb"))))
    }
}
