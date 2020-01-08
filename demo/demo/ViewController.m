//
//  ViewController.m
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "ViewController.h"
#import "DocumentListViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)demoButtonClick:(id)sender {
    DocumentListViewController *vc = [DocumentListViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
