//
//  JxbIMDelegate.h
//  JxbIMKit
//
//  Created by Peter on 16/3/14.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import "JxbIMMessage.h"

@protocol JxbIMDelegate <NSObject>

/**
 *  即将发送消息
 *
 *  @param msg 发送的消息
 *
 *  @return 若返回false，则此消息不会发送
 */
- (BOOL)willSendMessage:(JxbIMMessage*)msg;

/**
 *  已经将将消息发送出去
 *
 *  @param msg 发送的消息
 */
- (void)didSendMessage:(JxbIMMessage*)msg;

/**
 *  发送消息失败
 *
 *  @param msg 发送的消息
 */
- (void)failedSendMessage:(JxbIMMessage*)msg;
@end
