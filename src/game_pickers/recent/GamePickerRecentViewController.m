//
//  GamePickerRecentViewController.m
//  ARIS
//
//  Created by David J Gagnon on 6/7/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

#include <QuartzCore/QuartzCore.h>
#import "GamePickerRecentViewController.h"
#import "AppModel.h"
#import "AppServices.h"
#import "Game.h"
#import "User.h"
#import "Location.h"
#import "GameDetailsViewController.h"
#import "GamePickerCell.h"
#import "UIColor+ARISColors.h"

@implementation GamePickerRecentViewController

- (id) initWithDelegate:(id<GamePickerViewControllerDelegate>)d
{
    if(self = [super initWithDelegate:d])
    {
        self.title = NSLocalizedString(@"GamePickerRecentTabKey", @"");
        
        [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"clock_red.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"clock.png"]];   
  _ARIS_NOTIF_LISTEN_(@"MODEL_RECENT_GAMES_AVAILABLE",self,@selector(recentGamesAvailable),nil);
    }
    return self;
}

- (void) recentGamesAvailable
{
    [self removeLoadingIndicator]; 
    [self refreshViewFromModel];
}

- (void) refreshViewFromModel
{
	gameList = _MODEL_GAMES_.recentGames;
	[gameTable reloadData];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
