import UIKit

protocol IGuidesGalleryOutdoorItemViewModel: IGuidesGalleryItemViewModel {
  var distance: String { get }
  var duration: String { get }
  var ascent: String { get }
}

final class GuidesGalleryOutdoorCell: GuidesGalleryCell {
  @IBOutlet private var timeLabel: UILabel!
  @IBOutlet private var distanceLabel: UILabel!
  @IBOutlet private var ascentLabel: UILabel!

  func config(_ item: IGuidesGalleryOutdoorItemViewModel) {
    super.config(item)

    if !item.downloaded {
      timeLabel.text = item.duration
      distanceLabel.text = item.distance
      ascentLabel.text = item.ascent
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    timeLabel.text = nil
    distanceLabel.text = nil
    ascentLabel.text = nil
  }
}
