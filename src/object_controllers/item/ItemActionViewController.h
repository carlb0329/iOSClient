//
//  ItemActionViewController.h
//  ARIS
//
//  Created by Brian Thiel on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARISViewController.h"

#import "ItemViewController.h"

@class Item;

@protocol ItemActionViewControllerDelegate
- (void) amtChosen:(long)amt positive:(BOOL)p;
@end
@interface ItemActionViewController : ARISViewController
- (id) initWithPrompt:(NSString *)s positive:(BOOL)p maxqty:(long)q delegate:(id)d;
@end
