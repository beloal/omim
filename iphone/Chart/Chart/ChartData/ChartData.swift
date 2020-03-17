import UIKit

public enum ChartType {
  case regular
  case yScaled
  case stacked
  case percentage
}

public enum ChartLineType: String {
  case line = "line"
  case bar = "bar"
  case area = "area"
  case lineArea = "lineArea"
}

public protocol IFormatter {
  func string(from value: Int) -> String
}

public protocol IChartData {
  var xAxisLabels: [String] { get }
//  var xAxisDates: [Date] { get }
  var lines: [IChartLine] { get }
  var type: ChartType { get }
}

public protocol IChartLine {
  var values: [Int] { get }
  var name: String { get }
  var color: UIColor { get }
  var type: ChartLineType { get }
}
