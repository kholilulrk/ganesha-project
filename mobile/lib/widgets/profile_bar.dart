import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileBar extends StatelessWidget {
  const ProfileBar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4, left: 16, right: 16, bottom: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: user?.photo != null
                  ? NetworkImage('${ApiService.baseUploadUrl}${user!.photo}')
                  : null,
              child: user?.photo == null
                  ? Text(
                      (user?.name ?? '?')[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(user?.role ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
