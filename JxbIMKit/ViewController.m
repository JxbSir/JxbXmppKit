//
//  ViewController.m
//  JxbIMKit
//
//  Created by Peter on 16/3/11.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import "ViewController.h"
#import "JxbIMKit.h"

@interface ViewController ()<UIImagePickerControllerDelegate,UIActionSheetDelegate,UINavigationControllerDelegate>
@property (nonatomic, assign) BOOL bConnect;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[JxbIMKit sharedInstance] setResourceName:@"JxbIMKit_Demo"];
    [[JxbIMKit sharedInstance] setConnectHost:@"192.168.1.193"];//127.0.0.1
    [[JxbIMKit sharedInstance] setLogLevel:JxbIMLogLevel_Log];

}


- (void)btnAction:(id)sender {
    __weak typeof (self) wSelf = self;
    if (!self.bConnect) {
        JxbIMLoginBlock loginBlock = ^(NSError *error) {
            if (!error) {
                wSelf.bConnect = YES;
                [wSelf.btn setTitle:@"连接成功，点击断开" forState:UIControlStateNormal];
            }
        };
        
        JxbIMFriendBlock friendBlock = ^(NSArray *friends) {
            for (JxbIMFriend* friend in friends) {
                NSLog(@"%@,%@",friend.jid.user,friend.displayName);
            }
        };
        
        [[JxbIMKit sharedInstance] setLoginBlock:loginBlock];
        [[JxbIMKit sharedInstance] setFriendBlock:friendBlock];
        [[JxbIMKit sharedInstance] login:self.txt1.text password:@"123456"];
    }
    else {
        [[JxbIMKit sharedInstance] logout:^{
            wSelf.bConnect = NO;
            [wSelf.btn setTitle:@"已断开，点击连接" forState:UIControlStateNormal];
        }];
    }
}

- (void)btnAddAction:(id)sender {
    [[JxbIMKit sharedInstance] addFriend:self.txt2.text];
}

- (void)btnSendAction:(id)sender {
    JxbIMMessage* msg = [[JxbIMMessage alloc] init];
    msg.toUser = [JxbIMUser userWithName:self.txt2.text];
    msg.content = @"hi";
    msg.extra = @"hehe";
    [[JxbIMKit sharedInstance] sendTextMessage:msg];
}

- (void)btnShakeAction:(id)sender {
    JxbIMMessage* msg = [[JxbIMMessage alloc] init];
    msg.toUser = [JxbIMUser userWithName:self.txt2.text];
    msg.extra = @"hehe";
    [[JxbIMKit sharedInstance] sendShakeMessage:msg];
}

- (void)btnLocationAction:(id)sender {
    JxbLocationMessage* msg = [[JxbLocationMessage alloc] init];
    msg.toUser = [JxbIMUser userWithName:self.txt2.text];
    msg.longitude = @"123.41323";
    msg.latitude = @"31.12412";
    [[JxbIMKit sharedInstance] sendLocationMessage:msg];
}

- (void)btnInputingAction:(id)sender {
    JxbIMMessage* msg = [[JxbIMMessage alloc] init];
    msg.toUser = [JxbIMUser userWithName:self.txt2.text];
    [[JxbIMKit sharedInstance] sendInputingStatus:msg];
}

- (void)btnImageAction:(id)sender {
    [self showImagePicker:self];
}

- (void)showImagePicker:(UIViewController*)vc {
    NSString* title = @"选照片";
    UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:title delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:@"拍照" otherButtonTitles:@"照片", nil];
    [sheet showInView:vc.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSInteger sourceType = 0;

    switch (buttonIndex) {
        case 2:
            //取消
            //[txtContent becomeFirstResponder];
            return;
            break;
        case 0:
            //相机
            sourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        case 1:
            //相册
            sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        default:
            break;
    }
    
    //跳转到相机或相册页面
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = sourceType;
    imagePickerController.allowsEditing = YES;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
   
    JxbImageMessage* msg = [[JxbImageMessage alloc] init];
    msg.toUser = [JxbIMUser userWithName:self.txt2.text];
    msg.extra = @"hehe";
    msg.image = image;
    [[JxbIMKit sharedInstance] sendImageMessage:msg];

}
@end
