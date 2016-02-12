#import "MWMViewController.h"

@class MWMPageController;

@interface MWMWhatsNewController : MWMViewController

@property (nonatomic) NSUInteger pageIndex;
@property (weak, nonatomic) MWMPageController * pageController;
@property (weak, nonatomic, readonly) IBOutlet UIButton * enableButton;

- (void)updateForSize:(CGSize)size;

@end
