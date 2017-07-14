//
//  PedometerManager.h
//  JibuDemo
//
//  Created by jason on 2016/10/26.
//  Copyright © 2016年 callwan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

#define STEP_COUNT_STATUS @"step_count_status"
#define NUMBER_OF_STEPS @"number_of_steps"
#define NUMBER_OF_DISTANCE @"number_of_distance"
#define START_DATE @"start_date"

@interface PedometerManager : NSObject

+(PedometerManager *)sharedPedometerManager;

-(CMPedometer *)sharePedometer;


/*
-(void)startStepCountWithCallBack:(void (^)(NSString *steps))callBack;

-(void)colseStepCount;
*/



//某个时间点的date
-(NSDate *)getCustomDateWithHour:(NSInteger)hour Minute:(NSInteger)minute Second:(NSInteger)second;

//现在的系统时间
-(NSDate *)getNowDate;

//获取步数
-(void)getStepCountFrom:(NSDate *)fromDate to:(NSDate *)toDate CallBack:(void(^)(int steps,float distance))callBack;



@end
