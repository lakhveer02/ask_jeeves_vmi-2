// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/glassmorphic_container.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/holographic_button.dart';
import 'package:ask_jeeves_vmi/core/router/app_router.dart';
import 'package:ask_jeeves_vmi/data/services/location/geofence_monitor_service.dart';
import 'package:ask_jeeves_vmi/data/services/location/geofence_service.dart';
import 'package:ask_jeeves_vmi/core/utils/distance_formatter.dart';

/// Geofence validation screen with location verification using real API
class GeofenceValidationScreen extends ConsumerStatefulWidget {
  const GeofenceValidationScreen({super.key});

  @override
  ConsumerState<GeofenceValidationScreen> createState() =>
      _GeofenceValidationScreenState();
}

class _GeofenceValidationScreenState
    extends ConsumerState<GeofenceValidationScreen> {
  bool _isValidating = true;
  bool _isAuthorized = false;
  Position? _currentPosition;
  String? _errorMessage;
  String? _currentAddress;
  double? _distance;

  @override
  void initState() {
    super.initState();
    _validateLocation();
  }

  Future<void> _validateLocation() async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _currentAddress = null;
      _distance = null;
    });

    try {
      final geofenceService = ref.read(geofenceServiceProvider);
      
      // Get current position first
      final monitorService = ref.read(geofenceMonitorServiceProvider);
      final position = await monitorService.getCurrentPosition();
      
      if (position == null) {
        setState(() {
          _isValidating = false;
          _isAuthorized = false;
          _errorMessage = 'Unable to get location. Please enable location services.';
        });
        return;
      }

      setState(() {
        _currentPosition = position;
      });

      // Get address from coordinates
      await _getAddressFromCoordinates(position.latitude, position.longitude);

      // Check location using real API
      // This will automatically create a geofence if none exists (404)
      final checkResult = await geofenceService.checkCurrentLocation();
      
      setState(() {
        _isValidating = false;
        _isAuthorized = checkResult.insideGeofence;
        _distance = checkResult.distance;
        
        if (!checkResult.insideGeofence) {
          _errorMessage = 'You are outside the authorized zone\n'
              'Distance: ${DistanceFormatter.format(checkResult.distance)}\n'
              '${_currentAddress ?? "Location unavailable"}';
        }
      });
      
    } catch (e) {
      setState(() {
        _isValidating = false;
        _isAuthorized = false;
        _errorMessage = 'Location validation error: $e';
      });
    }
  }

  /// Get address from coordinates using geocoding
  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        // Build address string
        List<String> addressParts = [];
        
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        
        setState(() {
          _currentAddress = addressParts.join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Address unavailable';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.deepBlack,
              AppTheme.darkMatterViolet,
            ],
          ),
        ),
        child: SafeArea(
          child: _isAuthorized && !_isValidating
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: content,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      content,
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
                // Location icon
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isAuthorized
                        ? LinearGradient(
                            colors: [
                              AppTheme.successGreen,
                              AppTheme.mercuryTeal,
                            ],
                          )
                        : AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: (_isAuthorized
                                ? AppTheme.successGreen
                                : AppTheme.electricCyan)
                            .withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isAuthorized
                        ? Icons.location_on
                        : Icons.location_searching,
                    size: 40,
                    color: AppTheme.deepBlack,
                  ),
                )
                    .animate(
                      onPlay: (controller) =>
                          _isValidating ? controller.repeat() : null,
                    )
                    .shimmer(duration: 2000.ms),

                const SizedBox(height: 16),

                Text(
                  _isValidating
                      ? 'Validating Location'
                      : _isAuthorized
                          ? 'Location Authorized'
                          : 'Location Restricted',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _isValidating
                        ? 'Checking geofence boundaries...'
                        : _isAuthorized
                            ? ''
                            : _errorMessage ?? 'Access denied from this location',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _isAuthorized
                              ? AppTheme.successGreen
                              : _isValidating
                                  ? AppTheme.electricCyan
                                  : AppTheme.warningRed,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if (!_isValidating && !_isAuthorized) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.warningRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.warningRed.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.warningRed,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Geofence Validation Failed',
                            style: TextStyle(
                              color: AppTheme.warningRed,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (_distance != null) ...[
                            Flexible(
                              child: Text(
                                'You are ${DistanceFormatter.format(_distance!)} from the authorized location',
                                style: TextStyle(
                                  color: AppTheme.warningRed.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Flexible(
                            child: Text(
                              'Possible reasons:\n'
                              '• Outside authorized geofence area\n'
                              '• Location services disabled\n'
                              '• GPS signal unavailable\n'
                              '• No geofence configured for device',
                              style: TextStyle(
                                color: AppTheme.warningRed.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 6,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Map visualization
                GlassmorphicContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: AppTheme.radiusLarge,
                  child: Column(
                    children: [
                      // Simulated map
                      Container(
                        height: _isAuthorized && !_isValidating ? 160 : 200,
                        decoration: BoxDecoration(
                          color: AppTheme.deepBlack.withOpacity(0.5),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: AppTheme.electricCyan.withOpacity(0.3),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Geofence circle
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isAuthorized
                                      ? AppTheme.successGreen
                                      : AppTheme.electricCyan,
                                  width: 2,
                                ),
                                color: (_isAuthorized
                                        ? AppTheme.successGreen
                                        : AppTheme.electricCyan)
                                    .withOpacity(0.1),
                              ),
                            )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .scale(
                                  duration: 2000.ms,
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.2, 1.2),
                                )
                                .fadeOut(duration: 2000.ms),

                            // Location marker
                            Icon(
                              Icons.my_location,
                              color: _isAuthorized
                                  ? AppTheme.successGreen
                                  : AppTheme.electricCyan,
                              size: 32,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Location details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Latitude:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            _currentPosition != null
                                ? '${_currentPosition!.latitude.toStringAsFixed(4)}°'
                                : 'N/A',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppTheme.electricCyan,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Longitude:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            _currentPosition != null
                                ? '${_currentPosition!.longitude.toStringAsFixed(4)}°'
                                : 'N/A',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppTheme.electricCyan,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   // children: [
                      //   //   Text(
                      //   //     'Accuracy:',
                      //   //     style: Theme.of(context).textTheme.bodySmall,
                      //   //   ),
                      //   //   Text(
                      //   //     _currentPosition != null
                      //   //         ? '±${_currentPosition!.accuracy.toStringAsFixed(0)}m'
                      //   //         : 'N/A',
                      //   //     style: Theme.of(context)
                      //   //         .textTheme
                      //   //         .labelMedium
                      //   //         ?.copyWith(
                      //   //           color: _currentPosition != null &&
                      //   //                   _currentPosition!.accuracy < 50
                      //   //               ? AppTheme.successGreen
                      //   //               : AppTheme.warningRed,
                      //   //         ),
                      //   //   ),
                      //   // ],
                      // ),

                      // Distance from geofence
                      // if (_distance != null) ...[
                      //   const SizedBox(height: 8),
                      //   Row(
                      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //     children: [
                      //       Text(
                      //         'Distance:',
                      //         style: Theme.of(context).textTheme.bodySmall,
                      //       ),
                      //       Text(
                      //         '${_distance!.toStringAsFixed(1)}m',
                      //         style: Theme.of(context)
                      //             .textTheme
                      //             .labelMedium
                      //             ?.copyWith(
                      //               color: _isAuthorized
                      //                   ? AppTheme.successGreen
                      //                   : AppTheme.warningRed,
                      //               fontWeight: FontWeight.bold,
                      //             ),
                      //       ),
                      //     ],
                      //   ),
                      // ],

                      // Geofence name
                      // if (_geofenceName != null) ...[
                      //   const SizedBox(height: 8),
                      //   Row(
                      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //     children: [
                      //       Text(
                      //         'Geofence:',
                      //         style: Theme.of(context).textTheme.bodySmall,
                      //       ),
                      //       Flexible(
                      //         child: Text(
                      //           _geofenceName!,
                      //           style: Theme.of(context)
                      //               .textTheme
                      //               .labelMedium
                      //               ?.copyWith(
                      //                 color: AppTheme.electricCyan,
                      //               ),
                      //           textAlign: TextAlign.right,
                      //           overflow: TextOverflow.ellipsis,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ],

                      // Address display
                      if (_currentAddress != null) ...[
                        const SizedBox(height: 16),
                        const Divider(
                          color: AppTheme.electricCyan,
                          thickness: 0.5,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location:',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppTheme.electricCyan,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _currentAddress!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.electricCyan,
                                        ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (!_isValidating && _isAuthorized)
                  HolographicButton(
                    text: 'Continue to Vault',
                    onPressed: () {
                      context.go(AppRoutes.vaultInitialization);
                    },
                    icon: Icons.arrow_forward_rounded,
                  ),

                if (!_isValidating && !_isAuthorized)
                  HolographicButton(
                    text: 'Retry Validation',
                    onPressed: _validateLocation,
                    icon: Icons.refresh,
                  ),

                if (_isValidating)
                  const CircularProgressIndicator(
                    color: AppTheme.electricCyan,
                  ),
              ],
            );
  }
}

  /* COMMENTED OUT - Not needed when geolocation is disabled
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkMatterViolet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(
            color: AppTheme.electricCyan.withAlpha(77),
          ),
        ),
        title: Text(
          'Location Permission Required',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'This app requires location permission to validate your geofence. Please enable location permission in app settings.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.electricCyan),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final permissionService = ref.read(permissionProvider);
              await permissionService.openSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: AppTheme.successGreen),
            ),
          ),
        ],
      ),
    );
  }
  */

