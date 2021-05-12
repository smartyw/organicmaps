#import "MWMAlertViewController.h"
#import "MWMAuthorizationCommon.h"
#import "MWMAuthorizationLoginViewController.h"
#import "MWMAuthorizationWebViewLoginViewController.h"

#include <CoreApi/Framework.h>

namespace
{
NSString * const kWebViewAuthSegue = @"Authorization2WebViewAuthorizationSegue";
NSString * const kOSMAuthSegue = @"Authorization2OSMAuthorizationSegue";

NSString * const kCancel = L(@"cancel");
NSString * const kLogout = L(@"logout");
NSString * const kRefresh = L(@"refresh");
} // namespace

using namespace osm;
using namespace osm_auth_ios;

@interface MWMAuthorizationLoginViewController ()

@property (weak, nonatomic) IBOutlet UIView * authView;
@property (weak, nonatomic) IBOutlet UIView * accountView;

@property (weak, nonatomic) IBOutlet UIButton * loginOSMButton;
@property (weak, nonatomic) IBOutlet UIButton * signupButton;

@property (weak, nonatomic) IBOutlet UILabel * changesCountLabel;
@property (weak, nonatomic) IBOutlet UILabel * lastUpdateLabel;

@end

@implementation MWMAuthorizationLoginViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self checkConnection];
  if (AuthorizationHaveCredentials())
    [self configHaveAuth];
  else
    [self configNoAuth];

  AuthorizationSetNeedCheck(NO);
}

- (void)checkConnection
{
  self.signupButton.enabled = Platform::IsConnected();
}

- (void)configHaveAuth
{
  NSString * osmUserName = OSMUserName();
  self.title = osmUserName.length > 0 ? osmUserName : L(@"osm_account").capitalizedString;
  self.authView.hidden = YES;
  self.accountView.hidden = NO;

  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"•••" style:UIBarButtonItemStylePlain target:self action:@selector(showActionSheet)];
  [self refresh:NO];
}

- (void)configNoAuth
{
  self.title = L(@"profile").capitalizedString;
  self.authView.hidden = NO;
  self.accountView.hidden = YES;
}

#pragma mark - Actions

- (void)performOnlineAction:(MWMVoidBlock)block
{
  if (Platform::IsConnected())
    block();
  else
    [self.alertController presentNoConnectionAlert];
}

- (IBAction)loginOSM
{
  [self performOnlineAction:^
  {
    [self performSegueWithIdentifier:kOSMAuthSegue sender:self.loginOSMButton];
  }];
}

- (IBAction)signup
{
  [self performOnlineAction:^
  {
    [self openUrl:[NSURL URLWithString:@(OsmOAuth::ServerAuth().GetRegistrationURL().c_str())]];
  }];
}

- (IBAction)osmTap
{
  [self openUrl:[NSURL URLWithString:@"https://wiki.openstreetmap.org/wiki/Main_Page"]];
}

- (IBAction)historyTap
{
  [self openUrl:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.openstreetmap.org/user/%@/history", OSMUserName()]]];
}

- (void)logout
{
  AuthorizationClearCredentials();
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)refresh:(BOOL)force
{
  self.changesCountLabel.text = @(OSMUserChangesetsCount()).stringValue;
//  int32_t rank;
//  if (stats.GetRank(rank))
//    self.rankLabel.text = @(rank).stringValue;
//  std::string levelUpFeat;
//  if (stats.GetLevelUpRequiredFeat(levelUpFeat))
//  {
//    self.yourPlaceLabelCenterYAlignment.priority = UILayoutPriorityDefaultLow;
//    self.changesToNextPlaceLabel.hidden = NO;
//    self.changesToNextPlaceLabel.text =
//        [NSString stringWithFormat:@"%@ %@", L(@"editor_profile_changes_for_next_place"),
//                                   @(levelUpFeat.c_str())];
//  }
//  else
//  {
//    self.yourPlaceLabelCenterYAlignment.priority = UILayoutPriorityDefaultHigh;
//    self.changesToNextPlaceLabel.hidden = YES;
//  }

//  NSString * lastUploadDate = [NSDateFormatter
//      localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:stats.GetLastUpdate()]
//                    dateStyle:NSDateFormatterShortStyle
//                    timeStyle:NSDateFormatterShortStyle];
//  self.lastUpdateLabel.text =
//      [NSString stringWithFormat:L(@"last_update"), lastUploadDate.UTF8String];
}

#pragma mark - ActionSheet

- (void)showActionSheet
{
  UIAlertController * alertController =
      [UIAlertController alertControllerWithTitle:nil
                                          message:nil
                                   preferredStyle:UIAlertControllerStyleActionSheet];
  alertController.popoverPresentationController.barButtonItem =
      self.navigationItem.rightBarButtonItem;
  [alertController addAction:[UIAlertAction actionWithTitle:kRefresh
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                      [self refresh:YES];
                                                    }]];
  [alertController addAction:[UIAlertAction actionWithTitle:kLogout
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction * action) {
                                                      [self logout];
                                                    }]];
  [alertController
      addAction:[UIAlertAction actionWithTitle:kCancel style:UIAlertActionStyleCancel handler:nil]];

  [self presentViewController:alertController animated:YES completion:nil];
}

@end
