//
//  File+CoreDataProperties.m
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//
//

#import "File+CoreDataProperties.h"

@implementation File (CoreDataProperties)

+ (NSFetchRequest<File *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"File"];
}

@dynamic name;
@dynamic size;
@dynamic createTime;
@dynamic type;

@end
