//
//  CustomCollectionView.m
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "CustomCollectionView.h"

@interface CustomCollectionView ()

@property (nonatomic, copy) void (^reloadDataCompletionBlock)(void);

@end

@implementation CustomCollectionView

- (void)reloadDataWithCompletion:(void (^)(void))completionBlock {
    self.reloadDataCompletionBlock = completionBlock;
    [super reloadData];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.reloadDataCompletionBlock) {
        self.reloadDataCompletionBlock();
    }
}

@end
