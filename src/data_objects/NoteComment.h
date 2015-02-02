//
//  NoteComment.h
//  ARIS
//
//  Created by Phil Dougherty on 1/23/14.
//
//

#import <Foundation/Foundation.h>

@interface NoteComment : NSObject
{
    long note_comment_id;
    long note_id;
    long user_id;
    NSString *name;
    NSString *desc;
    NSDate *created; 
}

@property(nonatomic, assign) long note_comment_id;
@property(nonatomic, assign) long note_id;
@property(nonatomic, assign) long user_id;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *desc;
@property(nonatomic, retain) NSDate *created; 

- (id) initWithDictionary:(NSDictionary *)dict;

@end
