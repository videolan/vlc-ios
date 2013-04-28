//
//  VLCPlaylistTableViewCell.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 01.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCPlaylistTableViewCell.h"

@implementation VLCPlaylistTableViewCell

+ (VLCPlaylistTableViewCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCPlaylistTableViewCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCPlaylistTableViewCell class]], @"meh meh");
    VLCPlaylistTableViewCell *cell = (VLCPlaylistTableViewCell *)[nibContentArray lastObject];
    CGRect frame = [cell frame];
    UIView *background = [[UIView alloc] initWithFrame:frame];
    background.backgroundColor = [UIColor colorWithWhite:.05 alpha:1.];
    cell.backgroundView = background;
    UIView *highlightedBackground = [[UIView alloc] initWithFrame:frame];
    highlightedBackground.backgroundColor = [UIColor colorWithWhite:.2 alpha:1.];
    cell.selectedBackgroundView = highlightedBackground;

    return cell;
}

+ (CGFloat)heightOfCell
{
    return 80.;
}

@end
