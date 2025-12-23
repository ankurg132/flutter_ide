import 'package:flutter/material.dart';
import 'package:pub_api_client/pub_api_client.dart';

class PubDevSidebar extends StatefulWidget {
  final void Function(String title, String url)? onOpenInBrowser;
  final void Function(String command)? onRunCommand;

  const PubDevSidebar({
    super.key,
    this.onOpenInBrowser,
    this.onRunCommand,
  });

  @override
  State<PubDevSidebar> createState() => _PubDevSidebarState();
}

class _PubDevSidebarState extends State<PubDevSidebar> {
  final PubClient _pubClient = PubClient();
  final TextEditingController _searchController = TextEditingController();

  List<PackageResult> _packages = [];
  PubPackage? _selectedPackage;
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPopularPackages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pubClient.close();
    super.dispose();
  }

  Future<void> _loadPopularPackages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _pubClient.search('flutter', page: 1);
      setState(() {
        _packages = result.packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load packages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchPackages(String query) async {
    if (query.isEmpty) {
      _loadPopularPackages();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _pubClient.search(query, page: 1);
      setState(() {
        _packages = result.packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPackageDetails(String packageName) async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final package = await _pubClient.packageInfo(packageName);
      setState(() {
        _selectedPackage = package;
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: const Color(0xFF181818),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF3C3C3C), width: 1),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: Color(0xFF42A5F5),
                ),
                SizedBox(width: 8),
                Text(
                  'PUB.DEV PACKAGES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search packages...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF3C3C3C),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white38,
                        size: 18,
                      ),
                    ),
                    onSubmitted: _searchPackages,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white54, size: 20),
                  onPressed: () => _searchPackages(_searchController.text),
                  tooltip: 'Search',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _selectedPackage != null
                ? _buildPackageDetails()
                : _buildPackageList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF42A5F5)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPopularPackages,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_packages.isEmpty) {
      return const Center(
        child: Text(
          'No packages found',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final package = _packages[index];
        return _buildPackageItem(package);
      },
    );
  }

  Widget _buildPackageItem(PackageResult package) {
    return InkWell(
      onTap: () => _loadPackageDetails(package.package),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF2D2D2D), width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.package,
              style: const TextStyle(
                color: Color(0xFF42A5F5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageDetails() {
    if (_isLoadingDetails) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF42A5F5)),
      );
    }

    final package = _selectedPackage!;
    final pubspec = package.latestPubspec;
    final latestVersion = package.version;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedPackage = null;
              });
            },
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to list'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white54,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),

          // Package name and version
          Text(
            package.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v$latestVersion',
            style: const TextStyle(
              color: Color(0xFF66BB6A),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          if (pubspec.description != null) ...[
            Text(
              pubspec.description!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onOpenInBrowser?.call(
                      package.name,
                      'https://pub.dev/packages/${package.name}',
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View on Pub.dev'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF42A5F5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Install section
          const Text(
            'INSTALL',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // pubspec.yaml dependency
          _buildCodeBlock(
            'pubspec.yaml',
            '${package.name}: ^$latestVersion',
          ),
          const SizedBox(height: 8),

          // Command line
          _buildCodeBlock(
            'Command line',
            'flutter pub add ${package.name}',
            showRunButton: true,
          ),
          const SizedBox(height: 16),

          // Metadata section
          const Text(
            'METADATA',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          if (pubspec.homepage != null)
            _buildMetadataRow(
              'Homepage',
              pubspec.homepage!,
              isLink: true,
              onTap: () => widget.onOpenInBrowser?.call('Homepage', pubspec.homepage!),
            ),

          if (pubspec.repository() != null)
            _buildMetadataRow(
              'Repository',
              pubspec.repository()!,
              isLink: true,
              onTap: () => widget.onOpenInBrowser?.call('Repository', pubspec.repository()!),
            ),

          if (pubspec.documentation != null)
            _buildMetadataRow(
              'Documentation',
              pubspec.documentation!,
              isLink: true,
              onTap: () => widget.onOpenInBrowser?.call('Documentation', pubspec.documentation!),
            ),

          if (pubspec.issueTracker() != null)
            _buildMetadataRow(
              'Issues',
              pubspec.issueTracker()!,
              isLink: true,
              onTap: () => widget.onOpenInBrowser?.call('Issues', pubspec.issueTracker()!),
            ),

          _buildMetadataRow('License', package.latestPubspec.name ?? 'Unknown'),
          _buildMetadataRow('Published', package.version),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String title, String code, {bool showRunButton = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF3C3C3C), width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                if (showRunButton)
                  InkWell(
                    onTap: () => widget.onRunCommand?.call(code),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, size: 14, color: Color(0xFF66BB6A)),
                          SizedBox(width: 2),
                          Text(
                            'Add to Application',
                            style: TextStyle(color: Color(0xFF66BB6A), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SelectableText(
              code,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, {bool isLink = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: isLink
                ? InkWell(
                    onTap: onTap,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF42A5F5),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
