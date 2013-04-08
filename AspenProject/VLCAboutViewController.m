//
//  VLCAboutViewController.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 07.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCAboutViewController.h"

@interface VLCAboutViewController ()

@end

@implementation VLCAboutViewController
@synthesize textContents=_textContents, aspenVersion=_aspenVersion, vlckitVersion=_vlckitVersion;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)dealloc
{
    [_textContents release];
    [_aspenVersion release];
    [_vlckitVersion release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.textContents.attributedText = [[[NSAttributedString alloc] initWithString:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"About Contents" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil]] autorelease];
    self.aspenVersion.text = [NSString stringWithFormat:@"Version: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    self.vlckitVersion.text = [NSString stringWithFormat:@"Based on:\n%@",[[VLCLibrary sharedLibrary] version]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [super viewWillDisappear:animated];
}

- (IBAction)dismiss:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end