//
//  GameDetailsViewController.m
//  ARIS
//
//  Created by David J Gagnon on 4/18/10.
//  Copyright 2010 University of Wisconsin - Madison. All rights reserved.
//

#import "GameDetailsViewController.h"
#import "AppModel.h"
#import "MediaModel.h"
#import "GameCommentsViewController.h"
#import "Game.h"

#import "ARISAlertHandler.h"
#import "ARISTemplate.h"
#import "ARISWebView.h"
#import "ARISMediaView.h"
#import "ARISStarView.h"

#import "StateControllerProtocol.h"

#import <QuartzCore/QuartzCore.h>

@interface GameDetailsViewController() <ARISMediaViewDelegate, ARISWebViewDelegate, StateControllerProtocol, GameCommentsViewControllerDelegate, UIWebViewDelegate>
{
    ARISMediaView *mediaView;
    ARISWebView *descriptionView;
    UIButton *startButton;
    UIButton *resetButton;
    UIButton *rateButton;
    
   	Game *game; 
    id<GameDetailsViewControllerDelegate> __unsafe_unretained delegate;
}

@end

@implementation GameDetailsViewController

- (id) initWithGame:(Game *)g delegate:(id<GameDetailsViewControllerDelegate>)d
{
    if(self = [super init])
    {
        delegate = d;
        game = g;
    }
    return self;
}

- (void) loadView
{
    [super loadView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    mediaView = [[ARISMediaView alloc] initWithDelegate:self];
    [mediaView setDisplayMode:ARISMediaDisplayModeAspectFit];
    
    descriptionView = [[ARISWebView alloc] initWithDelegate:self];
    
    startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [startButton setTitle:NSLocalizedString(@"GameDetailsNewGameKey", @"") forState:UIControlStateNormal]; 
    [startButton setBackgroundColor:[UIColor ARISColorLightBlue]];
    [startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    startButton.titleLabel.font = [ARISTemplate ARISButtonFont];
    
    resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [resetButton setTitle:NSLocalizedString(@"GameDetailsResetKey", nil) forState:UIControlStateNormal];
    [resetButton setBackgroundColor:[UIColor ARISColorRed]];
    [resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    resetButton.titleLabel.font = [ARISTemplate ARISButtonFont];
    
    rateButton  = [UIButton buttonWithType:UIButtonTypeCustom];
    [rateButton setBackgroundColor:[UIColor ARISColorOffWhite]];
    
    ARISStarView *starView = [[ARISStarView alloc] initWithFrame:CGRectMake(10,10,100,20)];
    starView.rating = game.rating;
    
    UILabel *reviewsTextView = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width-110,12,100,15)];
    reviewsTextView.font = [ARISTemplate ARISButtonFont];
    reviewsTextView.text = [NSString stringWithFormat:@"%d %@",game.comments.count, NSLocalizedString(@"ReviewsKey", @"")];
    
    [rateButton addSubview:starView];
    [rateButton addSubview:reviewsTextView];
    
    [startButton addTarget:self action:@selector(startButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    [resetButton addTarget:self action:@selector(resetButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    [rateButton  addTarget:self action:@selector(rateButtonTouched)  forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0,0,19,19);
    [backButton setImage:[UIImage imageNamed:@"arrowBack"] forState:UIControlStateNormal];
    backButton.accessibilityLabel = @"Back Button";
    [backButton addTarget:self action:@selector(backButtonTouched) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    [self.view addSubview:mediaView];
    [self.view addSubview:startButton]; 
    [self.view addSubview:resetButton];
    [self.view addSubview:rateButton];
    [self.view addSubview:descriptionView];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [mediaView setFrame:CGRectMake(0,0+64,self.view.bounds.size.width,200)];
    rateButton.frame = CGRectMake(0, startButton.frame.origin.y-40, self.view.bounds.size.width, 40);
    descriptionView.frame = CGRectMake(0,200+64,self.view.bounds.size.width,rateButton.frame.origin.y-(200+64));
    if(game.has_been_played)
    {
        [self.view addSubview:resetButton];
        startButton.frame = CGRectMake((self.view.bounds.size.width/2),self.view.bounds.size.height-40,(self.view.bounds.size.width/2),40);
        resetButton.frame = CGRectMake(0,self.view.bounds.size.height-40,(self.view.bounds.size.width/2),40);
    }
    else
    {
        [resetButton removeFromSuperview];
        startButton.frame = CGRectMake(0,self.view.bounds.size.height-40,self.view.bounds.size.width,40);
    }
}

- (void) refreshFromGame
{
    self.title = game.name; 
    
    if(![game.desc isEqualToString:@""])
        [descriptionView loadHTMLString:[NSString stringWithFormat:[ARISTemplate ARISHtmlTemplate], game.desc] baseURL:nil];
    
    if(game.media_id) [mediaView setMedia:[_MODEL_MEDIA_ mediaForId:game.media_id]];
    else              [mediaView setImage:[UIImage imageNamed:@"DefaultGameSplash"]]; 
    
    if(game.has_been_played) [startButton setTitle:NSLocalizedString(@"GameDetailsResumeKey", @"")  forState:UIControlStateNormal];
    else                     [startButton setTitle:NSLocalizedString(@"GameDetailsNewGameKey", @"") forState:UIControlStateNormal]; 
    
    [self viewWillLayoutSubviews]; //let that take care of adding/removing reset
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated]; 
    
    [self refreshFromGame]; 
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *requestURL = [request URL];

    if(([[requestURL scheme] isEqualToString:@"http"] ||
        [[requestURL scheme] isEqualToString:@"https"]) &&
       (navigationType == UIWebViewNavigationTypeLinkClicked))
        return ![[UIApplication sharedApplication] openURL:requestURL];

    return YES;
} 

- (void) startButtonTouched
{
    game.has_been_played = YES;
    [_MODEL_ chooseGame:game];
}

- (void) resetButtonTouched
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GameDetailsResetTitleKey", nil) message:NSLocalizedString(@"GameDetailsResetMessageKey", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CancelKey", @"") otherButtonTitles:NSLocalizedString(@"GameDetailsResetKey", @""), nil];
    [alert show];	 
}

- (void) rateButtonTouched
{
    GameCommentsViewController *commentsVC = [[GameCommentsViewController alloc] initWithGame:game delegate:self];
    [self.navigationController pushViewController:commentsVC animated:YES]; 
}

- (void) backButtonTouched
{
    [delegate gameDetailsCanceled:game];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        [_MODEL_ resetGame];
        startButton.enabled =NO;
        game.has_been_played = NO;
        [self refreshFromGame];
    }
}

- (void) gameReset
{
    startButton.enabled = YES;
}

//implement statecontrol stuff for webpage, but ignore any requests
- (void) displayTab:(NSString *)t {}
- (BOOL) displayGameObject:(id)g fromSource:(id)s {return NO;}
- (void) displayScannerWithPrompt:(NSString *)p {}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
