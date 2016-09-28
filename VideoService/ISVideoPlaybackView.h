

#import <UIKit/UIKit.h>

@class AVPlayer;

@interface ISVideoPlaybackView : UIView

@property (nonatomic, strong) AVPlayer* player;

- (void)setPlayer:(AVPlayer*)player;
- (void)setVideoFillMode:(NSString *)fillMode;
- (CGRect)videoRect;

@end
