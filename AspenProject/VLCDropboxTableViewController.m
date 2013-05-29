//
//  VLCDropboxTableViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 24.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCDropboxTableViewController.h"
#import "VLCDropboxTableViewCell.h"
#import "VLCDropboxController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "VLCDropboxConstants.h"
#import <DropboxSDK/DropboxSDK.h>

@interface VLCDropboxTableViewController ()
{
    VLCDropboxController *_dropboxController;
    NSString *_currentPath;

    UIBarButtonItem *_numberOfFilesBarButtonItem;
    UIBarButtonItem *_progressBarButtonItem;
    UIBarButtonItem *_downloadingBarLabel;
    UIProgressView *_progressView;

    UIActivityIndicatorView *_activityIndicator;
}

@end

@implementation VLCDropboxTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _dropboxController = [[VLCDropboxController alloc] init];
    _dropboxController.delegate = self;

    DBSession* dbSession = [[DBSession alloc] initWithAppKey:kVLCDropboxAppKey appSecret:kVLCDropboxPrivateKey root:kDBRootDropbox];
    [DBSession setSharedSession:dbSession];
    [DBRequest setNetworkRequestDelegate:_dropboxController];

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", @"") style:UIBarButtonItemStyleDone target:self action:@selector(dismiss:)];
    self.navigationItem.rightBarButtonItem = addButton;

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@".." style:UIBarButtonItemStyleBordered target:self action:@selector(folderUp:)];
    self.navigationItem.leftBarButtonItem = backButton;

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dropbox-white"]];

    self.tableView.rowHeight = [VLCDropboxTableViewCell heightOfCell];
    self.tableView.separatorColor = [UIColor colorWithWhite:.2 alpha:1.];

    _numberOfFilesBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", @""), 0] style:UIBarButtonItemStylePlain target:nil action:nil];
    [_numberOfFilesBarButtonItem setTitleTextAttributes:@{ UITextAttributeFont : [UIFont systemFontOfSize:11.] } forState:UIControlStateNormal];

    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_progressView];
    _downloadingBarLabel = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DOWNLOADING",@"") style:UIBarButtonItemStylePlain target:nil action:nil];
    [_downloadingBarLabel setTitleTextAttributes:@{ UITextAttributeFont : [UIFont systemFontOfSize:11.] } forState:UIControlStateNormal];

    [self _showProgressInToolbar:NO];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;

    CGRect aiFrame = _activityIndicator.frame;
    CGSize tvSize = self.tableView.frame.size;
    aiFrame.origin.x = (tvSize.width - aiFrame.size.width) / 2.;
    aiFrame.origin.y = (tvSize.height - aiFrame.size.height) / 2.;
    _activityIndicator.frame = aiFrame;

    [self.view addSubview:_activityIndicator];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    [self updateViewAfterSessionChange];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
    [super viewWillDisappear:animated];
}

- (void)_showProgressInToolbar:(BOOL)value
{
    if (!value)
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _numberOfFilesBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:YES];
    else {
        _progressView.progress = 0.;
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _downloadingBarLabel, _progressBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:YES];
    }
}

- (void)_requestInformationForCurrentPath
{
    [_activityIndicator startAnimating];
    [_dropboxController requestDirectoryListingAtPath:_currentPath];
}

- (IBAction)dismiss:(id)sender
{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (IBAction)folderUp:(id)sender
{
    _currentPath = [_currentPath stringByDeletingLastPathComponent];
    [self _requestInformationForCurrentPath];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dropboxController.currentListFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DropboxCell";

    VLCDropboxTableViewCell *cell = (VLCDropboxTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCDropboxTableViewCell cellWithReuseIdentifier:CellIdentifier];

    cell.fileMetadata = _dropboxController.currentListFiles[indexPath.row];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBMetadata *selectedFile = _dropboxController.currentListFiles[indexPath.row];
    if (!selectedFile.isDirectory) {
        /* selected item is a proper file, download it */
        [_dropboxController downloadFileToDocumentFolder:selectedFile];
    } else {
        /* dive into subdirectory */
        _currentPath = [_currentPath stringByAppendingFormat:@"/%@", selectedFile.filename];
        [self _requestInformationForCurrentPath];
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - dropbox controller delegate

- (void)mediaListUpdated
{
    [_activityIndicator stopAnimating];

    [self.tableView reloadData];

    NSUInteger count = _dropboxController.currentListFiles.count;
    if (count == 0)
        _numberOfFilesBarButtonItem.title = NSLocalizedString(@"NO_FILES", @"");
    else if (count != 1)
        _numberOfFilesBarButtonItem.title = [NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", @""), count];
    else
        _numberOfFilesBarButtonItem.title = NSLocalizedString(@"ONE_FILE", @"");
}

- (void)operationWithProgressInformationStarted
{
    [self _showProgressInToolbar:YES];
}

- (void)currentProgressInformation:(float)progress
{
    [_progressView setProgress: progress animated:YES];
}

- (void)operationWithProgressInformationStopped
{
    [self _showProgressInToolbar:NO];
}

#pragma mark - communication with app delegate

- (void)updateViewAfterSessionChange
{
    if (![[DBSession sharedSession] isLinked]) {
        [self _showLoginPanel];
        return;
    } else if (self.loginToDropboxView.superview)
        [self.loginToDropboxView removeFromSuperview];

    _currentPath = @"/";
    [self _requestInformationForCurrentPath];
}

#pragma mark - login dialog

- (void)_showLoginPanel
{
    self.loginToDropboxView.frame = self.tableView.frame;
    [self.tableView addSubview:self.loginToDropboxView];
}

- (IBAction)loginToDropboxAction:(id)sender
{
    if (!_dropboxController.sessionIsLinked)
        [[DBSession sharedSession] linkFromController:self];
    else
        [_dropboxController logout];
}

@end