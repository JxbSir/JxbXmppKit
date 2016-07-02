//
//  JxbIMKit.m
//  JxbIMKit
//
//  Created by Peter on 16/3/11.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import "JxbIMKit.h"

#import "XMPPFramework.h"
#import "XMPPReconnect.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPRoster.h"

#define xmppLongitude   @"lng"
#define xmppLatitude    @"lat"
#define xmppResource    @"JxbIMKit_iOS"

#define JxbLog(level, frmt, ...) if (self.logLevel>=level) {                                                           \
                NSString * description = [NSString stringWithFormat:frmt, ##__VA_ARGS__]; \
                NSLog(@"%@", description); }

@interface JxbIMKit()<NSFetchedResultsControllerDelegate>
@property (nonatomic, copy)   NSString      *domainHost;
@property (nonatomic, strong) XMPPStream    *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster    *xmppRoster;
@property (nonatomic, strong) NSManagedObjectContext    *xmppManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext    *xmppRosterManagedObjectContext;

@property (nonatomic, strong) NSFetchedResultsController    *fetchFriends;

@property (nonatomic, strong) dispatch_queue_t          queueSend;
@end

@implementation JxbIMKit

#pragma mark - 单例
+ (instancetype)sharedInstance {
    static JxbIMKit* kit;
    static dispatch_once_t  once;
    dispatch_once(&once, ^{
        kit = [[JxbIMKit alloc] init];
    });
    return kit;
}

#pragma mark - 初始化
- (id)init {
    if (self == [super init]) {
        self.domainHost = @"127.0.0.1";
        self.resourceName = xmppResource;
        //创建发送消息队列
        self.queueSend = dispatch_queue_create("Jxb_Msg_Send_Queue", nil);
        //创建xmppstream
        self.xmppStream = [[XMPPStream alloc]init];
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        //创建重写连接组件
        self.xmppReconnect= [[XMPPReconnect alloc] init];
        //使组件生效
        [self.xmppReconnect activate:self.xmppStream];
        
        //创建消息保存策略（规则，规定）
        XMPPMessageArchivingCoreDataStorage* messageStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
        //用消息保存策略创建消息保存组件
        XMPPMessageArchiving* xmppMessageArchiving = [[XMPPMessageArchiving alloc]initWithMessageArchivingStorage:messageStorage];
        //使组件生效
        [xmppMessageArchiving activate:self.xmppStream];
        //提取消息保存组件的coreData上下文
        self.xmppManagedObjectContext = messageStorage.mainThreadManagedObjectContext;
        
        XMPPRosterCoreDataStorage* xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
        self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
        //自动获取用户列表
        self.xmppRoster.autoFetchRoster = YES;
        self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
        [self.xmppRoster activate:self.xmppStream];
        self.xmppRosterManagedObjectContext = xmppRosterStorage.mainThreadManagedObjectContext;
    }
    return self;
}

#pragma mark - setter
- (void)setFriends:(NSArray *)friends {
    _friends = friends;
}

#pragma mark - 连接服务器
-(void)login:(NSString *)username password:(NSString *)password {
    if (!username || username.length == 0 || !password || password.length == 0) {
        if (self.loginBlock != NULL) {
            NSError* error = [NSError errorWithDomain:@"JxbIMKit" code:-1 userInfo:@{@"msg":@"username or password is empty!"}];
            JxbLog(JxbIMLogLevel_Eroor,@"连接失败:%@",error);
            self.loginBlock(error);
        }
        return;
    }
    _username = username;
    _password = password;
    XMPPJID *jid = [XMPPJID jidWithUser:username domain:self.connectHost resource:self.resourceName];
    //2.把JID添加到xmppSteam中
    [self.xmppStream setMyJID:jid];
    //连接服务器
   
    __weak typeof (self) wSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSError *error = nil;
        [wSelf.xmppStream connectWithTimeout:10 error:&error];
    });
}

-(void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    if (error && self.loginBlock != NULL) {
        JxbLog(JxbIMLogLevel_Eroor,@"连接失败:%@",error);
        self.loginBlock(error);
    }
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    NSError *error = nil;
    [self.xmppStream authenticateWithPassword:self.password error:&error];
    if (error) {
        [sender disconnect];
        JxbLog(JxbIMLogLevel_Eroor,@"认证错误：%@",[error localizedDescription]);
        if (self.loginBlock != NULL) {
            self.loginBlock(error);
        }
    }
}

-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    JxbLog(JxbIMLogLevel_Log, @"登录成功！");
    //设置此用户在线
    [self.xmppStream sendElement:[XMPPPresence presenceWithType:@"available"]];
    if (self.loginBlock != NULL) {
        self.loginBlock(nil);
    }
    
    //获取好友列表，延时1s，否则无法获取
    __weak typeof (self) wSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        NSArray* list = [wSelf getMyFriends];
        [wSelf setFriends:list];
        if (wSelf.friendBlock != NULL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                wSelf.friendBlock(wSelf.friends);
            });
        }
    });
}

-(void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error {
    JxbLog(JxbIMLogLevel_Eroor,@"验证失败:%@",error);
    [sender disconnect];
}


#pragma mark - 断开连接
- (void)logout:(void (^)(void))completeBlock {
    JxbLog(JxbIMLogLevel_Log, @"用户断开了！");
    _username = nil;
    _password = nil;
    XMPPPresence *presene = [XMPPPresence presenceWithType:@"unavailable"];
    //设置下线状态
    [self.xmppStream sendElement:presene];
    //2.断开连接
    [self.xmppStream disconnect];
    if (completeBlock != NULL) {
        completeBlock();
    }
}

#pragma mark - 获取好友列表
//获取好友列表
-(NSArray*)getMyFriends {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"XMPPUserCoreDataStorageObject"];
    //筛选本用户的好友
    NSString *userinfo = [NSString stringWithFormat:@"%@@%@",self.username,self.domainHost];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr like %@" ,userinfo];
    request.predicate = predicate;
    //排序
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
    request.sortDescriptors = @[sort];
    
    self.fetchFriends = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.xmppRosterManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
    self.fetchFriends.delegate = self;
    NSError *error;
    [self.fetchFriends performFetch:&error];
    
    //返回的数组是XMPPUserCoreDataStorageObject  *obj类型的
    //名称为 obj.displayName
    JxbLog(JxbIMLogLevel_Log, @"获取到好友个数：%lu",(unsigned long)self.fetchFriends.fetchedObjects.count);
    return self.fetchFriends.fetchedObjects;
}

#pragma mark - 好友添加
//添加好友
-(void)addFriend:(NSString*)friendName {
    XMPPJID *friendJid = [XMPPJID jidWithUser:friendName domain:self.domainHost resource:self.resourceName];
    [self.xmppRoster subscribePresenceToUser:friendJid];
}

////删除好友
//-(BOOL)deleteFriend:(NSString*)friendName {
//    XMPPJID * friendJid = [XMPPJID jidWithString:[NSString stringWithFormat:@%@@%@,friendName,self.domain]];
//    [self.rosterModule removeUser:friendJid];
//    return  YES;
//    
//}

//收到好友请求 代理函数
-(void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence {
    NSString * presenceType = [presence type];
    JxbLog(JxbIMLogLevel_Log,@"presenceType = %@",presenceType);
    XMPPJID * fromJid = presence.from;
    if ([presenceType isEqualToString:@"subscribe"]) {//是订阅请求  直接通过
        [self.xmppRoster acceptPresenceSubscriptionRequestFrom:fromJid andAddToRoster:YES];
    }
}

-(void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(DDXMLElement *)item {
    NSString *subscription = [item attributeStringValueForName:@"subscription"];
    JxbLog(JxbIMLogLevel_Log,@"%@",subscription);
    if ([subscription isEqualToString:@"both"]) {
        JxbLog(JxbIMLogLevel_Log,@"双方成为好友！");
    }
}

#pragma mark - 消息接收
- (void)xmppStream:(XMPPStream *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error {
    //TODO:
}


- (void)xmppStream:(XMPPStream *)sender didSendPresence:(XMPPPresence *)presence {
    //TODO:
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
    //TODO:
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error {
    if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(failedSendMessage:)]) {
        JxbIMMessage* msg = [self convertXmppmsgToJxbMsg:message];
        [self.messageDelegate failedSendMessage:msg];
    }
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
    if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(failedSendMessage:)]) {
        JxbIMMessage* msg = [self convertXmppmsgToJxbMsg:message];
        [self.messageDelegate didSendMessage:msg];
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    JxbIMMessage* msg = [self convertXmppmsgToJxbMsg:message];
    [[NSNotificationCenter defaultCenter] postNotificationName:JxbReceivedMessageNotification object:msg];
}

- (JxbIMMessage*)convertXmppmsgToJxbMsg:(XMPPMessage*)message {
    NSInteger type = [[[message attributeForName:@"msgtype"] stringValue] integerValue];
    JxbIMMessage* msg = nil;
    switch (type) {
        case JxbIM_Text: {
            msg = [[JxbIMMessage alloc] initWithType:type];
            msg.content = [[message elementForName:@"body"] stringValue];
            JxbLog(JxbIMLogLevel_Log, @"收到文本：%@",msg.content);
            break;
        }
        case JxbIM_Image: {
            msg = [[JxbImageMessage alloc] initWithType:type];
            NSString* baseString = [[message elementForName:@"body"] stringValue];
            NSData* data = [[NSData alloc] initWithBase64EncodedString:baseString options:NSDataBase64DecodingIgnoreUnknownCharacters];
            ((JxbImageMessage*)msg).image = [UIImage imageWithData:data];
            JxbLog(JxbIMLogLevel_Log, @"收到图片");
            break;
        }
        case JxbIM_Location: {
            NSString* lat = [[message elementForName:xmppLatitude] stringValue];
            NSString* lng = [[message elementForName:xmppLongitude] stringValue];
            msg = [[JxbLocationMessage alloc] initWithType:type];
            ((JxbLocationMessage*)msg).latitude = lat;
            ((JxbLocationMessage*)msg).longitude = lng;
            JxbLog(JxbIMLogLevel_Log, @"收到坐标：经度：%@，纬度：%@",lng,lat);
            break;
        }
        case JxbIM_Voice: {
            JxbLog(JxbIMLogLevel_Log, @"收到语音");
            break;
        }
        case JxbIM_Video: {
            JxbLog(JxbIMLogLevel_Log, @"收到视频");
            break;
        }
        case JxbIM_Shake: {
            msg = [[JxbIMMessage alloc] initWithType:type];
            JxbLog(JxbIMLogLevel_Log, @"收到震屏");
            break;
        }
        case JxbIM_Inputing: {
            msg = [[JxbIMMessage alloc] initWithType:type];
            JxbLog(JxbIMLogLevel_Log, @"对方正在输入");
            break;
        }
        case JxbIM_Money: {
            msg = [[JxbIMMessage alloc] initWithType:type];
            JxbLog(JxbIMLogLevel_Warning, @"收到红包[暂未支持]");
            break;
        }
        default: {
            msg = [[JxbIMMessage alloc] initWithType:JxbIM_Unknown];
            break;
        }
    }
    return msg;
}

#pragma mark - 消息发送
- (BOOL)willSendMessage:(JxbIMMessage*)msg {
    BOOL bCanSend = YES;
    if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(willSendMessage:)]) {
        bCanSend = [self.messageDelegate willSendMessage:msg];
    }
    return bCanSend;
}

- (XMPPMessage*)buildMessage:(NSString*)toUser extra:(NSString*)extra {
    if (toUser.length == 0) {
        JxbLog(JxbIMLogLevel_Eroor, @"接收用户不能为空");
        return nil;
    }
    XMPPMessage * message = [[XMPPMessage alloc] initWithType:@"chat"];
    [message addAttributeWithName:@"from" stringValue:[NSString stringWithFormat:@"%@@%@/%@",self.username,self.domainHost,self.resourceName]];
    [message addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"%@@%@/%@",toUser,self.domainHost,self.resourceName]];
    
    NSXMLElement *timeElement = [NSXMLElement elementWithName:@"sentTime" stringValue:[NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]]];
    [message addChild:timeElement];
    
    if (extra.length > 0) {
        NSXMLElement *extraElement = [NSXMLElement elementWithName:@"extra" stringValue:extra];
        [message addChild:extraElement];
    }
    return message;
}

- (void)sendTextMessage:(JxbIMMessage*)msg {
    if (![self willSendMessage:msg]) {
        return ;
    }
    __weak typeof (self) wSelf = self;
    dispatch_async(self.queueSend, ^{
        XMPPMessage * message = [wSelf buildMessage:msg.toUser.username extra:msg.extra];
        [message addBody:msg.content];
        [message addAttributeWithName:@"msgtype" integerValue:JxbIM_Text];
        [wSelf.xmppStream sendElement:message];
    });
}

- (void)sendImageMessage:(JxbImageMessage*)msg {
    if (![self willSendMessage:msg]) {
        return ;
    }
    __weak typeof (self) wSelf = self;
    dispatch_async(self.queueSend, ^{
        NSString* base64String = [UIImageJPEGRepresentation(msg.image, 1) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        XMPPMessage * message = [wSelf buildMessage:msg.toUser.username extra:msg.extra];
        [message addBody:base64String];
        [message addAttributeWithName:@"msgtype" integerValue:JxbIM_Image];
        [wSelf.xmppStream sendElement:message];
    });
}

- (void)sendVoiceMessage:(JxbIMMessage*)msg {
    if (![self willSendMessage:msg]) {
        return ;
    }
    __weak typeof (self) wSelf = self;
    dispatch_async(self.queueSend, ^{
        //TODO: 发送语音
        XMPPMessage * message = [wSelf buildMessage:msg.toUser.username extra:msg.extra];
        [message addAttributeWithName:@"msgtype" integerValue:JxbIM_Voice];
        [wSelf.xmppStream sendElement:message];
    });
}

- (void)sendVideoMessage:(JxbIMMessage*)msg {
    if (![self willSendMessage:msg]) {
        return ;
    }
    __weak typeof (self) wSelf = self;
    dispatch_async(self.queueSend, ^{
        //TODO: 发送视频
        XMPPMessage * message = [wSelf buildMessage:msg.toUser.username extra:msg.extra];
        [message addAttributeWithName:@"msgtype" integerValue:JxbIM_Video];
        [wSelf.xmppStream sendElement:message];
    });
}

- (void)sendLocationMessage:(JxbLocationMessage*)msg {
    if (![self willSendMessage:msg]) {
        return ;
    }
    __weak typeof (self) wSelf = self;
    dispatch_async(self.queueSend, ^{
        XMPPMessage * message = [wSelf buildMessage:msg.toUser.username extra:msg.extra];
        NSXMLElement *lngElement = [NSXMLElement elementWithName:xmppLongitude stringValue:msg.longitude];
        [message addChild:lngElement];
        NSXMLElement *latElement = [NSXMLElement elementWithName:xmppLatitude stringValue:msg.latitude];
        [message addChild:latElement];
        [message addAttributeWithName:@"msgtype" integerValue:JxbIM_Location];
        [wSelf.xmppStream sendElement:message];
    });
}

- (void)sendShakeMessage:(JxbIMMessage*)msg {
    if (![self willSendMessage:msg]) {
        return ;
    }
    __weak typeof (self) wSelf = self;
    dispatch_async(self.queueSend, ^{
        XMPPMessage * message = [wSelf buildMessage:msg.toUser.username extra:msg.extra];
        [message addAttributeWithName:@"msgtype" integerValue:JxbIM_Shake];
        [wSelf.xmppStream sendElement:message];
    });
}

- (void)sendInputingStatus:(JxbIMMessage*)msg {
    __weak typeof (self) wSelf = self;
    dispatch_async(self.queueSend, ^{
        XMPPMessage * message = [wSelf buildMessage:msg.toUser.username extra:msg.extra];
        [message addAttributeWithName:@"msgtype" integerValue:JxbIM_Inputing];
        [wSelf.xmppStream sendElement:message];
    });
}

@end
