//
//  ViewController.h
//  JxbIMKit
//
//  Created by Peter on 16/3/11.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (nonatomic, strong)  IBOutlet UIButton   *btn;
@property (nonatomic, strong)  IBOutlet UITextField   *txt1;
@property (nonatomic, strong)  IBOutlet UITextField   *txt2;


- (IBAction)btnAction:(id)sender;

- (IBAction)btnAddAction:(id)sender;
- (IBAction)btnSendAction:(id)sender;
- (IBAction)btnImageAction:(id)sender;
- (IBAction)btnLocationAction:(id)sender;
- (IBAction)btnShakeAction:(id)sender;
- (IBAction)btnInputingAction:(id)sender;
@end

