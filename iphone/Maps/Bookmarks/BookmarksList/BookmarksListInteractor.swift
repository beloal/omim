protocol IBookmarksListInteractor {
  func getBookmarkGroup() -> BookmarkGroup
  func getTitle() -> String
  func getBookmarks() -> [Bookmark]
  func getTracks() -> [Track]
  func getServerId() -> String
  func isEditable() -> Bool
  func isGuide() -> Bool
  func prepareForSearch()
  func search(_ text: String, completion: @escaping ([Bookmark]) -> Void)
  func availableSortingTypes(hasMyPosition: Bool) -> [BookmarksListSortingType]
  func viewOnMap()
  func viewBookmarkOnMap(_ bookmarkId: MWMMarkID)
  func viewTrackOnMap(_ trackId: MWMTrackID)
  func sort(_ sortingType: BookmarksListSortingType,
            location: CLLocation?,
            completion: @escaping ([BookmarksSection]) -> Void)
  func deleteBookmark(_ bookmarkId: MWMMarkID)
  func deleteBookmarksGroup()
  func canDeleteGroup() -> Bool
  func exportFile(_ completion: @escaping (URL?, ExportFileStatus) -> Void)
  func finishExportFile()
}

enum BookmarksListSortingType {
  case distance
  case date
  case type
}

enum ExportFileStatus {
  case success
  case empty
  case error
}

fileprivate final class BookmarksManagerListener: NSObject {
  private var callback: (ExportFileStatus) -> Void

  init(_ callback: @escaping (ExportFileStatus) -> Void) {
    self.callback = callback
  }
}

extension BookmarksManagerListener: BookmarksObserver {
  func onBookmarksCategoryFilePrepared(_ status: BookmarksShareStatus) {
    switch status {
    case .success:
      callback(.success)
    case .emptyCategory:
      callback(.empty)
    case .archiveError, .fileError:
      callback(.error)
    @unknown default:
      fatalError()
    }
  }
}

final class BookmarksListInteractor {
  private let markGroupId: MWMMarkGroupID
  private var bookmarksManager: BookmarksManager { BookmarksManager.shared() }
  private var bookmarksManagerListener: BookmarksManagerListener?

  init(markGroupId: MWMMarkGroupID) {
    self.markGroupId = markGroupId
  }
}

extension BookmarksListInteractor: IBookmarksListInteractor {
  func getBookmarkGroup() -> BookmarkGroup {
    bookmarksManager.category(withId: markGroupId)
  }

  func getTitle() -> String {
    bookmarksManager.getCategoryName(markGroupId)
  }
  
  func getBookmarks() -> [Bookmark] {
    bookmarksManager.bookmarks(forGroup: markGroupId)
  }

  func getTracks() -> [Track] {
    bookmarksManager.tracks(forGroup: markGroupId)
  }

  func getServerId() -> String {
    bookmarksManager.getServerId(markGroupId)
  }

  func isEditable() -> Bool {
    bookmarksManager.isCategoryEditable(markGroupId)
  }

  func isGuide() -> Bool {
    bookmarksManager.isGuide(markGroupId)
  }

  func prepareForSearch() {
    bookmarksManager.prepare(forSearch: markGroupId)
  }

  func search(_ text: String, completion: @escaping ([Bookmark]) -> Void) {
    bookmarksManager.searchBookmarksGroup(markGroupId, text: text) {
      completion($0)
    }
  }

  func availableSortingTypes(hasMyPosition: Bool) -> [BookmarksListSortingType] {
    bookmarksManager.availableSortingTypes(markGroupId, hasMyPosition: hasMyPosition).map {
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

  func viewBookmarkOnMap(_ bookmarkId: MWMMarkID) {
    FrameworkHelper.showBookmark(bookmarkId)
  }

  func viewTrackOnMap(_ trackId: MWMTrackID) {
    FrameworkHelper.showTrack(trackId)
  }

  func viewOnMap(_ bookmarkId: MWMMarkID) {
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

    bookmarksManager.sortBookmarks(markGroupId,
                                   sortingType: coreSortingType,
                                   location: location) { sections in
      guard let sections = sections else { return }
      completion(sections)
    }
  }

  func deleteBookmark(_ bookmarkId: MWMMarkID) {
    bookmarksManager.deleteBookmark(bookmarkId)
  }

  func deleteBookmarksGroup() {
    bookmarksManager.deleteCategory(markGroupId)
  }

  func canDeleteGroup() -> Bool {
    bookmarksManager.userCategories().count > 1
  }

  func exportFile(_ completion: @escaping (URL?, ExportFileStatus) -> Void) {
    bookmarksManagerListener = BookmarksManagerListener({ [weak self] status in
      guard let self = self else { return }
      self.bookmarksManager.remove(self.bookmarksManagerListener!)
      var url: URL? = nil
      if status == .success {
        url = self.bookmarksManager.shareCategoryURL()
      }
      completion(url, status)
    })
    bookmarksManager.add(bookmarksManagerListener!)
    bookmarksManager.shareCategory(markGroupId)
  }

  func finishExportFile() {
    bookmarksManager.finishShareCategory()
  }
}
