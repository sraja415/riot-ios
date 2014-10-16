/*
 Copyright 2014 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "RecentsViewController.h"
#import "RoomViewController.h"

#import "AppDelegate.h"
#import "MatrixHandler.h"

@interface RecentsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *roomTitle;
@property (weak, nonatomic) IBOutlet UILabel *lastEventDescription;
@property (weak, nonatomic) IBOutlet UILabel *recentDate;

@end

@implementation RecentsTableViewCell
@end

@interface RecentsViewController () {
    NSArray  *recents;
}
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation RecentsViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createNewRoom:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    // Add activity indicator
    [self.view addSubview:_activityIndicator];
    _activityIndicator.center = CGPointMake(self.view.center.x, 100);
    [self.view bringSubviewToFront:_activityIndicator];
    
    // Initialisation
    recents = nil;
}

- (void)dealloc {
    recents = nil;
    _preSelectedRoomId = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Refresh recents table
    [self configureView];
    [[MatrixHandler sharedHandler] addObserver:self forKeyPath:@"isInitialSyncDone" options:0 context:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Leave potential editing mode
    [self setEditing:NO];
    
    _preSelectedRoomId = nil;
    [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"isInitialSyncDone"];
}

#pragma mark -

- (void)setPreSelectedRoomId:(NSString *)roomId {
    _preSelectedRoomId = nil;

    if (roomId) {
        // Check whether recents update is in progress
        if ([_activityIndicator isAnimating]) {
            // Postpone room details display
            _preSelectedRoomId = roomId;
            return;
        }
        
        // Look for the room index in recents list
        NSIndexPath *indexPath = nil;
        for (NSUInteger index = 0; index < recents.count; index++) {
            MXEvent *mxEvent = [recents objectAtIndex:index];
            if ([roomId isEqualToString:mxEvent.room_id]) {
                indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                break;
            }
        }
        
        if (indexPath) {
            // Open details view
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            UITableViewCell *recentCell = [self.tableView cellForRowAtIndexPath:indexPath];
            [self performSegueWithIdentifier:@"showDetail" sender:recentCell];
        } else {
            NSLog(@"We are not able to open room (%@) because it does not appear in recents yet", roomId);
            // Postpone room details display. We run activity indicator until recents are updated
            _preSelectedRoomId = roomId;
            // Start activity indicator
            [_activityIndicator startAnimating];
        }
    }
}

#pragma mark - Internals

- (void)configureView {
    [_activityIndicator startAnimating];
    
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    if ([mxHandler isInitialSyncDone] || [mxHandler isLogged] == NO) {
        // Update recents
        if (mxHandler.mxData) {
            recents = mxHandler.mxData.recents;
        } else {
            recents = nil;
        }
        
        // Reload table
        [self.tableView reloadData];
        [_activityIndicator stopAnimating];
        
        // Check whether a room is preselected
        if (_preSelectedRoomId) {
            self.preSelectedRoomId = _preSelectedRoomId;
        }
    }
}

- (void)createNewRoom:(id)sender {
    [[AppDelegate theDelegate].masterTabBarController showRoomCreationForm];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"isInitialSyncDone" isEqualToString:keyPath])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureView];
        });
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        MXEvent *mxEvent = recents[indexPath.row];
        
        UIViewController *controller;
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            controller = [[segue destinationViewController] topViewController];
        } else {
            controller = [segue destinationViewController];
        }
        
        if ([controller isKindOfClass:[RoomViewController class]]) {
            [(RoomViewController *)controller setRoomId:mxEvent.room_id];
        }
        
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return recents.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RecentsTableViewCell *cell = (RecentsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"RecentsCell" forIndexPath:indexPath];

    MXEvent *mxEvent = recents[indexPath.row];
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    MXRoomData *mxRoomData = [mxHandler.mxData getRoomData:mxEvent.room_id];
    
    cell.roomTitle.text = [mxRoomData displayname];
    cell.lastEventDescription.text = [mxHandler displayTextFor:mxEvent inDetailMode:YES];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:mxEvent.ts/1000];
    NSString *dateFormat =  @"MMM dd HH:mm";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:dateFormat];
    cell.recentDate.text = [dateFormatter stringFromDate:date];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // TODO enable the following code when "leave" will be available in SDK
//        // Leave the selected room
//        MXEvent *mxEvent = recents[indexPath.row];
//        [[MatrixHandler sharedHandler].mxSession leave:mxEvent.room_id success:^{
//            // Refresh table display
//            [recents removeObjectAtIndex:indexPath.row];
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//        } failure:^(NSError *error) {
//            NSLog(@"Failed to leave room (%@) failed: %@", mxEvent.room_id, error);
//            //Alert user
//            [[AppDelegate theDelegate] showErrorAsAlert:error];
//        }];
    }
}

@end