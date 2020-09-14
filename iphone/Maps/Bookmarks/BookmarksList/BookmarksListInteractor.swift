protocol IBookmarksListInteractor {
  func getTitle() -> String
  func getBookmarks() -> [Bookmark]
  func getTracks() -> [Track]
  func prepareForSearch()
  func search(_ text: String, completion: @escaping ([Bookmark]) -> Void)
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

  func prepareForSearch() {
    BookmarksManager.shared().prepare(forSearch: markGroupId)
  }

  func search(_ text: String, completion: @escaping ([Bookmark]) -> Void) {
    BookmarksManager.shared().searchBookmarksGroup(markGroupId, text: text) {
      completion($0)
    }
  }
}
