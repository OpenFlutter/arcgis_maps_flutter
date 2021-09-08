//
// Created by Valentin Grigorean on 08.09.2021.
//

import Foundation
import ArcGIS

struct SymbolVisibilityFilter: Hashable {

    let minZoom: Double
    let maxZoom: Double

    init(data: Dictionary<String, Any>) {
        minZoom = data["minZoom"] as! Double
        maxZoom = data["maxZoom"] as! Double
    }
}

class SymbolVisibilityFilterController {
    private var graphicControllers = Dictionary<UInt, GraphicControllerInfo>()
    private var initialValues = Dictionary<UInt, Bool>()

    private let workerQueue: DispatchQueue
    private weak var mapView: AGSMapView?
    private var scaleObservation: NSKeyValueObservation?

    private var mapScale: Double


    init(workerQueue: DispatchQueue,
         mapView: AGSMapView) {
        self.workerQueue = workerQueue
        self.mapView = mapView
        mapScale = mapView.mapScale
    }

    deinit {
        unbindFromMapView(mapView: mapView)
    }

    func clear() {
        unbindFromMapView(mapView: mapView)

        workerQueue.async { [self] in
            for item in (graphicControllers.values) {
                item.graphicController.isVisible = initialValues[objectIdentifierFor(item.graphicController)]!
            }

            initialValues.removeAll()
            graphicControllers.removeAll()
        }
    }

    func addGraphicsController(graphicController: BaseGraphicController,
                               visibilityFilter: SymbolVisibilityFilter,
                               initValue: Bool) {

        workerQueue.async { [self] in

            let id = objectIdentifierFor(graphicController)

            initialValues[id] = initValue

            let graphicControllerInfo = graphicControllers[id] ?? GraphicControllerInfo(graphicController: graphicController, visibilityFilter: visibilityFilter)

            handleGraphicsFilterZoom(graphicControllerInfo: graphicControllerInfo, currentZoom: mapScale)

            if let temp = graphicControllers[id] {
                if temp.visibilityFilter == visibilityFilter {
                    return
                }
            }

            graphicControllers[id] = graphicControllerInfo

            handleRegistrationToScaleChanged()
        }
    }

    func removeGraphicsController(graphicController: BaseGraphicController) {
        workerQueue.async { [self] in
            let id = objectIdentifierFor(graphicController)

            guard let graphicControllerInfo = graphicControllers.removeValue(forKey: id) else {
                return
            }

            graphicControllerInfo.graphicController.isVisible = initialValues[id]!
            handleRegistrationToScaleChanged()
        }
    }


    private func mapScaleChanged() {
        guard let currentZoom = mapView?.mapScale else {
            return
        }
        mapScale = currentZoom
        workerQueue.async { [self] in
            for item in (graphicControllers.values) {
                handleGraphicsFilterZoom(graphicControllerInfo: item, currentZoom: mapScale)
            }
        }
    }

    private func handleGraphicsFilterZoom(graphicControllerInfo: GraphicControllerInfo,
                                          currentZoom: Double) {
        if currentZoom == Double.nan {
            return
        }

        let visibilityFilter = graphicControllerInfo.visibilityFilter
        let graphicController = graphicControllerInfo.graphicController
        if currentZoom < visibilityFilter.minZoom && currentZoom > visibilityFilter.maxZoom {
            graphicController.isVisible = initialValues[objectIdentifierFor(graphicController)]!
        } else {
            graphicController.isVisible = false
        }
    }

    private func bindToMapView(mapView: AGSMapView?) {
        scaleObservation = mapView?.observe(\.mapScale, options: .new) { [weak self] _,
                                                                                     _ in
            self?.mapScaleChanged()
        }
    }

    private func unbindFromMapView(mapView: AGSMapView?) {
        // invalidate observations and set to nil
        scaleObservation?.invalidate()
        scaleObservation = nil
    }

    private func handleRegistrationToScaleChanged() {
        if graphicControllers.count > 0 && scaleObservation == nil {
            bindToMapView(mapView: mapView)
        } else if graphicControllers.count == 0 && scaleObservation != nil {
            unbindFromMapView(mapView: mapView)
        }
    }

    // Returns a unique UINT for each object. Used because GraphicController is not hashable
    // and we need to use it as the key in our dictionary of legendInfo arrays.
    private func objectIdentifierFor(_ obj: AnyObject) -> UInt {
        UInt(bitPattern: ObjectIdentifier(obj))
    }
}

fileprivate struct GraphicControllerInfo {
    let graphicController: BaseGraphicController
    let visibilityFilter: SymbolVisibilityFilter
}
