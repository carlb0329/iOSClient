//
//  DialogsModel.m
//  ARIS
//
//  Created by Phil Dougherty on 2/13/13.
//
//

// RULE OF THUMB:
// Merge any new object data rather than replace. Becuase 'everything is pointers' in obj c, 
// we can't know what data we're invalidating by replacing a ptr

#import "DialogsModel.h"
#import "AppServices.h"

@interface DialogsModel()
{
    NSMutableDictionary *dialogs;
}

@end

@implementation DialogsModel

- (id) init
{
    if(self = [super init])
    {
        [self clearGameData];
        _ARIS_NOTIF_LISTEN_(@"SERVICES_DIALOGS_RECEIVED",self,@selector(dialogsReceived:),nil);
    }
    return self;
}

- (void) clearGameData
{
    dialogs = [[NSMutableDictionary alloc] init];
}

- (void) dialogsReceived:(NSNotification *)notif
{
    [self updateDialogs:[notif.userInfo objectForKey:@"dialogs"]];
}

- (void) updateDialogs:(NSArray *)newDialogs
{
    Dialog *newDialog;
    NSNumber *newDialogId;
    for(int i = 0; i < newDialogs.count; i++)
    {
      newDialog = [newDialogs objectAtIndex:i];
      newDialogId = [NSNumber numberWithInt:newDialog.dialog_id];
      if(![dialogs objectForKey:newDialogId]) [dialogs setObject:newDialog forKey:newDialogId];
    }
}

- (void) requestDialogs
{
    [_SERVICES_ fetchDialogs];
}

- (Dialog *) dialogForId:(int)dialog_id
{
  return [dialogs objectForKey:[NSNumber numberWithInt:dialog_id]];
}

- (void) dealloc
{
    _ARIS_NOTIF_IGNORE_ALL_(self);  
}

@end
