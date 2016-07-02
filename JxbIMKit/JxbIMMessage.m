//
//  JxbIMMessage.m
//  JxbIMKit
//
//  Created by Peter on 16/3/11.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import "JxbIMMessage.h"

@implementation JxbIMMessage

- (id)initWithType:(JxbIMMsgType)type {
    if (self = [super init]) {
        _msgType = type;
    }
    return self;
}
@end
