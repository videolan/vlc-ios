//
//  VLCDetailViewController.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VLCMovieViewController : UIViewController <UISplitViewControllerDelegate, VLCMediaPlayerDelegate, UIActionSheetDelegate>
{
    VLCMediaPlayer *_mediaPlayer;
    UIView *_movieView;
    UIView *_tabBarView;
    UIBarButtonItem * _backButton;
    UISlider *_positionSlider;
    UIBarButtonItem *_timeDisplay;
    UIButton *_playPauseButton;
    UIButton *_bwdButton;
    UIButton *_fwdButton;
    UIButton *_subtitleSwitcherButton;
    UIButton *_audioSwitcherButton;
    UIView *_controllerPanel;

    BOOL _controlsHidden;

    UIActionSheet *_subtitleActionSheet;
    UIActionSheet *_audiotrackActionSheet;
}

@property (nonatomic, retain) IBOutlet UIView * movieView;
@property (nonatomic, retain) IBOutlet UIView * tapBarView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem * backButton;
@property (nonatomic, retain) IBOutlet UISlider * positionSlider;
@property (nonatomic, retain) IBOutlet UIBarButtonItem * timeDisplay;
@property (nonatomic, retain) IBOutlet UIButton * playPauseButton;
@property (nonatomic, retain) IBOutlet UIButton * bwdButton;
@property (nonatomic, retain) IBOutlet UIButton * fwdButton;
@property (nonatomic, retain) IBOutlet UIButton * subtitleSwitcherButton;
@property (nonatomic, retain) IBOutlet UIButton * audioSwitcherButton;
@property (nonatomic, retain) IBOutlet UIView * controllerPanel;

@property (strong, nonatomic) MLFile *mediaItem;

- (IBAction)closePlayback:(id)sender;
- (IBAction)positionSliderAction:(id)sender;

- (IBAction)play:(id)sender;
- (IBAction)backward:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)switchAudioTrack:(id)sender;
- (IBAction)switchSubtitleTrack:(id)sender;

@end
