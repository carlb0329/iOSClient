//
//  GamePickerPopularViewController.m
//  ARIS
//
//  Created by Jacob Hanshaw on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <QuartzCore/QuartzCore.h>
#import "GamePickerPopularViewController.h"
#import "AppModel.h"
#import "AppServices.h"
#import "Game.h"
#import "User.h"
#import "GameDetailsViewController.h"
#import "GamePickerCell.h"
#import "UIColor+ARISColors.h"

@interface GamePickerPopularViewController()
{
    int time;
    UISegmentedControl *timeControl;
}
@property (nonatomic, strong) UISegmentedControl *timeControl;
@end
    
@implementation GamePickerPopularViewController

@synthesize timeControl;

- (id) initWithDelegate:(id<GamePickerViewControllerDelegate>)d
{
    if(self = [super initWithDelegate:d])
    {
        time = 1;
        
        self.title = NSLocalizedString(@"GamePickerPopularTabKey", @"");
        
        [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"star_red.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"star.png"]];  

  _ARIS_NOTIF_LISTEN_(@"NewPopularGameListReady",self,@selector(refreshViewFromModel),nil);
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.timeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"GamePickerDailyKey", @""),NSLocalizedString(@"GamePickerWeeklyKey", @""),NSLocalizedString(@"GamePickerMonthlyKey", @""), nil]];
    self.timeControl.frame = CGRectMake(5, 5, self.view.bounds.size.width-10, 30);
    self.timeControl.selectedSegmentIndex = time;
    self.timeControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [self.timeControl addTarget:self action:@selector(controlChanged) forControlEvents:UIControlEventValueChanged];
}

- (void) requestNewGameList
{
    [super requestNewGameList];
    
    if(_MODEL_.deviceLocation && _MODEL_PLAYER_)   
    {
        [_SERVICES_ fetchPopularGameListForTime:time];
        [self showLoadingIndicator];
    }
}

- (void) refreshViewFromModel
{
	gameList = _MODEL_GAMES_.popularGames;
	[gameTable reloadData];
    
    [self removeLoadingIndicator];
}

- (void) controlChanged
{
    time = self.timeControl.selectedSegmentIndex;
    [self requestNewGameList];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0) return 40;
    else return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row-1 inSection:0]];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [super tableView:tableView numberOfRowsInSection:section]+1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0)
    {
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SegCell"];
        if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SegCell"];
        [cell addSubview:self.timeControl];
        return cell;
    }
    else if([gameList count] > 0)
    {
        GamePickerCell *cell = (GamePickerCell *)[super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row-1 inSection:0]];
        Game *gameForCell = [gameList objectAtIndex:(indexPath.row-1)];
        [cell setCustomLabelText:[NSString stringWithFormat:@"%d %@",gameForCell.player_count, NSLocalizedString(@"PlayersKey", @"")]];
        return cell;
    }
    else
        return (GamePickerCell *)[super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row-1 inSection:0]];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row-1 inSection:0]];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
