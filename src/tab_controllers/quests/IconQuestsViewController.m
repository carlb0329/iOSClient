//
//  IconQuestsViewController.m
//  ARIS
//
//  Created by Jacob Hanshaw on 9/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IconQuestsViewController.h"
#import "ARISAppDelegate.h"
#import "AppModel.h"
#import "Quest.h"
#import "IconQuestsButton.h"
#import "QuestDetailsViewController.h"

#import "AppServices.h"
#import "Media.h"
#import "AsyncMediaImageView.h"
#import "WebPage.h"
#import "WebPageViewController.h"

#define ICONWIDTH 76
#define ICONHEIGHT 90
#define ICONSPERROW 3
#define TEXTLABELHEIGHT 10
#define TEXTLABELPADDING 7

static NSString * const OPTION_CELL = @"quest";
static int const ACTIVE_SECTION = 0;
static int const COMPLETED_SECTION = 1;

NSString *const kIconQuestsHtmlTemplate =
@"<html>"
@"<head>"
@"	<title>Aris</title>"
@"	<style type='text/css'><!--"
@"	body {"
@"		background-color: #E9E9E9;"
@"		color: #000000;"
@"		font-family: Helvetia, Sans-Serif;"
@"		margin: 0;"
@"	}"
@"	h1 {"
@"		color: #000000;"
@"		font-size: 18px;"
@"		font-style: bold;"
@"		font-family: Helvetia, Sans-Serif;"
@"		margin: 0 0 10 0;"
@"	}"
@"	--></style>"
@"</head>"
@"<body></div><div style=\"position:relative; top:0px; background-color:#DDDDDD; border-style:ridge; border-width:3px; border-radius:11px; border-color:#888888;padding:15px;\"><h1>%@</h1>%@</div></body>"
@"</html>";

@interface IconQuestsViewController() <UICollectionViewDataSource,UICollectionViewDelegate>
{
    UIScrollView *questIconScrollView;
    UICollectionView *questIconCollectionView;
    UICollectionViewFlowLayout *questIconCollectionViewLayout;
    
    int newItemsSinceLastView;
    int itemsPerColumnWithoutScrolling;
    int initialHeight;
    
    NSArray *sortedQuests;
    
    id<QuestsViewControllerDelegate> __unsafe_unretained delegate;
}

@property(nonatomic) NSMutableArray *quests;

- (id)initWithDelegate:(id<QuestsViewControllerDelegate>)d;
- (void)refresh;
- (void)showLoadingIndicator;
- (void)removeLoadingIndicator;
- (void)refreshViewFromModel;

@end

@implementation IconQuestsViewController

@synthesize quests;

- (id)initWithDelegate:(id<QuestsViewControllerDelegate>)d
{
    self = [super initWithNibName:@"IconQuestsViewController" bundle:nil];
    if (self)
    {
        self.tabID = @"QUESTS";
        self.title = NSLocalizedString(@"QuestViewTitleKey",@"");
        [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"todoTabBarSelected"] withFinishedUnselectedImage:[UIImage imageNamed:@"todoTabBarUnselected"]];
        
        sortedQuests = [[NSArray alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeLoadingIndicator) name:@"ConnectionLost"                object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeLoadingIndicator) name:@"ReceivedQuestList"             object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewFromModel)   name:@"NewlyActiveQuestsAvailable"    object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewFromModel)   name:@"NewlyCompletedQuestsAvailable" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incrementBadge)         name:@"NewlyChangedQuestsGameNotificationSent"    object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    questIconCollectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    questIconCollectionViewLayout.itemSize = CGSizeMake(ICONWIDTH, ICONHEIGHT);
    questIconCollectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    questIconCollectionViewLayout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);
    questIconCollectionViewLayout.minimumLineSpacing = 30.0;
    questIconCollectionViewLayout.minimumInteritemSpacing = 10.0;
        
    questIconCollectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:questIconCollectionViewLayout];
    questIconCollectionView.dataSource = self;
    questIconCollectionView.delegate = self;
    [questIconCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.view addSubview:questIconCollectionView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (![AppModel sharedAppModel].player || [AppModel sharedAppModel].currentGame.gameId==0) return;
    
	newItemsSinceLastView = 0;
    
	[[AppServices sharedAppServices] updateServerQuestsViewed];
	
	[self refresh];
    [self refreshViewFromModel];
}

- (void)refresh
{
	[[AppServices sharedAppServices] fetchPlayerQuestList];
	[self showLoadingIndicator];
}

-(void)showLoadingIndicator
{
	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	[[self navigationItem] setRightBarButtonItem:barButton];
	[activityIndicator startAnimating];
}

-(void)removeLoadingIndicator
{
	[[self navigationItem] setRightBarButtonItem:nil];
}

-(void)refreshViewFromModel
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortNum" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedActiveQuests    = [[AppModel sharedAppModel].currentGame.questsModel.currentActiveQuests    sortedArrayUsingDescriptors:sortDescriptors];
    NSArray *sortedCompletedQuests = [[AppModel sharedAppModel].currentGame.questsModel.currentCompletedQuests sortedArrayUsingDescriptors:sortDescriptors];
    
    sortedQuests = [sortedActiveQuests arrayByAddingObjectsFromArray:sortedCompletedQuests];
    
    [questIconCollectionView reloadData];
}

- (void) questSelected: (id)sender
{
    UIButton *button = (UIButton*)sender;
    
    Quest *questSelected = [sortedQuests objectAtIndex:button.tag];
    
    QuestDetailsViewController *questDetailsViewController =[[QuestDetailsViewController alloc] initWithQuest: questSelected];
    questDetailsViewController.navigationItem.title = questSelected.name;
    [[self navigationController] pushViewController:questDetailsViewController animated:YES];
}

#pragma mark CollectionView DataSource and Delegate Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.quests count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    for (UIView *view in [cell.contentView subviews])
        [view removeFromSuperview];
    
    int questNumber = indexPath.item;
    
    Quest *currentQuest = [sortedQuests objectAtIndex:questNumber];
    
    UIImage *iconImage;
    if(currentQuest.iconMediaId != 0)
    {
        Media *iconMedia = [[AppModel sharedAppModel] mediaForMediaId: currentQuest.iconMediaId ofType:@"PHOTO"];
        iconImage = [UIImage imageWithData:iconMedia.image];
    }
    else iconImage = [UIImage imageNamed:@"item.png"];
    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.height - TEXTLABELHEIGHT - (2*TEXTLABELPADDING))];
    [iconImageView setImage:iconImage];
    iconImageView.layer.cornerRadius = 11.0f;
    [cell.contentView addSubview:iconImageView];
    
    CGRect textFrame = CGRectMake(0, (cell.contentView.frame.size.height-TEXTLABELHEIGHT - TEXTLABELPADDING), cell.contentView.frame.size.width, TEXTLABELHEIGHT);
    UILabel *iconTitleLabel = [[UILabel alloc] initWithFrame:textFrame];
    iconTitleLabel.text = currentQuest.name;
    iconTitleLabel.textColor = [UIColor whiteColor];
    iconTitleLabel.backgroundColor = [UIColor clearColor];
    iconTitleLabel.textAlignment = NSTextAlignmentCenter;
    iconTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    iconTitleLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
    [cell.contentView addSubview:iconTitleLabel];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *activeQuests = [self.quests objectAtIndex:ACTIVE_SECTION];
    NSArray *completedQuests = [self.quests objectAtIndex:COMPLETED_SECTION];
    
    int questNumber = indexPath.item;
    
    Quest *questSelected;
    if(questNumber >= [activeQuests count])
    {
        questNumber -= [activeQuests count];
        questSelected = [completedQuests objectAtIndex:questNumber];
    }
    else questSelected = [activeQuests objectAtIndex:questNumber];
    QuestDetailsViewController *questDetailsViewController =[[QuestDetailsViewController alloc] initWithQuest: questSelected];
    questDetailsViewController.navigationItem.title = questSelected.name;
    [[self navigationController] pushViewController:questDetailsViewController animated:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
