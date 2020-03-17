//
//  KmlPoints.swift
//  Charts
//
//  Created by aleksey.belousov on 06/02/2020.
//  Copyright © 2020 aleksey.belousov. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import MapKit

struct KmlPoint {
  let location: CLLocation
  let alt: Int
  init(_ rawString: String) {
    let components = rawString.split(separator: ",")
    let lon = Double(components[0])!
    let lat = Double(components[1])!
    location = CLLocation(latitude: lat, longitude: lon)
    alt = Int(components[2])!
  }
}

struct ChartPoint {
  let distance: Double
  let altitude: Int
}

public struct KmlPoints {
  struct Line: IChartLine {
    var values: [Int]
    var name: String
    var color: UIColor
    var type: ChartLineType
  }
  fileprivate let chartLines: [Line]
  fileprivate let points: [ChartPoint]
  fileprivate let labels: [String]

  public init(_ rawString: String) {
    let kmlPoints = rawString.split(separator: " ").map {
      KmlPoint(String($0))
    }

    let distancePoints = KmlPoints.convertPoints(kmlPoints)
    points = KmlPoints.rearrangePoints(distancePoints)
    let values = points.map { $0.altitude }
    let formatter = MKDistanceFormatter()
    formatter.unitStyle = .abbreviated
    formatter.units = .metric
    labels = points.map { formatter.string(fromDistance: $0.distance )}
    let color = UIColor(red: 0.12, green: 0.59, blue: 0.94, alpha: 1)
    let l1 = Line(values: values, name: "Altitude", color: color, type: .line)
    let l2 = Line(values: values, name: "Altitude", color: color.withAlphaComponent(0.12), type: .lineArea)
    chartLines = [l1, l2]
  }

  private static func convertPoints(_ kmlPoints: [KmlPoint]) -> [ChartPoint] {
    var result: [ChartPoint] = []
    var lastPoint: KmlPoint? = nil
    var distance: Double = 0
    for kmlPoint in kmlPoints {
      if let p = lastPoint {
        distance += p.location.distance(from: kmlPoint.location)
      }
      result.append(ChartPoint(distance: distance, altitude: kmlPoint.alt))
      lastPoint = kmlPoint
    }
    return result
  }

  private static func rearrangePoints(_ points: [ChartPoint]) -> [ChartPoint] {
    if points.isEmpty {
      return []
    }

    var result: [ChartPoint] = []

    let distance = points.last?.distance ?? 0
    let step = floor(distance / Double(points.count))
    result.append(points[0])
    var currentDistance = step
    var i = 1
    while i < points.count {
      let prevPoint = points[i - 1]
      let nextPoint = points[i]
      if currentDistance > nextPoint.distance {
        i += 1
        continue
      }
      result.append(ChartPoint(distance: currentDistance,
                               altitude: altBetweenPoints(prevPoint, nextPoint, at: currentDistance)))
      currentDistance += step
      if currentDistance > nextPoint.distance {
        i += 1
      }
    }

    return result
  }

  private static func altBetweenPoints(_ p1: ChartPoint, _ p2: ChartPoint, at distance: Double) -> Int {
    assert(distance > p1.distance && distance < p2.distance, "distance must be between points")

    let d = (distance - p1.distance) / (p2.distance - p1.distance)
    return p1.altitude + Int(round(Double(p2.altitude - p1.altitude) * d))
  }
}

extension KmlPoints: IChartData {
  public var xAxisLabels: [String] {
    labels
  }

  public var lines: [IChartLine] {
    chartLines
  }

  public var type: ChartType {
    .regular
  }
}
