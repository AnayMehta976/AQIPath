import 'dart:async';
import 'dart:convert';

import 'package:aqi_app/configs/network.dart';
import 'package:aqi_app/utils/dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../../constants/constants.dart';

class PlacePrediction {
  final String description;
  final String placeId;

  PlacePrediction({required this.description, required this.placeId});

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'],
      placeId: json['place_id'],
    );
  }
}

class PlaceDetails {
  final String name;
  final double lat;
  final double lng;
  final String disp;

  PlaceDetails({
    required this.disp,
    required this.name,
    required this.lat,
    required this.lng,
  });
}

class PlaceAutocompleteFieldWithOverlay extends StatefulWidget {
  final String apiKey;
  final Function(PlaceDetails) onPlaceSelected;
  final String hintText;
  final double? biasLat;
  final double? biasLng;
  final bool isborder;
  final crossbtn;
  final TextEditingController mytxtctrl;

  const PlaceAutocompleteFieldWithOverlay({
    Key? key,
    required this.apiKey,
    required this.onPlaceSelected,
    required this.hintText,
    this.biasLat,
    this.biasLng,
    this.isborder = false,
    required this.mytxtctrl,
    required this.crossbtn,
  }) : super(key: key);

  @override
  State<PlaceAutocompleteFieldWithOverlay> createState() =>
      _PlaceAutocompleteFieldWithOverlayState();
}

class _PlaceAutocompleteFieldWithOverlayState
    extends State<PlaceAutocompleteFieldWithOverlay> {
  // final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  final Uuid _uuid = const Uuid();
  String _sessionToken = '';
  List<PlacePrediction> _predictions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _sessionToken = _uuid.v4();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeOverlay();
      } else {
        if (_predictions.isNotEmpty) {
          _showOverlay();
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    // widget.mytxtctrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _getPredictions(String input) async {
    if (input.isEmpty) {
      _removeOverlay();
      return;
    }

    final params = {
      'input': input,
      'key': widget.apiKey,
      'sessiontoken': _sessionToken,
      'components': 'country:in',
    };

    if (widget.biasLat != null && widget.biasLng != null) {
      params['location'] = '${widget.biasLat},${widget.biasLng}';
      params['radius'] = '50000';
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      params,
    );
    if (await Network.isConnected()) {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions =
            (data['predictions'] as List)
                .map((p) => PlacePrediction.fromJson(p))
                .toList();
        setState(() {
          _predictions = predictions;
        });
        if (_predictions.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      } else {
        throw Exception('Failed to fetch predictions');
      }
    } else {
      UtilDialog.showRetry(
        title: "No Internet Connection ?",
        content: "NO Internet Connection found. Please Connect with internet",
        onClose: () async {
          Navigator.pop(context);
        },
      );
    }
  }

  Future<void> _getPlaceDetails(String placeId, String disp) async {
    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
          'place_id': placeId,
          'fields': 'name,geometry',
          'key': widget.apiKey,
          'sessiontoken': _sessionToken,
        });

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = data['result'];
      // log("my prediction: $data $disp" + "filter" + result.toString());

      final name = result['name'];
      final lat = result['geometry']['location']['lat'];
      final lng = result['geometry']['location']['lng'];

      widget.onPlaceSelected(
        PlaceDetails(name: name, lat: lat, lng: lng, disp: disp),
      );

      setState(() {
        widget.mytxtctrl.text = disp;
        _predictions = [];
      });

      _sessionToken = _uuid.v4();
      _removeOverlay();
      _focusNode.unfocus();
    } else {
      throw Exception('Failed to fetch place details');
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder:
          (context) => Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 5.0),
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _predictions.length,
                  itemBuilder: (context, index) {
                    final p = _predictions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(p.description),
                      onTap: () {
                        _getPlaceDetails(p.placeId, p.description);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.mytxtctrl,
        focusNode: _focusNode,
        textAlignVertical: widget.isborder ? TextAlignVertical(y: 0.1) : null,
        style: FONT_CONST.REGULAR_PRIMARY.copyWith(
          color: COLOR_CONST.btnColorblk,
        ),
        decoration: InputDecoration(
          // filled: true,
          border:
              widget.isborder
                  ? UnderlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          COLOR_CONST
                              .deleteButtonColor, // You can change the color of the bottom border here
                      width: 1.0, // Customize the width of the border
                    ),
                  )
                  : InputBorder.none,
          hintStyle: FONT_CONST.REGULAR_PRIMARY.copyWith(
            color: COLOR_CONST.btnColorblk,
          ),
          alignLabelWithHint: true,

          labelStyle: FONT_CONST.REGULAR_PRIMARY.copyWith(
            color: COLOR_CONST.btnColorblk,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4.0,
            vertical: 4,
          ),
          hintText: widget.hintText,
          suffixIcon:
              widget.mytxtctrl.text.isNotEmpty && widget.crossbtn
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.mytxtctrl.clear();
                      setState(() {
                        _predictions = [];
                      });
                      _removeOverlay();
                    },
                  )
                  : null,
        ),
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            _getPredictions(value);
          });
        },
      ),
    );
  }
}
