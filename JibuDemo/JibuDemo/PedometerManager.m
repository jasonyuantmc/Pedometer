//
//  PedometerManager.m
//  JibuDemo
//
//  Created by jason on 2016/10/26.
//  Copyright © 2016年 callwan. All rights reserved.
//

#import "PedometerManager.h"



@interface PedometerManager ()

@property(nonatomic,strong)NSDate * startDate;
@property(nonatomic,strong)NSDate * endDate;

@end

static PedometerManager * shareManager;
static NSString * steps = @"0";
static NSString * distance = @"0";

@implementation PedometerManager

-(instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

+(PedometerManager *)sharedPedometerManager
{
    static PedometerManager *sharedsharedPedometerrInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedsharedPedometerrInstance = [[PedometerManager alloc] init];
    });
    return sharedsharedPedometerrInstance;
}

-(CMPedometer *)sharePedometer
{
    static CMPedometer *sharedsharedPedometerrInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedsharedPedometerrInstance = [[CMPedometer alloc] init];
    });
    return sharedsharedPedometerrInstance;
}

-(NSString *)getSteps
{
    return steps;
}

-(NSString *)getDistance
{
    return distance;
}

-(void)getStepsAction:(NSNotification *)notification
{
    steps = [[notification userInfo]objectForKey:NUMBER_OF_STEPS];
    distance = [[notification userInfo]objectForKey:NUMBER_OF_DISTANCE];
}

-(void)getStepCountFrom:(NSDate *)fromDate to:(NSDate *)toDate CallBack:(void(^)(int steps,float distance))callBack{
    
    if ([CMPedometer isStepCountingAvailable]) {
        [[self sharePedometer]queryPedometerDataFromDate:fromDate toDate:toDate withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
            if (error) {
                NSLog(@"error====%@",error);
                callBack(0,0);
            }
            else
            {
                //NSLog(@"AAA步数====%@",pedometerData.numberOfSteps);
                //NSLog(@"AAA距离====%@",pedometerData.distance);
                int numberOfSteps = pedometerData.numberOfSteps.intValue;
                float numerOfDistance = pedometerData.distance.floatValue;
                callBack(numberOfSteps,numerOfDistance);
            }
        }];
    }
    else
    {
        NSLog(@"记步功能不可用");
        callBack(0,0);
    }
}

-(void)startStepCountWithCallBack:(void (^)(NSString *steps))callBack
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:STEP_COUNT_STATUS];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if ([CMPedometer isStepCountingAvailable])
    {
        [[self sharePedometer] startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
            if (error)
            {
                [[NSUserDefaults standardUserDefaults]setBool:NO forKey:STEP_COUNT_STATUS];
                [[NSUserDefaults standardUserDefaults]synchronize];
            }
            else
            {
                NSLog(@"%@",pedometerData.numberOfSteps);
                NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@",pedometerData.numberOfSteps],NUMBER_OF_STEPS,[NSString stringWithFormat:@"%@",pedometerData.distance],NUMBER_OF_DISTANCE, nil];
                [[NSUserDefaults standardUserDefaults]setValue:[self getNowDate] forKey:START_DATE];
//                [[NSNotificationCenter defaultCenter]postNotificationName:NUMBER_OF_STEPS object:nil userInfo:dic];
                callBack([NSString stringWithFormat:@"%@",pedometerData.numberOfSteps]);
            }
        }];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:STEP_COUNT_STATUS];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
}

-(void)colseStepCount
{
    if ([CMPedometer isStepCountingAvailable]) {
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:STEP_COUNT_STATUS];
        [[NSUserDefaults standardUserDefaults]synchronize];
        [[self sharePedometer] stopPedometerUpdates];
    }
}

-(NSDate *)getNowDate
{
    NSDate * date = [NSDate date];
    NSInteger interval = [[NSTimeZone systemTimeZone]secondsFromGMTForDate:date];
    return [date dateByAddingTimeInterval:interval];
}

/**
 * @brief 生成当天的某个点（返回的是伦敦时间，可直接与当前时间[NSDate date]比较）
 * @param hour 如hour为“8”，就是上午8:00（本地时间）
 */
- (NSDate *)getCustomDateWithHour:(NSInteger)hour Minute:(NSInteger)minute Second:(NSInteger)second
{
    //获取当前时间
    NSDate *currentDate = [NSDate date];
    NSCalendar *currentCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *currentComps = [[NSDateComponents alloc] init];
    
    NSInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    
    currentComps = [currentCalendar components:unitFlags fromDate:currentDate];
    
    //设置当天的某个点
    NSDateComponents *resultComps = [[NSDateComponents alloc] init];
    [resultComps setYear:[currentComps year]];
    [resultComps setMonth:[currentComps month]];
    [resultComps setDay:[currentComps day]];
    [resultComps setHour:hour];
    [resultComps setMinute:minute];
    [resultComps setSecond:second];
    
    NSCalendar *resultCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate * date = [resultCalendar dateFromComponents:resultComps];
    NSInteger interval = [[NSTimeZone systemTimeZone]secondsFromGMTForDate:date];
    return [date dateByAddingTimeInterval:interval];
}



@end
