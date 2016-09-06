//
//  RCDGroupSettingsTableViewController.m
//  RCloudMessage
//
//  Created by Jue on 16/3/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCDGroupSettingsTableViewController.h"
#import "DefaultPortraitView.h"
#import "MBProgressHUD.h"
#import "RCDAddFriendViewController.h"
#import "RCDCommonDefine.h"
#import "RCDContactSelectedTableViewController.h"
#import "RCDConversationSettingTableViewHeaderItem.h"
#import "RCDEditGroupNameViewController.h"
#import "RCDGroupMembersTableViewController.h"
//#import "RCDGroupSettingsTableViewCell.h"
#import "RCDHttpTool.h"
#import "RCDPersonDetailViewController.h"
#import "RCDataBaseManager.h"
#import "UIImageView+WebCache.h"
#import <RongIMLib/RongIMLib.h>
#import "RCDGroupAnnouncementViewController.h"
#import "UIColor+RCColor.h"
#import "RCDUserInfoManager.h"

static NSString *CellIdentifier = @"RCDBaseSettingTableViewCell";

#define SwitchButtonTag  1111

@interface RCDGroupSettingsTableViewController ()
//开始会话
@property(strong, nonatomic) UIButton *btChat;
//加入或退出群组
@property(strong, nonatomic) UIButton *btJoinOrQuitGroup;
//解散群组
@property(strong, nonatomic) UIButton *btDismissGroup;

@end

@implementation RCDGroupSettingsTableViewController {
  NSInteger numberOfSections;
  RCConversation *currentConversation;
  BOOL enableNotification;
  NSMutableArray *collectionViewResource;
  UICollectionView *headerView;
  NSString *groupId;
  NSString *creatorId;
  BOOL isCreator;
  UIImage *image;
  NSData *data;
  MBProgressHUD *hud;
}

+ (instancetype)groupSettingsTableViewController {
    return [[[self class] alloc]init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
//        [self.tableView registerClass:[RCDBaseSettingTableViewCell class ] forCellReuseIdentifier:CellIdentifier];

        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews {
    
}

- (void)setGroup:(RCDGroupInfo *)Group {
    _Group = Group;
    if (_Group) {
        groupId = _Group.groupId;
        if (creatorId == nil) {
            creatorId = _Group.creatorId;
            if ([creatorId
                 isEqualToString:[RCIM sharedRCIM].currentUserInfo.userId]) {
                isCreator = YES;
            }
        }
    }
}

- (void)viewDidLoad {

  [super viewDidLoad];

  self.tableView.tableFooterView = [UIView new];
  self.tableView.backgroundColor = HEXCOLOR(0xf0f0f6);
  self.tableView.separatorColor = HEXCOLOR(0xdfdfdf);
  
  if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
  }

  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;

  // Uncomment the following line to display an Edit button in the navigation
  // bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
  numberOfSections = 0;

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 6, 87, 23);
    UIImageView *backImg = [[UIImageView alloc]
                            initWithImage:[UIImage imageNamed:@"navigator_btn_back"]];
    backImg.frame = CGRectMake(-6, 4, 10, 17);
    [backBtn addSubview:backImg];
    UILabel *backText =
    [[UILabel alloc] initWithFrame:CGRectMake(9,4, 85, 17)];
    backText.text = @"返回";
    [backText setBackgroundColor:[UIColor clearColor]];
    [backText setTextColor:[UIColor whiteColor]];
    [backBtn addSubview:backText];
    [backBtn addTarget:self
                action:@selector(backBarButtonItemClicked:)
      forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftButton =
    [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    [self.navigationItem setLeftBarButtonItem:leftButton];



  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(addGroupMemberList:)
             name:@"addGroupMemberList"
           object:nil];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(deleteGroupMemberList:)
             name:@"deleteGroupMemberList"
           object:nil];

  CGRect tempRect = CGRectMake(
      0, 0, [UIScreen mainScreen].bounds.size.width,
      headerView.collectionViewLayout.collectionViewContentSize.height);
  UICollectionViewFlowLayout *flowLayout =
      [[UICollectionViewFlowLayout alloc] init];
  flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
  headerView = [[UICollectionView alloc] initWithFrame:tempRect
                                  collectionViewLayout:flowLayout];
  headerView.delegate = self;
  headerView.dataSource = self;
  headerView.scrollEnabled = NO;
  headerView.backgroundColor = [UIColor whiteColor];
  [headerView registerClass:[RCDConversationSettingTableViewHeaderItem class]
      forCellWithReuseIdentifier:@"RCDConversationSettingTableViewHeaderItem"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startLoad];
    if(self.Group.number){
        self.title = [NSString stringWithFormat:@"群组信息(%@)",self.Group.number];
    }else{
        self.title = @"群组信息";
    }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - 本类的私有方法
- (void)clickNotificationBtn:(id)sender {
  UISwitch *swch = sender;
  [[RCIMClient sharedRCIMClient]
      setConversationNotificationStatus:ConversationType_GROUP
      targetId:groupId
      isBlocked:swch.on
      success:^(RCConversationNotificationStatus nStatus) {
        NSLog(@"成功");

      }
      error:^(RCErrorCode status) {
        NSLog(@"失败");
      }];
}

- (void)clickIsTopBtn:(id)sender {
  UISwitch *swch = sender;
  [[RCIMClient sharedRCIMClient] setConversationToTop:ConversationType_GROUP
                                             targetId:groupId
                                                isTop:swch.on];
}

- (void)backBarButtonItemClicked:(id)sender {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)startLoad {
  currentConversation =
      [[RCIMClient sharedRCIMClient] getConversation:ConversationType_GROUP
                                            targetId:groupId];
  if (currentConversation.targetId == nil) {
    numberOfSections = 2;
    [self.tableView reloadData];
  } else {
    numberOfSections = 3;
    [[RCIMClient sharedRCIMClient]
        getConversationNotificationStatus:ConversationType_GROUP
        targetId:groupId
        success:^(RCConversationNotificationStatus nStatus) {
          enableNotification = NO;
          if (nStatus == NOTIFY) {
            enableNotification = YES;
          }
          [self.tableView reloadData];
        }
        error:^(RCErrorCode status){

        }];
  }
  _GroupMemberList = [[RCDataBaseManager shareInstance] getGroupMember:groupId];
  _GroupMemberList = [self moveCreator:_GroupMemberList];
  NSArray *resultList = [[RCDUserInfoManager shareInstance] getFriendInfoList:_GroupMemberList];
  _GroupMemberList = [[NSMutableArray alloc] initWithArray:resultList];
  if ([_GroupMemberList count] > 0) {
    /******************添加headerview*******************/
    collectionViewResource =
        [[NSMutableArray alloc] initWithArray:_GroupMemberList];
    [self setHeaderView];
  }
    __weak typeof(self) weakSelf = self;
    [RCDHTTPTOOL
     getGroupMembersWithGroupId:groupId
     Block:^(NSMutableArray *result) {
       if ([result count] > 0) {
           dispatch_async(dispatch_get_main_queue(), ^{
               weakSelf.title = [NSString stringWithFormat:@"群组信息(%lu)",(unsigned long)result.count];
           });
         collectionViewResource = [NSMutableArray new];
         _GroupMemberList = [NSMutableArray new];
         [_GroupMemberList addObjectsFromArray:result];
         _GroupMemberList = [self moveCreator:_GroupMemberList];
         NSArray *resultList = [[RCDUserInfoManager shareInstance] getFriendInfoList:_GroupMemberList];
         _GroupMemberList = [[NSMutableArray alloc] initWithArray:resultList];
         [collectionViewResource
          addObjectsFromArray:_GroupMemberList];
         [self setHeaderView];
         [self.tableView reloadData];
         [[RCDataBaseManager shareInstance]
          insertGroupMemberToDB:result
          groupId:groupId];
         for (RCDUserInfo *user in result) {
           [[RCIM sharedRCIM] refreshUserInfoCache:user withUserId:user.userId];
         }
       }
     }];

  
  /******************添加footerview*******************/
  UIView *view = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 150)];

  //删除并退出按钮
  UIImage *quitImage = [UIImage imageNamed:@"group_quit"];
  UIImage *quitImageSelected = [UIImage imageNamed:@"group_quit_hover"];
  _btJoinOrQuitGroup = [[UIButton alloc] init];
  [_btJoinOrQuitGroup setBackgroundImage:quitImage
                                forState:UIControlStateNormal];
  [_btJoinOrQuitGroup setBackgroundImage:quitImageSelected
                                forState:UIControlStateSelected];
  [_btJoinOrQuitGroup setTitle:@"删除并退出" forState:UIControlStateNormal];
  [_btJoinOrQuitGroup setCenter:CGPointMake(view.bounds.size.width / 2,
                                            view.bounds.size.height / 2)];
  [_btJoinOrQuitGroup addTarget:self
                         action:@selector(btnJOQAction:)
               forControlEvents:UIControlEventTouchUpInside];
  _btJoinOrQuitGroup.layer.cornerRadius = 5.f;
  _btJoinOrQuitGroup.layer.borderWidth = 0.5f;
  _btJoinOrQuitGroup.layer.borderColor = [HEXCOLOR(0xcc4445) CGColor];
  [view addSubview:_btJoinOrQuitGroup];

  //解散群组按钮
  _btDismissGroup = [[UIButton alloc] init];
  [_btDismissGroup setBackgroundImage:quitImage
                                forState:UIControlStateNormal];
  [_btDismissGroup setBackgroundImage:quitImageSelected
                                forState:UIControlStateSelected];
  [_btDismissGroup setTitle:@"解散并删除" forState:UIControlStateNormal];
  [_btDismissGroup setBackgroundColor:[UIColor orangeColor]];
  [_btDismissGroup setCenter:CGPointMake(view.bounds.size.width / 2,
                                         view.bounds.size.height / 2)];
  [_btDismissGroup addTarget:self
                      action:@selector(btnDismissAction:)
            forControlEvents:UIControlEventTouchUpInside];
  _btDismissGroup.layer.cornerRadius = 5.f;
  [_btDismissGroup setHidden:YES];
  _btDismissGroup.layer.borderWidth = 0.5f;
  _btDismissGroup.layer.borderColor = [HEXCOLOR(0xcc4445) CGColor];
  [view addSubview:_btDismissGroup];

  //自动布局
  [_btChat setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_btJoinOrQuitGroup setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_btDismissGroup setTranslatesAutoresizingMaskIntoConstraints:NO];

  NSDictionary *views = NSDictionaryOfVariableBindings(_btJoinOrQuitGroup, _btDismissGroup);

  if (isCreator == YES) {
    [_btDismissGroup setHidden:NO];
    [_btJoinOrQuitGroup setHidden:YES];
    [view
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:|-29-[_"
                                                       @"btDismissGroup(42)]"
                                               options:0
                                               metrics:nil
                                                 views:views]];
    
    [view addConstraints:[NSLayoutConstraint
                            constraintsWithVisualFormat:@"H:|-10-[_btDismissGroup]-10-|"
                                               options:0
                                               metrics:nil
                                               views:views]];
  } else {
    [view
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:|-29-[_"
                                                       @"btJoinOrQuitGroup(42)]"
                                               options:0
                                               metrics:nil
                                                 views:views]];
    [view addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:
                                 @"H:|-10-[_btJoinOrQuitGroup]-10-|"
                                                 options:0
                                                 metrics:nil
                                                   views:views]];
  }

  self.tableView.tableFooterView = view;

  //添加或删除群组成员后刷新数据
  if (_Group == nil) {
    [RCDHTTPTOOL getGroupByID:groupId
            successCompletion:^(RCDGroupInfo *group) {
              dispatch_async(dispatch_get_main_queue(), ^{
                _Group = group;
                [self.tableView reloadData];
              });
            }];
  }
}

- (void)buttonChatAction:(id)sender {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)btnJOQAction:(id)sender {
  UIActionSheet *actionSheet =
      [[UIActionSheet alloc] initWithTitle:@"确定退出群组？"
                                  delegate:self
                         cancelButtonTitle:@"取消"
                    destructiveButtonTitle:@"确定"
                         otherButtonTitles:nil];

  [actionSheet showInView:self.view];
  actionSheet.tag = 101;
}

- (void)btnDismissAction:(id)sender {
  UIActionSheet *actionSheet =
      [[UIActionSheet alloc] initWithTitle:@"确定解散群组？"
                                  delegate:self
                         cancelButtonTitle:@"取消"
                    destructiveButtonTitle:@"确定"
                         otherButtonTitles:nil];

  [actionSheet showInView:self.view];
  actionSheet.tag = 102;
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
  [UIApplication sharedApplication].statusBarHidden = NO;

  NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];

  if ([mediaType isEqual:@"public.image"]) {
    UIImage *originImage =
        [info objectForKey:UIImagePickerControllerEditedImage];

    UIImage *scaleImage = [self scaleImage:originImage toScale:0.8];
    data = UIImageJPEGRepresentation(scaleImage, 0.00001);
  }

  image = [UIImage imageWithData:data];
  [self dismissViewControllerAnimated:YES completion:nil];

  hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  hud.color = [UIColor colorWithHexString:@"343637" alpha:0.5];
  hud.labelText = @"上传头像中...";
  [hud show:YES];
   __weak typeof(self) weakSelf = self;
  [RCDHTTPTOOL uploadImageToQiNiu:[RCIM sharedRCIM].currentUserInfo.userId
      ImageData:data
      success:^(NSString *url) {
        RCGroup *groupInfo = [RCGroup new];
        groupInfo.groupId = weakSelf.Group.groupId;
        groupInfo.portraitUri = url;
        groupInfo.groupName = weakSelf.Group.groupName;
          weakSelf.Group.portraitUri = url;
        [[RCIM sharedRCIM] refreshGroupInfoCache:groupInfo
                                     withGroupId:groupInfo.groupId];
        [RCDHTTPTOOL setGroupPortraitUri:url
                                 groupId:weakSelf.Group.groupId
                                complete:^(BOOL result) {
                                  if (result == YES) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                      RCDBaseSettingTableViewCell *cell =
                                          (RCDBaseSettingTableViewCell *)
                                              [self.tableView viewWithTag:1000];
                                        [cell.rightImageView sd_setImageWithURL:[NSURL URLWithString:self.Group.portraitUri]];
//                                      cell.PortraitImg.image = image;
                                      //关闭HUD
                                      [hud hide:YES];
                                    });
                                  }
                                  if (result == NO) {
                                    //关闭HUD
                                    [hud hide:YES];
                                    UIAlertView *alert = [[UIAlertView alloc]
                                            initWithTitle:nil
                                                  message:@"上传头像失败"
                                                 delegate:self
                                        cancelButtonTitle:@"确定"
                                        otherButtonTitles:nil];
                                    [alert show];
                                  }
                                }];

      }
      failure:^(NSError *err) {
        //关闭HUD
        [hud hide:YES];
        UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:nil
                                       message:@"上传头像失败"
                                      delegate:self
                             cancelButtonTitle:@"确定"
                             otherButtonTitles:nil];
        [alert show];
      }];
  dispatch_async(dispatch_get_main_queue(), ^{
    RCDBaseSettingTableViewCell *cell =
        (RCDBaseSettingTableViewCell *)[self.tableView viewWithTag:1000];
      [cell.rightImageView sd_setImageWithURL:[NSURL URLWithString:self.Group.portraitUri]];
//    cell.PortraitImg.image = image;
  });
}

- (UIImage *)scaleImage:(UIImage *)Image toScale:(float)scaleSize {
  UIGraphicsBeginImageContext(
      CGSizeMake(Image.size.width * scaleSize, Image.size.height * scaleSize));
  [Image drawInRect:CGRectMake(0, 0, Image.size.width * scaleSize,
                               Image.size.height * scaleSize)];
  UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return scaledImage;
}

- (void)chosePortrait {
  UIActionSheet *actionSheet =
      [[UIActionSheet alloc] initWithTitle:nil
                                  delegate:self
                         cancelButtonTitle:@"取消"
                    destructiveButtonTitle:@"拍照"
                         otherButtonTitles:@"我的相册", nil];
  actionSheet.tag = 200;
  [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet
    didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (actionSheet.tag == 200) {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.allowsEditing = YES;
    picker.delegate = self;

    switch (buttonIndex) {
    case 0:
      if ([UIImagePickerController
              isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
      } else {
        NSLog(@"模拟器无法连接相机");
      }
      [self presentViewController:picker animated:YES completion:nil];
      break;

    case 1:
      picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
      [self presentViewController:picker animated:YES completion:nil];
      break;

    default:
      break;
    }
  }
}


- (void)clearCacheAlertMessage:(NSString *)msg {
  UIAlertView *alertView =
  [[UIAlertView alloc] initWithTitle:nil
                             message:msg
                            delegate:nil
                   cancelButtonTitle:@"确定"
                   otherButtonTitles:nil, nil];
  [alertView show];
}


#pragma mark -UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (actionSheet.tag == 100) {
    if (buttonIndex == 0) {
      NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
      RCDBaseSettingTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
      UIActivityIndicatorView *activityIndicatorView =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
      float cellWidth = cell.bounds.size.width;
      UIView *loadingView = [[UIView alloc]initWithFrame:CGRectMake(cellWidth - 50, 10, 40, 40)];
      [loadingView addSubview:activityIndicatorView];
      dispatch_async(dispatch_get_main_queue(), ^{
        [activityIndicatorView startAnimating];
        [cell addSubview:loadingView];
      });
      
      [[RCIMClient sharedRCIMClient]deleteMessages:ConversationType_GROUP targetId:groupId success:^{
        [self performSelectorOnMainThread:@selector(clearCacheAlertMessage:)
                               withObject:@"清除聊天记录成功！"
                            waitUntilDone:YES];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"ClearHistoryMsg" object:nil];
         dispatch_async(dispatch_get_main_queue(), ^{
           [loadingView removeFromSuperview];
         });
        
      } error:^(RCErrorCode status) {
        [self performSelectorOnMainThread:@selector(clearCacheAlertMessage:)
                               withObject:@"清除聊天记录失败！"
                            waitUntilDone:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
          [loadingView removeFromSuperview];
        });
      }];
      
    }
  }
  if (actionSheet.tag == 101) {
    if (buttonIndex == 0) {
      [RCDHTTPTOOL
          quitGroupWithGroupId:groupId
                      complete:^(BOOL isOk) {

                        dispatch_async(dispatch_get_main_queue(), ^{
                          if (isOk) {
                            [[RCIMClient sharedRCIMClient]
                                clearMessages:ConversationType_GROUP
                                     targetId:groupId];

                            [[RCIMClient sharedRCIMClient]
                                removeConversation:ConversationType_GROUP
                                          targetId:groupId];

                            [[RCDataBaseManager shareInstance]
                                deleteGroupToDB:groupId];
                            [self.navigationController
                                popToRootViewControllerAnimated:YES];
                          } else {
                            UIAlertView *alertView = [[UIAlertView alloc]
                                    initWithTitle:nil
                                          message:@"退出失败！"
                                         delegate:nil
                                cancelButtonTitle:@"确定"
                                otherButtonTitles:nil, nil];
                            [alertView show];
                          }
                        });
                      }];
    }
  }

  if (actionSheet.tag == 102) {
    if (buttonIndex == 0) {
      [RCDHTTPTOOL
          dismissGroupWithGroupId:groupId
                         complete:^(BOOL isOk) {

                           dispatch_async(dispatch_get_main_queue(), ^{
                             if (isOk) {
                               [[RCIMClient sharedRCIMClient]
                                   clearMessages:ConversationType_GROUP
                                        targetId:groupId];

                               [[RCIMClient sharedRCIMClient]
                                   removeConversation:ConversationType_GROUP
                                             targetId:groupId];
                               [self.navigationController
                                   popToRootViewControllerAnimated:YES];
                             } else {
                               UIAlertView *alertView = [[UIAlertView alloc]
                                       initWithTitle:nil
                                             message:@"解散群组失败！"
                                            delegate:nil
                                   cancelButtonTitle:@"确定"
                                   otherButtonTitles:nil, nil];
                               [alertView show];
                             }
                           });
                         }];
    }
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (numberOfSections > 0) {
    return numberOfSections;
  }
  return 0;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  NSInteger rows;
  switch (section) {
  case 0:
    rows = 1;
    break;

  case 1:
    rows = 3;
    break;

  case 2:
    rows = 3;
    break;

  default:
    break;
  }
  return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCDBaseSettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    static NSString *cellIndeti = @"baseCell";
    RCDBaseSettingTableViewCell *__cell = [tableView dequeueReusableCellWithIdentifier:cellIndeti];
    
    if(!cell){
        cell = [[RCDBaseSettingTableViewCell alloc]init];
    }
    if(!__cell) {
        __cell = [[RCDBaseSettingTableViewCell alloc]initWithLeftImage:nil leftImageSize:CGSizeZero rightImae:[UIImage imageNamed:@"icon_person"] rightImageSize:CGSizeMake(25, 25)];
        __cell.tag = 1000;
    }

    if (indexPath.section == 0) {
        [cell setCellStyle:DefaultStyle];
        cell.leftLabel.text = [NSString stringWithFormat:@"全部群成员(%@)", _Group.number];
    }else if(indexPath.section == 1){
        switch (indexPath.row) {
            case 0:
                [__cell setCellStyle:DefaultStyle];
                __cell.leftLabel.text = @"群组头像";
                if ([_Group.portraitUri isEqualToString:@""]) {
                    DefaultPortraitView *defaultPortrait = [[DefaultPortraitView alloc]
                                                            initWithFrame:CGRectMake(0, 0, 100, 100)];
                    [defaultPortrait setColorAndLabel:groupId Nickname:_Group.groupName];
                    UIImage *portrait = [defaultPortrait imageFromView];
                    __cell.rightImageView.image = portrait;
                } else {
                    [__cell.rightImageView
                     sd_setImageWithURL:[NSURL URLWithString:_Group.portraitUri]
                     placeholderImage:[UIImage imageNamed:@"icon_person"]];
                }
                return __cell;
                break;
            case 1:
                [cell setCellStyle:DefaultStyle_RightLabel];
                cell.leftLabel.text = @"群组名称";
                cell.rightLabel.text = self.Group.groupName;
                break;
            case 2:
                [cell setCellStyle:DefaultStyle];
                cell.leftLabel.text = @"群公告";
                break;
            default:
                break;
        }
    }else {
        switch (indexPath.row) {
            case 0:
                [cell setCellStyle:SwitchStyle];
                cell.leftLabel.text = @"消息免打扰";
                cell.switchButton.on = !enableNotification;
                cell.switchButton.tag = SwitchButtonTag;
                break;
            case 1:
                [cell setCellStyle:SwitchStyle];
                cell.leftLabel.text = @"会话置顶";
                cell.switchButton.on = currentConversation.isTop;
                cell.switchButton.tag = SwitchButtonTag + 1;
                break;
            case 2:
                [cell setCellStyle:DefaultStyle];
                cell.leftLabel.text= @"清除聊天记录";
                break;
            default:
                break;
        }
    }
    
    cell.baseSettingTableViewDelegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return 0;
  }
  return 14.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 44.f;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.section) {
    case 0:{
      RCDGroupMembersTableViewController *GroupMembersVC =
      [[RCDGroupMembersTableViewController alloc] init];
      GroupMembersVC.GroupMembers =_GroupMemberList;
      [self.navigationController pushViewController:GroupMembersVC animated:YES];
    }break;
      
    case 1:{
      switch (indexPath.row) {
        case 0:
        {
          if (isCreator == YES) {
            [self chosePortrait];
          }
          else
          {
            [self showAlert:@"只有群主可以修改群组头像"];
          }
        }break;
         
        case 1:
        {
          if (isCreator == YES) {
              //如果是创建者，进入修改群名称页面
              RCDEditGroupNameViewController *editGroupNameVC = [RCDEditGroupNameViewController editGroupNameViewController];
              editGroupNameVC.groupInfo = _Group;
            _Group = nil;
            [self.navigationController pushViewController:editGroupNameVC
                                                 animated:YES];
          }
          else
          {
            [self showAlert:@"只有群主可以修改群组名称"];
          }
        }break;
         
          case 2:
        {
          if (isCreator == YES) {
            RCDGroupAnnouncementViewController *vc = [[RCDGroupAnnouncementViewController alloc] init];
            vc.GroupId = _Group.groupId;
            [self.navigationController pushViewController:vc animated:YES];
          }
          else
          {
            [self showAlert:@"只有群主可以发布群公告"];
          }
        }break;
          
        default:
          break;
      }
    }break;
      
      case 2:
    {
      switch (indexPath.row) {
        case 2:
        {
          UIActionSheet *actionSheet =
          [[UIActionSheet alloc] initWithTitle:@"确定清除聊天记录？"
                                      delegate:self
                             cancelButtonTitle:@"取消"
                        destructiveButtonTitle:@"确定"
                             otherButtonTitles:nil];
          
          [actionSheet showInView:self.view];
          actionSheet.tag = 100;
        }break;
          
        default:
          break;
      }
    }break;
      
    default:
      break;
  }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  float width = 55;
  float height = width + 15 + 9;

  return CGSizeMake(width, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return 12;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
  UICollectionViewFlowLayout *flowLayout =
      (UICollectionViewFlowLayout *)collectionViewLayout;
  flowLayout.minimumInteritemSpacing = 20;
  flowLayout.minimumLineSpacing = 12;
  return UIEdgeInsetsMake(15, 10, 10, 10);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  return [collectionViewResource count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  RCDConversationSettingTableViewHeaderItem *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:
                          @"RCDConversationSettingTableViewHeaderItem"
                                                forIndexPath:indexPath];
  
  if (collectionViewResource.count > 0) {
    if (indexPath.row == 0) {
    collectionViewResource = [self moveCreator:collectionViewResource];
    }
    if (![collectionViewResource[indexPath.row]
            isKindOfClass:[UIImage class]]) {
      RCUserInfo *user = collectionViewResource[indexPath.row];
      if ([user.userId isEqualToString:[RCIMClient sharedRCIMClient]
                                           .currentUserInfo.userId]) {
        [cell.btnImg setHidden:YES];
      }
      [cell setUserModel:user];
    } else {
      UIImage *Image = collectionViewResource[indexPath.row];
      cell.ivAva.image = nil;
      cell.ivAva.image = Image;
      cell.titleLabel.text = @"";
        
    }
  }
  cell.ivAva.contentMode = UIViewContentModeScaleAspectFill;
  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    RCDContactSelectedTableViewController * contactSelectedVC= [[RCDContactSelectedTableViewController alloc]init];
  contactSelectedVC.groupId = _Group.groupId;
  contactSelectedVC.isAllowsMultipleSelection = YES;
  NSMutableArray *membersId = [NSMutableArray new];
  for (RCUserInfo *user in _GroupMemberList) {
    NSString *userId = user.userId;
    [membersId addObject:userId];
  }
  //判断如果是创建者
  if (isCreator == YES) {
    //点加号
    if (indexPath.row == collectionViewResource.count - 2) {
      contactSelectedVC.titleStr = @"选择联系人";
      contactSelectedVC.addGroupMembers = membersId;
      _Group = nil;
      [self.navigationController pushViewController:contactSelectedVC
                                           animated:YES];
      return;
    }
    //点减号
    if (indexPath.row == collectionViewResource.count - 1) {
      contactSelectedVC.titleStr = @"移除成员";
      NSMutableArray *members = [NSMutableArray new];
      for (RCUserInfo *user in _GroupMemberList) {
        if (![user.userId isEqualToString:creatorId]) {
          [members addObject:user];
        }
      }
      contactSelectedVC.delGroupMembers = members;
      _Group = nil;
      [self.navigationController pushViewController:contactSelectedVC
                                           animated:YES];
      return;
    }
  } else {
    if (indexPath.row == collectionViewResource.count - 1) {
      NSLog(@"点加号");
      contactSelectedVC.titleStr = @"选择联系人";
      contactSelectedVC.addGroupMembers = membersId;
      [self.navigationController pushViewController:contactSelectedVC
                                           animated:YES];
      _Group = nil;
      return;
    }
  }
  RCUserInfo *selectedUser = [_GroupMemberList objectAtIndex:indexPath.row];
  BOOL isFriend = NO;
  NSArray *friendList = [[RCDataBaseManager shareInstance] getAllFriends];
  for (RCDUserInfo *friend in friendList) {
    if ([selectedUser.userId isEqualToString:friend.userId] &&
        [friend.status isEqualToString:@"20"]) {
      isFriend = YES;
    }
  }
  if (isFriend == YES ||
      [selectedUser.userId
          isEqualToString:[RCIM sharedRCIM].currentUserInfo.userId]) {
    UIStoryboard *storyboard =
        [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RCDPersonDetailViewController *detailViewController =
        [storyboard instantiateViewControllerWithIdentifier:
                        @"RCDPersonDetailViewController"];
    [self.navigationController pushViewController:detailViewController
                                         animated:YES];
    RCUserInfo *user = [_GroupMemberList objectAtIndex:indexPath.row];
    detailViewController.userId = user.userId;
  } else {
    UIStoryboard *mainStoryboard =
        [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RCDAddFriendViewController *addViewController = [mainStoryboard
        instantiateViewControllerWithIdentifier:@"RCDAddFriendViewController"];
    addViewController.targetUserInfo =
        [_GroupMemberList objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:addViewController
                                         animated:YES];
  }
}

- (void)addGroupMemberList:(NSNotification *)notify {
  [_GroupMemberList addObjectsFromArray:notify.object];
}

- (void)deleteGroupMemberList:(NSNotification *)notify {
  NSArray *tempArray = notify.object;
  for (RCUserInfo *user in tempArray) {
    [_GroupMemberList removeObject:user];
  }
}

- (void)limitDisplayMemberCount {
  if (isCreator == YES && [collectionViewResource count] > 18) {
    NSRange rang = NSMakeRange(18, [collectionViewResource count] - 18);
    [collectionViewResource removeObjectsInRange:rang];
  } else if ([collectionViewResource count] > 19) {
    NSRange rang = NSMakeRange(19, [collectionViewResource count] - 19);
    [collectionViewResource removeObjectsInRange:rang];
  }
}

-(void)showAlert:(NSString *)alertContent
{
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:alertContent delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
  [alert show];
}

//将创建者挪到第一的位置
-(NSMutableArray *) moveCreator:(NSMutableArray *)GroupMemberList
{
  if (GroupMemberList ==nil || GroupMemberList.count == 0) {
    return nil;
  }
  NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:GroupMemberList];
  int index = 0;
  RCUserInfo *creator;
  for (int i = 0; i < [temp count]; i++) {
    RCUserInfo *user = [temp objectAtIndex:i];
    
    if ([creatorId isEqualToString:user.userId]) {
      index = i;
      creator = user;
      break;
    }
  }
  if (creator == nil) {
    return nil;
      }
  [temp insertObject:creator atIndex:0];
  [temp removeObjectAtIndex:index+1];
  return temp;
}

- (void)setHeaderView
{
  [self limitDisplayMemberCount];
  UIImage *addImage = [UIImage imageNamed:@"add_member"];
  [collectionViewResource addObject:addImage];
  //判断如果是创建者，添加踢人按钮
  if (isCreator == YES) {
    UIImage *delImage = [UIImage imageNamed:@"delete_member"];
    [collectionViewResource addObject:delImage];
  }
  [headerView reloadData];
  headerView.frame = CGRectMake(
                                0, 0, [UIScreen mainScreen].bounds.size.width,
                                headerView.collectionViewLayout.collectionViewContentSize.height);
  CGRect frame = headerView.frame;
  frame.size.height += 14;
  self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:frame];
  self.tableView.tableHeaderView.backgroundColor = [UIColor whiteColor];
  [self.tableView.tableHeaderView addSubview:headerView];
}

#pragma mark - RCDBaseSettingTableViewCellDelegate
- (void)onClickSwitchButton:(id)sender {
    UISwitch *switchBtn = (UISwitch *)sender;
    //如果是“消息免打扰”的switch点击
    if(switchBtn.tag == SwitchButtonTag){
        [self clickNotificationBtn:sender];
    }else { //否则是“会话置顶”的switch点击
        [self clickIsTopBtn:sender];
    }
}
@end