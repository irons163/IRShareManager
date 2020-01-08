//
//  DocumentTableViewCell.h
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "File+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface DocumentTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIView *InfoView;
@property (strong, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *fileSizeLabel;
@property (strong, nonatomic) IBOutlet UILabel *createDateLabel;

@property (nonatomic) id delegate;
@property (strong, nonatomic) File *file;
@property (strong, nonatomic) NSOperation *operation;

@end

NS_ASSUME_NONNULL_END
