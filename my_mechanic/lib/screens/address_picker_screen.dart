import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../utils/platform_utils.dart';

class AddressPickerScreen extends StatefulWidget {
  final String? initialAddress;

  const AddressPickerScreen({
    super.key,
    this.initialAddress,
  });

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  
  bool _isSearching = false;
  List<Map<String, dynamic>> _suggestions = [];
  String? _selectedAddress;
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _searchController.text = widget.initialAddress!;
      _selectedAddress = widget.initialAddress;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cityController.dispose();
    _searchController.dispose();
    _cityFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Build search query with city if specified
      String searchQuery = query;
      
      // Add city if provided
      if (_cityController.text.trim().isNotEmpty) {
        searchQuery = '$query, ${_cityController.text.trim()}';
      }
      
      // Add Romania to query for better results
      if (!searchQuery.toLowerCase().contains('romania') && !searchQuery.toLowerCase().contains('românia')) {
        searchQuery = '$searchQuery, Romania';
      }
      
      // Search for locations using geocoding
      List<Location> locations = await locationFromAddress(searchQuery);
      
      if (locations.isNotEmpty && mounted) {
        // Get placemarks for each location to get formatted addresses
        List<Map<String, dynamic>> newSuggestions = [];
        
        for (var location in locations.take(5)) {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );
            
            if (placemarks.isNotEmpty) {
              final placemark = placemarks.first;
              final formattedAddress = _formatAddress(placemark);
              
              newSuggestions.add({
                'address': formattedAddress,
                'latitude': location.latitude,
                'longitude': location.longitude,
                'placemark': placemark,
              });
            }
          } catch (e) {
            // Skip this location if we can't get placemark
            continue;
          }
        }
        
        setState(() {
          _suggestions = newSuggestions;
          _isSearching = false;
        });
      } else if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
        // Don't show error message during typing, only when no results found
      }
    }
  }

  String _formatAddress(Placemark placemark) {
    List<String> parts = [];
    
    // Add street name and number
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    } else if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
      String street = placemark.thoroughfare!;
      if (placemark.subThoroughfare != null && placemark.subThoroughfare!.isNotEmpty) {
        street += ' ${placemark.subThoroughfare!}';
      }
      parts.add(street);
    }
    
    // Add locality/city
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    } else if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
      parts.add(placemark.subAdministrativeArea!);
    }
    
    // Add county/state
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }
    
    // Add country
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }
    
    return parts.join(', ');
  }

  void _selectAddress(Map<String, dynamic> suggestion) {
    setState(() {
      _selectedAddress = suggestion['address'];
      _selectedLatitude = suggestion['latitude'];
      _selectedLongitude = suggestion['longitude'];
      _searchController.text = suggestion['address'];
      _suggestions = [];
    });
    _searchFocusNode.unfocus();
  }

  void _confirmSelection() {
    if (_selectedAddress == null) {
      _showSnackBar('Please select an address', isError: true);
      return;
    }

    Navigator.pop(context, {
      'address': _selectedAddress,
      'latitude': _selectedLatitude,
      'longitude': _selectedLongitude,
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    if (PlatformUtils.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Select Address'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Done'),
            onPressed: _confirmSelection,
          ),
        ),
        child: SafeArea(
          child: _buildContent(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Address'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmSelection,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PlatformUtils.isIOS 
                ? CupertinoColors.systemBackground 
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // City field
              Material(
                color: Colors.transparent,
                child: TextField(
                  controller: _cityController,
                  focusNode: _cityFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Oraș (ex: Timișoara)',
                    labelText: 'Oraș',
                    prefixIcon: Icon(
                      PlatformUtils.isIOS ? CupertinoIcons.building_2_fill : Icons.location_city,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    // Clear suggestions when city changes
                    if (_suggestions.isNotEmpty) {
                      setState(() {
                        _suggestions = [];
                        _selectedAddress = null;
                        _selectedLatitude = null;
                        _selectedLongitude = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Street address field
              Material(
                color: Colors.transparent,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Stradă și număr (ex: Vasile Pârvan 4)',
                    labelText: 'Adresă',
                    prefixIcon: Icon(
                      PlatformUtils.isIOS ? CupertinoIcons.search : Icons.search,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              PlatformUtils.isIOS ? CupertinoIcons.clear : Icons.clear,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _suggestions = [];
                                _selectedAddress = null;
                                _selectedLatitude = null;
                                _selectedLongitude = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: _searchAddress,
                  onChanged: (value) {
                    // Cancel previous timer
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    
                    if (value.isEmpty) {
                      setState(() {
                        _suggestions = [];
                        _selectedAddress = null;
                        _selectedLatitude = null;
                        _selectedLongitude = null;
                      });
                      return;
                    }
                    
                    if (value.length >= 3) {
                      // Wait 800ms after user stops typing before searching
                      _debounce = Timer(const Duration(milliseconds: 800), () {
                        _searchAddress(value);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completează orașul și apoi adresa (min. 3 caractere)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Results
        Expanded(
          child: _isSearching
              ? Center(
                  child: PlatformUtils.isIOS 
                      ? const CupertinoActivityIndicator()
                      : const CircularProgressIndicator(),
                )
              : _suggestions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PlatformUtils.isIOS 
                                ? CupertinoIcons.location 
                                : Icons.location_on_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Start typing to search for an address'
                                : 'No results found',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          final isSelected = _selectedAddress == suggestion['address'];
                          
                          return ListTile(
                            leading: Icon(
                              PlatformUtils.isIOS 
                                  ? CupertinoIcons.location_solid 
                                  : Icons.location_on,
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Colors.grey,
                            ),
                            title: Text(
                              suggestion['address'],
                              style: TextStyle(
                                fontWeight: isSelected 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary 
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              'Lat: ${suggestion['latitude'].toStringAsFixed(6)}, '
                              'Lng: ${suggestion['longitude'].toStringAsFixed(6)}',
                              style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  PlatformUtils.isIOS 
                                      ? CupertinoIcons.check_mark_circled_solid 
                                      : Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () => _selectAddress(suggestion),
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
  }
}
