//
//  JxbIMUser.m
//  JxbIMKit
//
//  Created by Peter on 16/3/14.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import "JxbIMUser.h"

@implementation JxbIMUser

+ (JxbIMUser*)userWithName:(NSString*)name {
    JxbIMUser* user = [[JxbIMUser alloc] init];
    user.username= name;
    return user;
}

@end
