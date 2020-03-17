#import "PlacePageData.h"

#import "PlacePageButtonsData+Core.h"
#import "PlacePagePreviewData+Core.h"
#import "PlacePageInfoData+Core.h"
#import "PlacePageBookmarkData+Core.h"
#import "CatalogPromoData+Core.h"
#import "HotelBookingData+Core.h"
#import "HotelRooms+Core.h"
#import "UgcData+Core.h"
#import "ElevationProfileData+Core.h"

#include <CoreApi/CoreApi.h>
#include "platform/network_policy.hpp"

static place_page::Info & rawData() { return GetFramework().GetCurrentPlacePageInfo(); }

static PlacePageSponsoredType convertSponsoredType(place_page::SponsoredType sponsoredType) {
  switch (sponsoredType) {
    case place_page::SponsoredType::None:
      return PlacePageSponsoredTypeNone;
    case place_page::SponsoredType::Booking:
      return PlacePageSponsoredTypeBooking;
    case place_page::SponsoredType::Opentable:
      return PlacePageSponsoredTypeOpentable;
    case place_page::SponsoredType::Partner:
      return PlacePageSponsoredTypePartner;
    case place_page::SponsoredType::Holiday:
      return PlacePageSponsoredTypeHoliday;
    case place_page::SponsoredType::PromoCatalogCity:
      return PlacePageSponsoredTypePromoCatalogCity;
    case place_page::SponsoredType::PromoCatalogSightseeings:
      return PlacePageSponsoredTypePromoCatalogSightseeings;
    case place_page::SponsoredType::PromoCatalogOutdoor:
      return PlacePageSponsoredTypePromoCatalogOutdoor;
  }
}

static PlacePageTaxiProvider convertTaxiProvider(taxi::Provider::Type providerType) {
  switch (providerType) {
    case taxi::Provider::Uber:
      return PlacePageTaxiProviderUber;
    case taxi::Provider::Yandex:
      return PlacePageTaxiProviderYandex;
    case taxi::Provider::Maxim:
      return PlacePageTaxiProviderMaxim;
    case taxi::Provider::Rutaxi:
      return PlacePageTaxiProviderRutaxi;
    case taxi::Provider::Count:
      return PlacePageTaxiProviderNone;
  }
}

static PlacePageRoadType convertRoadType(RoadWarningMarkType roadType) {
  switch (roadType) {
    case RoadWarningMarkType::Toll:
      return PlacePageRoadTypeToll;
    case RoadWarningMarkType::Ferry:
      return PlacePageRoadTypeFerry;
    case RoadWarningMarkType::Dirty:
      return PlacePageRoadTypeDirty;
    case RoadWarningMarkType::Count:
      return PlacePageRoadTypeNone;
  }
}

@implementation PlacePageData

- (instancetype)initWithLocalizationProvider:(id<IOpeningHoursLocalization>)localization {
  self = [super init];
  if (self) {
    _buttonsData = [[PlacePageButtonsData alloc] initWithRawData:rawData()];
    _previewData = [[PlacePagePreviewData alloc] initWithRawData:rawData()];
    _infoData = [[PlacePageInfoData alloc] initWithRawData:rawData() ohLocalization:localization];

    if (rawData().IsBookmark()) {
      _bookmarkData = [[PlacePageBookmarkData alloc] initWithRawData:rawData()];
    }

    NSString *descr = @(rawData().GetDescription().c_str());
    if (descr.length > 0) {
      _wikiDescriptionHtml = [NSString stringWithFormat:@"<html><body>%@</body></html>", descr];
    }

    _sponsoredType = convertSponsoredType(rawData().GetSponsoredType());
    _roadType = convertRoadType(rawData().GetRoadType());

    auto const &taxiProviders = rawData().ReachableByTaxiProviders();
    if (!taxiProviders.empty()) {
      _taxiProvider = convertTaxiProvider(taxiProviders.front());
    }

    _isLargeToponim = rawData().GetSponsoredType() == place_page::SponsoredType::PromoCatalogCity;
    _isSightseeing = rawData().GetSponsoredType() == place_page::SponsoredType::PromoCatalogSightseeings;
    _isOutdoor = rawData().GetSponsoredType() == place_page::SponsoredType::PromoCatalogOutdoor;
    _isPromoCatalog = _isLargeToponim || _isSightseeing || _isOutdoor;
    _shouldShowUgc = rawData().ShouldShowUGC();
    _isMyPosition = rawData().IsMyPosition();
    _isRoutePoint = rawData().IsRoutePoint();
    _isPreviewPlus = rawData().GetOpeningMode() == place_page::OpeningMode::PreviewPlus;
    _isPartner = rawData().GetSponsoredType() == place_page::SponsoredType::Partner;
    _partnerIndex = _isPartner ? rawData().GetPartnerIndex() : -1;
    _partnerName = _isPartner ? @(rawData().GetPartnerName().c_str()) : nil;
    _bookingSearchUrl = rawData().GetBookingSearchUrl().empty() ? nil : @(rawData().GetBookingSearchUrl().c_str());
    auto latlon = rawData().GetLatLon();
    _locationCoordinate = CLLocationCoordinate2DMake(latlon.m_lat, latlon.m_lon);

    NSMutableArray *ratingCategoriesArray = [NSMutableArray array];
    for (auto ratingCategory : rawData().GetRatingCategories()) {
      [ratingCategoriesArray addObject:@(ratingCategory.c_str())];
    }
    _ratingCategories = [ratingCategoriesArray copy];

    NSMutableArray *tagsArray = [NSMutableArray array];
    for (auto const & s : rawData().GetRawTypes()) {
      [tagsArray addObject:@(s.c_str())];
    }
    _statisticsTags = [tagsArray componentsJoinedByString:@", "];

    if (rawData().IsSponsored()) {
      _sponsoredURL = @(rawData().GetSponsoredUrl().c_str());
      _sponsoredDescriptionURL = @(rawData().GetSponsoredDescriptionUrl().c_str());
      _sponsoredMoreURL = @(rawData().GetSponsoredMoreUrl().c_str());
      _sponsoredReviewURL = @(rawData().GetSponsoredReviewUrl().c_str());
      _sponsoredDeeplink = @(rawData().GetSponsoredDeepLink().c_str());
    }

    if (rawData().IsTrack()) {
      _elevationProfileData = [[ElevationProfileData alloc] initWithElevationInfo:GetFramework().GetBookmarkManager().MakeElevationInfo(rawData().GetTrackId())];
    }
  }
  return self;
}

- (void)loadOnlineDataWithCompletion:(MWMVoidBlock)completion {
  dispatch_group_t group = dispatch_group_create();
  if (self.previewData.isBookingPlace) {
    dispatch_group_enter(group);
    [self loadBookingDataWithCompletion:^{
      dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [self loadHotelRoomsWithCompletion:^{
      dispatch_group_leave(group);
    }];
  }

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    completion();
  });
}

- (void)loadUgcWithCompletion:(MWMVoidBlock)completion {
  __weak __typeof(self) wSelf = self;
  GetFramework().GetUGC(rawData().GetID(), [wSelf, completion] (ugc::UGC const & ugc, ugc::UGCUpdate const & update) {
    __strong __typeof(wSelf) self = wSelf;
    if (self == nil) {
      completion();
      return;
    }

    _ugcData = [[UgcData alloc] initWithUgc:ugc ugcUpdate:update];
    completion();
  });
}

- (void)loadCatalogPromoWithCompletion:(MWMVoidBlock)completion {
  auto const api = GetFramework().GetPromoApi(platform::GetCurrentNetworkPolicy());
  if (!api) {
    completion();
    return;
  }

  __weak __typeof(self) wSelf = self;
  auto const resultHandler = [wSelf, completion](promo::CityGallery const &cityGallery) {
    __strong __typeof(wSelf) self = wSelf;
    if (self == nil) {
      completion();
      return;
    }

    _catalogPromo = [[CatalogPromoData alloc] initWithCityGallery:cityGallery];
    completion();
  };

  auto const errorHandler = [completion]() {
    completion();
  };

  auto locale = AppInfo.sharedInfo.twoLetterLanguageId.UTF8String;
  if (self.isLargeToponim) {
    api->GetCityGallery(rawData().GetMercator(), locale, UTM::LargeToponymsPlacepageGallery, resultHandler, errorHandler);
  } else {
    api->GetPoiGallery(rawData().GetMercator(),
                       locale,
                       rawData().GetRawTypes(),
                       [MWMFrameworkHelper isWiFiConnected],
                       UTM::SightseeingsPlacepageGallery,
                       resultHandler,
                       errorHandler);
  }
}

#pragma mark - Private

- (void)loadBookingDataWithCompletion:(MWMVoidBlock)completion {
  auto api = GetFramework().GetBookingApi(platform::GetCurrentNetworkPolicy());
  if (!api) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
      completion();
    });
    return;
  }

  std::string const hotelId = rawData().GetMetadata().Get(feature::Metadata::FMD_SPONSORED_ID);
  __weak __typeof(self) wSelf = self;
  api->GetHotelInfo(hotelId,
                    [[AppInfo sharedInfo] twoLetterLanguageId].UTF8String,
                    [wSelf, hotelId, completion] (booking::HotelInfo const & hotelInfo) {
    __strong __typeof(wSelf) self = wSelf;
    if (self == nil || hotelId != hotelInfo.m_hotelId) {
      completion();
      return;
    }

    _hotelBooking = [[HotelBookingData alloc] initWithHotelInfo:hotelInfo];
    completion();
  });
}

- (void)loadHotelRoomsWithCompletion:(MWMVoidBlock)completion {
  auto api = GetFramework().GetBookingApi(platform::GetCurrentNetworkPolicy());
  if (!api) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
      completion();
    });
    return;
  }

  std::string const currency = "RUB";

  auto params = booking::BlockParams::MakeDefault();
  params.m_hotelId = rawData().GetMetadata().Get(feature::Metadata::FMD_SPONSORED_ID);
  params.m_currency = currency;

  __weak __typeof(self) wSelf = self;
  api->GetBlockAvailability(std::move(params),
                            [wSelf, currency, completion] (std::string const &hotelId, booking::Blocks const &blocks) {
    __strong __typeof(wSelf) self = wSelf;
    if (self == nil || currency != blocks.m_currency) {
      completion();
      return;
    }

    _hotelRooms = [[HotelRooms alloc] initWithBlocks:blocks];
    completion();
  });
}

- (void)updateBookmarkStatus {
  if (!GetFramework().HasPlacePageInfo()) {
    return;
  }
  if (rawData().IsBookmark()) {
    _bookmarkData = [[PlacePageBookmarkData alloc] initWithRawData:rawData()];
  } else {
    _bookmarkData = nil;
  }
  if (self.onBookmarkStatusUpdate != nil) {
    self.onBookmarkStatusUpdate();
  }
}

@end
