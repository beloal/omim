protocol IBookmarksListSectionViewModel {
  var numberOfItems: Int { get }
  var sectionTitle: String { get }
  var hasVisibilityButton: Bool { get }
}

protocol IBookmarksSectionViewModel: IBookmarksListSectionViewModel {
  var bookmarks: [IBookmarkViewModel] { get }
}

extension IBookmarksSectionViewModel {
  var numberOfItems: Int { bookmarks.count }
  var hasVisibilityButton: Bool { false }
}

protocol ITracksSectionViewModel: IBookmarksListSectionViewModel {
  var tracks: [ITrackViewModel] { get }
}

extension ITracksSectionViewModel {
  var numberOfItems: Int { tracks.count }
  var sectionTitle: String { L("tracks_title") }
  var hasVisibilityButton: Bool { false }
}

protocol IBookmarkViewModel {
  var bookmarkName: String { get }
  var subtitle: String { get }
  var image: UIImage { get }
}

protocol ITrackViewModel {
  var trackName: String { get }
  var subtitle: String { get }
  var image: UIImage { get }
}

protocol IBookmarksListMenuItem {
  var title: String { get }
  var destructive: Bool { get }
  var action: () -> Void { get }
}

protocol IBookmarksListView: AnyObject {
  func setTitle(_ title: String)
  func setSections(_ sections: [IBookmarksListSectionViewModel])
  func setMoreItemTitle(_ itemTitle: String)
  func showMenu(_ items: [IBookmarksListMenuItem])
}

final class BookmarksListViewController: MWMViewController {
  var presenter: IBookmarksListPresenter!

  private var sections: [IBookmarksListSectionViewModel]?

  private let cellStrategy = BookmarksListCellStrategy()

  @IBOutlet var tableView: UITableView!
  @IBOutlet var searchBar: UISearchBar!
  @IBOutlet var toolBar: UIToolbar!
  @IBOutlet var sortToolbarItem: UIBarButtonItem!
  @IBOutlet var moreToolbarItem: UIBarButtonItem!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let toolbarItemAttributes = [NSAttributedString.Key.font: UIFont.medium16(),
                                 NSAttributedString.Key.foregroundColor: UIColor.linkBlue()]

    sortToolbarItem.setTitleTextAttributes(toolbarItemAttributes, for: .normal)
    moreToolbarItem.setTitleTextAttributes(toolbarItemAttributes, for: .normal)
    sortToolbarItem.title = L("sort")
    searchBar.placeholder = L("search_in_the_list")
    cellStrategy.registerCells(tableView)
    presenter.viewDidLoad()
  }

  @IBAction func onSortItem(_ sender: UIBarButtonItem) {
    presenter.sort()
  }

  @IBAction func onMoreItem(_ sender: UIBarButtonItem) {
    presenter.more()
  }
}

extension BookmarksListViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    sections?.count ?? 0
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let section = sections?[section] else { fatalError() }
    return section.numberOfItems
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let section = sections?[indexPath.section] else { fatalError() }
    return cellStrategy.tableCell(tableView, for: section, at: indexPath)
  }
}

extension BookmarksListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    48
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let section = sections?[section] else { fatalError() }
    return cellStrategy.headerView(tableView, for: section)
  }
}

extension BookmarksListViewController: UISearchBarDelegate {
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchBar.setShowsCancelButton(true, animated: true)
    navigationController?.setNavigationBarHidden(true, animated: true)
    presenter.activateSearch()
  }

  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    searchBar.setShowsCancelButton(false, animated: true)
    navigationController?.setNavigationBarHidden(false, animated: true)
    presenter.deactivateSearch()
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = nil
    searchBar.resignFirstResponder()
    presenter.cancelSearch()
  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    guard !searchText.isEmpty else {
      presenter.cancelSearch()
      return
    }

    presenter.search(searchText)
  }
}

extension BookmarksListViewController: IBookmarksListView {
  func setTitle(_ title: String) {
    self.title = title
  }

  func setSections(_ sections: [IBookmarksListSectionViewModel]) {
    self.sections = sections
    tableView.reloadData()
  }

  func setMoreItemTitle(_ itemTitle: String) {
    moreToolbarItem.title = itemTitle
  }

  func showMenu(_ items: [IBookmarksListMenuItem]) {
    let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    items.forEach { item in
      let action = UIAlertAction(title: item.title, style: item.destructive ? .destructive : .default) { _ in
        item.action()
      }
      actionSheet.addAction(action)
    }
    actionSheet.addAction(UIAlertAction(title: L("cancel"), style: .cancel, handler: nil))
    present(actionSheet, animated: true)
  }
}
