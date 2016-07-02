//
//  JxbLocationMessage.h
//  JxbIMKit
//
//  Created by Peter on 16/3/14.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import "JxbIMMessage.h"

@interface JxbLocationMessage : JxbIMMessage

//经度
@property (nonatomic, copy ) NSString   *longitude;

//纬度
@property (nonatomic, copy ) NSString   *latitude;

@end
