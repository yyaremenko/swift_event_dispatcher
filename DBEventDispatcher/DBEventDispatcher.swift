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
    
    static func dispatch(event: DBEventProtocol) {
        let eventNameRaw = event.eventName.stringVal
        
        guard let subscriptions = subscribers[eventNameRaw] else {
            return
        }
        
        for subscription in subscriptions.sort() {
            // remove subscription if referenced object does not exist anymore
            guard let _ = subscription.subscriber else {
                subscribers[eventNameRaw]!.remove(subscription)
                continue
            }
            
            subscription.handle(event: event)
            if event.propagate == false {
                return
            }
        }
    }
    
    static func subscribe(subscriber: DBEventDrivenProtocol, toEventName eventName: DBHasStringVal, weight: Int = 0, handle: DBEventHandle) {
        let eventNameRaw = eventName.stringVal
        if subscribers[eventNameRaw] == nil {
            subscribers[eventNameRaw] = []
        }
        
        subscribers[eventNameRaw]!.insert(DBEventSubscription(subscriber: subscriber, weight: weight, handle: handle))
    }
    
    static func unsubscirbe(subscriber: DBEventDrivenProtocol) {
        for (eventNameRaw, subscriptions) in subscribers {
            for subscription in subscriptions {
                
                guard let existingSubscriber = subscription.subscriber else {
                    subscribers[eventNameRaw]!.remove(subscription)
                    continue
                }
                
                if existingSubscriber.getHashValue() == subscriber.getHashValue() {
                    subscribers[eventNameRaw]!.remove(subscription)
                }
            }
        }
    }
    
}

