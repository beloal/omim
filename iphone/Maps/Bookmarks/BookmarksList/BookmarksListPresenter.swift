protocol IBookmarksListPresenter {
  func viewDidLoad()
  func activateSearch()
  func deactivateSearch()
  func cancelSearch()
  func search(_ text: String)
  func sort()
  func more()
}

final class BookmarksListPresenter {
  private unowned let view: IBookmarksListView
  private let router: IBookmarksListRouter
  private let interactor: IBookmarksListInteractor

  private let distanceFormatter = MeasurementFormatter()
  private let imperialUnits: Bool

  init(view: IBookmarksListView,
       router: IBookmarksListRouter,
       interactor: IBookmarksListInteractor,
       imperialUnits: Bool) {
    self.view = view
    self.router = router
    self.interactor = interactor
    self.imperialUnits = imperialUnits

    distanceFormatter.unitOptions = [.providedUnit]
  }

  private func setDefaultSections() {
    var sections: [IBookmarksListSectionViewModel] = []
    let tracks = interactor.getTracks().map { track in
      TrackViewModel(track, formattedDistance: formatDistance(Double(track.trackLength)))
    }
    if !tracks.isEmpty {
      sections.append(TracksSectionViewModel(tracks: tracks))
    }
    let bookmarks = mapBookmarks(interactor.getBookmarks())
    sections.append(BookmarksSectionViewModel(title: L("bookmarks"), bookmarks: bookmarks))
    view.setSections(sections)
  }

  private func mapBookmarks(_ bookmarks: [Bookmark]) -> [BookmarkViewModel] {
    let location = LocationManager.lastLocation()
    return bookmarks.map {
      let formattedDistance: String?
      if let location = location {
        let distance = location.distance(from: CLLocation(latitude: $0.locationCoordinate.latitude,
                                                          longitude: $0.locationCoordinate.longitude))
        formattedDistance = formatDistance(distance)
      } else {
        formattedDistance = nil
      }
      return BookmarkViewModel($0, formattedDistance: formattedDistance)
    }
  }

  private func formatDistance(_ distance: Double) -> String {
    let unit = imperialUnits ? UnitLength.miles : UnitLength.kilometers
    let distanceInUnits = unit.converter.value(fromBaseUnitValue: distance)
    let measurement = Measurement(value: distanceInUnits.rounded(), unit: unit)
    return distanceFormatter.string(from: measurement)
  }

  private func showSortMenu() {
    var sortItems = interactor.availableSortingTypes(hasMyPosition: LocationManager.lastLocation() != nil)
      .map { sortingType -> BookmarksListMenuItem in
        switch sortingType {
        case .distance:
          return BookmarksListMenuItem(title: L("sort_distance"), action: { [weak self] in
            self?.sort(.distance)
          })
        case .date:
          return BookmarksListMenuItem(title: L("sort_date"), action: { [weak self] in
            self?.sort(.date)
          })
        case .type:
          return BookmarksListMenuItem(title: L("sort_type"), action: { [weak self] in
            self?.sort(.type)
          })
        }
    }
    sortItems.append(BookmarksListMenuItem(title: L("sort_default"), action: { [weak self] in
      self?.setDefaultSections()
    }))
    view.showMenu(sortItems)
  }

  private func showMoreMenu() {
    var moreItems: [BookmarksListMenuItem] = []
    moreItems.append(BookmarksListMenuItem(title: L("sharing_options"), action: { [weak self] in
      self?.router.sharingOptions()
    }))
    moreItems.append(BookmarksListMenuItem(title: L("search_show_on_map"), action: { [weak self] in
      self?.viewOnMap()
    }))
    moreItems.append(BookmarksListMenuItem(title: L("list_settings"), action: { [weak self] in
      self?.router.listSettings()
    }))
    moreItems.append(BookmarksListMenuItem(title: L("export_file"), action: { [weak self] in

    }))
    moreItems.append(BookmarksListMenuItem(title: L("delete_list"), destructive: true, action: { [weak self] in

    }))
    view.showMenu(moreItems)
  }

  private func viewOnMap() {
    interactor.viewOnMap()
  }

  private func sort(_ sortingType: BookmarksListSortingType) {
    interactor.sort(sortingType, location: LocationManager.lastLocation()) { [weak self] sortedSections in
      let sections = sortedSections.map { (bookmarksSection) -> IBookmarksListSectionViewModel in
        if let bookmarks = bookmarksSection.bookmarks, let self = self {
          return BookmarksSectionViewModel(title: bookmarksSection.sectionName, bookmarks: self.mapBookmarks(bookmarks))
        }
        if let tracks = bookmarksSection.tracks, let self = self {
          return TracksSectionViewModel(tracks: tracks.map { track in
            TrackViewModel(track, formattedDistance: self.formatDistance(Double(track.trackLength)))
          })
        }
        fatalError()
      }
      self?.view.setSections(sections)
    }
  }
}

extension BookmarksListPresenter: IBookmarksListPresenter {
  func viewDidLoad() {
    setDefaultSections()
    view.setTitle(interactor.getTitle())
    view.setMoreItemTitle(interactor.isEditable() ? L("placepage_more_button") : L("view_on_map_bookmarks"))
  }

  func activateSearch() {
    interactor.prepareForSearch()
  }

  func deactivateSearch() {

  }

  func cancelSearch() {
    setDefaultSections()
  }

  func search(_ text: String) {
    interactor.search(text) { [weak self] in
      guard let self = self else { return }
      let bookmarks = self.mapBookmarks($0)
      self.view.setSections(bookmarks.isEmpty ? [] : [BookmarksSectionViewModel(title: L("bookmarks"),
                                                                                 bookmarks: bookmarks)])
    }
  }

  func more() {
    if interactor.isEditable() {
      showMoreMenu()
    } else {
      viewOnMap()
    }
  }

  func sort() {
    showSortMenu()
  }
}

fileprivate struct BookmarkViewModel: IBookmarkViewModel {
  let bookmarkName: String
  let subtitle: String
  var image: UIImage {
    bookmarkColor.image(bookmarkIconName)
  }

  private let bookmarkColor: BookmarkColor
  private let bookmarkIconName: String

  init(_ bookmark: Bookmark, formattedDistance: String?) {
    bookmarkName = bookmark.bookmarkName
    bookmarkColor = bookmark.bookmarkColor
    bookmarkIconName = bookmark.bookmarkIconName
    subtitle = [formattedDistance, bookmark.bookmarkType].compactMap { $0 }.joined(separator: " • ")
  }
}

fileprivate struct TrackViewModel: ITrackViewModel {
  let trackName: String
  let subtitle: String
  var image: UIImage {
    circleImageForColor(trackColor, frameSize: 22)
  }

  private let trackColor: UIColor

  init(_ track: Track, formattedDistance: String) {
    trackName = track.trackName
    subtitle = "\(L("length")) \(formattedDistance)"
    trackColor = track.trackColor
  }
}

fileprivate struct BookmarksSectionViewModel: IBookmarksSectionViewModel {
  let sectionTitle: String
  let bookmarks: [IBookmarkViewModel]

  init(title: String, bookmarks: [IBookmarkViewModel]) {
    sectionTitle = title
    self.bookmarks = bookmarks
  }
}

fileprivate struct TracksSectionViewModel: ITracksSectionViewModel {
  var tracks: [ITrackViewModel]

  init(tracks: [ITrackViewModel]) {
    self.tracks = tracks
  }
}

fileprivate struct BookmarksListMenuItem: IBookmarksListMenuItem {
  let title: String
  let destructive: Bool
  let action: () -> Void

  init(title: String, destructive: Bool = false, action: @escaping () -> Void) {
    self.title = title
    self.destructive = destructive
    self.action = action
  }
}
