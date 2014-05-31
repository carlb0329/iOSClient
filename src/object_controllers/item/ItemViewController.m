//
//  ItemViewController.m
//  ARIS
//
//  Created by Phil Dougherty on 10/17/13.
//
//

#import "ItemViewController.h"

#import "ItemActionViewController.h"
#import "InventoryTagViewController.h"

#import "Item.h"
#import "Instance.h"
#import "ARISWebView.h"
#import "ARISMediaView.h"
#import "ARISCollapseView.h"
#import "AppModel.h"
#import "Game.h"
#import "ItemsModel.h"
#import "MediaModel.h"

#import "ARISTemplate.h"

@interface ItemViewController()  <ARISMediaViewDelegate, ARISWebViewDelegate, ARISCollapseViewDelegate, StateControllerProtocol, ItemActionViewControllerDelegate, UITextViewDelegate>
{
    //Labels as buttons (easier formatting)
    UILabel *dropBtn;
    UILabel *destroyBtn; 
    UILabel *pickupBtn;  
    UIView *line; //separator between buttons/etc...
    
    ARISWebView *webView;
    ARISCollapseView *collapseView;
    ARISWebView *descriptionView;
    UIScrollView *scrollView;
    ARISMediaView *imageView;
    
    UIActivityIndicatorView *activityIndicator;
    
    id<GameObjectViewControllerDelegate,StateControllerProtocol> __unsafe_unretained delegate;
    id<ItemViewControllerSource> source; 
}
@end

@implementation ItemViewController

@synthesize instance;
@synthesize item;

- (id) initWithInstance:(Instance *)i delegate:(id<GameObjectViewControllerDelegate,StateControllerProtocol>)d source:(id<ItemViewControllerSource>)s
{
    if(self = [super init])
    {
        instance = i;
        item = (Item *)instance.object;
        delegate = d;
        source = s;
    }
    return self;
}

//Helper to cleanly/consistently create bottom buttons
- (UILabel *) createItemButtonWithText:(NSString *)t selector:(SEL)s
{
    UILabel *btn = [[UILabel alloc] init];
    btn.userInteractionEnabled = YES;
    btn.textAlignment = NSTextAlignmentCenter;
    btn.text = t;
    btn.backgroundColor = [ARISTemplate ARISColorTextBackdrop];
    btn.textColor       = [ARISTemplate ARISColorText];
    [btn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:s]];
    [btn addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(passPanToDescription:)]];
    
    return btn;
}

- (void) loadView
{
    [super loadView];
    self.view.backgroundColor = [ARISTemplate ARISColorContentBackdrop];
    
    int numButtons = 0;
    if([(NSObject *)source isKindOfClass:[InventoryTagViewController class]] && item.destroyable)      { destroyBtn = [self createItemButtonWithText:NSLocalizedString(@"ItemDeleteKey", @"") selector:@selector(destroyButtonTouched)]; numButtons++; }
    if([(NSObject *)source isKindOfClass:[InventoryTagViewController class]] && item.droppable)         { dropBtn    = [self createItemButtonWithText:NSLocalizedString(@"ItemDropKey", @"")    selector:@selector(dropButtonTouched)];    numButtons++; }
    //if([(NSObject *)source isKindOfClass:[Location class]] && (instance.qty > 0 || instance.infinite_qty)) { pickupBtn  = [self createItemButtonWithText:NSLocalizedString(@"ItemPickupKey", @"") selector:@selector(pickupButtonTouched)];  numButtons++; }
    
    line = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-44, self.view.bounds.size.width, 1)];
    line.backgroundColor = [UIColor ARISColorLightGray];
    
    //Web Item
    //if(item.itemType == ItemTypeWebPage && item.url && (![item.url isEqualToString: @"0"]) &&(![item.url isEqualToString:@""]))
    if(false)
    {
        webView = [[ARISWebView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height) delegate:self];
        if(numButtons > 0) webView.scrollView.contentInset = UIEdgeInsetsMake(64,0,54,0);
        else               webView.scrollView.contentInset = UIEdgeInsetsMake(64,0,10,0);
        
        webView.hidden                          = YES;
        webView.scalesPageToFit                 = YES;
        webView.allowsInlineMediaPlayback       = YES;
        webView.mediaPlaybackRequiresUserAction = NO;
        
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:item.url]] withAppendation:[NSString stringWithFormat:@"item_id=%d",item.item_id]];
    }
    //Normal Item
    else
    {
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        if(numButtons > 0) scrollView.contentInset = UIEdgeInsetsMake(64,0,54,0);
        else               scrollView.contentInset = UIEdgeInsetsMake(64,0,10,0);
        scrollView.clipsToBounds    = NO;
        scrollView.maximumZoomScale = 20;
        scrollView.minimumZoomScale = 1;
        scrollView.delegate = self;
        
        Media *media;
        if(item.media_id) media = [_MODEL_MEDIA_ mediaForId:item.media_id];
        else                  media = [_MODEL_MEDIA_ mediaForId:item.icon_media_id];
        
        if(media)
        {
            imageView = [[ARISMediaView alloc] initWithFrame:CGRectMake(0,0,scrollView.frame.size.width,scrollView.frame.size.height-64) delegate:self];
            [imageView setMedia:media];
            [imageView setDisplayMode:ARISMediaDisplayModeAspectFit];
            [scrollView addSubview:imageView];
            [scrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(passTapToDescription:)]];
        }
    }
    
    if(![item.desc isEqualToString:@""])
    {
        descriptionView = [[ARISWebView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,10) delegate:self];
        descriptionView.userInteractionEnabled   = NO;
        descriptionView.scrollView.scrollEnabled = NO;
        descriptionView.scrollView.bounces       = NO;
        descriptionView.opaque                   = NO;
        descriptionView.backgroundColor = [UIColor clearColor];
        [descriptionView loadHTMLString:[NSString stringWithFormat:[ARISTemplate ARISHtmlTemplate], item.desc] baseURL:nil];
        collapseView = [[ARISCollapseView alloc] initWithContentView:descriptionView frame:CGRectMake(0,self.view.bounds.size.height-(10+((numButtons > 0)*44)),self.view.frame.size.width,10) open:YES showHandle:YES draggable:YES tappable:YES delegate:self];
    }
    
    //nil subviews should be ignored
    [self.view addSubview:webView];
    [self.view addSubview:scrollView];
    [self.view addSubview:collapseView];
    [self updateViewButtons]; 
    [self.view addSubview:line];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateViewButtons];
    [self refreshTitle]; 
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, 19, 19);
    [backButton setImage:[UIImage imageNamed:@"arrowBack"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    backButton.accessibilityLabel = @"Back Button";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
}

- (void) refreshTitle
{
    if(instance.qty < 2 || instance.infinite_qty) self.title = item.name; 
    else self.title = [NSString stringWithFormat:@"%@ x%d",item.name,instance.qty];
}

- (void) updateViewButtons
{
    if(destroyBtn) [destroyBtn removeFromSuperview];
    if(dropBtn)    [dropBtn    removeFromSuperview]; 
    if(pickupBtn)  [pickupBtn  removeFromSuperview]; 
    if(line)       [line       removeFromSuperview]; 
    
    if(instance.qty < 1 && !instance.infinite_qty)
    {
        destroyBtn = nil;
        dropBtn    = nil; 
        pickupBtn  = nil; 
    }
    
    int numButtons = (destroyBtn != nil) + (dropBtn != nil) + (pickupBtn != nil);
    int numPlacedButtons = 0;
    if(destroyBtn) { destroyBtn.frame = CGRectMake(numPlacedButtons*(self.view.bounds.size.width/numButtons),self.view.bounds.size.height-44,self.view.bounds.size.width/numButtons,44); numPlacedButtons++; }
    if(dropBtn)    { dropBtn.frame    = CGRectMake(numPlacedButtons*(self.view.bounds.size.width/numButtons),self.view.bounds.size.height-44,self.view.bounds.size.width/numButtons,44); numPlacedButtons++; }
    if(pickupBtn)  { pickupBtn.frame  = CGRectMake(numPlacedButtons*(self.view.bounds.size.width/numButtons),self.view.bounds.size.height-44,self.view.bounds.size.width/numButtons,44); numPlacedButtons++; }
    
    [self.view addSubview:destroyBtn];
    [self.view addSubview:dropBtn];
    [self.view addSubview:pickupBtn];
    if(numButtons > 0)[self.view addSubview:line];
    
    if(collapseView) [collapseView setFrame:CGRectMake(0,self.view.bounds.size.height-((descriptionView.frame.size.height+10)+((numButtons > 0) ? 44 : 0)),self.view.frame.size.width,descriptionView.frame.size.height+10)]; 
}

- (void) passTapToDescription:(UITapGestureRecognizer *)r
{
    [collapseView handleTapped:r];
}

- (void) passPanToDescription:(UIPanGestureRecognizer *)g
{
    [collapseView handlePanned:g];
}

- (void) dropButtonTouched
{	
    int amtCanDrop = [_MODEL_ITEMS_ qtyOwnedForItem:item.item_id];
    
    if(amtCanDrop > 1)
    {
        ItemActionViewController *itemActionVC = [[ItemActionViewController alloc] initWithPrompt:NSLocalizedString(@"ItemDropKey", @"") positive:NO maxqty:instance.qty delegate:self]; 
        
        [[self navigationController] pushViewController:itemActionVC animated:YES];
    }
    else if(amtCanDrop > 0)
        [self dropItemQty:1]; 
}

- (void) dropItemQty:(int)q
{
    if([_MODEL_ITEMS_ takeItemFromPlayer:item.item_id qtyToRemove:q] == 0) [self dismissSelf];
    else
    {
        [self updateViewButtons]; 
        [self refreshTitle];
    }
}

- (void) destroyButtonTouched
{
    int amtCanDestroy = [_MODEL_ITEMS_ qtyOwnedForItem:item.item_id];
    
    if(amtCanDestroy > 1)
    {
        ItemActionViewController *itemActionVC = [[ItemActionViewController alloc] initWithPrompt:NSLocalizedString(@"ItemDeleteKey", @"") positive:NO maxqty:instance.qty delegate:self]; 
        
        [[self navigationController] pushViewController:itemActionVC animated:YES];
    }
    else if(amtCanDestroy > 0)
        [self destroyItemQty:1];
}

- (void) destroyItemQty:(int)q
{
    if([_MODEL_ITEMS_ takeItemFromPlayer:item.item_id qtyToRemove:q] == 0) [self dismissSelf];
    else
    {
        [self updateViewButtons];  
        [self refreshTitle];   
    }
}

- (void) pickupButtonTouched
{
    int amtMoreCanHold = [_MODEL_ITEMS_ qtyAllowedToGiveForItem:item.item_id];
    int allowablePickupAmt = instance.infinite_qty ? 99999999 : instance.qty;
    if(amtMoreCanHold < allowablePickupAmt) allowablePickupAmt = amtMoreCanHold;  
    
    if(allowablePickupAmt > 1 && !instance.infinite_qty)
    {
        ItemActionViewController *itemActionVC = [[ItemActionViewController alloc] initWithPrompt:NSLocalizedString(@"ItemPickupKey", @"") positive:YES maxqty:amtMoreCanHold delegate:self];
        [[self navigationController] pushViewController:itemActionVC animated:YES];
    }
    else if(allowablePickupAmt > 0)
        [self pickupItemQty:1];
}

- (void) pickupItemQty:(int)q
{
    [_MODEL_GAME_.itemsModel giveItemToPlayer:item.item_id qtyToAdd:q];
    instance.qty -= q;
    [self updateViewButtons];   
    [self refreshTitle];   
}

- (void) amtChosen:(int)amt positive:(BOOL)p
{
    [[self navigationController] popToViewController:self animated:YES]; 
    if(p)
        [self pickupItemQty:amt];
    else
        [self destroyItemQty:amt];
}

- (void) movieFinishedCallback:(NSNotification*) aNotification
{
    //[self dismissMoviePlayerViewControllerAnimated];
}

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView 
{
    return imageView;
}

- (void) ARISWebViewRequestsDismissal:(ARISWebView *)awv
{
    [delegate gameObjectViewControllerRequestsDismissal:self];
}

- (void) ARISWebViewRequestsRefresh:(ARISWebView *)awv
{
    //ignore
}

- (BOOL) displayGameObject:(id)g fromSource:(id)s
{
    return [delegate displayGameObject:g fromSource:self];
}

- (void) displayTab:(NSString *)t
{
    [delegate displayTab:t];
}

- (void) displayScannerWithPrompt:(NSString *)p
{
    [delegate displayScannerWithPrompt:p];
}

- (BOOL) ARISWebView:(ARISWebView *)wv shouldStartLoadWithRequest:(NSURLRequest *)r navigationType:(UIWebViewNavigationType)nt
{
    if(wv == webView) return YES;
    
    //else, this is a link from the description- so launch externally
    WebPage *tempWebPage = [[WebPage alloc] init];
    tempWebPage.url = [[r URL] absoluteString];
    [delegate displayGameObject:tempWebPage fromSource:self];
    return NO;
}

- (void) ARISWebViewDidFinishLoad:(ARISWebView *)wv
{
    if(wv == webView)
    {
        webView.hidden = NO;
        [self dismissWaitingIndicator];
    }
    if(wv == descriptionView)
    {
        float newHeight = [[descriptionView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] floatValue];
        [collapseView setContentFrameHeight:newHeight];
        
        if(newHeight+10 < self.view.bounds.size.height-44-64)
            [collapseView setFrameHeight:newHeight+10];
        else
            [collapseView setFrameHeight:self.view.bounds.size.height-44-64];
        
        [collapseView open];
    }
}

- (void) ARISWebViewDidStartLoad:(ARISWebView *)wv
{
    if(wv == webView) [self showWaitingIndicator];
}

- (void) showWaitingIndicator
{
    if(!activityIndicator)
        activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:scrollView.bounds];
    [activityIndicator startAnimating];
    [scrollView addSubview:activityIndicator];
}

- (void) dismissWaitingIndicator
{
    [activityIndicator stopAnimating];
    [activityIndicator removeFromSuperview];
}

- (void) dismissSelf
{
    //int locationId = ([(NSObject *)source isKindOfClass:[Location class]]) ? ((Location *)source).locationId : 0;
    [delegate gameObjectViewControllerRequestsDismissal:self];
}

- (void) backButtonTouched
{
    [self dismissSelf];
}

- (void) dealloc
{
    _ARIS_NOTIF_IGNORE_ALL_(self);                
}

@end
