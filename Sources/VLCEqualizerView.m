/*****************************************************************************
 * VLCEqualizerView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan dot org>
 *          Sylver Bruneau <sylver.bruneau # gmail dot com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCEqualizerView.h"
#import "VLCTrackSelectorTableViewCell.h"
#import "VLCTrackSelectorHeaderView.h"
#import "VLCSlider.h"

#define PROFILE_SELECTOR_TABLEVIEW_SECTIONHEADER @"profile selector table section header"
#define PROFILE_SELECTOR_TABLEVIEW_CELL @"profile selector table view cell"

@interface VLCEqualizerView ()
{
    VLCSlider *_preAmp_slider;
    VLCSlider *_60_slider;
    VLCSlider *_170_slider;
    VLCSlider *_310_slider;
    VLCSlider *_600_slider;
    VLCSlider *_1K_slider;
    VLCSlider *_3K_slider;
    VLCSlider *_6K_slider;
    VLCSlider *_12K_slider;
    VLCSlider *_14K_slider;
    VLCSlider *_16K_slider;
}

@end

@implementation VLCEqualizerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (!self)
        return self;

#define horizontal_padding 6.
#define vertical_padding_up 8.
#define vertical_padding_down 135.
#define spacer 8.

    UITextView *textView = nil;

    CGFloat sliderHeight = frame.size.height - (vertical_padding_up + vertical_padding_down);
    CGFloat sliderWidth = (frame.size.width - (spacer * 11.)) / 12.;
    CGFloat sliderY = (sliderHeight / 2.) - horizontal_padding;

    _preAmp_slider = [[VLCSlider alloc] initWithFrame:CGRectMake(-sliderWidth + horizontal_padding, sliderY, sliderHeight, sliderWidth)];
    _preAmp_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _preAmp_slider.minimumValue = -20.;
    _preAmp_slider.maximumValue = 20.;
    [_preAmp_slider addTarget:self action:@selector(preampSliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_preAmp_slider];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(0, frame.size.height - vertical_padding_down, 55, 25)];
    textView.text = NSLocalizedString(@"PREAMP", nil);
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    // Info
    textView = [[UITextView alloc] initWithFrame:CGRectMake(sliderWidth, vertical_padding_up - 10, 55, 20)];
    textView.text = [NSString stringWithFormat:NSLocalizedString(@"DB_FORMAT", nil), 20];
    textView.textAlignment = NSTextAlignmentRight;
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(sliderWidth, vertical_padding_up + sliderHeight / 2 - 15, 55, 20)];
    textView.text = [NSString stringWithFormat:NSLocalizedString(@"DB_FORMAT", nil), 0];
    textView.textAlignment = NSTextAlignmentRight;
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(sliderWidth, frame.size.height - vertical_padding_down - 20, 55, 20)];
    textView.text = [NSString stringWithFormat:NSLocalizedString(@"DB_FORMAT", nil), -20];
    textView.textAlignment = NSTextAlignmentRight;
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];


    _60_slider = [[VLCSlider alloc] initWithFrame:CGRectMake(horizontal_padding * 3. + sliderWidth, sliderY, sliderHeight, sliderWidth)];
    _60_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _60_slider.tag = 0;
    _60_slider.minimumValue = -20.;
    _60_slider.maximumValue = 20.;
    [_60_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_60_slider];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(horizontal_padding * 2. + sliderWidth * 2.5, frame.size.height - vertical_padding_down, 25, 25)];
    textView.text = @"60";
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    _170_slider = [[VLCSlider alloc] initWithFrame:CGRectMake(horizontal_padding * 4. + sliderWidth * 2, sliderY, sliderHeight, sliderWidth)];
    _170_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _170_slider.tag = 1;
    _170_slider.minimumValue = -20.;
    _170_slider.maximumValue = 20.;
    [_170_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_170_slider];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(horizontal_padding * 3. + sliderWidth * 3.5, frame.size.height - vertical_padding_down, 35, 25)];
    textView.text = @"170";
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    _310_slider = [[VLCSlider alloc] initWithFrame:CGRectMake(horizontal_padding * 5. + sliderWidth * 3., sliderY, sliderHeight, sliderWidth)];
    _310_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _310_slider.tag = 2;
    _310_slider.minimumValue = -20.;
    _310_slider.maximumValue = 20.;
    [_310_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_310_slider];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(horizontal_padding * 4. + sliderWidth * 4.5, frame.size.height - vertical_padding_down, 35, 25)];
    textView.text = @"310";
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    _600_slider = [[VLCSlider alloc] initWithFrame:CGRectMake(horizontal_padding * 6. + sliderWidth * 4., sliderY, sliderHeight, sliderWidth)];
    _600_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _600_slider.tag = 3;
    _600_slider.minimumValue = -20.;
    _600_slider.maximumValue = 20.;
    [_600_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_600_slider];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(horizontal_padding * 5. + sliderWidth * 5.5, frame.size.height - vertical_padding_down, 35, 25)];
    textView.text = @"600";
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    _1K_slider = [[VLCSlider alloc] initWithFrame:CGRectMake(horizontal_padding * 7. + sliderWidth * 5., sliderY, sliderHeight, sliderWidth)];
    _1K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _1K_slider.tag = 4;
    _1K_slider.minimumValue = -20.;
    _1K_slider.maximumValue = 20.;
    [_1K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_1K_slider];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(horizontal_padding * 6. + sliderWidth * 6.5, frame.size.height - vertical_padding_down, 35, 25)];
    textView.text = @"1K";
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    _3K_slider = [[VLCSlider alloc] initWithFrame:CGRectMake(horizontal_padding * 8. + sliderWidth * 6., sliderY, sliderHeight, sliderWidth)];
    _3K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _3K_slider.tag = 5;
    _3K_slider.minimumValue = -20.;
    _3K_slider.maximumValue = 20.;
    [_3K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_3K_slider];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(horizontal_padding * 7. + sliderWidth * 7.5, frame.size.height - vertical_padding_down, 35, 25)];
    textView.text = @"3K";
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    _6K_slider = [[VLCSlider alloc] initWithFrame:CGRectMake(horizontal_padding * 9. + sliderWidth * 7., sliderY, sliderHeight, sliderWidth)];
    _6K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _6K_slider.tag = 6;
    _6K_slider.minimumValue = -20.;
    _6K_slider.maximumValue = 20.;
    [_6K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_6K_slider];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(horizontal_padding * 8. + sliderWidth * 8.5, frame.size.height - vertical_padding_down, 35, 25)];
    textView.text = @"6K";
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    _12K_slider = [[VLCSlider alloc] initWithFrame:CGRectMake(horizontal_padding * 10. + sliderWidth * 8., sliderY, sliderHeight, sliderWidth)];
    _12K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _12K_slider.tag = 7;
    _12K_slider.minimumValue = -20.;
    _12K_slider.maximumValue = 20.;
    [_12K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_12K_slider],

    textView = [[UITextView alloc] initWithFrame:CGRectMake(horizontal_padding * 9. + sliderWidth * 9.5, frame.size.height - vertical_padding_down, 35, 25)];
    textView.text = @"12K";
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    _14K_slider = [[VLCSlider alloc] initWithFrame:CGRectMake(horizontal_padding * 11. + sliderWidth * 9., sliderY, sliderHeight, sliderWidth)];
    _14K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _14K_slider.tag = 8;
    _14K_slider.minimumValue = -20.;
    _14K_slider.maximumValue = 20.;
    [_14K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_14K_slider];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(horizontal_padding * 10. + sliderWidth * 10.5, frame.size.height - vertical_padding_down, 35, 25)];
    textView.text = @"14K";
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    _16K_slider = [[VLCSlider alloc] initWithFrame:CGRectMake(horizontal_padding * 12. + sliderWidth * 10., sliderY, sliderHeight, sliderWidth)];
    _16K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _16K_slider.tag = 9;
    _16K_slider.minimumValue = -20.;
    _16K_slider.maximumValue = 20.;
    [_16K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_16K_slider];

    textView = [[UITextView alloc] initWithFrame:CGRectMake(horizontal_padding * 11. + sliderWidth * 11.5, frame.size.height - vertical_padding_down, 35, 25)];
    textView.text = @"16K";
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.userInteractionEnabled = NO;
    [self addSubview:textView];

    // TableView
    CGFloat tableInset = frame.size.height - vertical_padding_down + 25.;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,tableInset,frame.size.width, frame.size.height - tableInset)
                                              style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorColor = [UIColor clearColor];
    _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _tableView.rowHeight = 44.;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.sectionHeaderHeight = 28.;
    [_tableView registerClass:[VLCTrackSelectorHeaderView class] forHeaderFooterViewReuseIdentifier:PROFILE_SELECTOR_TABLEVIEW_SECTIONHEADER];
    [_tableView registerClass:[VLCTrackSelectorTableViewCell class] forCellReuseIdentifier:PROFILE_SELECTOR_TABLEVIEW_CELL];
    _tableView.opaque = NO;
    _tableView.backgroundColor = [UIColor clearColor];
    [self addSubview:_tableView];
    return self;
}

- (IBAction)sliderChangedValue:(VLCSlider *)sender
{
    if (self.delegate)
        [self.delegate setAmplification:[sender value] forBand:(unsigned)[sender tag]];
    if ([self.UIdelegate respondsToSelector:@selector(equalizerViewReceivedUserInput)])
        [self.UIdelegate equalizerViewReceivedUserInput];
}

- (IBAction)preampSliderChangedValue:(VLCSlider *)sender
{
    if (self.delegate)
        [self.delegate setPreAmplification:sender.value];
    if ([self.UIdelegate respondsToSelector:@selector(equalizerViewReceivedUserInput)])
        [self.UIdelegate equalizerViewReceivedUserInput];
}

- (void)reloadData
{
    if (self.delegate) {
        _preAmp_slider.value = [self.delegate preAmplification];
        _60_slider.value = [self.delegate amplificationOfBand:0];
        _170_slider.value = [self.delegate amplificationOfBand:1];
        _310_slider.value = [self.delegate amplificationOfBand:2];
        _600_slider.value = [self.delegate amplificationOfBand:3];
        _1K_slider.value = [self.delegate amplificationOfBand:4];
        _3K_slider.value = [self.delegate amplificationOfBand:5];
        _6K_slider.value = [self.delegate amplificationOfBand:6];
        _12K_slider.value = [self.delegate amplificationOfBand:7];
        _14K_slider.value = [self.delegate amplificationOfBand:8];
        _16K_slider.value = [self.delegate amplificationOfBand:9];
    }
}

#pragma mark - track selector table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:PROFILE_SELECTOR_TABLEVIEW_SECTIONHEADER];
    if (!view)
        view = [[VLCTrackSelectorHeaderView alloc] initWithReuseIdentifier:PROFILE_SELECTOR_TABLEVIEW_SECTIONHEADER];

    return view;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"CHOOSE_EQUALIZER_PROFILES", nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCTrackSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PROFILE_SELECTOR_TABLEVIEW_CELL];

    if (!cell)
        cell = [[VLCTrackSelectorTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PROFILE_SELECTOR_TABLEVIEW_CELL];

    NSInteger row = indexPath.row;

    cell.textLabel.text = [[self.delegate equalizerProfiles] objectAtIndex:row];
    unsigned int profile = (unsigned int)[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingEqualizerProfile] integerValue];

    if (profile == row)
        [cell setShowsCurrentTrack];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.delegate equalizerProfiles].count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSInteger index = indexPath.row;

    [self.delegate resetEqualizerFromProfile:(unsigned)index];
    [self reloadData];
    [self.tableView reloadData];
}

@end
