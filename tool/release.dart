import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

/// Automated release script for rdf_mapper
///
/// This script automates the entire release process:
/// 1. Ensures the working directory is clean
/// 2. Runs all tests
/// 3. Ensures version is correctly incremented
/// 4. Updates documentation and version references
/// 5. Commits version changes and creates a git tag
/// 6. Pushes changes and tag to remote repository
/// 7. Publishes the package to pub.dev
///
/// Usage:
///   dart run tool/release.dart [options]
///     --dry-run: Simulate the release process without making changes
///     --no-publish: Skip publishing to pub.dev
///     --help: Show this help message
void main(List<String> args) async {
  if (args.contains('--help')) {
    _printUsage();
    exit(0);
  }

  final dryRun = args.contains('--dry-run');
  final skipPublish = args.contains('--no-publish') || dryRun;

  print('rdf_mapper release script');
  print('------------------------');
  if (dryRun) {
    print('DRY RUN: No changes will be made');
  }
  print('');

  // Find workspace root (directory containing pubspec.yaml)
  final rootDir = _findWorkspaceRoot();
  if (rootDir == null) {
    print(
      'Error: Could not find workspace root (directory containing pubspec.yaml)',
    );
    exit(1);
  }

  // Change to workspace root
  Directory.current = rootDir;

  // Step 1: Check for clean working directory
  print('Step 1/7: Checking git status...');
  final gitStatus = await _runProcess('git', ['status', '--porcelain']);

  if (gitStatus.stdout.toString().trim().isNotEmpty) {
    print(
      'Error: Working directory not clean. Commit or stash changes before release.',
    );
    exit(1);
  }
  print('  ✓ Working directory clean');

  // Step 2: Run tests
  print('\nStep 2/7: Running tests...');
  final testResult = await _runProcess('dart', ['test']);
  if (testResult.exitCode != 0) {
    print('Error: Tests failed. Fix test failures before release.');
    exit(1);
  }
  print('  ✓ All tests passed');

  // Step 3: Verify version increment
  print('\nStep 3/7: Checking version...');
  final currentVersion = _getCurrentVersion();
  final lastVersion = await _getLastReleasedVersion();

  if (lastVersion != null &&
      !_isVersionIncremented(lastVersion, currentVersion)) {
    print(
      'Error: Version $currentVersion is not incremented from $lastVersion',
    );
    exit(1);
  }
  print('  ✓ Version $currentVersion is valid');

  // Step 4: Update documentation and version references
  print('\nStep 4/7: Updating documentation...');
  if (!dryRun) {
    final updateDocsResult = await _runProcess('dart', [
      'run',
      'tool/update_version.dart',
    ]);
    if (updateDocsResult.exitCode != 0) {
      print('Error: Failed to update documentation');
      exit(1);
    }
  } else {
    print('  (dry run) Would update documentation and version references');
  }
  print('  ✓ Documentation updated');

  // Step 5: Commit changes and create tag
  print('\nStep 5/7: Committing changes and creating tag...');
  final tagName = 'v$currentVersion';

  if (!dryRun) {
    // Check if any files were changed by the doc update
    final statusAfterDocs = await _runProcess('git', ['status', '--porcelain']);
    final hasChanges = statusAfterDocs.stdout.toString().trim().isNotEmpty;

    if (hasChanges) {
      // Commit changes
      await _runProcess('git', ['add', '.']);
      await _runProcess('git', [
        'commit',
        '-m',
        'Prepare for release $tagName',
      ]);
      print('  ✓ Changes committed');
    } else {
      print('  ✓ No files changed during documentation update');
    }

    // Create tag
    await _runProcess('git', ['tag', '-a', tagName, '-m', 'Release $tagName']);
    print('  ✓ Created tag $tagName');
  } else {
    print('  (dry run) Would commit changes and create tag $tagName');
  }

  // Step 6: Push changes and tags
  print('\nStep 6/7: Pushing changes and tags...');
  if (!dryRun) {
    await _runProcess('git', ['push', 'origin', 'main']);
    await _runProcess('git', ['push', 'origin', tagName]);
    print('  ✓ Pushed changes and tag to remote repository');
  } else {
    print('  (dry run) Would push changes and tag to remote repository');
  }

  // Step 7: Publish to pub.dev
  print('\nStep 7/7: Publishing to pub.dev...');
  if (skipPublish) {
    if (dryRun) {
      print('  (dry run) Would publish to pub.dev');
    } else {
      print('  Skipping publishing to pub.dev');
    }
  } else {
    final pubResult = await _runProcess('dart', ['pub', 'publish', '--force']);
    if (pubResult.exitCode != 0) {
      print('Error: Failed to publish package to pub.dev');
      exit(1);
    }
    print('  ✓ Published to pub.dev');
  }

  print('\nRelease $tagName completed successfully!');
  print('GitHub Actions will automatically create a GitHub release.');

  if (dryRun) {
    print('\nThis was a dry run. No changes were made.');
  } else if (skipPublish) {
    print('\nPackage was not published. To publish manually, run:');
    print('  dart pub publish');
  }
}

/// Prints usage information for the tool
void _printUsage() {
  print('Release Script');
  print('-------------');
  print('Automates the release process for the rdf_mapper package.');
  print('');
  print('Usage:');
  print('  dart run tool/release.dart [options]');
  print('');
  print('Options:');
  print('  --dry-run     Simulate the release process without making changes');
  print('  --no-publish  Skip publishing to pub.dev');
  print('  --help        Show this help message');
}

/// Finds the workspace root directory (containing pubspec.yaml)
Directory? _findWorkspaceRoot() {
  var dir = Directory.current;

  while (dir.path != dir.parent.path) {
    if (File(path.join(dir.path, 'pubspec.yaml')).existsSync()) {
      return dir;
    }
    dir = dir.parent;
  }

  return null;
}

/// Gets the current version from pubspec.yaml
String _getCurrentVersion() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final pubspec = loadYaml(pubspecContent) as Map;
  final version = pubspec['version'];

  if (version == null || version.toString().isEmpty) {
    print('Error: No version field found in pubspec.yaml');
    exit(1);
  }

  return version.toString();
}

/// Gets the most recently released version from git tags
Future<String?> _getLastReleasedVersion() async {
  try {
    final result = await _runProcess('git', [
      'tag',
      '-l',
      'v*.*.*',
      '--sort=-v:refname',
    ]);
    final tags = result.stdout.toString().trim().split('\n');

    if (tags.isEmpty || tags.first.isEmpty) {
      return null; // No previous version tags
    }

    // Extract version number from tag (remove 'v' prefix)
    return tags.first.replaceFirst('v', '');
  } catch (e) {
    print('Warning: Could not determine last released version: $e');
    return null;
  }
}

/// Checks if the current version is incremented according to semver rules
bool _isVersionIncremented(String lastVersion, String currentVersion) {
  final last = lastVersion.split('.').map(int.parse).toList();
  final current = currentVersion.split('.').map(int.parse).toList();

  // Ensure both have 3 components (major.minor.patch)
  if (last.length != 3 || current.length != 3) {
    return false;
  }

  // Compare major.minor.patch
  if (current[0] > last[0]) {
    return true;
  } else if (current[0] == last[0]) {
    if (current[1] > last[1]) {
      return true;
    } else if (current[1] == last[1]) {
      return current[2] > last[2];
    }
  }

  return false;
}

/// Runs a process and returns the result, streaming output to console
Future<ProcessResult> _runProcess(
  String command,
  List<String> arguments,
) async {
  print('  Running: $command ${arguments.join(' ')}');

  final process = await Process.start(
    command,
    arguments,
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;

  // Create synthetic ProcessResult since we used inheritStdio
  return ProcessResult(process.pid, exitCode, '', '');
}
