//
//  JxbIMMessage.h
//  JxbIMKit
//
//  Created by Peter on 16/3/11.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JxbIMUser.h"

/**
 *  消息类星
 */
typedef NS_ENUM(NSInteger,JxbIMMsgType) {
    /**
     *  未知
     */
    JxbIM_Unknown = -1,
    /**
     *  文本信息
     */
    JxbIM_Text = 1,
    /**
     *  图片信息
     */
    JxbIM_Image = 2,
    /**
     *  位置消息
     */
    JxbIM_Location = 3,
    /**
     *  语音
     */
    JxbIM_Voice = 4,
    /**
     *  视频
     */
    JxbIM_Video = 5,
    /**
     *  震屏
     */
    JxbIM_Shake = 11,
    /**
     *  正在输入
     */
    JxbIM_Inputing = 21,
    /**
     *  红包
     */
    JxbIM_Money = 91
};

@interface JxbIMMessage : NSObject

//目标用户
@property (nonatomic, strong) JxbIMUser *toUser;

//发送用户
@property (nonatomic, copy  ) NSString  *fromUser;

//消息类型
@property (nonatomic, assign, readonly) JxbIMMsgType    msgType;

//消息内容
@property (nonatomic, copy  ) NSString  *content;

//扩展字段
@property (nonatomic, copy  ) NSString  *extra;

//发送时间
@property (nonatomic, copy  ) NSNumber  *sentTime;


/**
 *  初始化
 *
 *  @param type 消息类型
 *
 *  @return
 */
- (id)initWithType:(JxbIMMsgType)type;
@end
