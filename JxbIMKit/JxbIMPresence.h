//
//  JxbIMPresence.h
//  JxbIMKit
//
//  Created by Peter on 16/3/14.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *   用户状态
 */
typedef NS_ENUM(NSInteger,JxbPresence) {
    /**
     *  在线：available
     */
    JxbPresence_Online,
    /**
     *  离线：unavailable
     */
    JxbPresence_Offline,
    /**
     *  离开：away
     */
    JxbPresence_Away,
    /**
     *  忙碌：do not disturb
     */
    JxbPresence_Busy
};

@interface JxbIMPresence : NSObject

@end
