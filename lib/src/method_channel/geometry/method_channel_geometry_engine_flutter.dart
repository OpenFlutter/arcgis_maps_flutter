import 'package:arcgis_maps_flutter/arcgis_maps_flutter.dart';
import 'package:arcgis_maps_flutter/src/method_channel/geometry/geometry_engine_flutter_platform.dart';
import 'package:flutter/services.dart';

class MethodChannelGeometryEngineFlutter extends GeometryEngineFlutterPlatform {
  final MethodChannel _channel =
      const MethodChannel("plugins.flutter.io/geometry_engine");

  @override
  Future<Geometry?> project(
      Geometry geometry, SpatialReference spatialReference) async {
    final result = await _channel.invokeMethod("project", {
      "geometry": geometry.toJson(),
      "spatialReference": spatialReference.toJson(),
    });
    if (result == null) {
      return null;
    }
    return Geometry.fromJson(result);
  }

  @override
  Future<GeodeticDistanceResult?> distanceGeodetic({
    required AGSPoint point1,
    required AGSPoint point2,
    required LinearUnitId distanceUnitId,
    required AngularUnitId azimuthUnitId,
    required GeodeticCurveType curveType,
  }) async {
    final result = await _channel.invokeMethod("distanceGeodetic", {
      "point1": point1.toJson(),
      "point2": point2.toJson(),
      "distanceUnitId": distanceUnitId.index,
      "azimuthUnitId": azimuthUnitId.index,
      "curveType": curveType.index,
    });
    if (result == null) {
      return null;
    }
    return GeodeticDistanceResult.fromJson(result);
  }

  @override
  Future<AGSPolygon?> bufferGeometry({
    required Geometry geometry,
    required double distance,
  }) {
    return _channel.invokeMethod("bufferGeometry", {
      "geometry": geometry.toJson(),
      "distance": distance,
    }).then((result) {
      if (result == null) {
        return null;
      }
      return AGSPolygon.fromJson(result);
    });
  }

  @override
  Future<AGSPolygon?> geodeticBufferGeometry({
    required Geometry geometry,
    required double distance,
    required LinearUnitId distanceUnit,
    required double maxDeviation,
    required GeodeticCurveType curveType,
  }) {
    return _channel.invokeMethod("geodeticBufferGeometry", {
      "geometry": geometry.toJson(),
      "distance": distance,
      "distanceUnit": distanceUnit.index,
      "maxDeviation": maxDeviation,
      "curveType": curveType.index,
    }).then((result) {
      if (result == null) {
        return null;
      }
      return AGSPolygon.fromJson(result);
    });
  }
}
