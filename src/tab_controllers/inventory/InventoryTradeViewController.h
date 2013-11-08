//
//  InventoryTradeViewController.h
//  ARIS
//
//  Created by Jacob Hanshaw on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppModel.h"
#import "AppServices.h"
#import "ARISAppDelegate.h"
#import "Item.h"
#import "RoundedTableViewCell.h"

@protocol InventoryTradeViewControllerDelegate
- (void) tradeDidComplete;
- (void) tradeCancelled;
@end

@interface InventoryTradeViewController : ARISViewController
{
	UITableView *tradeTableView;
	NSMutableArray *inventory;
    NSMutableArray *itemsToTrade;
	NSMutableArray *iconCache;
    NSMutableArray *mediaCache;
}

@property(nonatomic) IBOutlet UITableView *tradeTableView;
@property(nonatomic) NSMutableArray *inventory;
@property(nonatomic) NSMutableArray *itemsToTrade;
@property(nonatomic) NSMutableArray *iconCache;
@property(nonatomic) NSMutableArray *mediaCache;

- (id) initWithDelegate:(id<InventoryTradeViewControllerDelegate>)d;
- (NSString *)generateTransactionJSON;

@end
