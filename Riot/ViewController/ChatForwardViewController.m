//
//  ChatForwardViewController.m
//
//  Created by mac1 on 04/04/17.
//  Copyright © 2017 matrix.org. All rights reserved.
//

#import "ChatForwardViewController.h"
#import "HomeViewController.h"
#import "RecentsViewController.h"
#import "RecentCellData.h"
#import "RecentsDataSource.h"
#import "RoomDataSource.h"
#import "AppDelegate.h"
#import "RoomBubbleCellData.h"
#import "MasterTabBarController.h"

#import "HomeMessagesSearchViewController.h"



@interface ChatForwardViewController ()
{
    RecentsViewController *recentsViewController;
    RecentsDataSource *_recentsDataSource;
    NSMutableArray *selectedRoomIds;
    NSIndexPath *selectedIndexPath;
    UIView *contentView;
    MasterTabBarController *homeCurrChat;
    UIAlertController *currentAlert;
    MXKRoomDataSource *roomDataSource;
    MXRoomSummary *summary;
    MXRoom *room;
    MXSession *mainSession;
}
@end

@implementation ChatForwardViewController

- (void)viewDidLoad {
    selectedRoomIds = [[NSMutableArray alloc]init];
    recentsViewController = [RecentsViewController recentListViewController];
    recentsViewController.delegate = self;
    _listContentView.backgroundColor = [UIColor whiteColor];
    _sendButtonActivityIndicatorView.hidden = YES;
    [self initializeDataSources];
    [self didChangeSelecteditems];
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)initializeDataSources
{
    
    mainSession = self.mainSession;
    
    //temp_Changes_ChatListing
    if (!mainSession) {
        NSArray *mxSessions = appDelegate().mxSessions;
        mainSession = [mxSessions firstObject];
    }
    NSMutableArray *allviewControllers = [self.navigationController.viewControllers mutableCopy];
    for (UIViewController*current in allviewControllers) {
        if ([current isKindOfClass:[MasterTabBarController class]]) {
            homeCurrChat = (MasterTabBarController*)current;
            _recentsDataSource = homeCurrChat.getRecentDataSource;
            break;
        }
    }
    if(_recentsDataSource==nil){
        _recentsDataSource = appDelegate().recentDataSource;
    }
    
    NSLog(@"_recentsDataSource %@",_recentsDataSource.conversationCellDataArray);
    
    if (mainSession && _recentsDataSource && recentsViewController)
    {
        [recentsViewController displayList:_recentsDataSource fromChatForwardViewController:self];
        contentView = recentsViewController.view;
        contentView.tag = 906161;
        [_listContentView addSubview:contentView];
        [self addConstraintstoView:contentView];
        
    }else{
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,21)];
        
        //set text of label
        label.text = @"Chat list is Empty";
        
        //set color
        label.backgroundColor = [UIColor darkGrayColor];
        label.textColor = [UIColor whiteColor];
        
        //properties
        label.textAlignment = NSTextAlignmentCenter;
        [label sizeToFit];
        
        //add the components to the view
        [self.view addSubview: label];
        label.center = self.view.center;
        [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    }
}


#pragma mark - MXKRecentListViewControllerDelegate

//- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)matrixSession
//{
//    if (!matrixSession) {
//        NSArray* accounts = [[MXKAccountManager sharedManager] activeAccounts];
//        for (MXKAccount *theAccount in accounts)
//        {
//            if (theAccount.mxSession)
//            {
//                matrixSession = theAccount.mxSession;
//                break;
//            }
//        }
//    }
//    for (UIView *subview in self.view.subviews) {
//        if (subview.tag == 906161) {
//            [subview removeFromSuperview];
//            break;
//        }
//    }
//    [recentsViewController destroy];
//    [self selectThisRoomID:roomId];
//}

//

//- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(MXKRoomDataSource *)roomDataSource inMatrixSession:(MXSession *)mxSession
//
//{
////    RoomBubbleCellData *cellData = (RoomBubbleCellData*)[self.dataSource cellDataAtIndex:indexPath.row];
////    _selectedEvent = cellData.bubbleComponents[0].event;
//
//    NSLog(@"did select ---> %@", selectedRoomIds);
//    
//    if (!mxSession) {
//        NSArray* accounts = [[MXKAccountManager sharedManager] activeAccounts];
//        for (MXKAccount *theAccount in accounts)
//        {
//            if (theAccount.mxSession)
//            {
//                mxSession = theAccount.mxSession;
//                break;
//            }
//        }
//    }
//    for (UIView *subview in _listContentView.subviews) {
//        if (subview.tag == 906161) {
//            [subview removeFromSuperview];
//            break;
//        }
//    }
//    [recentsViewController destroy];
//    [self selectThisRoomID:roomDataSource];
//
//}

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoomDataSource:(MXRoomSummary *)roomDataSource2 withSection:(NSUInteger)sec inMatrixSession:(MXSession *)mxSession{
    if (!mxSession) {
        NSArray* accounts = [[MXKAccountManager sharedManager] activeAccounts];
        for (MXKAccount *theAccount in accounts)
        {
            if (theAccount.mxSession)
            {
                mxSession = theAccount.mxSession;
                break;
            }
        }
    }
    for (UIView *subview in _listContentView.subviews) {
        if (subview.tag == 906161) {
            [subview removeFromSuperview];
            break;
        }
    }
    [recentsViewController destroy];
    [self selectThisRoomID:roomDataSource2 withSection:sec];
    
}

//- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)mxSession { 
//    
//}



- (void)selectThisRoomID:(MXRoomSummary*)roomDataSource1 withSection:(NSUInteger)section{
    recentsViewController = [RecentsViewController recentListViewController];
    recentsViewController.delegate = self;
    RecentsDataSource *currentRecentData = _recentsDataSource;
    NSMutableArray *currentRecentDataArray;
    if (section ==0) {
       currentRecentDataArray = [_recentsDataSource.peopleCellDataArray mutableCopy];
    }
    else if (section ==1) {
       currentRecentDataArray = [_recentsDataSource.conversationCellDataArray mutableCopy];
    }
    else if (section ==2) {
        currentRecentDataArray = [_recentsDataSource.lowPriorityCellDataArray mutableCopy];
    }

    
    if (![selectedRoomIds containsObject:roomDataSource1]){
        [selectedRoomIds addObject:roomDataSource1];
        for (int i = 0 ; i <= currentRecentDataArray.count ; i++)
        {
            RecentCellData *currentCellData = currentRecentDataArray[i];
            if ([currentCellData.roomSummary.roomId isEqual:roomDataSource1.roomId]) {
                NSUInteger indexOfobject = [currentRecentDataArray indexOfObject:currentCellData];
                selectedIndexPath = [NSIndexPath indexPathForRow:indexOfobject inSection:section];
                currentCellData.isSelectedRoom = YES;
                [currentRecentDataArray removeObjectAtIndex:indexOfobject];
                [currentRecentDataArray insertObject:currentCellData atIndex:indexOfobject];
                break;
            }
        }
        
    }
    else{
        [selectedRoomIds removeObject:roomDataSource1];
        for (int i = 0 ; i <= currentRecentDataArray.count ; i++)
        {
            RecentCellData *currentCellData = currentRecentDataArray[i];
            if ([currentCellData.roomSummary.roomId isEqual:roomDataSource1.roomId]) {
                NSUInteger indexOfobject = [currentRecentDataArray indexOfObject:currentCellData];
                selectedIndexPath = [NSIndexPath indexPathForRow:indexOfobject inSection:section];
                currentCellData.isSelectedRoom = NO;
                [currentRecentDataArray removeObjectAtIndex:indexOfobject];
                [currentRecentDataArray insertObject:currentCellData atIndex:indexOfobject];
                break;
            }
        }
    }
    
    if (section ==0) {
        currentRecentData.peopleCellDataArray = currentRecentDataArray;
    }
    else if (section ==1) {
        currentRecentData.conversationCellDataArray = currentRecentDataArray;
    }
    else if (section ==2) {
        currentRecentData.lowPriorityCellDataArray = currentRecentDataArray;
    }

    [recentsViewController displayList:currentRecentData fromChatForwardViewController:self];
    contentView = recentsViewController.view;
    contentView.tag = 906161;
    [_listContentView addSubview:contentView];
    [self addConstraintstoView:contentView];
//    [recentsViewController scrollToIndexPath:selectedIndexPath];
    [self didChangeSelecteditems];
    //NSLog(@"selectedRoomIds %@",selectedRoomIds);
    
}
- (void)addConstraintstoView:(UIView*)subView{
    
    subView.translatesAutoresizingMaskIntoConstraints = NO;
    
    //Trailing
    NSLayoutConstraint *trailing =[NSLayoutConstraint
                                   constraintWithItem:subView
                                   attribute:NSLayoutAttributeTrailing
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:_listContentView
                                   attribute:NSLayoutAttributeTrailing
                                   multiplier:1.0f
                                   constant:0.f];
    
    //Leading
    
    NSLayoutConstraint *leading = [NSLayoutConstraint
                                   constraintWithItem:subView
                                   attribute:NSLayoutAttributeLeading
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:_listContentView
                                   attribute:NSLayoutAttributeLeading
                                   multiplier:1.0f
                                   constant:0.f];
    
    //Bottom
    NSLayoutConstraint *bottom =[NSLayoutConstraint
                                 constraintWithItem:subView
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                 toItem:_listContentView
                                 attribute:NSLayoutAttributeBottom
                                 multiplier:1.0f
                                 constant:0.f];
    
    //Height to be fixed for SubView same as AdHeight
    NSLayoutConstraint *top = [NSLayoutConstraint
                               constraintWithItem:subView
                               attribute:NSLayoutAttributeTop
                               relatedBy:NSLayoutRelationEqual
                               toItem:_listContentView
                               attribute:NSLayoutAttributeTop
                               multiplier:1.0f
                               constant:0.f];
    
    
    [_listContentView addConstraint:trailing];
    [_listContentView addConstraint:bottom];
    [_listContentView addConstraint:leading];
    [_listContentView addConstraint:top];
}
-(void)didChangeSelecteditems{
    _selectedMemebersCount.text = selectedRoomIds.count > 0 ? [NSString stringWithFormat:@"%lu Chats Selected",(unsigned long)selectedRoomIds.count]
    : [NSString stringWithFormat:@"No Chats Selected"];
    BOOL enable = selectedRoomIds.count > 0 ? YES : NO;
    _sendButton.enabled = enable;
}
/*
 #pragma mark - Navigation
 
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)onButtonPressed:(id)sender {
    NSLog(@"selectedRoomIds %@",selectedRoomIds);
    [self showActivityIndicator:YES];
        //     [self.navigationController popViewControllerAnimated:YES];
    room = [[MXRoom alloc]init];
    for (int i=0; i<[selectedRoomIds count]; i++) {
        NSLog(@"[%@] - Forward Event - %@",NSStringFromClass([self class]),self.selectedEvent);
        [room sendRoomSummary:selectedRoomIds[i] withSession:mainSession withDictionary:_selectedEvent.content success:^(NSString *eventId) {
            if (i==[selectedRoomIds count]-1) {
                NSLog(@"[%@]- Success - %@",NSStringFromClass([self class]),eventId);
                UIAlertView *alert_view = [[UIAlertView alloc]initWithTitle:@"Messaage" message:@"Message successfully forwarded to selected chat room." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert_view show];
                [self.navigationController popViewControllerAnimated:YES];
            }
        } failure:^(NSError *error) {
            NSLog(@"[%@]- Failure - %@",NSStringFromClass([self class]),error);}];
    }
//    for (MXRoomSummary *currentRoomDataSource in selectedRoomIds) {
    
        //        __strong __typeof(weakSelf)strongSelf = weakSelf;
        //        [strongSelf cancelEventSelection];
        //       self.selectedEvent = selectedComponent.event;
    
        //        _selectedEvent=@"textSample";
//        [roomDataSource sendThisEvent:_selectedEvent success:^(NSString *eventId) {
//            NSLog(@"[%@]- Success - %@",NSStringFromClass([self class]),eventId);
//            if ([currentRoomDataSource isEqual:[selectedRoomIds lastObject]]) {
//                [self showActivityIndicator:NO];
//            }
//        } failure:^(NSError *error) {
//            NSLog(@"[%@]- Failure - %@",NSStringFromClass([self class]),error);
//            if ([currentRoomDataSource isEqual:[selectedRoomIds lastObject]]) {
//                [self showActivityIndicator:NO];
//            }
//        }];
//    }
    
}

-(void)showActivityIndicator:(BOOL)start{
    [_sendButtonActivityIndicatorView setHidden:!start];
    [_sendButton setHidden:start];
    
    if (start)
        [_sendButtonActivityIndicatorView startAnimating];
    else{
        [_sendButtonActivityIndicatorView stopAnimating];
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Message!"
                                      message:@"Message successfully forwarded to selected chat rooms."
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"Ok"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 //                             __strong __typeof(weakSelf)strongSelf = weakSelf;
                                 [self.navigationController popViewControllerAnimated:YES];
                                 
                             }];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
        
        [alert addAction:ok];
        [alert addAction:cancel];
        
        
        //        currentAlert = [[MXKAlert alloc] initWithTitle:kAppName message:@"Message successfully forwarded to selected chat rooms." style:MXKAlertStyleAlert];
        //
        //        [currentAlert addActionWithTitle:@"Ok" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        //            alert = nil;
        //            __strong __typeof(weakSelf)strongSelf = weakSelf;
        //            [[strongSelf navigationController]popViewControllerAnimated:YES];
        //        }];
        //        currentAlert.sourceView = self.view;
        //        [currentAlert showInViewController:self];
    }
}
@end
