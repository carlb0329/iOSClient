//
//  ARISMediaLoader.m
//  ARIS
//
//  Created by Phil Dougherty on 11/21/13.
//
//

#import "ARISMediaLoader.h"
#import "AppServices.h"
#import "AppModel.h"
#import "MediaModel.h"
#import "ARISDelegateHandle.h"

@interface ARISMediaLoader()
{
  NSMutableDictionary *dataConnections;
  NSMutableArray *metaConnections;
}
@end

@implementation ARISMediaLoader

- (id) init
{
  if(self = [super init])
  {
    dataConnections = [[NSMutableDictionary alloc] initWithCapacity:10];
    metaConnections = [[NSMutableArray      alloc] initWithCapacity:10];
    _ARIS_NOTIF_LISTEN_(@"MODEL_MEDIA_AVAILABLE",self,@selector(retryLoadingAllMedia),nil);
  }
  return self;
}

- (void) loadMedia:(Media *)m delegateHandle:(ARISDelegateHandle *)dh
{
  if(!m) return;

  MediaResult *mr = [[MediaResult alloc] init];
  mr.media = m;
  if (dh) {
    mr.delegateHandles = @[dh];
  } else {
    mr.delegateHandles = @[];
  }

  [self loadMediaFromMR:mr];
}

- (void) loadMediaFromMR:(MediaResult *)mr
{
       if(mr.media.thumb)      { [self mediaLoadedForMR:mr]; }
  else if(mr.media.data)       { [self deriveThumbForMR:mr]; }
  else if(mr.media.localURL)   { mr.media.data = [NSData dataWithContentsOfURL:mr.media.localURL]; [self loadMediaFromMR:mr]; }
  else if(mr.media.remoteURL)
  {
    NSURLRequest *request = [NSURLRequest requestWithURL:mr.media.remoteURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    if(mr.connection) [mr.connection cancel];
    mr.data = [[NSMutableData alloc] initWithCapacity:2048];
    mr.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [dataConnections setObject:mr forKey:mr.connection.description];
  }
  else if(!mr.media.remoteURL) { [self loadMetaDataForMR:mr]; }
}

- (void) loadMetaDataForMR:(MediaResult *)mr
{
  for(long i = 0; i < metaConnections.count; i++)
  {
    MediaResult *existingMR = metaConnections[i];
    if(existingMR.media.media_id == mr.media.media_id)
    {
      // If mediaresult already exists, merge delegates to notify rather than 1.Throwing new request out (need to keep delegate) or 2.Redundantly requesting
      existingMR.delegateHandles = [existingMR.delegateHandles arrayByAddingObjectsFromArray:mr.delegateHandles];
      return;
    }
  }
  [metaConnections addObject:mr];
  [_SERVICES_ fetchMediaById:mr.media.media_id];
}

- (void) retryLoadingAllMedia
{
  //do the ol' switcheroo so we wont get into an infinite loop of adding, removing, readding, etc...
  NSMutableArray *oldMetaConnections = metaConnections;
  metaConnections = [[NSMutableArray alloc] initWithCapacity:10];

  MediaResult *mr;
  while(oldMetaConnections.count > 0)
  {
    mr = [oldMetaConnections objectAtIndex:0];
    mr.media = [_MODEL_MEDIA_ mediaForId:mr.media.media_id];
    [oldMetaConnections removeObjectAtIndex:0];
    [self loadMediaFromMR:mr];
  }
}

- (void) connection:(NSURLConnection *)c didReceiveData:(NSData *)d
{
  MediaResult *mr; if(!(mr = [dataConnections objectForKey:c.description])) return;
  [mr.data appendData:d];
}

- (void) connectionDidFinishLoading:(NSURLConnection*)c
{
  MediaResult *mr; if(!(mr = [dataConnections objectForKey:c.description])) return;
  [dataConnections removeObjectForKey:c.description];
  mr.media.data = mr.data;
  [mr cancelConnection];//MUST do this only AFTER data has already been transferred to media

  //short names to cope with obj-c verbosity
  NSString *g = [NSString stringWithFormat:@"%ld",mr.media.game_id]; //game_id as string
  NSString *f = [[[[mr.media.remoteURL absoluteString] componentsSeparatedByString:@"/"] lastObject] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //filename

  NSString *newFolder = _ARIS_LOCAL_URL_FROM_PARTIAL_PATH_(g);
  if(![[NSFileManager defaultManager] fileExistsAtPath:newFolder isDirectory:nil])
    [[NSFileManager defaultManager] createDirectoryAtPath:newFolder withIntermediateDirectories:YES attributes:nil error:nil];
  [mr.media setPartialLocalURL:[NSString stringWithFormat:@"%@/%@",g,f]];
  [mr.media.data writeToURL:mr.media.localURL options:nil error:nil];
  [mr.media.localURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];

  [_MODEL_MEDIA_ saveAlteredMedia:mr.media];//not as elegant as I'd like...
  _ARIS_LOG_(@"Media loader  : Media id:%ld loaded:%@",mr.media.media_id,mr.media.remoteURL);
  [self loadMediaFromMR:mr];
}

- (void) mediaLoadedForMR:(MediaResult *)mr
{
  //This is so ugly. See comments in ARISDelegateHandle.h for reasoning
  for(long i = 0; i < mr.delegateHandles.count; i++)
  {
    ARISDelegateHandle *dh = mr.delegateHandles[i];
    if(dh.delegate && [[dh.delegate class] conformsToProtocol:@protocol(ARISMediaLoaderDelegate)])
      [dh.delegate mediaLoaded:mr.media];
  }
}

- (void) deriveThumbForMR:(MediaResult *)mr
{
    NSData *data = mr.media.data;
    UIImage *i;

    NSString *type = [mr.media type];
    if([type isEqualToString:@"IMAGE"])
    {
        i = [UIImage imageWithData:data];
    }
    else if([type isEqualToString:@"VIDEO"])
    {
        AVAsset *asset = [AVAsset assetWithURL:mr.media.localURL];
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
        CMTime t = [asset duration];
        t.value = 1000;
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:t actualTime:NULL error:NULL];
        i = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    }
    else if([type isEqualToString:@"AUDIO"])
    {
        i = [UIImage imageNamed:@"microphone"]; //hack
    }
    if(!i) i = [UIImage imageNamed:@"logo_icon"];

    int s = 128;
    int w = s;
    int h = s;
    if(i.size.width > i.size.height)
        h = i.size.height * (s/i.size.width);
    else
        w = i.size.width * (s/i.size.height);
    UIGraphicsBeginImageContext(CGSizeMake(w,h));
    [i drawInRect:CGRectMake(0,0,w,h)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    mr.media.thumb = UIImagePNGRepresentation(newImage);
    [self loadMediaFromMR:mr];
}

- (void) mediaResultThumbFound:(NSNotification*)notification
{
    MediaResult *mr = notification.userInfo[@"media_result"];
    [self loadMediaFromMR:mr];
}

- (void) dealloc
{
  NSArray *objects = [dataConnections allValues];
  for(long i = 0; i < objects.count; i++)
    [[objects objectAtIndex:i] cancelConnection];
  _ARIS_NOTIF_IGNORE_ALL_(self);
}

@end

@implementation MediaResult
@synthesize media;
@synthesize data;
@synthesize url;
@synthesize connection;
@synthesize start;
@synthesize time;
@synthesize delegateHandles;

- (void) cancelConnection
{
  [self.connection cancel];
  self.connection = nil;
  self.data = nil;
}

- (void) dealloc
{
  [self cancelConnection];
}

@end
