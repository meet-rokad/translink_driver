import 'package:flutter/material.dart';
import '../widgets/auth_layout.dart';

class OAuthConsentScreen extends StatefulWidget {
  final String? ctx;
  
  const OAuthConsentScreen({Key? key, this.ctx}) : super(key: key);

  @override
  _OAuthConsentScreenState createState() => _OAuthConsentScreenState();
}

class _OAuthConsentScreenState extends State<OAuthConsentScreen> {
  Map<String, dynamic>? _info;
  bool _checking = true;
  bool _submitting = false;
  String _decided = "";
  String _error = "";
  String _reconnect = "";

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  void _checkConsent() async {
    if (widget.ctx == null || widget.ctx!.isEmpty) {
      setState(() {
        _error = "This authorization link is invalid or has expired.";
        _checking = false;
      });
      return;
    }

    try {
      // Simulate API call to /api/apps/{appId}/mcp/consent-info
      await Future.delayed(const Duration(seconds: 1));
      
      // Example response
      setState(() {
        _info = {
          "client_name": "AI Assistant",
          "app_name": "Return Translink",
          "tools": [
            {
              "name": "read_data",
              "title": "Read Data",
              "description": "View your account information and preferences",
            },
            {
              "name": "write_data",
              "title": "Write Data",
              "description": "Update your preferences and settings",
            }
          ]
        };
        _checking = false;
      });
    } catch (e) {
      setState(() {
        _error = "Could not load this authorization request. Please try again.";
        _checking = false;
      });
    }
  }

  void _respond(String action) async {
    setState(() {
      _submitting = true;
      _error = "";
    });

    try {
      // Simulate API call to /api/apps/{appId}/mcp/authorize-grant
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _decided = action;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const AuthLayout(
        icon: Icons.shield_outlined,
        title: "Authorize access",
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text("Loading…", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final client = _info?['client_name'] ?? "An AI client";
    final appName = _info?['app_name'] ?? "this app";

    if (_decided.isNotEmpty) {
      return AuthLayout(
        icon: Icons.shield_outlined,
        title: _decided == "approve" ? "Access granted" : "Access denied",
        subtitle: "You can return to $client and close this window.",
        child: const SizedBox(height: 16),
      );
    }

    if (_reconnect.isNotEmpty) {
      return AuthLayout(
        icon: Icons.shield_outlined,
        title: "Reconnect required",
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _reconnect,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ),
      );
    }

    if (_error.isNotEmpty && _info == null) {
      return AuthLayout(
        icon: Icons.shield_outlined,
        title: "Authorize access",
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _error,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ),
      );
    }

    final List<dynamic> tools = _info?['tools'] ?? [];

    return AuthLayout(
      icon: Icons.shield_outlined,
      title: "Authorize access",
      subtitle: "$client wants to access $appName on your behalf",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          Text(
            tools.isNotEmpty 
              ? "It will be able to use these tools in $appName:" 
              : "No tools requested",
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
          
          if (tools.isNotEmpty)
            ...tools.map((tool) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool['title'] ?? tool['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (tool['description'] != null)
                    Text(
                      tool['description'],
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                ],
              ),
            )).toList(),
            
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => _respond("deny"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Deny"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : () => _respond("approve"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Text("Approve"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
