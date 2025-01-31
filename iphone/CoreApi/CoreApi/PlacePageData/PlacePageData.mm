#import "PlacePageData.h"

#import "PlacePageButtonsData+Core.h"
#import "PlacePagePreviewData+Core.h"
#import "PlacePageInfoData+Core.h"
#import "PlacePageBookmarkData+Core.h"
#import "ElevationProfileData+Core.h"
#import "MWMMapNodeAttributes.h"

#include <CoreApi/CoreApi.h>
#include "platform/network_policy.hpp"

static place_page::Info & rawData() { return GetFramework().GetCurrentPlacePageInfo(); }

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

@interface PlacePageData () <MWMStorageObserver> {
  FeatureID m_featureID;
  m2::PointD m_mercator;
  std::vector<std::string> m_rawTypes;
  std::string m_hotelId;
}

@end

@implementation PlacePageData

- (instancetype)initWithLocalizationProvider:(id<IOpeningHoursLocalization>)localization {
  self = [super init];
  if (self) {
    _buttonsData = [[PlacePageButtonsData alloc] initWithRawData:rawData()];
    _infoData = [[PlacePageInfoData alloc] initWithRawData:rawData() ohLocalization:localization];

    if (rawData().IsBookmark()) {
      _bookmarkData = [[PlacePageBookmarkData alloc] initWithRawData:rawData()];
    }

    NSString *descr = @(rawData().GetDescription().c_str());
    if (descr.length > 0) {
      _wikiDescriptionHtml = [NSString stringWithFormat:@"<html><body>%@</body></html>", descr];
    }

    _roadType = convertRoadType(rawData().GetRoadType());

    _isMyPosition = rawData().IsMyPosition();
    _isRoutePoint = rawData().IsRoutePoint();
    _isPreviewPlus = rawData().GetOpeningMode() == place_page::OpeningMode::PreviewPlus;
    auto latlon = rawData().GetLatLon();
    _locationCoordinate = CLLocationCoordinate2DMake(latlon.m_lat, latlon.m_lon);

    NSMutableArray *tagsArray = [NSMutableArray array];
    for (auto const & s : rawData().GetRawTypes()) {
      [tagsArray addObject:@(s.c_str())];
    }

    if (rawData().IsTrack()) {
      auto const &bm = GetFramework().GetBookmarkManager();
      auto const &trackId = rawData().GetTrackId();
      auto const &elevationInfo = bm.MakeElevationInfo(trackId);
      _elevationProfileData = [[ElevationProfileData alloc] initWithElevationInfo:elevationInfo
                                                                      activePoint:bm.GetElevationActivePoint(trackId)
                                                                       myPosition:bm.GetElevationMyPosition(trackId)];
      _previewData = [[PlacePagePreviewData alloc] initWithElevationInfo:elevationInfo];
    } else {
      _previewData = [[PlacePagePreviewData alloc] initWithRawData:rawData()];
    }

    auto const &countryId = rawData().GetCountryId();
    if (!countryId.empty()) {
      _mapNodeAttributes = [[MWMStorage sharedStorage] attributesForCountry:@(rawData().GetCountryId().c_str())];
      [[MWMStorage sharedStorage] addObserver:self];
    }

    m_featureID = rawData().GetID();
    m_mercator = rawData().GetMercator();
    m_rawTypes = rawData().GetRawTypes();
    m_hotelId = rawData().GetMetadata().Get(feature::Metadata::FMD_SPONSORED_ID);

  }
  return self;
}

- (void)dealloc {
  if (self.mapNodeAttributes != nil) {
    [[MWMStorage sharedStorage] removeObserver:self];
  }
}

+ (BOOL)hasData {
  return GetFramework().HasPlacePageInfo();
}

#pragma mark - Private

- (void)updateBookmarkStatus {
  if (!GetFramework().HasPlacePageInfo()) {
    return;
  }
  if (rawData().IsBookmark()) {
    _bookmarkData = [[PlacePageBookmarkData alloc] initWithRawData:rawData()];
  } else {
    _bookmarkData = nil;
  }
  _previewData = [[PlacePagePreviewData alloc] initWithRawData:rawData()];
  if (self.onBookmarkStatusUpdate != nil) {
    self.onBookmarkStatusUpdate();
  }
}

#pragma mark - MWMStorageObserver

- (void)processCountryEvent:(NSString *)countryId {
  if ([countryId isEqualToString:self.mapNodeAttributes.countryId]) {
    _mapNodeAttributes = [[MWMStorage sharedStorage] attributesForCountry:countryId];
    if (self.onMapNodeStatusUpdate != nil) {
      self.onMapNodeStatusUpdate();
    }
  }
}

- (void)processCountry:(NSString *)countryId downloadedBytes:(uint64_t)downloadedBytes totalBytes:(uint64_t)totalBytes {
  if ([countryId isEqualToString:self.mapNodeAttributes.countryId] && self.onMapNodeProgressUpdate != nil) {
    self.onMapNodeProgressUpdate(downloadedBytes, totalBytes);
  }
}

@end
