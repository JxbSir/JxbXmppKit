//
//  JxbIMKit.h
//  JxbIMKit
//
//  Created by Peter on 16/3/11.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JxbIMDelegate.h"
#import "JxbIMFriend.h"
#import "JxbIMMessage.h"
#import "JxbImageMessage.h"
#import "JxbLocationMessage.h"
#import "JxbIMUser.h"

#define JxbReceivedMessageNotification  @"JxbReceivedMessageNotification"

/**
 *  Log枚举
 */
typedef NS_ENUM(NSInteger, JxbIMLogLevel) {
    /**
     *  错误日志
     */
    JxbIMLogLevel_Eroor = 1,
    /**
     *  警告日志
     */
    JxbIMLogLevel_Warning = 2,
    /**
     *  普通日志
     */
    JxbIMLogLevel_Log = 3
};

typedef void(^JxbIMLoginBlock)(NSError* error);
typedef void(^JxbIMFriendBlock)(NSArray* friends);


@interface JxbIMKit : NSObject

//日志等级
@property (nonatomic, assign) JxbIMLogLevel       logLevel;
@property (nonatomic, copy  ) NSString            *resourceName;
//服务器地址
@property (nonatomic, copy)   NSString            *connectHost;
//用户名
@property (nonatomic, copy,   readonly) NSString  *username;
//用户密码
@property (nonatomic, copy,   readonly) NSString  *password;
//好友列表
@property (nonatomic, strong, readonly) NSArray   *friends;
//登录结果执行块
@property (nonatomic, copy  ) JxbIMLoginBlock     loginBlock;
//获取好友列表执行块
@property (nonatomic, copy  ) JxbIMFriendBlock    friendBlock;

//message代理
@property (nonatomic, weak  ) id<JxbIMDelegate>   messageDelegate;

/**
 *  单例模式
 *
 *  @param serverHost 服务器地址
 *
 *  @return JxbIMKit
 */
+ (instancetype)sharedInstance;

/**
 *  连接IM
 *
 *  @param username         用户名
 *  @param password         密码
 */
-(void)login:(NSString*)username password:(NSString*)password;

/**
 *  断开连接
 *
 *  @param completeBlock    执行代码
 */
- (void)logout:(void (^)(void))completeBlock;

/**
 *  添加好友
 *
 *  @param friendName 目标好友名称
 */
- (void)addFriend:(NSString*)friendName;

/**
 *  发送文本消息
 *
 *  @param msg 消息
 *
 */
- (void)sendTextMessage:(JxbIMMessage*)msg;

/**
 *  发送图片消息
 *
 *  @param msg 消息
 */
- (void)sendImageMessage:(JxbImageMessage*)msg;

/**
 *  发送语音消息
 *
 *  @param msg 消息
 */
- (void)sendVoiceMessage:(JxbIMMessage*)msg;

/**
 *  发送视频消息
 *
 *  @param msg 消息
 */
- (void)sendVideoMessage:(JxbIMMessage*)msg;

/**
 *  发送坐标消息
 *
 *  @param msg 消息
 */
- (void)sendLocationMessage:(JxbLocationMessage*)msg;

/**
 *  发送震屏消息
 *
 *  @param msg 消息
 */
- (void)sendShakeMessage:(JxbIMMessage*)msg;

/**
 *  发送正在输入:使用心跳包发送状态，接收方也使用心跳处理
 */
- (void)sendInputingStatus:(JxbIMMessage*)msg;

@end
