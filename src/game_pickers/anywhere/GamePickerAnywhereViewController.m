//
//  GamePickerAnywhereViewController.m
//  ARIS
//
//  Created by Ben Longoria on 2/13/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#include <QuartzCore/QuartzCore.h>
#import "GamePickerAnywhereViewController.h"
#import "AppModel.h"
#import "AppServices.h"
#import "Game.h"
#import "GameDetailsViewController.h"
#import "GamePickerCell.h"
#import "Player.h"
#import "UIImage+Color.h"
#import "UIColor+ARISColors.h"
#import "UIImage+Resize.h"

@implementation GamePickerAnywhereViewController

- (id) initWithDelegate:(id<GamePickerViewControllerDelegate>)d
{
    if(self = [super initWithDelegate:d])
    {
        [[UIImage imageNamed:@"Globe.png" withColor:[UIColor ARISColorRed]] resizedImage:CGSizeMake(48, 48) interpolationQuality:kCGInterpolationHigh];
        self.title = NSLocalizedString(@"GamePickerAnywhereTabKey", @"");
        [self.tabBarItem setFinishedSelectedImage:[[UIImage imageNamed:@"globe-512.png" withColor:[UIColor ARISColorRed]] resizedImage:CGSizeMake(24, 24) interpolationQuality:kCGInterpolationHigh] withFinishedUnselectedImage:[[UIImage imageNamed:@"globe-512.png" withColor:[UIColor ARISColorDarkGray]] resizedImage:CGSizeMake(24, 24) interpolationQuality:kCGInterpolationHigh]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewFromModel) name:@"NewAnywhereGameListReady" object:nil];
    }
    return self;
}

- (void) requestNewGameList
{
    [super requestNewGameList];
    
    if([AppModel sharedAppModel].deviceLocation && [AppModel sharedAppModel].player) 
    {
        [[AppServices sharedAppServices] fetchAnywhereGameList];
        [self showLoadingIndicator];
    }
}

- (void) refreshViewFromModel
{
	self.gameList = [[AppModel sharedAppModel].anywhereGameList sortedArrayUsingSelector:@selector(compareCalculatedScore:)];
    [self.gameTable reloadData];
    
    [self removeLoadingIndicator];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
