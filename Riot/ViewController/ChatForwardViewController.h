//
//  ChatForwardViewController.h
//
//  Created by mac1 on 04/04/17.
//  Copyright © 2017 matrix.org. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "RecentsViewController.h"


@interface ChatForwardViewController :MXKViewController<MXKRecentListViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView *listContentView;
@property (strong, nonatomic) IBOutlet UIView *listFooterView;
@property (strong, nonatomic) IBOutlet UILabel *selectedMemebersCount;
- (IBAction)onButtonPressed:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *sendButtonActivityIndicatorView;

@property (strong,nonatomic) MXEvent *selectedEvent;
@end
