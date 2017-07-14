//
//  StepManager.h
//  JibuDemo
//
//  Created by jason on 2016/10/26.
//  Copyright © 2016年 callwan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface StepManager : NSObject

@property(nonatomic)NSInteger step; //步数

+(StepManager *)sharedInstance;

//开始计步
-(void)startRecordStep;

//+(CGFloat)getStepDistance;
//
//+(NSInteger)getStepTime;

@end
