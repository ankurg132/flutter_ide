// lib/services/git_service.dart
import 'dart:io';

class GitCommit {
  final String hash;
  final String shortHash;
  final String author;
  final DateTime? date;
  final String subject;

  GitCommit({
    required this.hash,
    required this.shortHash,
    required this.author,
    required this.date,
    required this.subject,
  });
}

class GitBranch {
  final String name;
  final bool current;

  GitBranch({required this.name, required this.current});
}

class GitStatusFile {
  final String xy; // porcelain XY, e.g. "M " or "??"
  final String path;

  GitStatusFile({required this.xy, required this.path});
}

class GitServiceResult {
  final int exitCode;
  final String stdoutText;
  final String stderrText;

  GitServiceResult({
    required this.exitCode,
    required this.stdoutText,
    required this.stderrText,
  });

  bool get ok => exitCode == 0;

  String get bestMessage {
    final err = stderrText.trim();
    final out = stdoutText.trim();
    return err.isNotEmpty ? err : out;
  }
}

class GitService {
  Future<GitServiceResult> _run(
      String workingDirectory,
      List<String> args,
      ) async {
    final result = await Process.run(
      'git',
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    return GitServiceResult(
      exitCode: result.exitCode,
      stdoutText: (result.stdout ?? '').toString(),
      stderrText: (result.stderr ?? '').toString(),
    );
  }

  Future<bool> isGitRepo(String workingDirectory) async {
    final res = await _run(
      workingDirectory,
      ['rev-parse', '--is-inside-work-tree'],
    );
    return res.ok && res.stdoutText.trim() == 'true';
  }

  Future<List<GitCommit>> getLog(
      String workingDirectory, {
        int maxCount = 200,
      }) async {
    final res = await _run(workingDirectory, [
      'log',
      '--max-count=$maxCount',
      '--date=iso-strict',
      r'--pretty=format:%H|%an|%ad|%s',
    ]);
    if (!res.ok) return <GitCommit>[];

    final commits = <GitCommit>[];
    for (final line in res.stdoutText.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      if (parts.length < 4) continue;

      final hash = parts[0].trim();
      final author = parts[1].trim();
      final dateRaw = parts[2].trim();
      final subject = parts.sublist(3).join('|').trim();

      DateTime? date;
      try {
        date = DateTime.parse(dateRaw);
      } catch (_) {
        date = null;
      }

      commits.add(
        GitCommit(
          hash: hash,
          shortHash: hash.length >= 7 ? hash.substring(0, 7) : hash,
          author: author,
          date: date,
          subject: subject,
        ),
      );
    }
    return commits;
  }

  Future<List<GitBranch>> getBranches(String workingDirectory) async {
    final res = await _run(
      workingDirectory,
      ['branch', '--format=%(HEAD)|%(refname:short)'],
    );
    if (!res.ok) return <GitBranch>[];

    final branches = <GitBranch>[];
    for (final line in res.stdoutText.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      final head = parts.isNotEmpty ? parts[0].trim() : '';
      final name = parts.length > 1 ? parts[1].trim() : line.trim();
      branches.add(GitBranch(name: name, current: head == '*'));
    }
    return branches;
  }

  Future<List<GitStatusFile>> getStatus(String workingDirectory) async {
    final res = await _run(workingDirectory, ['status', '--porcelain=v1']);
    if (!res.ok) return <GitStatusFile>[];

    final files = <GitStatusFile>[];
    for (final line in res.stdoutText.split('\n')) {
      if (line.trim().isEmpty) continue;
      if (line.length < 4) continue;
      final xy = line.substring(0, 2);
      final path = line.substring(3).trim();
      files.add(GitStatusFile(xy: xy, path: path));
    }
    return files;
  }

  Future<bool> hasUpstream(String workingDirectory) async {
    final res = await _run(workingDirectory, [
      'rev-parse',
      '--abbrev-ref',
      '--symbolic-full-name',
      '@{u}',
    ]);
    return res.ok && res.stdoutText.trim().isNotEmpty;
  }

  Future<String?> getCurrentBranchName(String workingDirectory) async {
    final res = await _run(workingDirectory, ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (!res.ok) return null;
    final name = res.stdoutText.trim();
    return name.isEmpty ? null : name;
  }

  Future<bool> isDirty(String workingDirectory) async {
    final res = await _run(workingDirectory, ['status', '--porcelain=v1']);
    if (!res.ok) return false;
    return res.stdoutText.trim().isNotEmpty;
  }

  Future<GitServiceResult> stageAll(String workingDirectory) {
    return _run(workingDirectory, ['add', '-A']);
  }

  Future<GitServiceResult> stageFile(String workingDirectory, String path) {
    return _run(workingDirectory, ['add', '--', path]);
  }

  Future<GitServiceResult> unstageFile(String workingDirectory, String path) {
    // Unstages only, keeps working tree changes intact.
    return _run(workingDirectory, ['reset', '-q', 'HEAD', '--', path]);
  }

  Future<GitServiceResult> revertFile(String workingDirectory, String path) {
    return _run(workingDirectory, ['checkout', '--', path]);
  }

  Future<GitServiceResult> commit(String workingDirectory, String message) {
    return _run(workingDirectory, ['commit', '-m', message]);
  }

  Future<GitServiceResult> fetch(String workingDirectory) {
    return _run(workingDirectory, ['fetch', '--prune']);
  }

  Future<GitServiceResult> pull(String workingDirectory) {
    return _run(workingDirectory, ['pull', '--ff-only']);
  }

  Future<GitServiceResult> push(String workingDirectory) {
    return _run(workingDirectory, ['push']);
  }

  Future<GitServiceResult> sync(String workingDirectory) async {
    final f = await fetch(workingDirectory);
    if (!f.ok) return f;
    final p = await pull(workingDirectory);
    if (!p.ok) return p;
    return push(workingDirectory);
  }

  Future<GitServiceResult> checkoutNewBranch(
      String workingDirectory,
      String branchName,
      ) {
    return _run(workingDirectory, ['checkout', '-b', branchName]);
  }

  Future<GitServiceResult> checkoutBranch(
      String workingDirectory,
      String branchName,
      ) {
    return _run(workingDirectory, ['checkout', branchName]);
  }
}