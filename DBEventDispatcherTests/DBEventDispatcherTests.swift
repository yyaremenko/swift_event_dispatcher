//
//  DBEventDispatcherTests.swift
//  DBEventDispatcherTests
//
//  Created by Yaroslav Yaremenko on 3/16/16.
//  Copyright © 2016 DigitBrains. All rights reserved.
//

import XCTest

class DBEventDispatcherTests: XCTestCase {
    
    enum EventNames {
        enum CustomData: String, DBHasStringVal {
            case customDataCreated
            case customDataChanged
            
            var stringVal: String {
                return self.rawValue
            }
        }
    }
    
    class CustomDataEvent: DBEventProtocol {
        let eventName: DBHasStringVal
        var propagate = true
        
        var data: MyCustomData
        
        init(data: MyCustomData, eventName: EventNames.CustomData) {
            self.data = data
            self.eventName = eventName
        }
    }
    
    struct MyCustomData {
        var a: String
        var b: String
    }

    let eventNameDefault = EventNames.CustomData.customDataChanged
    
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
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    override func setUp() {
        super.setUp()
        DBEventDispatcher.clearAll()
    }
    
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    override func tearDown() {
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
    
    // MARK: Clear all
    
    func testClearAll() {
        let subscriberA = EventSubscriber()
        let subscriberB = EventSubscriber()
        
        doSubscribe(subscriberA, 100)
        doSubscribe(subscriberB, 200)
        
        DBEventDispatcher.clearAll()
        
        XCTAssertEqual(DBEventDispatcher.subscriptionsCatalog.count, 0, "Clear does not work as expected")
    }
    
    // MARK: Subscribe
    
    func testSubscriptionDifferentSubscribersSameEvent() {
        let subscriberA = EventSubscriber()
        let subscriberB = EventSubscriber()
        
        doSubscribe(subscriberA, 1)
        doSubscribe(subscriberB, 2)
        
        XCTAssertEqual(DBEventDispatcher.subscriptionsCatalog[eventNameDefault.rawValue]!.count, 2, "Invalid number of subscribers")
        
        DBEventDispatcher.clearAll()
    }
    
    func testSubscriptionDifferentSubscribersDifferentEvents() {
        let subscriberA = EventSubscriber()
        let subscriberB = EventSubscriber()
        
        doSubscribe(subscriberA, 10, DBEventDispatcherTests.EventNames.CustomData.customDataCreated)
        doSubscribe(subscriberB, 10, DBEventDispatcherTests.EventNames.CustomData.customDataChanged)
        
        XCTAssertEqual(DBEventDispatcher.subscriptionsCatalog[EventNames.CustomData.customDataCreated.rawValue]!.count, 1, "Invalid number of subscribers")
        XCTAssertEqual(DBEventDispatcher.subscriptionsCatalog[EventNames.CustomData.customDataChanged.rawValue]!.count, 1, "Invalid number of subscribers")
        
        DBEventDispatcher.clearAll()
    }
    
    func testSbuscriptionClearedOnSubscriberDeinit() {
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
        XCTAssertEqual(DBEventDispatcher.subscriptionsCatalog[eventNameDefault.rawValue]!.count, 3, "Invalid number of subscribers")
        
        subscriberA = nil
        subscriberB = nil
        
        doDispatch()
        
        XCTAssertEqual(DBEventDispatcher.subscriptionsCatalog[eventNameDefault.rawValue]!.count, 1, "Invalid number of subscribers")
        XCTAssertNotNil(subscriberC?.handleCallTime, "Proper subscriber was not called")
        
        DBEventDispatcher.clearAll()
    }
    
    // MARK: Unsubscribe
    
    func testUnsubscribeFromPaticularEvent() {
        let subscriberA = EventSubscriber()
        
        doSubscribe(subscriberA, 10, DBEventDispatcherTests.EventNames.CustomData.customDataCreated)
        doSubscribe(subscriberA, 10, DBEventDispatcherTests.EventNames.CustomData.customDataChanged)
        
        DBEventDispatcher.unsubscirbe(subscriberA, fromEvent: EventNames.CustomData.customDataCreated)
        
        XCTAssertEqual(DBEventDispatcher.subscriptionsCatalog[EventNames.CustomData.customDataCreated.rawValue]!.count, 0, "Did not unsubscribe from target event")
        XCTAssertEqual(DBEventDispatcher.subscriptionsCatalog[EventNames.CustomData.customDataChanged.rawValue]!.count, 1, "Unsubscribe from non-target event")
        
        DBEventDispatcher.clearAll()
    }
    
    func testUnsubscribeFromAllEvents() {
        let subscriberA = EventSubscriber()
        let subscriberB = EventSubscriber()
        
        doSubscribe(subscriberA, 10, DBEventDispatcherTests.EventNames.CustomData.customDataCreated)
        doSubscribe(subscriberA, 10, DBEventDispatcherTests.EventNames.CustomData.customDataChanged)
        
        doSubscribe(subscriberB, 10, DBEventDispatcherTests.EventNames.CustomData.customDataCreated)
        doSubscribe(subscriberB, 10, DBEventDispatcherTests.EventNames.CustomData.customDataChanged)
        
        DBEventDispatcher.unsubscirbe(subscriberA)
        
        XCTAssertEqual(
            DBEventDispatcher.subscriptionsCatalog[EventNames.CustomData.customDataCreated.rawValue]!.count,
            1,
            "All subscribers for given event unsubscribed"
        )
        
        let subscriberToEventA = DBEventDispatcher.subscriptionsCatalog[EventNames.CustomData.customDataCreated.rawValue]!.first
        XCTAssertTrue(subscriberToEventA?.hashValue == subscriberB.getHashValue(), "Improper subscriber unsubscribed")
        
        XCTAssertEqual(DBEventDispatcher.subscriptionsCatalog[EventNames.CustomData.customDataChanged.rawValue]!.count, 1, "All subscribers for given event unsubscribed")
        
        let subscriberToEventB = DBEventDispatcher.subscriptionsCatalog[EventNames.CustomData.customDataCreated.rawValue]!.first
        XCTAssertTrue(subscriberToEventB?.hashValue == subscriberB.getHashValue(), "Improper subscriber unsubscribed")
        
        DBEventDispatcher.clearAll()
    }
    
    // MARK: Handler
    
    func testHandlerCall() {
        for dataTuple in dataProvider() {
            let (weightA, weightB, _) = dataTuple
            
            let subscriberA = EventSubscriber()
            let subscriberB = EventSubscriber()
            
            doSubscribe(subscriberA, weightA)
            doSubscribe(subscriberB, weightB)
            
            doDispatch()
            
            XCTAssertEqual(DBEventDispatcher.subscriptionsCatalog[eventNameDefault.rawValue]!.count, 2, "Number of expected subscribers for this event does not match")
            
            // test that target handlers were called
            XCTAssertNotNil(subscriberA.handleCallTime, "No expected handler was called for subscriber A")
            XCTAssertNotNil(subscriberB.handleCallTime, "No expected handler was called for subscriber B")
            
            // a must, as we're in loop
            DBEventDispatcher.clearAll()
        }
    }
    
    func testHandlerCallOrder() {
        for dataTuple in dataProvider() {
            let (weightA, weightB, testExecutionOrder) = dataTuple
            if !testExecutionOrder {
                continue
            }
            
            let subscriberA = EventSubscriber()
            let subscriberB = EventSubscriber()
            
            doSubscribe(subscriberA, weightA)
            doSubscribe(subscriberB, weightB)
            
            doDispatch()
            
            XCTAssertTrue(subscriberA.handleCallTime < subscriberB.handleCallTime, "The order in which subsribers were called is broken")
            
            // a must, as we're in loop
            DBEventDispatcher.clearAll()
        }
    }
    
    func testHandlerCallSameSubscriberOneEventDifferentWeights() {
        let subscriber = EventSubscriber()
        
        doSubscribe(subscriber, -9)
        doSubscribe(subscriber, 7)
        
        doDispatch()
        
        XCTAssertEqual(subscriber.numberOfHandleCalls, 2, "Subscriber was not called expected number of times")
    }
    
    func testHandlerCallSameSubscriberOneEventSameWeights() {
        let subscriber = EventSubscriber()
        
        doSubscribe(subscriber, 1)
        doSubscribe(subscriber, 1)
        
        doDispatch()
        
        XCTAssertEqual(subscriber.numberOfHandleCalls, 1, "Subscriber was not called expected number of times")
    }
    
    // MARK: Stop propagation
    
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
    
    // MARK: -
    
    private func doSubscribe(subscriber: EventSubscriber, _ weight: Int, _ eventName: EventNames.CustomData? = nil) {
        let eventName = eventName ?? eventNameDefault
        DBEventDispatcher.subscribe(subscriber, toEventName: eventName, weight: weight, handle: subscriber.handle!)
    }
    
    private func doDispatch() {
        DBEventDispatcher.dispatch(CustomDataEvent(data: MyCustomData(a: "aaa", b: "bbb"), eventName: eventNameDefault))
    }
}
