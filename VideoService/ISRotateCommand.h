

#import "ISCommand.h"

@interface ISRotateCommand : ISCommand

- (void)performWithAsset:(AVAsset*)asset andRotate:(float)degrees;

@end

