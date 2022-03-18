//
//  PHPhotoLibrary+Custom.h
//  WirelessKUS3
//
//  Created by mrq on 2019/2/20.
//  Copyright © 2019 MrQ. All rights reserved.
//

#import <Photos/Photos.h>

typedef void(^SaveImageCompletion)(NSError* error, NSString* localIdentifier);


@interface PHPhotoLibrary (Custom)

- (void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock;

- (void)saveVideo:(NSURL*)url toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock;

@end

