import UIKit

class ButtonView: UIView {
  static let font = UIFont.systemFont(ofSize: 14, weight: .semibold)

  var checked = true {
    didSet {
      updateAppearance()
    }
  }

  let titleLabel = UILabel()
  let imageView = UIImageView()
  var color = UIColor.clear {
    didSet {
      layer.borderColor = color.cgColor
    }
  }

  override init(frame: CGRect = .zero) {
    super.init(frame: frame)
    titleLabel.font = ButtonView.font
    imageView.image = UIImage(named: "check")
    addSubview(imageView)
    addSubview(titleLabel)
    layer.borderWidth = 1
    layer.cornerRadius = 5
    clipsToBounds = true
    tintColor = .white
    updateAppearance()
  }

  func updateAppearance() {
    if checked {
      titleLabel.textColor = .white
      backgroundColor = color
      imageView.alpha = 1
    } else {
      titleLabel.textColor = color
      backgroundColor = .clear
      imageView.alpha = 0
    }
    setNeedsLayout()
    layoutIfNeeded()
  }

  override func sizeToFit() {
    imageView.sizeToFit()
    titleLabel.sizeToFit()
    let height = max(imageView.frame.height, titleLabel.frame.height)
    let width = imageView.frame.width + titleLabel.frame.width + 28
    frame = CGRect(x: 0, y: 0, width: width, height: height)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    imageView.center = CGPoint(x: imageView.frame.width / 2 + 10, y: bounds.midY)
    if checked {
      titleLabel.center = CGPoint(x: imageView.frame.maxX + titleLabel.frame.width / 2 + 8, y: bounds.midY)
    } else {
      titleLabel.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
}

class ChartSettingsView: UIView {
  static let font = UIFont.systemFont(ofSize: 14, weight: .semibold)

  let spacing: CGFloat = 8

  var maxWidth: CGFloat = 0 {
    didSet {
      calculateLayout()
    }
  }

  private(set) var height: CGFloat = 0

  var buttons: [ButtonView] = []

  var chartData: ChartPresentationData! {
    didSet {
      if chartData.linesCount < 2 { return }
      for i in 0..<chartData.linesCount {
        let line = chartData.lineAt(i)
        let b = makeButton(name: line.name, color: line.color)
        buttons.append(b)
        addSubview(b)
      }
      updateVisibility()
    }
  }

  func updateVisibility() {
    for i in 0..<self.chartData.linesCount {
      let button = buttons[i]
      let visible = chartData.isLineVisibleAt(i)
      UIView.animate(withDuration: kAnimationDuration) {
        button.checked = visible
      }
    }
  }

  func makeButton(name: String, color: UIColor) -> ButtonView {
    let b = ButtonView()
    b.titleLabel.text = name
    b.color = color
    b.sizeToFit()
    var f = b.frame
    f.size = CGSize(width: f.width, height: 30)
    b.frame = f
    let tapGR = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
    b.addGestureRecognizer(tapGR)
    let longTapGr = UILongPressGestureRecognizer(target: self, action: #selector(onLongTap(_:)))
    b.addGestureRecognizer(longTapGr)
    return b
  }


  func calculateLayout() {
    if buttons.count == 0 { return }
    var x: CGFloat = 0
    var y: CGFloat = 16
    buttons.forEach {
      if x + $0.frame.width > maxWidth - 0 {
        y += ($0.frame.height + spacing)
        x = 0
      }

      var f = $0.frame
      f.origin = CGPoint(x: x, y: y)
      $0.frame = f.integral
      x += (f.width + spacing)
    }
    height = y + 30
  }

  @objc func onTap(_ sender: UITapGestureRecognizer) {
    let i = buttons.firstIndex(of: sender.view as! ButtonView)!
    let visible = chartData.isLineVisibleAt(i)
    chartData.setLineVisible(!visible, at: i)
    updateVisibility()
  }

  @objc func onLongTap(_ sender: UILongPressGestureRecognizer) {
    if sender.state == .began {
      let index = buttons.firstIndex(of: sender.view as! ButtonView)!
      chartData.setLineVisible(true, at: index)
      for i in 0..<chartData.linesCount {
        if i == index { continue }
        chartData.setLineVisible(false, at: i)
      }
      updateVisibility()
    }
  }
}
