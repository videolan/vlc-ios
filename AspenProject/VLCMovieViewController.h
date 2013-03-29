//
//  VLCDetailViewController.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VLCMovieViewController : UIViewController <UISplitViewControllerDelegate>
{
    VLCMediaPlayer *_mediaPlayer;
    UIView *_movieView;
    UIView *_tabBarView;
    UIBarButtonItem * _backButton;
    UISlider *_positionSlider;
    UIBarButtonItem *_timeDisplay;
}

@property (nonatomic, retain) IBOutlet UIView * movieView;
@property (nonatomic, retain) IBOutlet UIView * tapBarView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem * backButton;
@property (nonatomic, retain) IBOutlet UISlider * positionSlider;
@property (nonatomic, retain) IBOutlet UIBarButtonItem * timeDisplay;

@property (strong, nonatomic) MLFile *mediaItem;

- (IBAction)closePlayback:(id)sender;
- (IBAction)positionSliderAction:(id)sender;

@end
