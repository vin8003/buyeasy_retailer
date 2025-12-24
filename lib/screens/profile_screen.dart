import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Store Profile',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: user.shopImage != null
                  ? NetworkImage(
                      user.shopImage!.startsWith('http')
                          ? user.shopImage!
                          : '${ApiConstants.serverUrl}${user.shopImage!}',
                    )
                  : null,
              child: user.shopImage == null
                  ? const Icon(Icons.store, size: 60)
                  : null,
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoTile(context, 'Shop Name', user.shopName),
          _buildInfoTile(context, 'Username', user.username),
          _buildInfoTile(context, 'Email', user.email),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Edit profile implementation
              },
              child: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
