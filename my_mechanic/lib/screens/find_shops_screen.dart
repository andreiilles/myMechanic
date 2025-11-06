import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/mechanic.dart';
import '../providers/user_provider.dart';
import '../utils/platform_utils.dart';
import 'shop_detail_screen.dart';

class FindShopsScreen extends StatefulWidget {
  const FindShopsScreen({super.key});

  @override
  State<FindShopsScreen> createState() => _FindShopsScreenState();
}

class _FindShopsScreenState extends State<FindShopsScreen> {
  bool _isLoading = true;
  List<Mechanic> _mechanics = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMechanics();
  }

  Future<void> _loadMechanics() async {
    try {
      final userProvider = context.read<UserProvider>();
      final mechanics = await userProvider.loadAllMechanics();
      
      if (mounted) {
        setState(() {
          _mechanics = mechanics;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mechanics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Find Shops'),
        ),
        child: Material(
          color: CupertinoColors.systemGroupedBackground,
          child: SafeArea(
            child: _buildContent(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Shops'),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final filteredMechanics = _mechanics.where((mechanic) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return mechanic.businessName.toLowerCase().contains(query) ||
          (mechanic.businessAddress?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (filteredMechanics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No mechanic shops found'
                  : 'No shops match your search',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMechanics.length,
      itemBuilder: (context, index) {
        return _buildShopCard(filteredMechanics[index]);
      },
    );
  }

  Widget _buildShopCard(Mechanic mechanic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShopDetailScreen(mechanic: mechanic),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mechanic.businessName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (mechanic.isVerified)
                    const Icon(
                      Icons.verified,
                      color: Colors.blue,
                      size: 24,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (mechanic.averageRating != null)
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${mechanic.averageRating!.toStringAsFixed(1)} (${mechanic.totalReviews} reviews)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              if (mechanic.businessAddress != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        mechanic.businessAddress!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (mechanic.businessPhone != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      mechanic.businessPhone!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
              if (mechanic.hourlyRate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${mechanic.hourlyRate} RON/hour',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShopDetailScreen(mechanic: mechanic),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
