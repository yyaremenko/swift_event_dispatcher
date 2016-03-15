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

public protocol DBEventProtocol {
    var propagate: Bool { get set }
}

public protocol DBEventParcelProtocol {
    func unpack() -> (String, DBEventProtocol)
}

public protocol DBEventDrivenProtocol: DBIdentifiableProtocol {
    func subscribeAnotherToEvent(anotherSubscriber: DBEventDrivenProtocol, toEventName: String, weight: Int, handle: DBEventHandle)
    func subscribeToEvent(eventName: String, weight: Int, handle: DBEventHandle)
    func dispatchEventParcel(parcel: DBEventParcelProtocol)
    func unsubscribeFromAll()
}

extension DBIdentifiableProtocol {
    func getHashValue() -> Int {
        return ObjectIdentifier(self).hashValue
    }
}

// these methods are mostly wrappers, needed
// to prevent direct call of DBEventDispatcher static methods
extension DBEventDrivenProtocol {
    func subscribeAnotherToEvent(anotherSubscriber: DBEventDrivenProtocol, toEventName: String, weight: Int = 0, handle: DBEventHandle) {
        DBEventDispatcher.subscribe(anotherSubscriber, toEventName: toEventName, weight: weight, handle: handle)
    }
    
    func subscribeToEvent(eventName: String, weight: Int = 0, handle: DBEventHandle) {
        DBEventDispatcher.subscribe(self, toEventName: eventName, weight: weight, handle: handle)
    }
    
    func dispatchEventParcel(parcel: DBEventParcelProtocol) {
        DBEventDispatcher.dispatch(parcel)
    }
    
    func unsubscribeFromAll() {
        DBEventDispatcher.unsubscirbe(self)
    }
}