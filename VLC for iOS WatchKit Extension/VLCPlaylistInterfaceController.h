/*****************************************************************************
 * VLCPlaylistInterfaceController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

#import "VLCBaseInterfaceController.h"

@interface VLCPlaylistInterfaceController : VLCBaseInterfaceController
@property (weak, nonatomic) IBOutlet WKInterfaceButton *previousButton;
@property (nonatomic, weak) IBOutlet WKInterfaceTable *table;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *nextButton;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *emptyLibraryGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *emptyLibraryLabel;

- (IBAction)previousPagePressed;
- (IBAction)nextPagePressed;

@end
