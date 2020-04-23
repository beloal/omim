#import "GuidesGalleryItem.h"

#include <CoreApi/Framework.h>

NS_ASSUME_NONNULL_BEGIN

//@interface GuidesGalleryItem (Core)
//
//- (instancetype)initWithGuidesGalleryItem:(GuidesManager::GuidesGallery::Item const &)guidesGalleryItem;
//
//@end
//
@interface CityGalleryItem (Core)

- (instancetype)initWithGuidesGalleryItem:(GuidesManager::GuidesGallery::Item const &)guidesGalleryItem;

@end

@interface OutdoorGalleryItem (Core)

- (instancetype)initWithGuidesGalleryItem:(GuidesManager::GuidesGallery::Item const &)guidesGalleryItem;

@end

NS_ASSUME_NONNULL_END
