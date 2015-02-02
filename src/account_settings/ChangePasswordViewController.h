//
//  ChangePasswordViewController.h
//  ARIS
//
//  Created by Brian Thiel on 10/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARISViewController.h"

@protocol ChangePasswordViewControllerDelegate
- (void) changePasswordWasDismissed;
@end

@interface ChangePasswordViewController : ARISViewController
- (id) initWithDelegate:(id<ChangePasswordViewControllerDelegate>)d;
@end
