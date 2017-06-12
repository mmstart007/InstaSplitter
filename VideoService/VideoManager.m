

#import "VideoManager.h"

#import <AssetsLibrary/AssetsLibrary.h>

@interface VideoManager()
{
    
}


@end

static int trimIndex = 0;
static int cropIndex = 0;
static int rotateIndex = 0;


@implementation VideoManager

+ (id)shared
{
    static dispatch_once_t oncePredicate;
    static VideoManager *sharedInstance = nil;
    
    dispatch_once(&oncePredicate, ^{
        sharedInstance = [[VideoManager alloc] init];
        [sharedInstance reset];
    });
    return sharedInstance;
}
- (void)reset {
    self.cTime = CMTimeMakeWithSeconds(0, 1);
    self.scale = 1;
    self.videoURL = nil;
    self.videoAsset = nil;
}

+ (void)loadVideo:(NSURL *)videoURL completion:(void(^)(NSURL *outputURL))outputHandler
{
    AVAsset *inputAsset = [AVAsset assetWithURL:videoURL];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    AVMutableCompositionTrack *videoTrack = nil;
    
    AVAssetTrack *assetTrack = [[inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize renderSize = assetTrack.naturalSize;
    //duration
    if(inputAsset != nil)
    {
        //VIDEO TRACK
        videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        NSArray *videoDataSourceArray = [NSArray arrayWithArray:[inputAsset tracksWithMediaType:AVMediaTypeVideo]];
        NSError *error = nil;
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, inputAsset.duration)
                            ofTrack:videoDataSourceArray[0]
                             atTime:kCMTimeZero
                              error:&error];
        if(error)
        {
            NSLog(@"Insertion error: %@", error);
            outputHandler(nil);
            return;
        }
        
        //AUDIO TRACK
        NSArray *arrayAudioDataSources = [NSArray arrayWithArray:[inputAsset tracksWithMediaType:AVMediaTypeAudio]];
        if (arrayAudioDataSources.count > 0)
        {
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            error = nil;
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, inputAsset.duration)
                                ofTrack:arrayAudioDataSources[0]
                                 atTime:kCMTimeZero
                                  error:&error];
            if(error)
            {
                NSLog(@"Insertion error: %@", error);
                outputHandler(nil);
                return;
            }
        }
        
        layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        assetTrack = [[inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        [layerInstruction setTransform:CGAffineTransformConcat(assetTrack.preferredTransform, transform) atTime:kCMTimeZero];
        [layerInstruction setOpacity:1.0 atTime:kCMTimeZero];
    }
    
    AVMutableVideoCompositionInstruction * mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, inputAsset.duration);
    mainInstruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    CGAffineTransform transform = assetTrack.preferredTransform;
    if ((renderSize.width == transform.tx && renderSize.height == transform.ty) ||
        (transform.tx == 0 && transform.ty == 0))
        mainCompositionInst.renderSize = CGSizeMake(renderSize.width, renderSize.height);
    else
        mainCompositionInst.renderSize = CGSizeMake(renderSize.height, renderSize.width);
    
    NSString *videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LoadVideo.m4v"];
    unlink([videoPath UTF8String]);
    NSURL *videoOutputURL = [NSURL fileURLWithPath:videoPath];
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = videoOutputURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.videoComposition = mainCompositionInst;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, inputAsset.duration);
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
     {
         BOOL success = YES;
         switch ([exporter status]) {
             case AVAssetExportSessionStatusCompleted:
                 success = YES;
                 break;
             case AVAssetExportSessionStatusFailed:
                 success = NO;
                 NSLog(@"input videos - failed: %@", [[exporter error] localizedDescription]);
                 break;
             case AVAssetExportSessionStatusCancelled:
                 success = NO;
                 NSLog(@"input videos - canceled");
                 break;
             default:
                 success = NO;
                 break;
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             if (outputHandler == nil)
                 return;
             if (success == YES)
                 outputHandler(videoOutputURL);
             else
                 outputHandler(nil);
         });
     }];
}

+ (AVAssetExportSession *)trimVideo:(NSURL *)videoURL startTime:(CMTime)startTime endTime:(CMTime)endTime completion:(void(^)(NSURL *outputURL))completionHandler
{
    if (videoURL == nil)
    {
        if (completionHandler)
            completionHandler(nil);
        return nil;
    }
    
    AVAsset *videoAsset = [AVURLAsset assetWithURL:videoURL];
    
    if (videoAsset.isExportable == NO)
    {
        NSLog(@"videoAsset.isExportable == NO");
    }
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    AVMutableCompositionTrack *videoTrack = nil;
    
    AVAssetTrack *assetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize renderSize = assetTrack.naturalSize;
    CGAffineTransform transform = assetTrack.preferredTransform;
    if ((renderSize.width == transform.tx && renderSize.height == transform.ty) || (transform.tx == 0 && transform.ty == 0))
        renderSize = CGSizeMake(renderSize.width, renderSize.height);
    else
        renderSize = CGSizeMake(renderSize.height, renderSize.width);
    //duration
    if(videoAsset != nil)
    {
        //VIDEO TRACK
        videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        NSArray *arrayVideoDataSources = [NSArray arrayWithArray:[videoAsset tracksWithMediaType:AVMediaTypeVideo]];
        NSError *error = nil;
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                            ofTrack:arrayVideoDataSources[0]
                             atTime:kCMTimeZero
                              error:&error];
        if(error)
        {
            NSLog(@"Insertion error: %@", error);
            completionHandler(nil);
            return nil;
        }
        
        // AUDIO TRACK
        NSArray *arrayAudioDataSources = [NSArray arrayWithArray:[videoAsset tracksWithMediaType:AVMediaTypeAudio]];
        if (arrayAudioDataSources.count > 0)
        {
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            error = nil;
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                ofTrack:arrayAudioDataSources[0]
                                 atTime:kCMTimeZero
                                  error:&error];
            if(error)
            {
                NSLog(@"Insertion error: %@", error);
                completionHandler(nil);
                return nil;
            }
        }
        
        layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        assetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        CGAffineTransform transform = CGAffineTransformIdentity;

        if(assetTrack.preferredTransform.a < 0 && assetTrack.preferredTransform.d < 0)
            transform = CGAffineTransformTranslate(CGAffineTransformIdentity, renderSize.width, renderSize.height);
        else if(assetTrack.preferredTransform.b > 0 && assetTrack.preferredTransform.c < 0)
            transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, renderSize.width);
        else if(assetTrack.preferredTransform.b < 0 && assetTrack.preferredTransform.c > 0)
            transform = CGAffineTransformTranslate(CGAffineTransformIdentity, renderSize.height, 0);
        
        [layerInstruction setTransform:CGAffineTransformConcat(assetTrack.preferredTransform, transform) atTime:kCMTimeZero];
        [layerInstruction setOpacity:1.0 atTime:kCMTimeZero];
        
        CGAffineTransform temp = CGAffineTransformConcat(assetTrack.preferredTransform, transform);
        NSLog(@"CGAffineTransform: a=%f, b=%f, c=%f, d=%f, tx=%f, ty=%f", assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx, assetTrack.preferredTransform.ty);
        NSLog(@"CGAffineTransform SetTransform: a=%f, b=%f, c=%f, d=%f, tx=%f, ty=%f", temp.a, temp.b, temp.c, temp.d, temp.tx, temp.ty);
        NSLog(@"Render Size: width=%f, height=%f", renderSize.width, renderSize.height);
    }
    
    AVMutableVideoCompositionInstruction * mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    mainInstruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = renderSize;
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"videotrim_%d.m4v", trimIndex]];
    trimIndex += 1;
    unlink([path UTF8String]);
    NSURL *videoOutputURL = [NSURL fileURLWithPath:path];
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = videoOutputURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.videoComposition = mainCompositionInst;
    CMTime duration = CMTimeMake(endTime.value - startTime.value, startTime.timescale);
    exporter.timeRange = CMTimeRangeMake(startTime, duration);
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
    {
         BOOL success = YES;
         switch ([exporter status]) {
             case AVAssetExportSessionStatusCompleted:
                 success = YES;
                 break;
             case AVAssetExportSessionStatusFailed:
                 success = NO;
                 NSLog(@"input videos - failed: %@", [[exporter error] localizedDescription]);
                 break;
             case AVAssetExportSessionStatusCancelled:
                 success = NO;
                 NSLog(@"input videos - canceled");
                 break;
             default:
                 success = NO;
                 break;
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             if (completionHandler == nil)
                 return;
             if (success == YES)
                 completionHandler(videoOutputURL);
             else
                 completionHandler(nil);
         });
     }];
    
    return exporter;
}

+ (void)saveURL:(NSURL *)videoURL
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:videoURL]) {
        [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
            });
        }];
    }
}

+ (BOOL)isPortrait:(NSURL *)videoURL
{
    AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    AVAssetTrack *assetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize naturalSize = assetTrack.naturalSize;
    CGAffineTransform transform = assetTrack.preferredTransform;
    if ((naturalSize.width == transform.tx && naturalSize.height == transform.ty) || (transform.tx == 0 && transform.ty == 0))
        naturalSize = CGSizeMake(naturalSize.width, naturalSize.height);
    else
        naturalSize = CGSizeMake(naturalSize.height, naturalSize.width);
    
    return naturalSize.width <= naturalSize.height;
}

+ (AVAssetExportSession *)rotateVideo:(NSURL *)videoURL count: (NSInteger)count completion:(void(^)(NSURL *outputURL))completionHandler
{
    if (videoURL == nil)
    {
        if (completionHandler)
            completionHandler(nil);
        return nil;
    }
    if(count == 0) {
        completionHandler(videoURL);
        return nil;
    }
    
    AVAsset *videoAsset = [AVURLAsset assetWithURL:videoURL];
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    AVMutableCompositionTrack *videoTrack = nil;
    
    AVAssetTrack *assetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize renderSize = assetTrack.naturalSize;
    CGAffineTransform transform = assetTrack.preferredTransform;
    if ((renderSize.width == transform.tx && renderSize.height == transform.ty) || (transform.tx == 0 && transform.ty == 0))
        renderSize = CGSizeMake(renderSize.width, renderSize.height);
    else
        renderSize = CGSizeMake(renderSize.height, renderSize.width);
    
    if(count == 1 || count == 3) {
        renderSize = CGSizeMake(renderSize.height, renderSize.width);
    }
    
    //duration
    if(videoAsset != nil)
    {
        //VIDEO TRACK
        videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        NSArray *arrayVideoDataSources = [NSArray arrayWithArray:[videoAsset tracksWithMediaType:AVMediaTypeVideo]];
        NSError *error = nil;
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                            ofTrack:arrayVideoDataSources[0]
                             atTime:kCMTimeZero
                              error:&error];
        if(error)
        {
            NSLog(@"Insertion error: %@", error);
            completionHandler(nil);
            return nil;
        }
        
        // AUDIO TRACK
        NSArray *arrayAudioDataSources = [NSArray arrayWithArray:[videoAsset tracksWithMediaType:AVMediaTypeAudio]];
        if (arrayAudioDataSources.count > 0)
        {
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            error = nil;
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                ofTrack:arrayAudioDataSources[0]
                                 atTime:kCMTimeZero
                                  error:&error];
            if(error)
            {
                NSLog(@"Insertion error: %@", error);
                completionHandler(nil);
                return nil;
            }
        }
        
        layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        assetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        
        if(assetTrack.preferredTransform.a < 0 && assetTrack.preferredTransform.d < 0)
            transform = CGAffineTransformTranslate(CGAffineTransformIdentity, renderSize.width, renderSize.height);
        else if(assetTrack.preferredTransform.b > 0 && assetTrack.preferredTransform.c < 0)
            transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, renderSize.width);
        else if(assetTrack.preferredTransform.b < 0 && assetTrack.preferredTransform.c > 0)
            transform = CGAffineTransformTranslate(CGAffineTransformIdentity, renderSize.height, 0);
        [layerInstruction setTransform:CGAffineTransformConcat(assetTrack.preferredTransform, transform) atTime:kCMTimeZero];
        [layerInstruction setOpacity:1.0 atTime:kCMTimeZero];
        transform = CGAffineTransformIdentity;
        
        if(count == 1) {
            transform = CGAffineTransformRotate(transform, M_PI_2);
            transform = CGAffineTransformTranslate(transform, 0, -renderSize.width);
        }else if(count == 2){
            transform = CGAffineTransformRotate(transform, M_PI);
            transform = CGAffineTransformTranslate(transform, -renderSize.width, -renderSize.height);
        }else if(count == 3){
            transform = CGAffineTransformRotate(transform, M_PI_2 * 3);
            transform = CGAffineTransformTranslate(transform, -renderSize.height, 0);
        }
        
        
        [layerInstruction setTransform:CGAffineTransformConcat(assetTrack.preferredTransform, transform) atTime:kCMTimeZero];
        [layerInstruction setOpacity:1.0 atTime:kCMTimeZero];
    }
    
    AVMutableVideoCompositionInstruction * mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    mainInstruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = renderSize;
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"videorotate_%d.m4v", trimIndex]];
    trimIndex += 1;
    unlink([path UTF8String]);
    NSURL *videoOutputURL = [NSURL fileURLWithPath:path];
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = videoOutputURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.videoComposition = mainCompositionInst;
    CMTime duration = videoAsset.duration;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, duration);
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
     {
         BOOL success = YES;
         switch ([exporter status]) {
             case AVAssetExportSessionStatusCompleted:
                 success = YES;
                 break;
             case AVAssetExportSessionStatusFailed:
                 success = NO;
                 NSLog(@"input videos - failed: %@", [[exporter error] localizedDescription]);
                 break;
             case AVAssetExportSessionStatusCancelled:
                 success = NO;
                 NSLog(@"input videos - canceled");
                 break;
             default:
                 success = NO;
                 break;
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             if (completionHandler == nil)
                 return;
             if (success == YES)
                 completionHandler(videoOutputURL);
             else
                 completionHandler(nil);
         });
     }];
    
    return exporter;
}

@end
