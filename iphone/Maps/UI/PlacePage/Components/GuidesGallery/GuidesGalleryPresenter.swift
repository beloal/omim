import Foundation

protocol IGuidesGalleryPresenter {
  func viewDidLoad()
  func selectItemAtIndex(_ index: Int)
  func scrollToItemAtIndex(_ index: Int)
  func toggleVisibilityAtIndex(_ index: Int)
}

final class GuidesGalleryPresenter {
  private weak var view: IGuidesGalleryView?
  private var router: IGuidesGalleryRouter
  private var guidesGallery: GuidesGalleryData
  private let formatter = ChartFormatter(imperial: Settings.measurementUnits() == .imperial)

  init(view: IGuidesGalleryView, router: IGuidesGalleryRouter, guidesGallery: GuidesGalleryData) {
    self.view = view
    self.router = router
    self.guidesGallery = guidesGallery
  }

  deinit {
    GuidesManager.shared().resetGalleyChangedCallback()
  }

  private func makeViewModel(_ item: GuidesGalleryItem) -> IGuidesGalleryItemViewModel {
    switch item {
    case let cityItem as CityGalleryItem:
      return makeCityItemViewModel(cityItem)
    case let outdoorItem as OutdoorGalleryItem:
      return makeOutdoorItemViewModel(outdoorItem)
    default:
      fatalError("Unexpected item type \(item)")
    }
  }

  private func makeCityItemViewModel(_ item: CityGalleryItem) -> IGuidesGalleryCityItemViewModel {
    var model = GalleryCityItemViewModel(item)
//    if model.downloaded {
//      let groupId = MWMBookmarksManager.shared().getGroupId(item.guideId)
//      model.visible = MWMBookmarksManager.shared().isCategoryVisible(groupId)
//    }
    return model
  }

  private func makeOutdoorItemViewModel(_ item: OutdoorGalleryItem) -> IGuidesGalleryOutdoorItemViewModel {
    var model = GalleryOutdoorItemViewModel(item, formatter: formatter)
//    if model.downloaded {
//      let groupId = MWMBookmarksManager.shared().getGroupId(item.guideId)
//      model.visible = MWMBookmarksManager.shared().isCategoryVisible(groupId)
//    }
    return model
  }
}

extension GuidesGalleryPresenter: IGuidesGalleryPresenter {
  func viewDidLoad() {
    GuidesManager.shared().setGalleyChangedCallback { [weak self] (reloadGallery) in
      guard let self = self else { return }
      let activeGuideId = GuidesManager.shared().activeGuideId()
      guard let activeIndex = self.guidesGallery.galleryItems.firstIndex(where: {
        $0.guideId == activeGuideId
      }) else { return }
      self.view?.setActiveItem(activeIndex, animated: true)
    }

    view?.setGalleryItems(guidesGallery.galleryItems.map({ makeViewModel($0) }))
    guard let activeIndex = guidesGallery.galleryItems.firstIndex(where: {
      $0.guideId == guidesGallery.activeGuideId
    }) else { return }
    view?.setActiveItem(activeIndex, animated: false)
  }

  func selectItemAtIndex(_ index: Int) {
    let galleryItem = guidesGallery.galleryItems[index]
    guard let url = URL(string: galleryItem.url) else { return }
    router.openCatalogUrl(url)
  }

  func scrollToItemAtIndex(_ index: Int) {
    let galleryItem = guidesGallery.galleryItems[index]
    GuidesManager.shared().setActiveGuide(galleryItem.guideId)
  }

  func toggleVisibilityAtIndex(_ index: Int) {
    let galleryItem = guidesGallery.galleryItems[index]
    let groupId = MWMBookmarksManager.shared().getGroupId(galleryItem.guideId)
    let visible = MWMBookmarksManager.shared().isCategoryVisible(groupId)
    MWMBookmarksManager.shared().setCategory(groupId, isVisible: !visible)
    let model = makeViewModel(galleryItem)
    view?.updateItem(model, at: index)
  }
}

fileprivate struct GalleryCityItemViewModel: IGuidesGalleryCityItemViewModel {
  var title: String
  var subtitle: String
  var imageUrl: URL?
  var downloaded: Bool
  var visible: Bool?
  var info: String

  init(_ item: CityGalleryItem) {
    title = item.title
    subtitle = item.hasTrack ? L("routes_card_routes_tag") : L("routes_card_set_tag")
    imageUrl = URL(string: item.imageUrl)
    downloaded = item.downloaded
    var infoString = String(coreFormat: "routes_card_number_of_points", arguments: [item.bookmarksCount])
    if item.hasTrack {
      infoString.append(L("routes_card_plus_track"))
    }
    info = infoString
  }
}

fileprivate struct GalleryOutdoorItemViewModel: IGuidesGalleryOutdoorItemViewModel {
  var title: String
  var subtitle: String
  var imageUrl: URL?
  var downloaded: Bool
  var visible: Bool?
  var distance: String
  var duration: String
  var ascent: String

  init(_ item: OutdoorGalleryItem, formatter: ChartFormatter) {
    title = item.title
    subtitle = item.tag
    imageUrl = URL(string: item.imageUrl)
    downloaded = item.downloaded
    duration = formatter.timeString(from: Double(item.duration))
    distance = formatter.distanceString(from: item.distance)
    ascent = formatter.altitudeString(from: Double(item.ascent))
  }
}
