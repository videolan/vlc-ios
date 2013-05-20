//
//  VLCSettingsViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 19.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCSettingsViewController.h"
#import "VLCPlaylistViewController.h"
#import "VLCPasscodeLockViewController.h"
#import "VLCAppDelegate.h"

@interface VLCSettingsViewController ()
{
    NSArray *_userFacingTextEncodingNames;
    NSArray *_textEncodingNames;
}

@end

@implementation VLCSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.dismissButton.title = NSLocalizedString(@"BUTTON_DONE", @"");
    self.passcodeLockLabel.text = NSLocalizedString(@"PREF_PASSCODE", @"");
    self.audioPlaybackInBackgroundLabel.text = NSLocalizedString(@"PREF_AUDIOBACKGROUND", @"");
    self.audioStretchingLabel.text = NSLocalizedString(@"PREF_AUDIOSTRETCH", @"");
    self.debugOutputLabel.text = NSLocalizedString(@"PREF_VERBOSEDEBUG", @"");
}

- (void)viewWillDisappear:(BOOL)animated
{
    /* save some memory */
    _userFacingTextEncodingNames = nil;
    _textEncodingNames = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.passcodeLockSwitch.on = [[defaults objectForKey:kVLCSettingPasscodeOnKey] intValue];
    self.audioPlaybackInBackgroundSwitch.on = [[defaults objectForKey:kVLCSettingContinueAudioInBackgroundKey] intValue];
    self.audioStretchingSwitch.on = ![[defaults objectForKey:kVLCSettingStretchAudio] isEqualToString:kVLCSettingStretchAudioDefaultValue];
    self.debugOutputSwitch.on = [[defaults objectForKey:kVLCSettingVerboseOutput] isEqualToString:kVLCSettingVerboseOutputDefaultValue];

    _userFacingTextEncodingNames = @[@"Default (Windows-1252)", @"Universal (UTF-8)", @"Universal (UTF-16)", @"Universal (big endian UTF-16)", @"Universal (little endian UTF-16)", @"Universal, Chinese (GB18030)", @"Western European (Latin-9)", @"Western European (Windows-1252)", @"Western European (IBM 00850)", @"Eastern European (Latin-2)", @"Eastern European (Windows-1250)", @"Esperanto (Latin-3)", @"Nordic (Latin-6)", @"Cyrillic (Windows-1251)", @"Russian (KOI8-R)", @"Ukrainian (KOI8-U)", @"Arabic (ISO 8859-6)", @"Arabic (Windows-1256)", @"Greek (ISO 8859-7)", @"Greek (Windows-1253)", @"Hebrew (ISO 8859-8)", @"Hebrew (Windows-1255)", @"Turkish (ISO 8859-9)", @"Turkish (Windows-1254)", @"Thai (TIS 620-2533/ISO 8859-11)", @"Thai (Windows-874)", @"Baltic (Latin-7)", @"Baltic (Windows-1257)", @"Celtic (Latin-8)", @"South-Eastern European (Latin-10)", @"Simplified Chinese (ISO-2022-CN-EXT)", @"Simplified Chinese Unix (EUC-CN)", @"Japanese (7-bits JIS/ISO-2022-JP-2)", @"Japanese Unix (EUC-JP)", @"Japanese (Shift JIS)", @"Korean (EUC-KR/CP949)", @"Korean (ISO-2022-KR)", @"Traditional Chinese (Big5)", @"Traditional Chinese Unix (EUC-TW)", @"Hong-Kong Supplementary (HKSCS)", @"Vietnamese (VISCII)", @"Vietnamese (Windows-1258)"];
    _textEncodingNames = @[@"", @"UTF-8", @"UTF-16", @"UTF-16BE", @"UTF-16LE", @"GB18030", @"ISO-8859-15", @"Windows-1252", @"IBM850", @"ISO-8859-2", @"Windows-1250", @"ISO-8859-3", @"ISO-8859-10", @"Windows-1251", @"KOI8-R", @"KOI8-U", @"ISO-8859-6", @"Windows-1256", @"ISO-8859-7", @"Windows-1253", @"ISO-8859-8", @"Windows-1255", @"ISO-8859-9", @"Windows-1254", @"ISO-8859-11", @"Windows-874", @"ISO-8859-13", @"Windows-1257", @"ISO-8859-14", @"ISO-8859-16", @"ISO-2022-CN-EXT", @"EUC-CN", @"ISO-2022-JP-2", @"EUC-JP", @"Shift_JIS", @"CP949", @"ISO-2022-KR", @"Big5", @"ISO-2022-TW", @"Big5-HKSCS", @"VISCII", @"Windows-1258"];
    [self.textEncodingPicker reloadAllComponents];
    [self.textEncodingPicker selectRow:[_textEncodingNames indexOfObject:[defaults objectForKey:kVLCSettingTextEncoding]] inComponent:0 animated:NO];

    [super viewWillAppear:animated];
}

- (IBAction)toggleSetting:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (sender == self.passcodeLockSwitch) {
        if (self.passcodeLockSwitch.on) {
            VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                CGRect frame = self.view.frame;
                frame.size.height -= 44.;
                appDelegate.playlistViewController.passcodeLockViewController.view.frame = frame;
            }
            [self.view addSubview:appDelegate.playlistViewController.passcodeLockViewController.view];
            [appDelegate.playlistViewController.passcodeLockViewController resetPasscode];
        } else {
            [defaults setObject:@0 forKey:kVLCSettingPasscodeOnKey];
        }
    } else if (sender == self.audioPlaybackInBackgroundSwitch) {
        [defaults setObject:@(self.audioPlaybackInBackgroundSwitch.on) forKey:kVLCSettingContinueAudioInBackgroundKey];
    } else if (sender == self.audioStretchingSwitch) {
        if (self.audioStretchingSwitch.on)
            [defaults setObject:@"--audio-time-stretch" forKey:kVLCSettingStretchAudio];
        else
            [defaults setObject:kVLCSettingStretchAudioDefaultValue forKey:kVLCSettingStretchAudio];
    } else if (sender == self.debugOutputSwitch) {
        if (self.debugOutputSwitch.on)
            [defaults setObject:kVLCSettingVerboseOutputDefaultValue forKey:kVLCSettingVerboseOutput];
        else
            [defaults setObject:@"--verbose=0" forKey:kVLCSettingVerboseOutput];
    }

    [defaults synchronize];
}

- (IBAction)dismiss:(id)sender
{
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.playlistViewController.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark - text encoding picker view delegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_textEncodingNames[row] forKey:kVLCSettingTextEncoding];
    [defaults synchronize];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _userFacingTextEncodingNames[row];
}

#pragma mark - text encoding picker view data source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _textEncodingNames.count;
}

@end
