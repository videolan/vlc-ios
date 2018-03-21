//
//  BOXItemPickerTableViewCell.h
//  BoxSDK
//
//  Copyright (c) 2014 Box. All rights reserved.
//

#import "BoxItemPickerHelper.h"
#import "BoxItem.h"

@interface BOXItemPickerTableViewCell : UITableViewCell

@property (nonatomic, readwrite, strong) BoxItemPickerHelper *helper;
@property (nonatomic, readwrite, strong) BoxItem *item;
@property (nonatomic, readwrite, strong) NSString *cachePath;
@property (nonatomic, readwrite, assign) BOOL showThumbnails;
@property (nonatomic, readwrite, assign) BOOL enabled;

- (void)renderThumbnail;

@end
