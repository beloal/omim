final class BookmarksListBuilder {
  static func build(markGroupId: MWMMarkGroupID) -> BookmarksListViewController {
    let viewController = BookmarksListViewController()
    let router = BookmarksListRouter()
    let interactor = BookmarksListInteractor(markGroupId: markGroupId)
    let presenter = BookmarksListPresenter(view: viewController,
                                           router: router,
                                           interactor: interactor,
                                           imperialUnits: Settings.measurementUnits() == .imperial)
    viewController.presenter = presenter
    return viewController
  }
}
