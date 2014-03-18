//
//  NoteTagEditorViewController.m
//  ARIS
//
//  Created by Phil Dougherty on 11/8/13.
//
//

#import "NoteTagEditorViewController.h"
#import "NoteTagPredictionViewController.h"
#import "ARISTemplate.h"
#import "NoteTag.h"
#import "NoteTagView.h"
#import "AppModel.h"
#import "NotesModel.h"
#import "Game.h"

@interface NoteTagEditorViewController() <UITextFieldDelegate, NoteTagViewDelegate, NoteTagPredictionViewControllerDelegate>
{
    NSArray *tags;
    
    UIScrollView *existingTagsScrollView;
    UILabel *plus;
    UIImageView *grad;
    
    UITextField *tagInputField;
    NoteTagPredictionViewController *tagPredictionViewController;
    
    BOOL editable;
    
    BOOL appleStopTryingToDoStuffWithoutMyPermission;
    
    id<NoteTagEditorViewControllerDelegate> __unsafe_unretained delegate;
}
@end

@implementation NoteTagEditorViewController

- (id) initWithTags:(NSArray *)t editable:(BOOL)e delegate:(id<NoteTagEditorViewControllerDelegate>)d
{
    if(self = [super init])
    {
        tags = t;
        editable = e;
        delegate = d;
        appleStopTryingToDoStuffWithoutMyPermission = NO;
    }
    return self;
}

- (void) loadView
{
    [super loadView];
    existingTagsScrollView  = [[UIScrollView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width-30,30)];
    
    plus = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width-25,5,[@" + " sizeWithFont:[ARISTemplate ARISBodyFont]].width,20)];
    plus.font = [ARISTemplate ARISBodyFont];
    plus.textColor = [UIColor whiteColor];
    plus.backgroundColor = [UIColor ARISColorLightBlue];
    plus.text = @" + ";
    plus.layer.cornerRadius = 8;
    plus.layer.masksToBounds = YES;
    plus.userInteractionEnabled = YES;
    [plus addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addTagButtonTouched)]];
    
    grad = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"left_white_gradient"]];
    grad.frame = CGRectMake(self.view.frame.size.width-55,0,30,30);
    
    tagInputField = [[UITextField alloc] init];
    tagInputField.delegate = self;
    tagInputField.font = [ARISTemplate ARISTitleFont]; 
    tagInputField.placeholder = @" choose a tag";
    tagInputField.returnKeyType = UIReturnKeyDone; 
    
    tagPredictionViewController = [[NoteTagPredictionViewController alloc] 
                                   initWithGameNoteTags:[AppModel sharedAppModel].currentGame.notesModel.gameNoteTags
                                   playerNoteTags:[AppModel sharedAppModel].currentGame.notesModel.playerNoteTags 
                                   delegate:self];  
    
    [self refreshViewFromTags];  
}

- (void) viewWillLayoutSubviews
{
    if(!appleStopTryingToDoStuffWithoutMyPermission)
    {
        plus.frame = CGRectMake(self.view.frame.size.width-25, 5, plus.frame.size.width, plus.frame.size.height); 
        grad.frame = CGRectMake(self.view.frame.size.width-55,0,30,30); 
        existingTagsScrollView.frame = CGRectMake(0,0,self.view.frame.size.width-30,30);  
        tagInputField.frame = CGRectMake(10, 0, self.view.frame.size.width-20,30);
        tagPredictionViewController.view.frame = CGRectMake(0,30,self.view.frame.size.width,100);  
    }
    appleStopTryingToDoStuffWithoutMyPermission = NO; 
}

- (void) setTags:(NSArray *)t
{
    tags = t;
    [self refreshViewFromTags];
}

- (void) refreshViewFromTags
{
    while([[existingTagsScrollView subviews] count] != 0) [[[existingTagsScrollView subviews] objectAtIndex:0] removeFromSuperview];
    
    UIView *tv;
    int x = 10;
    for(int i = 0; i < [tags count]; i++)
    {
        tv = [[NoteTagView alloc] initWithNoteTag:[tags objectAtIndex:i] editable:editable delegate:self];
        tv.frame = CGRectMake(x,5,tv.frame.size.width,tv.frame.size.height);
        x += tv.frame.size.width+10;
        [existingTagsScrollView addSubview:tv];
    }
    existingTagsScrollView.contentSize = CGSizeMake(x+10,30);
    
    if([tags count] == 0 && editable)
    {
        [self.view addSubview:tagInputField]; 
        [existingTagsScrollView removeFromSuperview];         
    }
    else
    {
        [self.view addSubview:existingTagsScrollView];          
        [tagInputField removeFromSuperview];  
    }
    
    if(editable) [self.view addSubview:plus]; 
    
    [self.view addSubview:grad];  
}

- (void) addTagButtonTouched
{
    [self beginEditing];
}

- (void) beginEditing
{
    [self.view addSubview:tagInputField];
    [existingTagsScrollView removeFromSuperview];          
    
    [self.view addSubview:tagPredictionViewController.view]; 
    [tagPredictionViewController queryString:@""];
    
    if((NSObject *)delegate && [((NSObject *)delegate) respondsToSelector:@selector(noteTagEditorWillBeginEditing)])
       [delegate noteTagEditorWillBeginEditing];  
    
    [tagInputField becomeFirstResponder]; 
    [self expandView];   
}

- (void) stopEditing
{
    [tagInputField resignFirstResponder]; 
    tagInputField.text = @"";
    [tagPredictionViewController.view removeFromSuperview];
    [self retractView];  
    [self refreshViewFromTags];
}

- (void) expandView
{
    self.view.frame = CGRectMake(0,self.view.frame.origin.y,self.view.frame.size.width,self.view.frame.size.height+100);
    
    tagPredictionViewController.view.frame = CGRectMake(0,30,self.view.frame.size.width,100);
    
    appleStopTryingToDoStuffWithoutMyPermission = YES;
}

- (void) retractView
{
    self.view.frame = CGRectMake(0,self.view.frame.origin.y,self.view.frame.size.width,self.view.frame.size.height-100);
    
    existingTagsScrollView.frame = CGRectMake(existingTagsScrollView.frame.origin.x+existingTagsScrollView.frame.size.width,existingTagsScrollView.frame.origin.y-100,existingTagsScrollView.frame.size.width,existingTagsScrollView.frame.size.height);
    
    appleStopTryingToDoStuffWithoutMyPermission = YES; 
}

// totally convoluted function- essentially "textFieldDidChange"
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    //if backspace with already highlighted text... I know... weird
    if(range.location != 0 && range.length > 0 && string.length == 0) { range.location--; range.length++; }
    
    NSString *updatedInput = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSDictionary *matchedTags = [tagPredictionViewController queryString:updatedInput];
    
    NSArray *gnt = [matchedTags objectForKey:@"game"];
    NSArray *pnt = [matchedTags objectForKey:@"player"]; 
    NoteTag *nt;
    //If there's only one matched tag...
    if((gnt.count == 1 && pnt.count == 0 && (nt = [gnt objectAtIndex:0])) ||
       (gnt.count == 0 && pnt.count == 1 && (nt = [pnt objectAtIndex:0])))
    {
        //If curent input matches said tag FROM BEGINNING of string...
        if([nt.text rangeOfString:[NSString stringWithFormat:@"^%@.*",updatedInput] options:NSRegularExpressionSearch|NSCaseInsensitiveSearch].location != NSNotFound)  
        {
            //Set input to prediction with deltas highlighted for quick deletion
            NSString *hijackedInput = nt.text;
            tagInputField.text = hijackedInput; 
            UITextPosition *start = [tagInputField positionFromPosition:tagInputField.beginningOfDocument offset:updatedInput.length];
            UITextPosition *end = [tagInputField positionFromPosition:start offset:hijackedInput.length-updatedInput.length];
            [tagInputField setSelectedTextRange:[tagInputField textRangeFromPosition:start toPosition:end]];
            return NO;
        }
    }
    
    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    NSArray *allValidTags = [[AppModel sharedAppModel].currentGame.notesModel.gameNoteTags arrayByAddingObjectsFromArray:[AppModel sharedAppModel].currentGame.notesModel.playerNoteTags];
    BOOL tagExists = NO;
    for(int i = 0; i < allValidTags.count; i++)
    {
        if([[((NoteTag *)[allValidTags objectAtIndex:i]).text lowercaseString] isEqualToString:[tagInputField.text lowercaseString]])
        {
            tagExists = YES;
            [delegate noteTagEditorAddedTag:[allValidTags objectAtIndex:i]];
            break;
        }
    }
    if(!tagExists && ![tagInputField.text isEqualToString:@""])
    {
        NoteTag *newNoteTag = [[NoteTag alloc] init];
        newNoteTag.text = tagInputField.text;
        newNoteTag.playerCreated = YES;
        [delegate noteTagEditorCreatedTag:newNoteTag]; 
    }
    [self stopEditing];
    return YES;
}

- (void) noteTagDeleteSelected:(NoteTag *)nt
{
    [delegate noteTagEditorDeletedTag:nt];
}

- (void) existingTagChosen:(NoteTag *)nt
{
    [self stopEditing];
    if((NSObject *)delegate && [((NSObject *)delegate) respondsToSelector:@selector(noteTagEditorAddedTag:)]) 
        [delegate noteTagEditorAddedTag:nt];
}

@end
