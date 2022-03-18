//
//  PHPhotoLibrary+Custom.m
//  WirelessKUS3
//
//  Created by mrq on 2019/2/20.
//  Copyright © 2019 MrQ. All rights reserved.
//

#import "PHPhotoLibrary+Custom.h"

@implementation PHPhotoLibrary (Custom)

- (void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock
{
    __block NSString *localIdentifier = @"";
    
    NSError *error = nil;
    [self performChangesAndWait:^{
        localIdentifier = [PHAssetChangeRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset.localIdentifier;
    } error:nil];
    
    if (error){
        completionBlock(error,nil);
        return;
    }
    PHFetchResult<PHAsset *> *phAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
    [self performChangesAndWait:^{
        PHAssetCollectionChangeRequest *collectionRequest = [self getCurrentPhotoCollectionWithAlbumName:albumName];
        [collectionRequest insertAssets:phAsset atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    
    if (error) {
        completionBlock(error, nil);
    } else {
        completionBlock(nil, localIdentifier);
    }
}

- (void)saveVideo:(NSURL*)url toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock{
    __block NSString *localIdentifier = @"";
    
    NSError *error = nil;
    [self performChangesAndWait:^{
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
        PHObjectPlaceholder *placeholder = [assetRequest placeholderForCreatedAsset];
        localIdentifier = placeholder.localIdentifier;
    } error:&error];
    
    if (error){
        completionBlock(error,nil);
        return;
    }
    
    PHFetchResult<PHAsset *> *phAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
    [self performChangesAndWait:^{
        PHAssetCollectionChangeRequest *collectionRequest = [self getCurrentPhotoCollectionWithAlbumName:albumName];
        [collectionRequest insertAssets:phAsset atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    
    if (error) {
        completionBlock(error, nil);
    } else {
        completionBlock(nil, localIdentifier);
    }
}

- (PHAssetCollectionChangeRequest *)getCurrentPhotoCollectionWithAlbumName:(NSString *)albumName {
    // 1. 创建搜索集合
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    // 2. 遍历搜索集合并取出对应的相册，返回当前的相册changeRequest
    for (PHAssetCollection *assetCollection in result) {
        if ([assetCollection.localizedTitle containsString:albumName]) {
            PHAssetCollectionChangeRequest *collectionRuquest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
            return collectionRuquest;
        }
    }
    
    // 3. 如果不存在，创建一个名字为albumName的相册changeRequest
    PHAssetCollectionChangeRequest *collectionRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
    return collectionRequest;
}

@end
