//
//  File+CoreDataProperties.h
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//
//

#import "File+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface File (CoreDataProperties)

+ (NSFetchRequest<File *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) int64_t size;
@property (nullable, nonatomic, copy) NSDate *createTime;
@property (nullable, nonatomic, copy) NSString *type;

@end

NS_ASSUME_NONNULL_END
