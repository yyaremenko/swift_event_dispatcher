//
//  DBEventProtocols.swift
//  DBEventDispatcher
//
//  Created by Yaroslav Yaremenko on 3/16/16.
//  Copyright © 2016 DigitBrains. All rights reserved.
//

public typealias DBEventHandle = (event: DBEventProtocol) -> Void

public protocol DBIdentifiableProtocol: class {
    func getHashValue() -> Int
}

public protocol DBStringRawValue {
    var rawValue: String { get }
}

public protocol DBEventProtocol {
    var eventName: DBStringRawValue { get }
    var propagate: Bool { get set }
}

public protocol DBEventDrivenProtocol: DBIdentifiableProtocol {
    func subscribeAnotherToEvent(anotherSubscriber: DBEventDrivenProtocol, toEventName eventName: DBStringRawValue, weight: Int, handle: DBEventHandle)
    func subscribeToEvent(eventName: DBStringRawValue, weight: Int, handle: DBEventHandle)
    
    func dispatchEvent(event: DBEventProtocol)
    
    func unsubscribeFromAll()
}

extension DBIdentifiableProtocol {
    public func getHashValue() -> Int {
        return ObjectIdentifier(self).hashValue
    }
}

// these methods are mostly wrappers, needed
// to prevent direct call of DBEventDispatcher static methods
extension DBEventDrivenProtocol {
    public func subscribeAnotherToEvent(anotherSubscriber: DBEventDrivenProtocol, toEventName eventName: DBStringRawValue, weight: Int = 0, handle: DBEventHandle) {
        DBEventDispatcher.subscribe(anotherSubscriber, toEventName: eventName, weight: weight, handle: handle)
    }
    
    public func subscribeToEvent(eventName: DBStringRawValue, weight: Int = 0, handle: DBEventHandle) {
        DBEventDispatcher.subscribe(self, toEventName: eventName, weight: weight, handle: handle)
    }
    
    public func dispatchEvent(event: DBEventProtocol) {
        DBEventDispatcher.dispatch(event)
    }
    
    public func unsubscribeFromAll() {
        DBEventDispatcher.unsubscirbe(self)
    }
}