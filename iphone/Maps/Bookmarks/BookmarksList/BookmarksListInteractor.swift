protocol IBookmarksListInteractor {
  func getTitle() -> String
  func getBookmarks() -> [Bookmark]
  func getTracks() -> [Track]
  func isEditable() -> Bool
  func prepareForSearch()
  func search(_ text: String, completion: @escaping ([Bookmark]) -> Void)
  func availableSortingTypes(hasMyPosition: Bool) -> [BookmarksListSortingType]
  func viewOnMap()
  func sort(_ sortingType: BookmarksListSortingType,
            location: CLLocation?,
            completion: @escaping ([BookmarksSection]) -> Void)
}

enum BookmarksListSortingType {
  case distance
  case date
  case type
}

final class BookmarksListInteractor {
  private let markGroupId: MWMMarkGroupID

  init(markGroupId: MWMMarkGroupID) {
    self.markGroupId = markGroupId
  }
}

extension BookmarksListInteractor: IBookmarksListInteractor {
  func getTitle() -> String {
    BookmarksManager.shared().getCategoryName(markGroupId)
  }
  
  func getBookmarks() -> [Bookmark] {
    BookmarksManager.shared().bookmarks(forGroup: markGroupId)
  }

  func getTracks() -> [Track] {
    BookmarksManager.shared().tracks(forGroup: markGroupId)
  }

  func isEditable() -> Bool {
    BookmarksManager.shared().isCategoryEditable(markGroupId)
  }

  func prepareForSearch() {
    BookmarksManager.shared().prepare(forSearch: markGroupId)
  }

  func search(_ text: String, completion: @escaping ([Bookmark]) -> Void) {
    BookmarksManager.shared().searchBookmarksGroup(markGroupId, text: text) {
      completion($0)
    }
  }

  func availableSortingTypes(hasMyPosition: Bool) -> [BookmarksListSortingType] {
    BookmarksManager.shared().availableSortingTypes(markGroupId, hasMyPosition: hasMyPosition).map {
      BookmarksSortingType(rawValue: $0.intValue)!
    }.map {
      switch $0 {
      case .byType:
        return BookmarksListSortingType.type
      case .byDistance:
        return BookmarksListSortingType.distance
      case .byTime:
        return BookmarksListSortingType.date
      @unknown default:
        fatalError()
      }
    }
  }

  func viewOnMap() {
    FrameworkHelper.show(onMap: markGroupId)
  }

  func sort(_ sortingType: BookmarksListSortingType,
            location: CLLocation?,
            completion: @escaping ([BookmarksSection]) -> Void) {
    let coreSortingType: BookmarksSortingType
    switch sortingType {
    case .distance:
      coreSortingType = .byDistance
    case .date:
      coreSortingType = .byTime
    case .type:
      coreSortingType = .byType
    }

    BookmarksManager.shared().sortBookmarks(markGroupId,
                                            sortingType: coreSortingType,
                                            location: location) { sections in
                                              guard let sections = sections else { return }
                                              completion(sections)
    }
  }
}
