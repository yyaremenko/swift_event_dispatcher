//
//  DBEventDispatcher.swift
//  DBEventDispatcher
//
//  Created by Yaroslav Yaremenko on 3/16/16.
//  Copyright © 2016 DigitBrains. All rights reserved.
//

struct DBEventDispatcher {
    internal private(set) static var subscribers = [String: Set<DBEventSubscription>]()
    
    static func clearAll() {
        subscribers.removeAll()
    }
    
    static func dispatch(parcel: DBEventParcelProtocol) {
        let (eventName, event) = parcel.unpack()
        
        guard let subscriptions = subscribers[eventName] else {
            return
        }
        
        for subscription in subscriptions.sort() {
            // remove subscription if referenced object does not exist anymore
            guard let _ = subscription.subscriber else {
                subscribers[eventName]!.remove(subscription)
                continue
            }
            
            subscription.handle(event: event)
            if event.propagate == false {
                return
            }
        }
    }
    
    static func subscribe(subscriber: DBEventDrivenProtocol, toEventName eventName: String, weight: Int = 0, handle: DBEventHandle) {
        if subscribers[eventName] == nil {
            subscribers[eventName] = []
        }

        subscribers[eventName]!.insert(DBEventSubscription(subscriber: subscriber, weight: weight, handle: handle))
    }
    
    static func unsubscirbe(subscriber: DBEventDrivenProtocol) {
        for (eventName, subscriptions) in subscribers {
            for subscription in subscriptions {
                
                guard let existingSubscriber = subscription.subscriber else {
                    subscribers[eventName]!.remove(subscription)
                    continue
                }
                
                if existingSubscriber.getHashValue() == subscriber.getHashValue() {
                    subscribers[eventName]!.remove(subscription)
                }
            }
        }
    }
    
}

