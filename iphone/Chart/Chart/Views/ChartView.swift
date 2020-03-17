import UIKit

let kAnimationDuration = 0.3
let df: DateFormatter = {
  let f = DateFormatter()
  f.dateStyle = .medium
  return f
}()

enum ChartAnimation: TimeInterval {
  case none = 0.0
  case animated = 0.3
  case interactive = 0.1
}

public class ChartView: UIView {
  let chartsContainerView = UIView()
  let chartPreviewView = ChartPreviewView()
  let yAxisLeftView = ChartYAxisView()
  var yAxisRightView = ChartYAxisView()
  let xAxisView = ChartXAxisView()
  let chartInfoView = ChartInfoView()
  var lineViews: [ChartLineView] = []
  public var maxWidth: CGFloat = 0
  public var height: CGFloat {
    return 56 + 125
  }

  private var panStartPoint = 0
  private var panGR: UIPanGestureRecognizer!
  private var pinchStartLower = 0
  private var pinchStartUpper = 0
  private var pinchGR: UIPinchGestureRecognizer!

  public var previewSelectorColor: UIColor = UIColor.white {
    didSet {
      chartPreviewView.selectorColor = previewSelectorColor
    }
  }

  public var previewTintColor: UIColor = UIColor.clear {
    didSet {
      chartPreviewView.selectorTintColor = previewTintColor
    }
  }

  public var headerTextColor: UIColor = UIColor.lightGray {
    didSet {
      chartInfoView.textColor = headerTextColor
    }
  }

  public var gridTextColor: UIColor = UIColor(white: 0, alpha: 0.2) {
    didSet {
      xAxisView.gridColor = gridTextColor
      yAxisLeftView.gridColor = gridTextColor
    }
  }

  public var gridLineColor: UIColor = UIColor(white: 0, alpha: 0.2) {
    didSet {
      yAxisLeftView.gridLineColor = gridLineColor
    }
  }

  public var bgColor: UIColor = UIColor.white {
    didSet {
      chartInfoView.bgColor = bgColor
    }
  }

  weak var headerUpdateTimer: Timer?

  public var rasterize = false {
    didSet {
      lineViews.forEach {
        $0.layer.shouldRasterize = rasterize
        $0.layer.rasterizationScale = UIScreen.main.scale
      }
    }
  }

  public var chartData: ChartPresentationData! {
    didSet {
      chartData.delegate = self
      lineViews.forEach { $0.removeFromSuperview() }
      lineViews.removeAll()
      for i in (0..<chartData.linesCount).reversed() {
        let line = chartData.lineAt(i)
        let v = ChartLineView()
        v.clipsToBounds = true
        v.chartLine = line
        v.lineWidth = 3
        v.frame = chartsContainerView.bounds
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chartsContainerView.addSubview(v)
        lineViews.insert(v, at: 0)
      }

      yAxisLeftView.frame = chartsContainerView.bounds
      yAxisLeftView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      yAxisLeftView.transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
      chartsContainerView.addSubview(yAxisLeftView)

      if chartData.type == .yScaled {
        yAxisLeftView.textColor = chartData.lineAt(0).color
        yAxisRightView.textColor = chartData.lineAt(1).color
        yAxisRightView.alignment = .right
        yAxisRightView.frame = chartsContainerView.bounds
        yAxisRightView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        yAxisRightView.transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
        chartsContainerView.addSubview(yAxisRightView)
      }

      chartInfoView.frame = chartsContainerView.bounds
      chartInfoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      chartInfoView.delegate = self
      chartInfoView.bgColor = bgColor
      chartInfoView.textColor = headerTextColor
      chartsContainerView.addSubview(chartInfoView)

      xAxisView.values = chartData.labels
      chartPreviewView.chartData = chartData
      xAxisView.setBounds(lower: chartPreviewView.minX, upper: chartPreviewView.maxX)
      updateCharts()
    }
  }

  public typealias OnSelectePointChangedClosure = (_ px: CGFloat) -> Void
  public var onSelectedPointChanged: OnSelectePointChangedClosure?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  private func setup() {
    xAxisView.gridColor = gridTextColor
    yAxisLeftView.gridColor = gridTextColor
    yAxisRightView.gridColor = gridTextColor
    yAxisLeftView.gridLineColor = gridTextColor
    yAxisRightView.gridLineColor = gridTextColor
    chartInfoView.bgColor = bgColor

    panGR = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
    chartsContainerView.addGestureRecognizer(panGR)
    pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:)))
    chartsContainerView.addGestureRecognizer(pinchGR)
    addSubview(chartsContainerView)
    addSubview(chartPreviewView)
    chartPreviewView.delegate = self
    addSubview(xAxisView)
  }

  override public func layoutSubviews() {
    super.layoutSubviews()
    let chartsFrame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: 125)
    chartsContainerView.frame = chartsFrame

    let xAxisFrame = CGRect(x: bounds.minX, y: bounds.minY + 125, width: bounds.width, height: 26)
    xAxisView.frame = xAxisFrame

    let previewFrame = CGRect(x: bounds.minX, y: bounds.minY + 125 + 26, width: bounds.width, height: 30)
    chartPreviewView.frame = previewFrame
  }

  @objc func onPinch(_ sender: UIPinchGestureRecognizer) {
    if sender.state == .began {
      pinchStartLower = xAxisView.lowerBound
      pinchStartUpper = xAxisView.upperBound
    }

    if sender.state != .changed {
      return
    }

    let rangeLength = CGFloat(pinchStartUpper - pinchStartLower)
    let dx = Int(round((rangeLength * sender.scale - rangeLength) / 2))
    let lower = max(pinchStartLower + dx, 0)
    let upper = min(pinchStartUpper - dx, chartData.labels.count - 1)

    if upper - lower < chartData.labels.count / 10 {
      return
    }
    
    chartPreviewView.setX(min: lower, max: upper)
    xAxisView.setBounds(lower: lower, upper: upper)
    updateCharts(animationStyle: .none)
    chartInfoView.update()

  }

  @objc func onPan(_ sender: UIPanGestureRecognizer) {
    let t = sender.translation(in: chartsContainerView)
    if sender.state == .began {
      panStartPoint = xAxisView.lowerBound
    }

    if sender.state != .changed {
      return
    }

    let dx = Int(round(t.x / chartsContainerView.bounds.width * CGFloat(xAxisView.upperBound - xAxisView.lowerBound)))
    let lower = panStartPoint - dx
    let upper = lower + xAxisView.upperBound - xAxisView.lowerBound
    if lower < 0 || upper > chartData.labels.count - 1 {
      return
    }
    
    chartPreviewView.setX(min: lower, max: upper)
    xAxisView.setBounds(lower: lower, upper: upper)
    updateCharts(animationStyle: .none)
    chartInfoView.update()
  }

  func updateYScaled(animationStyle: ChartAnimation = .none) {
    for i in 0..<chartData.linesCount {
      var lower = CGFloat(Int.max)
      var upper = CGFloat(Int.min)
      guard chartData.isLineVisibleAt(i) else { continue }
      let line = chartData.lineAt(i)
      let subrange = line.aggregatedValues[xAxisView.lowerBound...xAxisView.upperBound]
      subrange.forEach {
        upper = max($0, CGFloat(upper))
        lower = min($0, CGFloat(lower))
      }

      let step = ceil(CGFloat(upper - lower) / 5)
      upper = lower + step * 5
      var steps: [CGFloat] = []
      for i in 0..<5 {
        steps.append(lower + step * CGFloat(i))
      }

      let yAxisView = i == 0 ? yAxisLeftView : yAxisRightView
      if (yAxisView.upperBound != upper || yAxisView.lowerBound != lower) {
        yAxisView.setBounds(lower: lower, upper: upper, steps: steps, animationStyle: animationStyle)
      }

      let lineView = lineViews[i]
      lineView.setViewport(minX: xAxisView.lowerBound,
                           maxX: xAxisView.upperBound,
                           minY: lower,
                           maxY: upper,
                           animationStyle: animationStyle)

    }
  }

  func updateCharts(animationStyle: ChartAnimation = .none) {
    if chartData.type == .yScaled {
      updateYScaled(animationStyle: animationStyle)
      return
    }

    var lower = CGFloat(Int.max)
    var upper = CGFloat(Int.min)

    for i in 0..<chartData.linesCount {
      guard chartData.isLineVisibleAt(i) else { continue }
      let line = chartData.lineAt(i)
      if line.type == .area || line.type == .bar {
        lower = min(line.minY, lower)
      }
      let subrange = line.aggregatedValues[xAxisView.lowerBound...xAxisView.upperBound]
      subrange.forEach {
        upper = max($0, upper)
        if line.type == .line || line.type == .lineArea {
          lower = min($0, lower)
        }
      }
    }

    let padding = round((upper - lower) / 10)
    lower = max(0, lower - padding)
    upper = upper + padding

    let stepsCount = 3
    let step = ceil((upper - lower) / CGFloat(stepsCount))
    upper = lower + step * CGFloat(stepsCount)
    var steps: [CGFloat] = []
    for i in 0..<stepsCount {
      steps.append(lower + step * CGFloat(i))
    }

    if yAxisLeftView.upperBound != upper || yAxisLeftView.lowerBound != lower {
      yAxisLeftView.setBounds(lower: lower, upper: upper, steps: steps, animationStyle: animationStyle)
    }

    lineViews.forEach {
      $0.setViewport(minX: xAxisView.lowerBound,
                     maxX: xAxisView.upperBound,
                     minY: lower,
                     maxY: upper,
                     animationStyle: animationStyle)
    }
  }
}

extension ChartView: ChartPreviewViewDelegate {
  func chartPreviewView(_ view: ChartPreviewView, didChangeMinX minX: Int, maxX: Int) {
    xAxisView.setBounds(lower: minX, upper: maxX)
    updateCharts(animationStyle: .none)
    chartInfoView.update()
  }
}

extension ChartView: ChartInfoViewDelegate {
  func chartInfoView(_ view: ChartInfoView, didCaptureInfoView captured: Bool) {
    panGR.isEnabled = !captured
  }

  func chartInfoView(_ view: ChartInfoView, infoAtPointX pointX: CGFloat) -> (String, [ChartLineInfo])? {
    let p = convert(CGPoint(x: pointX, y: 0), from: view)
    let x = (p.x / bounds.width) * CGFloat(xAxisView.upperBound - xAxisView.lowerBound) + CGFloat(xAxisView.lowerBound)
    let x1 = Int(floor(x))
    let x2 = Int(ceil(x))
    guard x1 < chartData.labels.count && x >= 0 else { return nil }
    let date = chartData.labelAt(x1)

    var result: [ChartLineInfo] = []
    for i in 0..<chartData.linesCount {
      guard chartData.isLineVisibleAt(i) else { continue }
      let line = chartData.lineAt(i)
      guard line.type != .lineArea else { continue }
      let y1 = line.values[x1]
      let y2 = line.values[x2]
      let yAxisView: ChartYAxisView
      if chartData.type == .yScaled && i == 1 {
        yAxisView = yAxisRightView
      } else {
        yAxisView = yAxisLeftView
      }

      let dx = x - CGFloat(x1)
      let y = dx * (y2 - y1) + y1
      let py = round(chartsContainerView.bounds.height * CGFloat(y - yAxisView.lowerBound) /
        CGFloat(yAxisView.upperBound - yAxisView.lowerBound))
      var left: CGFloat? = nil
      var right: CGFloat? = nil
      if line.type == .bar {
        left = chartsContainerView.convert(CGPoint(x: x1, y: 0), to: view).x
        right = chartsContainerView.convert(CGPoint(x: x2, y: 0), to: view).x
      }

      let v1 = line.originalValues[x1]
      let v2 = line.originalValues[x2]
      let v = Int(round(dx * CGFloat(v2 - v1))) + v1
      onSelectedPointChanged?(x)
      result.append(ChartLineInfo(name: line.name,
                                  color: line.color,
                                  point: chartsContainerView.convert(CGPoint(x: p.x, y: py), to: view),
                                  value: v,
                                  left: left,
                                  rigth: right))
    }

    return (date, result)
  }
}

extension ChartView: ChartPresentationDataDelegate {
  public func chartPresentationData(_ data: ChartPresentationData, didSetLineVisble visible: Bool, at index: Int) {
    updateCharts(animationStyle: .animated)
    chartPreviewView.setLineVisible(visible, atIndex: index)
    let lv = lineViews[index]
    UIView.animate(withDuration: kAnimationDuration) {
      lv.alpha = visible ? 1 : 0
    }
  }
}
