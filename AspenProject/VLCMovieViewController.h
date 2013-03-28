//
//  VLCDetailViewController.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VLCMovieViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) MLFile *mediaItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
