//
//  PanoramicViewController.m
//  ARIS
//
//  Created by Brian Thiel on 6/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PanoramicViewController.h"
#import "AppModel.h"
#import "AppServices.h"
#import "NodeOption.h"
#import "ARISAppDelegate.h"
#import "Media.h"
#import "AsyncImageView.h"

@implementation PanoramicViewController
@synthesize panoramic,plView,viewImageContainer,connection,data,media,imagePickerController,overlayMedia,didLoadOverlay,finishedAlignment;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
	if(viewImageContainer)
		[viewImageContainer release];
	if(plView)
		[plView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    self.imagePickerController = [[UIImagePickerController alloc] init];
    
    //Create a close button
	self.navigationItem.leftBarButtonItem = 
	[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BackButtonKey",@"")
									 style: UIBarButtonItemStyleBordered
									target:self 
									action:@selector(backButtonTouchAction:)];	
    
    
    plView.isDeviceOrientationEnabled = NO;
	plView.isAccelerometerEnabled = NO;
	plView.isScrollingEnabled = YES;
	plView.isInertiaEnabled = YES;
    plView.isGyroEnabled = YES;
    
	plView.type = PLViewTypeSpherical;
    
    

	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType];
        self.imagePickerController.allowsEditing = NO;
        self.imagePickerController.showsCameraControls = NO;

        

	}
	else {

	}
	
	self.imagePickerController.delegate = self;
	

    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)backButtonTouchAction: (id) sender{
	
	//Notify the server this item was displayed
	[[AppServices sharedAppServices] updateServerPanoramicViewed:self.panoramic.panoramicId];
	
	
	//[self.view removeFromSuperview];
	[self dismissModalViewControllerAnimated:NO];
    
}

-(void) viewDidAppear:(BOOL)animated {
   
if(!finishedAlignment && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
{
     Media *aMedia = [[AppModel sharedAppModel] mediaForMediaId: self.panoramic.alignMediaId];
    [self loadImageFromMedia:aMedia];
}
    else
    {
        Media *aMedia = [[AppModel sharedAppModel] mediaForMediaId: self.panoramic.mediaId];
        [self loadImageFromMedia:aMedia];
        finishedAlignment = YES;
        didLoadOverlay = YES;
    }
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)loadImage
{

    
    if(self.media.image && !didLoadOverlay && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        
        UIImageView *overlay = [[UIImageView alloc] initWithImage:self.media.image];
        overlay.frame = self.plView.frame;
        overlay.contentMode = UIViewContentModeScaleAspectFill;            
        overlay.alpha = .5;
        self.imagePickerController.cameraOverlayView = overlay;
        UIButton *touchScreen = [UIButton buttonWithType:UIButtonTypeCustom];
        touchScreen.frame = self.plView.frame;
        [self.imagePickerController.view addSubview:touchScreen];
        [touchScreen addTarget:self action:@selector(touchScreen) forControlEvents:UIControlEventTouchUpInside];
        [self presentModalViewController:self.imagePickerController animated:NO];
        self.media.image = nil;
        
        didLoadOverlay = YES;

    }
    if(didLoadOverlay && finishedAlignment && self.media.image){
        [plView stopAnimation];
        [plView removeAllTextures];
    	[plView addTextureAndRelease:[PLTexture textureWithImage:self.media.image]];
        [plView reset];
        [plView drawView];
        Media *oMedia = [[AppModel sharedAppModel] mediaForMediaId: self.panoramic.alignMediaId];
        [self loadImageFromMedia:oMedia];
        finishedAlignment = NO;
           }

}
-(IBAction) touchScreen {
    [self dismissModalViewControllerAnimated:YES];
    didLoadOverlay = NO;
    finishedAlignment = YES;
}
- (void)loadImageFromMedia:(Media *) aMedia {
	self.media = aMedia;
	//check if the media already as the image, if so, just grab it

    if (!aMedia.url) {
        return;
    }
	
	//set up indicators
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
		
	if (connection!=nil) { [connection release]; }
    NSURLRequest* request = [NSURLRequest requestWithURL:[[NSURL alloc]initWithString:aMedia.url]
											 cachePolicy:NSURLRequestUseProtocolCachePolicy
										 timeoutInterval:60.0];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
    if (self.data==nil) {
		self.data = [[NSMutableData alloc] initWithCapacity:2048];
    }
    [self.data appendData:incrementalData];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection {
	//end the UI indicator
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	//throw out the connection
    [self.connection release];
    self.connection=nil;
	
	//turn the data into an image
	UIImage* image = [UIImage imageWithData:data];
	
	//throw out the data
	[self.data release];
    self.data=nil;
	
	//Save the image in the media
	self.media.image = image;
	[self.media.image retain];
    [self loadImage];
	
	}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	CGRect frame = plView.frame;
	switch (interfaceOrientation) 
	{
		case UIInterfaceOrientationPortrait:
		case UIInterfaceOrientationPortraitUpsideDown:
			viewImageContainer.hidden = NO;
			frame.size.width = 320;
			frame.size.height = 416;
			plView.frame = frame;
			break;
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			viewImageContainer.hidden = YES;
			frame.size.width = 480;
			frame.size.height = 320;
			plView.frame = frame;
			break;
	}
    // Return YES for supported orientations
    return YES;

}


@end