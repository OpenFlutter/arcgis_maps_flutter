package com.valentingrigorean.arcgis_maps_flutter.map;

import androidx.annotation.NonNull;

import com.esri.arcgisruntime.mapping.view.Graphic;
import com.esri.arcgisruntime.mapping.view.GraphicsOverlay;
import com.esri.arcgisruntime.mapping.view.LocationDisplay;
import com.esri.arcgisruntime.mapping.view.MapView;
import com.valentingrigorean.arcgis_maps_flutter.Convert;

import java.util.ArrayList;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class LocationDisplayController implements MapTouchGraphicDelegate, LocationDisplay.LocationChangedListener, MethodChannel.MethodCallHandler, LocationDisplay.AutoPanModeChangedListener, LocationDisplay.DataSourceStatusChangedListener {
    private static final String LOCATION_ATTRIBUTE = "my_location_attribute";

    private final MethodChannel channel;
    private final MapView mapView;
    private final LocationDisplay locationDisplay;
    private final GraphicsOverlay locationGraphicsOverlay;

    private final Graphic locationGraphic;

    private LocationDisplayControllerDelegate delegate;

    private MethodChannel.Result startResult;


    private boolean trackUserLocationTap = false;

    public LocationDisplayController(MethodChannel methodChannel, MapView mapView) {
        this.channel = methodChannel;
        this.mapView = mapView;
        this.locationDisplay = mapView.getLocationDisplay();
        this.locationGraphicsOverlay = new GraphicsOverlay();
        this.locationGraphicsOverlay.setOpacity(0);
        this.locationGraphic = new Graphic();
        this.locationGraphic.setGeometry(mapView.getLocationDisplay().getMapLocation());
        this.locationGraphic.getAttributes().put(LOCATION_ATTRIBUTE, true);
        this.locationGraphic.setSymbol(locationDisplay.getDefaultSymbol());
        this.locationGraphicsOverlay.getGraphics().add(locationGraphic);
        channel.setMethodCallHandler(this);
        locationDisplay.addDataSourceStatusChangedListener(this);
        locationDisplay.addAutoPanModeChangedListener(this);
        locationDisplay.addLocationChangedListener(this);
    }

    @Override
    protected void finalize() throws Throwable {
        locationDisplay.removeLocationChangedListener(this);
        locationDisplay.removeAutoPanModeChangedListener(this);

        channel.setMethodCallHandler(null);
        super.finalize();
    }

    public void setTrackUserLocationTap(boolean trackUserLocationTap) {
        if (this.trackUserLocationTap != trackUserLocationTap) {
            this.trackUserLocationTap = trackUserLocationTap;
            if (trackUserLocationTap) {
                mapView.getGraphicsOverlays().add(locationGraphicsOverlay);
            } else {
                mapView.getGraphicsOverlays().remove(locationGraphicsOverlay);
            }
        }
    }

    public void setLocationDisplayControllerDelegate(LocationDisplayControllerDelegate delegate) {
        this.delegate = delegate;
    }


    @Override
    public boolean canConsumeTaps() {
        return trackUserLocationTap;
    }

    @Override
    public boolean didHandleGraphic(Graphic graphic) {
        final boolean result = graphic.getAttributes().containsKey(LOCATION_ATTRIBUTE);
        if (result && delegate != null) {
            delegate.onUserLocationTap();
        }
        return result;
    }

    @Override
    public void onStatusChanged(LocationDisplay.DataSourceStatusChangedEvent dataSourceStatusChangedEvent) {
        locationGraphic.setGeometry(locationDisplay.getMapLocation());
        if (startResult != null) {
            if (dataSourceStatusChangedEvent.isStarted()) {
                startResult.success(null);
            } else {
                String error = "Unknown error";
                if (dataSourceStatusChangedEvent.getError() != null) {
                    error = dataSourceStatusChangedEvent.getError().getMessage();
                }
                startResult.error("Failed to start locationDisplay", error, null);
            }
            startResult = null;
        }
    }


    @Override
    public void onAutoPanModeChanged(LocationDisplay.AutoPanModeChangedEvent autoPanModeChangedEvent) {
        channel.invokeMethod("onAutoPanModeChanged", autoPanModeChangedEvent.getAutoPanMode().ordinal());
    }

    @Override
    public void onLocationChanged(LocationDisplay.LocationChangedEvent locationChangedEvent) {
        locationGraphic.setGeometry(locationDisplay.getMapLocation());
        channel.invokeMethod("onLocationChanged", Convert.locationToJson(locationChangedEvent.getLocation()));
    }


    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "getStarted":
                result.success(locationDisplay.isStarted());
                break;
            case "setAutoPanMode":
                locationDisplay.setAutoPanMode(Convert.toAutoPanMode(call.arguments));
                break;
            case "setInitialZoomScale":
                locationDisplay.setInitialZoomScale(call.arguments());
                break;
            case "setNavigationPointHeightFactor":
                locationDisplay.setNavigationPointHeightFactor(call.arguments());
                break;
            case "setWanderExtentFactor":
                locationDisplay.setWanderExtentFactor(call.arguments());
                break;
            case "getLocation":
                if (locationDisplay.getLocation() != null) {
                    result.success(Convert.locationToJson(locationDisplay.getLocation()));
                } else {
                    result.success(null);
                }
                break;
            case "getMapLocation":
                if (locationDisplay.getMapLocation() != null) {
                    result.success(Convert.geometryToJson(locationDisplay.getMapLocation()));
                } else {
                    result.success(null);
                }
            case "getHeading":
                result.success(locationDisplay.getHeading());
                break;
            case "setUseCourseSymbolOnMovement":
                locationDisplay.setUseCourseSymbolOnMovement(call.arguments());
                break;
            case "setOpacity":
                locationDisplay.setOpacity(call.arguments());
                break;
            case "setShowAccuracy":
                locationDisplay.setShowAccuracy(call.arguments());
                break;
            case "setShowLocation":
                locationDisplay.setShowLocation(call.arguments());
                break;
            case "setShowPingAnimationSymbol":
                locationDisplay.setShowPingAnimation(call.arguments());
                break;
            case "start":
                startResult = result;
                locationDisplay.startAsync();
                break;
            case "stop":
                locationDisplay.stop();
                result.success(null);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    public interface LocationDisplayControllerDelegate {
        void onUserLocationTap();
    }
}
