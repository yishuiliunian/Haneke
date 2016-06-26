//
//  HNKNetworkFetcher.m
//  Haneke
//
//  Created by Hermes Pique on 7/23/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "HNKNetworkFetcher.h"
#import <SDWebImage/SDWebImageManager.h>
@implementation HNKNetworkFetcher {
    NSURL *_URL;
    BOOL _cancelled;
    id<SDWebImageOperation> _downloadOperation;
}

- (instancetype)initWithURL:(NSURL*)URL
{
    if (self = [super init])
    {
        _URL = URL;
    }
    return self;
}

- (NSString*)key
{
    return _URL.absoluteString;
}

- (void)fetchImageWithSuccess:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;
{
    
    _cancelled = NO;
    __weak __typeof__(self) weakSelf = self;
    
   _downloadOperation = [[SDWebImageManager sharedManager] downloadImageWithURL:_URL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (strongSelf->_cancelled) return;
        
        if (!image)
        {
            NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Failed to load image from data at URL %@", @""), imageURL];
            [strongSelf failWithLocalizedDescription:errorDescription code:HNKErrorNetworkFetcherInvalidData block:failureBlock];
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(image);
        });
 
    }];
}

- (void)cancelFetch
{
    [_downloadOperation cancel];
    _cancelled = YES;
}

- (void)dealloc
{
    [self cancelFetch];
}

#pragma mark Private

- (void)failWithLocalizedDescription:(NSString*)localizedDescription code:(NSInteger)code block:(void (^)(NSError *error))failureBlock;
{
    HanekeLog(@"%@", localizedDescription);
    if (!failureBlock) return;

    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : localizedDescription , NSURLErrorKey : _URL?_URL:@""};
    NSError *error = [NSError errorWithDomain:HNKErrorDomain code:code userInfo:userInfo];
    dispatch_async(dispatch_get_main_queue(), ^{
        failureBlock(error);
    });
}

@end

@implementation HNKNetworkFetcher(Subclassing)

- (NSURLSession*)URLSession
{
    return [NSURLSession sharedSession];
}

@end
