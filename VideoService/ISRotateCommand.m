

#import "ISRotateCommand.h"

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (180.0 * x / M_PI)

@implementation ISRotateCommand

- (void)performWithAsset:(AVAsset*)asset andRotate:(float)degrees
{
    AVMutableVideoCompositionInstruction *instruction;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    CGAffineTransform t1;
    CGAffineTransform t2;
    
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    }
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    }
    CMTime insertionPoint = kCMTimeInvalid;
    NSError *error = nil;
    
    
    // Step 1
    // Create a new composition
    if (!self.mutableComposition) {
        
        // Check whether a composition has already been created, i.e, some other tool has already been applied
        // Create a new composition
        self.mutableComposition = [AVMutableComposition composition];
        
        // Insert the video and audio tracks from AVAsset
        if (assetVideoTrack != nil) {
            AVMutableCompositionTrack *compositionVideoTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
        }
        if (assetAudioTrack != nil) {
            AVMutableCompositionTrack *compositionAudioTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
        }
        
    }
    
    // Step 2
    // Calculate position and size of render video after rotating
    
    
    float width=assetVideoTrack.naturalSize.width;
    float height=assetVideoTrack.naturalSize.height;
    float toDiagonal=sqrt(width*width+height*height);
    float toDiagonalAngle=radiansToDegrees(acosf(width/toDiagonal));
    float toDiagonalAngle2=90-radiansToDegrees(acosf(width/toDiagonal));
    
    float toDiagonalAngleComple;
    float toDiagonalAngleComple2;
    float finalHeight;
    float finalWidth;
    
    
    if(degrees>=0&&degrees<=90){
        
        toDiagonalAngleComple=toDiagonalAngle+degrees;
        toDiagonalAngleComple2=toDiagonalAngle2+degrees;
        
        finalHeight=ABS(toDiagonal*sinf(degreesToRadians(toDiagonalAngleComple)));
        finalWidth=ABS(toDiagonal*sinf(degreesToRadians(toDiagonalAngleComple2)));
        
        t1 = CGAffineTransformMakeTranslation(height*sinf(degreesToRadians(degrees)), 0.0);
    }
    else if(degrees>90&&degrees<=180){
        
        
        float degrees2 = degrees-90;
        
        toDiagonalAngleComple=toDiagonalAngle+degrees2;
        toDiagonalAngleComple2=toDiagonalAngle2+degrees2;
        
        finalHeight=ABS(toDiagonal*sinf(degreesToRadians(toDiagonalAngleComple2)));
        finalWidth=ABS(toDiagonal*sinf(degreesToRadians(toDiagonalAngleComple)));
        
        t1 = CGAffineTransformMakeTranslation(width*sinf(degreesToRadians(degrees2))+height*cosf(degreesToRadians(degrees2)), height*sinf(degreesToRadians(degrees2)));
    }
    else if(degrees>=-90&&degrees<0){
        
        float degrees2 = degrees-90;
        float degreesabs = ABS(degrees);
        
        toDiagonalAngleComple=toDiagonalAngle+degrees2;
        toDiagonalAngleComple2=toDiagonalAngle2+degrees2;
        
        finalHeight=ABS(toDiagonal*sinf(degreesToRadians(toDiagonalAngleComple2)));
        finalWidth=ABS(toDiagonal*sinf(degreesToRadians(toDiagonalAngleComple)));
        
        t1 = CGAffineTransformMakeTranslation(0, width*sinf(degreesToRadians(degreesabs)));
        
    }
    else if(degrees>=-180&&degrees<-90){
        
        float degreesabs = ABS(degrees);
        float degreesplus = degreesabs-90;
        
        toDiagonalAngleComple=toDiagonalAngle+degrees;
        toDiagonalAngleComple2=toDiagonalAngle2+degrees;
        
        finalHeight=ABS(toDiagonal*sinf(degreesToRadians(toDiagonalAngleComple)));
        finalWidth=ABS(toDiagonal*sinf(degreesToRadians(toDiagonalAngleComple2)));
        
        t1 = CGAffineTransformMakeTranslation(width*sinf(degreesToRadians(degreesplus)), height*sinf(degreesToRadians(degreesplus))+width*cosf(degreesToRadians(degreesplus)));
        
    }
    
    
    // Rotate transformation
    t2 = CGAffineTransformRotate(t1, degreesToRadians(degrees));
    
    
    // Step 3
    // Set the appropriate render sizes and rotational transforms
    
    
    // Create a new video composition
    if (!self.mutableVideoComposition){
        self.mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    }
    self.mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    self.mutableVideoComposition.renderSize = CGSizeMake(finalWidth,finalHeight);
    self.mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    
    // The rotate transform is set on a layer instruction
    instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.mutableComposition duration]);
    
    layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:[self.mutableComposition.tracks objectAtIndex:0]];
    [layerInstruction setTransform:t2 atTime:kCMTimeZero];
    
    
    
    // Step  4
    
    // Add the transform instructions to the video composition
    
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    self.mutableVideoComposition.instructions = [NSArray arrayWithObject:instruction];
	
	
	// Step 5
	// Notify AVSEViewController about rotation operation completion
	[[NSNotificationCenter defaultCenter] postNotificationName:ISEditCommandCompletionNotification object:self];
}

@end
