#import "RNSodyoSdkView.h"

@implementation RNSodyoSdkView

- (instancetype)initWithView:(UIView*) view {
    NSLog(@"RNSodyoSdkView init");
    self = [super init];

    if ( self ) {
        [self setUp:view];
    }

    return self;
}

- (void)setUp:(UIView*) view {
    NSLog(@"RNSodyoSdkView setup");
    [self addSubview:view];
}

- (void) layoutSubviews {
  [super layoutSubviews];
  for(UIView* view in self.subviews) {
    [view setFrame:self.bounds];
  }
}

@end
