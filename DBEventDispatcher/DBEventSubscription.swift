//
//  DBEventSubscription.swift
//  DBEventDispatcher
//
//  Created by Yaroslav Yaremenko on 3/16/16.
//  Copyright © 2016 DigitBrains. All rights reserved.
//

import Foundation

public struct DBEventSubscription: Hashable {
    weak var subscriber: DBEventDrivenProtocol?
    
    public let hashValue: Int
    let weight: Int
    let handle: DBEventHandle
    
    init(subscriber: DBEventDrivenProtocol, weight: Int, handle: DBEventHandle) {
        self.subscriber = subscriber
        self.hashValue = subscriber.getHashValue()
        self.weight = weight
        self.handle = handle
    }
}

extension DBEventSubscription: Equatable {}

public func ==(lhs: DBEventSubscription, rhs: DBEventSubscription) -> Bool {
    // allows same subscriber subscribe to the same event more than once,
    // using different weight
    return lhs.hashValue == rhs.hashValue && lhs.weight == rhs.weight
}

extension DBEventSubscription: Comparable {}

public func <(lhs: DBEventSubscription, rhs: DBEventSubscription) -> Bool {
    return lhs.weight < rhs.weight
}
public func <=(lhs: DBEventSubscription, rhs: DBEventSubscription) -> Bool {
    return lhs.weight <= rhs.weight
}
public func >=(lhs: DBEventSubscription, rhs: DBEventSubscription) -> Bool {
    return lhs.weight >= rhs.weight
}
public func >(lhs: DBEventSubscription, rhs: DBEventSubscription) -> Bool {
    return lhs.weight > rhs.weight
}

