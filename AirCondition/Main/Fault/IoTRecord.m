/**
 * IoTRecord.m
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "IoTRecord.h"

static IoTRecord *database = nil;

@interface IoTRecord()

@property (nonatomic, strong) NSMutableArray *list;

@end

@implementation IoTRecord

+ (instancetype)sharedInstance
{
    if(nil == database)
        database = [[IoTRecord alloc] init];
    return database;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        //读取保存过的列表
        self.list = [NSMutableArray array];
    }
    return self;
}

- (void)addRecord:(NSDate *)dateTime information:(NSString *)info
{
    [self.list addObject:@{@"dateTime": dateTime, @"information": info}];
}

- (void)clearAllRecord
{
    [self.list removeAllObjects];
}

- (NSArray *)recordedList
{
    return [NSArray arrayWithArray:self.list];
}

- (NSInteger)recordedCount
{
    return self.list.count;
}

@end
