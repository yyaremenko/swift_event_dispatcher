//
//  DBEventDispatcher.swift
//  DBEventDispatcher
//
//  Created by Yaroslav Yaremenko on 3/16/16.
//  Copyright © 2016 DigitBrains. All rights reserved.
//

struct DBEventDispatcher {
    internal private(set) static var subscriptionsCatalog = [String: Set<DBEventSubscription>]()
    
    static func clearAll() {
        subscriptionsCatalog.removeAll()
    }
    
    static func dispatch(event: DBEventProtocol) {
        let eventNameRaw = event.eventName.stringVal
        
        guard let subscriptions = subscriptionsCatalog[eventNameRaw] else {
            return
        }
        
        for subscription in subscriptions.sort() {
            // remove subscription if referenced object does not exist anymore
            guard let _ = subscription.subscriber else {
                removeSubscription(subscription, eventNameRaw: eventNameRaw)
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
        if subscriptionsCatalog[eventNameRaw] == nil {
            subscriptionsCatalog[eventNameRaw] = []
        }
        
        subscriptionsCatalog[eventNameRaw]!.insert(DBEventSubscription(subscriber: subscriber, weight: weight, handle: handle))
    }
    
    static func unsubscirbe(subscriber: DBEventDrivenProtocol, fromEvent eventName: DBHasStringVal? = nil) {
        guard let eventName = eventName else {
            for (eventNameRaw, _) in subscriptionsCatalog {
                unsubscribeFromEvent(subscriber, eventNameRaw: eventNameRaw)
            }
            return
        }
        
        unsubscribeFromEvent(subscriber, eventNameRaw: eventName.stringVal)
    }
    
    private static func unsubscribeFromEvent(subscriber: DBEventDrivenProtocol, eventNameRaw: String) {
        guard let subscriptions = subscriptionsCatalog[eventNameRaw] else {
            return
        }
        
        for subscription in subscriptions {
            // remove subscription if referenced object does not exist anymore
            guard let existingSubscriber = subscription.subscriber else {
                removeSubscription(subscription, eventNameRaw: eventNameRaw)
                continue
            }
            
            if existingSubscriber.getHashValue() == subscriber.getHashValue() {
                subscriptionsCatalog[eventNameRaw]!.remove(subscription)
            }
        }
    }
    
    private static func removeSubscription(subscription: DBEventSubscription, eventNameRaw: String) {
        subscriptionsCatalog[eventNameRaw]!.remove(subscription)
    }
}

