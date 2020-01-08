//
//  CustomCollectionView.h
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomCollectionView : UICollectionView

- (void)reloadDataWithCompletion:(void (^)(void))completionBlock;

@end

NS_ASSUME_NONNULL_END
