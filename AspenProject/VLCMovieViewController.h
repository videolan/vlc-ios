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
}

@property (nonatomic, retain) IBOutlet UIView * movieView;

@property (strong, nonatomic) MLFile *mediaItem;

@end
