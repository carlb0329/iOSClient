//
//  DisplayQueueModel.h
//  ARIS
//
//  Created by Phil Dougherty on 2/24/14.
//
//

#import <Foundation/Foundation.h>
@class Trigger;
@class Instance;
@protocol InstantiableProtocol;
@class Tab;

@interface DisplayQueueModel : NSObject

- (void) clear;

- (void) enqueueTrigger:(Trigger *)t;
- (void) injectTrigger:(Trigger *)t;
- (void) enqueueInstance:(Instance *)i;
- (void) injectInstance:(Instance *)i;
- (void) enqueueObject:(id<InstantiableProtocol>)o;
- (void) injectObject:(id<InstantiableProtocol>)o;
- (void) enqueueTab:(Tab *)t;
- (void) injectTab:(Tab *)t;

- (id) dequeue;

@end
