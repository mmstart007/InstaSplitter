
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface VideoManager : NSObject


@property (nonatomic, retain) NSURL *videoURL;
@property (nonatomic, assign) CMTime cTime;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, retain) AVAsset *videoAsset;

+ (VideoManager *)shared;


+ (void)loadVideo:(NSURL *)videoURL completion:(void(^)(NSURL *outputURL))outputHandler;
+ (AVAssetExportSession *)trimVideo:(NSURL *)videoURL startTime:(CMTime)startTime endTime:(CMTime)endTime completion:(void(^)(NSURL *outputURL))completionHandler;
+ (void)saveURL:(NSURL *)videoURL;
+ (BOOL)isPortrait:(NSURL *)videoURL;

+ (AVAssetExportSession *)rotateVideo:(NSURL *)videoURL count: (NSInteger)count completion:(void(^)(NSURL *outputURL))outputHandler;
+ (void) compressVideo : (NSURL *)videoURL completion:(void(^)(NSURL *outputURL)) completionHandler;

@end
