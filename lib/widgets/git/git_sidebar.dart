// lib/widgets/git/git_sidebar.dart
import 'package:flutter/material.dart';
import '../../services/git_service.dart';

enum _TopGitAction {
  fetch,
  pull,
  push,
  sync,
}

enum _CommitAction {
  commit,
  commitAndPush,
  commitAndSync,
}

class GitSidebar extends StatefulWidget {
  final String? workingDirectory;
  final void Function(String command)? onRunCommand;

  const GitSidebar({
    super.key,
    required this.workingDirectory,
    required this.onRunCommand,
  });

  @override
  State<GitSidebar> createState() => _GitSidebarState();
}

class _GitSidebarState extends State<GitSidebar> {
  final _git = GitService();

  bool _loading = false;
  bool _isRepo = false;

  List<GitBranch> _branches = <GitBranch>[];
  List<GitCommit> _commits = <GitCommit>[];
  List<GitStatusFile> _status = <GitStatusFile>[];

  final _commitController = TextEditingController();

  _CommitAction _selectedCommitAction = _CommitAction.commit;

  int? _hoveredStatusIndex;

  bool _stagedExpanded = true;
  int? _hoveredStagedIndex;

  /// Used to anchor the commit-action dropdown menu right under the arrow button.
  final GlobalKey _commitActionMenuKey = GlobalKey();

  List<GitStatusFile> get _stagedFiles {
    bool isStagedXY(String xy) {
      if (xy.length < 2) return false;
      final x = xy[0];
      return x != ' ' && x != '?';
    }

    return _status.where((f) => isStagedXY(f.xy)).toList(growable: false);
  }

  List<GitStatusFile> get _unstagedFiles {
    bool isStagedXY(String xy) {
      if (xy.length < 2) return false;
      final x = xy[0];
      return x != ' ' && x != '?';
    }

    return _status.where((f) => !isStagedXY(f.xy)).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant GitSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workingDirectory != widget.workingDirectory) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _commitController.dispose();
    super.dispose();
  }

  Future<void> _stageOne(GitStatusFile f) async {
    final wd = widget.workingDirectory;
    if (wd == null || !_isRepo) return;

    setState(() => _loading = true);
    try {
      final res = await _git.stageFile(wd, f.path);
      if (!mounted) return;

      if (!res.ok) {
        _showSnack(res.bestMessage.isEmpty ? 'Stage failed' : res.bestMessage);
        return;
      }

      await _refresh();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unstageOne(GitStatusFile f) async {
    final wd = widget.workingDirectory;
    if (wd == null || !_isRepo) return;

    setState(() => _loading = true);
    try {
      final res = await _git.unstageFile(wd, f.path);
      if (!mounted) return;

      if (!res.ok) {
        _showSnack(res.bestMessage.isEmpty ? 'Unstage failed' : res.bestMessage);
        return;
      }

      await _refresh();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revertOne(GitStatusFile f) async {
    final wd = widget.workingDirectory;
    if (wd == null || !_isRepo) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revert changes'),
        content: Text('Revert local changes in\n${f.path}\n?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revert'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      final res = await _git.revertFile(wd, f.path);
      if (!mounted) return;

      if (!res.ok) {
        _showSnack(res.bestMessage.isEmpty ? 'Revert failed' : res.bestMessage);
        return;
      }

      await _refresh();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _showOnHoverActions(GitStatusFile f, bool show) {
    if (!show) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniIconButton(
          tooltip: 'Revert',
          icon: Icons.undo,
          onPressed: _loading ? null : () => _revertOne(f),
        ),
        _miniIconButton(
          tooltip: 'Stage',
          icon: Icons.add_box_outlined,
          onPressed: _loading ? null : () => _stageOne(f),
        ),
      ],
    );
  }

  Widget _showOnHoverUnstage(GitStatusFile f, bool show) {
    if (!show) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniIconButton(
          tooltip: 'Unstage',
          icon: Icons.remove_circle_outline,
          onPressed: _loading ? null : () => _unstageOne(f),
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    final wd = widget.workingDirectory;
    if (wd == null) {
      setState(() {
        _isRepo = false;
        _branches = <GitBranch>[];
        _commits = <GitCommit>[];
        _status = <GitStatusFile>[];
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final isRepo = await _git.isGitRepo(wd);
      if (!mounted) return;

      if (!isRepo) {
        setState(() {
          _isRepo = false;
          _branches = <GitBranch>[];
          _commits = <GitCommit>[];
          _status = <GitStatusFile>[];
        });
        return;
      }

      final results = await Future.wait([
        _git.getBranches(wd),
        _git.getLog(wd, maxCount: 200),
        _git.getStatus(wd),
      ]);

      if (!mounted) return;
      setState(() {
        _isRepo = true;
        _branches = results[0] as List<GitBranch>;
        _commits = results[1] as List<GitCommit>;
        _status = results[2] as List<GitStatusFile>;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runTopAction(_TopGitAction action) async {
    final wd = widget.workingDirectory;
    if (wd == null || !_isRepo) return;

    setState(() => _loading = true);
    try {
      // Safety guards
      final hasUpstream = await _git.hasUpstream(wd);
      if (!mounted) return;

      if ((action == _TopGitAction.pull || action == _TopGitAction.sync) && !hasUpstream) {
        final branch = await _git.getCurrentBranchName(wd);
        _showSnack(
          'No upstream set for ${branch ?? 'current branch'}. Push \-u first.',
        );
        return;
      }

      if (action == _TopGitAction.pull || action == _TopGitAction.sync) {
        final dirty = await _git.isDirty(wd);
        if (!mounted) return;

        if (dirty) {
          _showSnack('Working tree has uncommitted changes. Commit/stash before pull/sync.');
          return;
        }
      }

      late final GitServiceResult res;
      switch (action) {
        case _TopGitAction.fetch:
          res = await _git.fetch(wd);
          break;
        case _TopGitAction.pull:
          res = await _git.pull(wd);
          break;
        case _TopGitAction.push:
          res = await _git.push(wd);
          break;
        case _TopGitAction.sync:
          res = await _git.sync(wd);
          break;
      }

      if (!mounted) return;

      if (!res.ok) {
        _showSnack(res.bestMessage.isEmpty ? 'Git command failed' : res.bestMessage);
        return;
      }

      // Show real output if present (e.g., "Already up to date.")
      final msg = res.bestMessage;
      _showSnack(msg.isEmpty ? _labelForTopAction(action) : msg);

      await _refresh();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _labelForTopAction(_TopGitAction a) {
    switch (a) {
      case _TopGitAction.fetch:
        return 'Fetched';
      case _TopGitAction.pull:
        return 'Pulled';
      case _TopGitAction.push:
        return 'Pushed';
      case _TopGitAction.sync:
        return 'Synced';
    }
  }

  Future<void> _commitFlow(_CommitAction action) async {
    final wd = widget.workingDirectory;
    if (wd == null || !_isRepo) return;

    final msg = _commitController.text.trim();
    if (msg.isEmpty) {
      _showSnack('Commit message required');
      return;
    }

    setState(() => _loading = true);
    try {
      final addRes = await _git.stageAll(wd);
      if (!addRes.ok) {
        _showSnack('git add failed');
        return;
      }

      final commitRes = await _git.commit(wd, msg);
      if (!mounted) return;

      if (!commitRes.ok) {
        _showSnack(
          'Commit failed: ${(commitRes.stderrText.trim().isEmpty ? commitRes.stdoutText : commitRes.stderrText).trim()}',
        );
        return;
      }

      if (action == _CommitAction.commitAndPush) {
        final pushRes = await _git.push(wd);
        if (!mounted) return;
        if (!pushRes.ok) {
          _showSnack(
            'Push failed: ${(pushRes.stderrText.trim().isEmpty ? pushRes.stdoutText : pushRes.stderrText).trim()}',
          );
          return;
        }
      }

      if (action == _CommitAction.commitAndSync) {
        final syncRes = await _git.sync(wd);
        if (!mounted) return;
        if (!syncRes.ok) {
          _showSnack(
            'Sync failed: ${(syncRes.stderrText.trim().isEmpty ? syncRes.stdoutText : syncRes.stderrText).trim()}',
          );
          return;
        }
      }

      _commitController.clear();
      _showSnack(_labelForCommitAction(action));
      await _refresh();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _labelForCommitAction(_CommitAction a) {
    switch (a) {
      case _CommitAction.commit:
        return 'Committed';
      case _CommitAction.commitAndPush:
        return 'Committed \& pushed';
      case _CommitAction.commitAndSync:
        return 'Committed \& synced';
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  Widget _miniIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 18,
      splashRadius: 18,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: Colors.white70),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wd = widget.workingDirectory;

    return Container(
      color: const Color(0xFF181818),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF3C3C3C), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'SOURCE CONTROL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _topActionsMenu(),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _refresh,
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF42A5F5)),
                  )
                : (wd == null)
                    ? const Center(
                        child: Text(
                          'Open a folder to use Git',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : !_isRepo
                        ? const Center(
                            child: Text(
                              'Not a Git repository',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : DefaultTabController(
                            length: 3,
                            child: Column(
                              children: [
                                const TabBar(
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.white54,
                                  indicatorColor: Color(0xFF42A5F5),
                                  tabs: [
                                    Tab(text: 'CHANGES'),
                                    Tab(text: 'LOG'),
                                    Tab(text: 'BRANCHES'),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      _buildChangesTab(),
                                      _buildLogTab(),
                                      _buildBranchesTab(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _topActionsMenu() {
    final enabled = !_loading && _isRepo;

    return PopupMenuButton<_TopGitAction>(
      tooltip: 'Git actions',
      enabled: enabled,
      offset: const Offset(0, 40),
      color: const Color(0xFF252526),
      icon: const Icon(Icons.more_vert, size: 18, color: Colors.white70),
      onSelected: _runTopAction,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _TopGitAction.fetch,
          child: Text('Fetch', style: TextStyle(color: Colors.white70)),
        ),
        PopupMenuItem(
          value: _TopGitAction.pull,
          child: Text('Pull', style: TextStyle(color: Colors.white70)),
        ),
        PopupMenuItem(
          value: _TopGitAction.push,
          child: Text('Push', style: TextStyle(color: Colors.white70)),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _TopGitAction.sync,
          child: Text('Sync', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildChangesTab() {
    final enabled = !_loading && _isRepo;

    final staged = _stagedFiles;
    final unstaged = _unstagedFiles;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        spacing: 12,
        children: [
          // Commit message bar (improved styling)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border.all(color: const Color(0xFF3C3C3C)),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _commitController,
                  enabled: enabled,
                  maxLines: 3,
                  minLines: 2,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Message (required)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF252526),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                _commitSplitButton(enabled: enabled),
              ],
            ),
          ),

          // Staged changes expandable list
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border.all(color: const Color(0xFF3C3C3C)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _stagedExpanded = !_stagedExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          _stagedExpanded ? Icons.expand_more : Icons.chevron_right,
                          size: 18,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Staged Changes (${staged.length})',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 160),
                  crossFadeState: _stagedExpanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: sizedBoxForStagedList(staged),
                  secondChild: const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Changes list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border.all(color: const Color(0xFF3C3C3C)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.separated(
                itemCount: unstaged.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFF2D2D2D)),
                itemBuilder: (context, index) {
                  final f = unstaged[index];
                  final isHovered = _hoveredStatusIndex == index;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredStatusIndex = index),
                    onExit: (_) {
                      if (_hoveredStatusIndex == index) {
                        setState(() => _hoveredStatusIndex = null);
                      }
                    },
                    child: ListTile(
                      dense: true,
                      enabled: enabled,
                      title: Text(
                        f.path,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: _statusChip(f.xy),
                      trailing: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 120),
                        child: _showOnHoverActions(f, isHovered),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _commitSplitButton({required bool enabled}) {
    const accent = Color(0xFF42A5F5);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: enabled ? () => _commitFlow(_selectedCommitAction) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _selectedCommitAction == _CommitAction.commit
                    ? 'Commit'
                    : _selectedCommitAction == _CommitAction.commitAndPush
                        ? 'Commit & Push'
                        : 'Commit & Sync',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          width: 44,
          child: Material(
            key: _commitActionMenuKey,
            color: enabled ? accent : const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: !enabled
                  ? null
                  : () async {
                      // Anchor the menu to the dropdown button rather than hard-coding a screen position.
                      final box = _commitActionMenuKey.currentContext?.findRenderObject() as RenderBox?;
                      final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
                      if (box == null || overlay == null) return;

                      final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
                      final bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay);

                      final position = RelativeRect.fromRect(
                        Rect.fromPoints(topLeft, bottomRight),
                        Offset.zero & overlay.size,
                      );

                      final selected = await showMenu<_CommitAction>(
                        context: context,
                        position: position,
                        color: const Color(0xFF252526),
                        items: const [
                          PopupMenuItem(
                            value: _CommitAction.commit,
                            child: Text('Commit', style: TextStyle(color: Colors.white70)),
                          ),
                          PopupMenuItem(
                            value: _CommitAction.commitAndPush,
                            child: Text('Commit & Push', style: TextStyle(color: Colors.white70)),
                          ),
                          PopupMenuItem(
                            value: _CommitAction.commitAndSync,
                            child: Text('Commit & Sync', style: TextStyle(color: Colors.white70)),
                          ),
                        ],
                      );
                      if (selected != null && mounted) {
                        setState(() => _selectedCommitAction = selected);
                      }
                    },
              child: const Icon(Icons.arrow_drop_down, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String xy) {
    Color c = Colors.blueGrey;
    final v = xy.trim();
    if (v == '??') c = const Color(0xFF66BB6A);
    if (v.contains('M')) c = const Color(0xFFFFCA28);
    if (v.contains('D')) c = const Color(0xFFEF5350);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        border: Border.all(color: c.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        xy,
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLogTab() {
    return Container(
      color: const Color(0xFF181818),
      child: ListView.separated(
        itemCount: _commits.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFF2D2D2D)),
        itemBuilder: (context, index) {
          final c = _commits[index];
          final dateText = c.date?.toLocal().toString().split('.').first ?? '';
          return ListTile(
            dense: true,
            title: Text(
              c.subject,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${c.shortHash} · ${c.author}${dateText.isEmpty ? '' : ' · $dateText'}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: 'Open in terminal: git show',
              onPressed: () => widget.onRunCommand?.call('git show ${c.hash}'),
              icon: const Icon(Icons.visibility, size: 18, color: Colors.white54),
            ),
          );
        },
      ),
    );
  }

  Widget sizedBoxForStagedList(List<GitStatusFile> staged) {
    final clamped = staged.length.clamp(0, 6);
    final height = (clamped * 44.0) + 2.0;

    return SizedBox(
      height: staged.isEmpty ? 44 : height,
      child: staged.isEmpty
          ? const Center(
        child: Text(
            'No staged changes', style: TextStyle(color: Colors.white38)),
      )
          : ListView.separated(
        itemCount: staged.length,
        separatorBuilder: (_, __) =>
        const Divider(height: 1, color: Color(0xFF2D2D2D)),
        itemBuilder: (context, index) {
          final f = staged[index];
          final isHovered = _hoveredStagedIndex == index;

          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredStagedIndex = index),
            onExit: (_) => setState(() => _hoveredStagedIndex = null),
            child: ListTile(
              dense: true,
              leading: _statusChip(f.xy),
              title: Text(
                f.path,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: _showOnHoverUnstage(f, isHovered), // ONLY unstage
            ),
          );
        },
      ),
    );
  }

  Widget _buildBranchesTab() {
    return Container(
      color: const Color(0xFF181818),
      child: ListView.separated(
        itemCount: _branches.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFF2D2D2D)),
        itemBuilder: (context, index) {
          final b = _branches[index];
          return ListTile(
            dense: true,
            leading: Icon(
              b.current ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: b.current ? const Color(0xFF66BB6A) : Colors.white54,
            ),
            title: Text(
              b.name,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => widget.onRunCommand?.call('git checkout ${b.name}'),
            trailing: IconButton(
              tooltip: 'Checkout (terminal)',
              onPressed: () => widget.onRunCommand?.call('git checkout ${b.name}'),
              icon: const Icon(Icons.terminal, size: 18, color: Colors.white54),
            ),
          );
        },
      ),
    );
  }
}