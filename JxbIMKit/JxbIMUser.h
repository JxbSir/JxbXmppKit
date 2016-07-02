//
//  JxbIMUser.h
//  JxbIMKit
//
//  Created by Peter on 16/3/14.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JxbIMUser : NSObject

//用户名
@property (nonatomic, copy  ) NSString  *username;

+ (JxbIMUser*)userWithName:(NSString*)name;

@end
