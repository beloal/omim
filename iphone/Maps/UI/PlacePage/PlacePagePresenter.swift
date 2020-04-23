protocol PlacePagePresenterProtocol: class {
  func updatePreviewOffset()
  func layoutIfNeeded()
  func showNextStop()
  func closeAnimated()
}

class PlacePagePresenter: NSObject {
  private weak var view: PlacePageViewProtocol!
  private let interactor: PlacePageInteractorProtocol
  private let isPreviewPlus: Bool
  private let layout: IPlacePageLayout

  init(view: PlacePageViewProtocol,
       interactor: PlacePageInteractorProtocol,
       layout: IPlacePageLayout,
       isPreviewPlus: Bool) {
    self.view = view
    self.interactor = interactor
    self.layout = layout
    self.isPreviewPlus = isPreviewPlus
    view.setLayout(layout)
  }
}

// MARK: - PlacePagePresenterProtocol

extension PlacePagePresenter: PlacePagePresenterProtocol {
  func updatePreviewOffset() {
    view.updatePreviewOffset()
  }

  func layoutIfNeeded() {
    view.layoutIfNeeded()
  }

  func showNextStop() {
    view.showNextStop()
  }

  func closeAnimated() {
    view.closeAnimated()
  }
}
