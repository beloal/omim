#import <Foundation/Foundation.h>

@class GuidesGalleryItem;

NS_ASSUME_NONNULL_BEGIN

@interface GuidesGalleryData : NSObject

@property(nonatomic, readonly) NSArray<GuidesGalleryItem *> *galleryItems;

@end

NS_ASSUME_NONNULL_END
