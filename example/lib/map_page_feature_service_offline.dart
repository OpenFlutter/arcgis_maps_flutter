import 'dart:io';

import 'package:arcgis_maps_flutter/arcgis_maps_flutter.dart';
import 'package:arcgis_maps_flutter_example/utils/credentials.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class MapPageFeatureServiceOffline extends StatefulWidget {
  const MapPageFeatureServiceOffline({Key? key}) : super(key: key);

  @override
  State<MapPageFeatureServiceOffline> createState() =>
      _MapPageFeatureServiceOfflineState();
}

class _MapPageFeatureServiceOfflineState
    extends State<MapPageFeatureServiceOffline> {
  final GeodatabaseSyncTask _task = GeodatabaseSyncTask(
    url:
        'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/WaterDistributionNetwork/FeatureServer',
  );

  GenerateGeodatabaseJob? _job;

  late ArcgisMapController _mapController;
  Layer? _downloadedFeatureLayer;

  bool _isDownloading = false;

  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _downloadTileCache();
  }

  @override
  void dispose() {
    _job?.cancel();
    _job?.dispose();
    _task.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Future service Cache'),
      ),
      body: ArcgisMapView(
        map: ArcGISMap.topographic(),
        viewpoint: Viewpoint.fromPoint(
          point: AGSPoint.fromLatLng(
            latitude: 41.774317,
            longitude: -88.149655,
          ),
          scale: 18055.954822,
        ),
        operationalLayers: _downloadedFeatureLayer != null
            ? {_downloadedFeatureLayer!}
            : const {},
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
      floatingActionButton: !_isDownloading
          ? null
          : FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(
                value: _progress,
                color: Colors.white,
              ),
            ),
    );
  }

  void _downloadTileCache() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = '${appDocDir.path}/gdb.geodatabase';

    if (kDebugMode) {
      print('appDocPath: $appDocPath');
    }

    if (await File(appDocPath).exists()) {
      _downloadedFeatureLayer = GeodatabaseLayer(
        layerId: LayerId(appDocPath),
        path: appDocPath,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {});
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    final params = await _task.defaultGenerateGeodatabaseParameters(
      areaOfInterest: AGSPolygon(
        points: [
          [
            AGSPoint.fromLatLng(
              latitude: 41.778064,
              longitude: -88.153245,
            ),
            AGSPoint.fromLatLng(
              latitude: 41.778870,
              longitude: -88.146708,
            ),
            AGSPoint.fromLatLng(
              latitude: 41.769764,
              longitude: -88.145878,
            ),
            AGSPoint.fromLatLng(
              latitude: 41.770330,
              longitude: -88.153431,
            ),
          ],
        ],
        spatialReference: SpatialReference.wgs84(),
      ),
    );
    final job = await _task.generateJob(
      parameters: params.copyWith(
        returnAttachments: false,
      ),
      fileNameWithPath: appDocPath,
    );

    job.onMessageAdded.listen((event) {
      if (kDebugMode) {
        print('message: $event');
      }
    });

    _job = job;
    job.onStatusChanged.listen((status) async {
      if (kDebugMode) {
        print('status: $status');
      }

      if (status == JobStatus.succeeded) {
        if (mounted) {
          setState(() {
            _downloadedFeatureLayer = GeodatabaseLayer(
              layerId: LayerId(appDocPath),
              path: appDocPath.replaceAll(
                '.geodatabase',
                '',
              ),
            );
            _isDownloading = false;
          });
        }
      }
      if (status == JobStatus.failed) {
        final error = await job.error;
        if (kDebugMode) {
          print('error: $error');
        }
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
        }
      }
    });

    job.onProgressChanged.listen((progress) {
      if (kDebugMode) {
        print('progress: $progress');
      }
      if (mounted) {
        setState(() {
          _progress = progress;
        });
      }
    });

    final didStart = await job.start();
    if (kDebugMode) {
      print('didStart: $didStart');
    }
  }
}
