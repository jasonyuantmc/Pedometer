//
//  StepManager.m
//  JibuDemo
//
//  Created by jason on 2016/10/26.
//  Copyright © 2016年 callwan. All rights reserved.
//

#import "StepManager.h"

#import "StepModel.h"
#import <CoreMotion/CoreMotion.h>

// 计步器开始计步时间（秒）
#define ACCELERO_START_TIME 2

// 计步器开始计步步数（步）
#define ACCELERO_START_STEP 1

// 数据库存储步数采集间隔（步）
#define DB_STEP_INTERVAL 1


@interface StepManager ()
{
    
    
    NSMutableArray *arrAll;                 // 加速度传感器采集的原始数组
    int record_no_save;
    int record_no;
    NSDate *lastDate;
    
}
@property (nonatomic) NSInteger startStep;                          // 计步器开始步数

@property (nonatomic, retain) NSMutableArray *arrSteps;         // 步数数组
@property (nonatomic, retain) NSMutableArray *arrStepsSave;     // 数据库纪录步数数组

@property (nonatomic) CGFloat gpsDistance;                  // GPS轨迹的移动距离（总计）
@property (nonatomic) CGFloat agoGpsDistance;               // GPS轨迹的移动距离（之前）
@property (nonatomic) CGFloat agoActionDistance;            // 实际运动的移动距离（之前）

@property (nonatomic, retain) NSString *actionId;           // 运动识别ID
@property (nonatomic) CGFloat distance;                     // 运动里程（总计）
@property (nonatomic) NSInteger calorie;                    // 消耗卡路里（总计）
@property (nonatomic) NSInteger second;                     // 运动用时（总计）

@end

@implementation StepManager

static StepManager *sharedManager;
static CMMotionManager *motionManager;

+(StepManager *)sharedInstance
{
    @synchronized (self) {
        if (!sharedManager) {
            sharedManager = [[StepManager alloc]init];
            motionManager = [[CMMotionManager alloc]init];
        }
    }
    return sharedManager;
}

-(void)startRecordStep
{
    if (!motionManager.isAccelerometerAvailable) {
        return;
    }
    else
    {
        motionManager.accelerometerUpdateInterval = 1.0/40;
    }
    [self startAccelerometer];
}

-(void)startAccelerometer
{
    @try {
        //如果不支持陀螺仪，用加速传感
        if (!motionManager.isAccelerometerActive) {
            if (arrAll == nil) {
                arrAll = [[NSMutableArray alloc]init];
            }else
            {
                [arrAll removeAllObjects];
            }
            
            //1.主动获取加速计的数据
            NSOperationQueue * queue = [[NSOperationQueue alloc]init];
            
            [motionManager startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
                if (!motionManager.isAccelerometerActive) {
                    return;
                }
                
                //三个方向加速度值
                double x = accelerometerData.acceleration.x;
                double y = accelerometerData.acceleration.y;
                double z = accelerometerData.acceleration.z;
                //g是一个double值 ,根据它的大小来判断是否计为1步.
                double g = sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2)) - 1;
                
                //保存信息
                StepModel * stepsModel = [[StepModel alloc]init];
                
                stepsModel.date = [NSDate date];
                
                NSDateFormatter * formatter = [[NSDateFormatter alloc]init];
                formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                NSString * timesString = [formatter stringFromDate:stepsModel.date];
                formatter = nil;
                stepsModel.record_time =timesString;
                stepsModel.g = g;
                
                [arrAll addObject:stepsModel];
                
                if (arrAll.count == 10) {
                    //步数缓存
                    NSMutableArray * arrBuffer = [[NSMutableArray alloc]init];
                    arrBuffer = [arrAll copy];
                    [arrAll removeAllObjects];
                    
                    NSMutableArray * arrCaiDian = [[NSMutableArray alloc]init];
                    
                    for (int i = 1; i < arrBuffer.count - 2; i ++) {
                        //如果数组个数大于3,继续,否则跳出循环,用连续的三个点,要判断其振幅是否一样
                        if (![arrBuffer objectAtIndex:i - 1] || ![arrBuffer objectAtIndex:i] || ![arrBuffer objectAtIndex:i + 1]) {
                            continue;
                        }
                        StepModel * bufferPrevious = (StepModel *)[arrBuffer objectAtIndex:i - 1];
                        StepModel * bufferCurrent = (StepModel *)[arrBuffer objectAtIndex:i];
                        StepModel * bufferNext = (StepModel *)[arrBuffer objectAtIndex:i + 1];
                        
                        if (bufferCurrent.g < -0.12 && bufferCurrent.g < bufferPrevious.g && bufferCurrent.g < bufferNext.g) {
                            [arrCaiDian addObject:bufferCurrent];
                        }
                    }
                    
                        
                        //如果没有不符，初始化
                        if (self.arrSteps == nil) {
                            self.arrSteps = [[NSMutableArray alloc]init];
                            self.arrStepsSave = [[NSMutableArray alloc]init];
                        }
                        
                        //踩点过滤
                        for(int j = 0;j <arrCaiDian.count; j++)
                        {
                            StepModel * caidainCurrent = (StepModel *)[arrCaiDian objectAtIndex:j];
                            
                            //如果之前的步数为0，重新开始记录
                            if (self.arrSteps.count == 0) {
                                //
                                lastDate = caidainCurrent.date;
                                
                                //重新开始时，记录No初始化
                                record_no = 1;
                                record_no_save = 1;
                                
                                //运动识别号
                                NSTimeInterval interval = [caidainCurrent.date timeIntervalSince1970];
                                NSNumber * numInter = [[NSNumber alloc]initWithDouble:interval * 1000];
                                long long llInter = numInter.longLongValue;
                                
                                //运动识别id
                                self.actionId = [NSString stringWithFormat:@"%lld",llInter];
                                
                                self.distance = 0.00f;
                                self.second = 0;
                                self.calorie = 0;
                                self.step = 0;
                                
                                self.gpsDistance = 0.00f;
                                self.agoGpsDistance = 0.00f;
                                self.agoActionDistance = 0.00;
                                
                                caidainCurrent.record_no = record_no;
                                caidainCurrent.step = (int)self.step;
                                
                                [self.arrSteps addObject:caidainCurrent];
                                [self.arrStepsSave addObject:caidainCurrent];
                            }
                            else
                            {
                                int intervalCaidain = [caidainCurrent.date timeIntervalSinceDate:lastDate] * 1000;
                                
                                int min = 259;
                                if (intervalCaidain >= min) {
                                    if (motionManager.isAccelerometerActive) {
                                        lastDate =caidainCurrent.date;
                                        
                                        if (intervalCaidain >= ACCELERO_START_TIME * 1000) {
                                            self.startStep = 0;
                                        }
                                        
                                        if (self.startStep < ACCELERO_START_STEP) {
                                            self.startStep ++;
                                            break;
                                        }
                                        else if (self.startStep == ACCELERO_START_STEP) {
                                            self.startStep ++;
                                            // 计步器开始步数
                                            // 运动步数（总计）
                                            self.step = self.step + self.startStep;
                                        }
                                        else {
                                            self.step ++;
                                        }
                                        
                                        //步数在这里
                                        NSLog(@"步数%ld",self.step);
                                        
                                        int intervalMillSecond = [caidainCurrent.date timeIntervalSinceDate:[[self.arrSteps lastObject] date]] * 1000;
                                        if (intervalMillSecond >= 1000) {
                                            
                                            record_no++;
                                            
                                            caidainCurrent.record_no = record_no;
                                            
                                            caidainCurrent.step = (int)self.step;
                                            [self.arrSteps addObject:caidainCurrent];
                                        }
                                        
                                        // 每隔100步保存一条数据（将来插入DB用）
                                        StepModel *arrStepsSaveVHSSteps = (StepModel *)[self.arrStepsSave lastObject];
                                        int intervalStep = caidainCurrent.step - arrStepsSaveVHSSteps.step;
                                        
                                        // DB_STEP_INTERVAL 数据库存储步数采集间隔（步） 100步
                                        if (self.arrStepsSave.count == 1 || intervalStep >= DB_STEP_INTERVAL) {
                                            //保存次数
                                            record_no_save++;
                                            caidainCurrent.record_no = record_no_save;
                                            [self.arrStepsSave addObject:caidainCurrent];
                                            
                                            NSLog(@"---***%ld",self.step);
                                            // 备份当前运动数据至文件中，以备APP异常退出时数据也不会丢失
                                            // [self bkRunningData];
                                        }
                                    }
                                }
                                
                                
                            }
                        }
                }
            }];
            
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception:%@",exception);
        return;
    }
}

@end
