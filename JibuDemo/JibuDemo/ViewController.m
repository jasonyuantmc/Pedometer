//
//  ViewController.m
//  JibuDemo
//
//  Created by jason on 2016/10/26.
//  Copyright © 2016年 callwan. All rights reserved.
//

#import "ViewController.h"
#import "PedometerManager.h"

#define NUMBER_OF_STEPS @"number_of_steps"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *stepLabel;
@property(nonatomic,strong)NSString * steps;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(getStepsAction:) name:NUMBER_OF_STEPS object:nil];
    PedometerManager * pmManager = [PedometerManager sharedPedometerManager];
    [pmManager getStepCountFrom:[pmManager getCustomDateWithHour:0 Minute:0 Second:0] to:[pmManager getNowDate] CallBack:^(int steps, float distance) {
        
    }];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)getStepsAction:(NSNotification *)notification
{
    _steps = [[notification userInfo]objectForKey:NUMBER_OF_STEPS];
    dispatch_async(dispatch_get_main_queue(), ^{
          _stepLabel.text = _steps;
    });
  
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
