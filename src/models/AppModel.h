//
//  AppModel.h
//  ARIS
//
//  Created by Ben Longoria on 2/17/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreData/CoreData.h>
#import "Game.h"
#import "Location.h"
#import "Item.h"
#import "Node.h"
#import "Npc.h"
#import "Media.h"
#import "WebPage.h"
#import "Panoramic.h"
#import "MediaCache.h"
#import "UploadMan.h"
#import "Overlay.h"
#import "Player.h"

@interface AppModel : NSObject <UIAccelerometerDelegate>
{
	NSUserDefaults *defaults;
	NSURL *serverURL;
    BOOL showGamesInDevelopment;
    BOOL showPlayerOnMap;
    
    BOOL disableLeaveGame;
    int skipGameDetails;
    
	Game *currentGame;
    Player *player;

    CMMotionManager *motionManager;

    int fallbackGameId;
    
    NSMutableArray *oneGameGameList;
	NSMutableArray *nearbyGameList;
	NSMutableArray *anywhereGameList;
    NSMutableArray *popularGameList;
    NSMutableArray *recentGamelist;
    NSMutableArray *searchGameList;
    
	NSMutableArray *nearbyLocationsList;

	NSMutableDictionary *gameMediaList;
	NSMutableDictionary *gameItemList;
	NSMutableDictionary *gameNodeList;
	NSMutableDictionary *gameNpcList;
    NSMutableDictionary *gameWebPageList;
    NSMutableDictionary *gamePanoramicList;
    NSMutableArray *gameTagList;
    NSMutableArray *overlayList;

    BOOL overlayIsVisible;

    //Accelerometer Data
    float averageAccelerometerReadingX;
    float averageAccelerometerReadingY;
    float averageAccelerometerReadingZ;
    
    BOOL hidePlayers;
    
    //CORE Data
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    UploadMan *uploadManager;
    MediaCache *mediaCache;
}

@property (nonatomic, strong) NSURL *serverURL;
@property (readwrite) BOOL showGamesInDevelopment;
@property (readwrite) BOOL showPlayerOnMap;
@property (readwrite) BOOL disableLeaveGame;
@property (readwrite) int  skipGameDetails;

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (readwrite) BOOL hidePlayers;

@property (readwrite) BOOL overlayIsVisible;

@property (readwrite) float averageAccelerometerReadingX;
@property (readwrite) float averageAccelerometerReadingY;
@property (readwrite) float averageAccelerometerReadingZ;

@property (readwrite) int fallbackGameId;//Used only to recover from crashes

@property (nonatomic, strong) Player *player;
@property (nonatomic, strong) Game *currentGame;

@property (nonatomic, strong) NSURL *fileToDeleteURL;
@property (nonatomic, strong) NSMutableArray *oneGameGameList;
@property (nonatomic, strong) NSMutableArray *nearbyGameList;
@property (nonatomic, strong) NSMutableArray *anywhereGameList;
@property (nonatomic, strong) NSMutableArray *searchGameList;
@property (nonatomic, strong) NSMutableArray *popularGameList;
@property (nonatomic, strong) NSMutableArray *recentGameList;	

@property (nonatomic, strong) NSMutableArray *nearbyLocationsList;	

@property (nonatomic, strong) NSMutableArray *gameTagList;
@property (nonatomic, strong) NSMutableArray *overlayList;
@property (nonatomic, strong) NSMutableDictionary *gameMediaList;
@property (nonatomic, strong) NSMutableDictionary *gameItemList;
@property (nonatomic, strong) NSMutableDictionary *gameNodeList;
@property (nonatomic, strong) NSMutableDictionary *gameNpcList;
@property (nonatomic, strong) NSMutableDictionary *gameWebPageList;
@property (nonatomic, strong) NSMutableDictionary *gamePanoramicList;

// CORE Data
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) UploadMan *uploadManager;
@property (nonatomic, strong) MediaCache *mediaCache;

+ (AppModel *) sharedAppModel;

- (void) resetAllGameLists;
- (void) resetAllPlayerLists;

- (void) commitPlayerLogin:(Player *)p;
- (void) setPlayerLocation:(CLLocation *)newLocation;

- (void) initUserDefaults;
- (void) saveUserDefaults;
- (void) loadUserDefaults;
- (void) saveCOREData;

- (Media *) mediaForMediaId:(int)mId ofType:(NSString *)type;
- (Item *) itemForItemId:(int)mId;
- (Node *) nodeForNodeId:(int)mId;
- (Npc *) npcForNpcId:(int)mId;
- (WebPage *) webPageForWebPageId:(int)mId;
- (Panoramic *) panoramicForPanoramicId:(int)mId;

@end
