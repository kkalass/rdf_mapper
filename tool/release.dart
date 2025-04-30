import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Automated release script for rdf_mapper
///
/// This script automates the entire release process:
/// 1. Ensures the working directory is clean (in non-interactive mode)
/// 2. Validates or guides updating CHANGELOG.md and version in pubspec.yaml
/// 3. Runs all tests
/// 4. Updates documentation and version references
/// 5. Commits changes and creates a git tag
/// 6. Pushes changes and tag to remote repository
/// 7. Publishes the package to pub.dev
///
/// Usage:
///   dart run tool/release.dart [options]
///     --dry-run: Simulate the release process without making changes
///     --no-publish: Skip publishing to pub.dev
///     --non-interactive: Skip interactive prompts (requires clean working directory)
///     --help: Show this help message
void main(List<String> args) async {
  if (args.contains('--help')) {
    _printUsage();
    exit(0);
  }

  final dryRun = args.contains('--dry-run');
  final skipPublish = args.contains('--no-publish') || dryRun;
  final nonInteractive = args.contains('--non-interactive');

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

  // Step 1: Check for clean working directory if in non-interactive mode
  if (nonInteractive) {
    print('Step 1/8: Checking git status (non-interactive mode)...');
    final gitStatus = await _runProcess('git', ['status', '--porcelain']);

    if (gitStatus.stdout.toString().trim().isNotEmpty) {
      print(
        'Error: Working directory not clean. Commit or stash changes before release in non-interactive mode.',
      );
      print(
        '       Alternatively, use interactive mode (default) to prepare changes during release.',
      );
      exit(1);
    }
    print('  ✓ Working directory clean');
  } else {
    print('Step 1/8: Interactive mode - will prepare changes as needed');
  }

  // Step 2: Verify or update version and changelog
  print('\nStep 2/8: Checking version and changelog...');
  var currentVersion = _getCurrentVersion();
  var lastVersion = await _getLastReleasedVersion();

  if (!nonInteractive) {
    // Suggest version increment in interactive mode
    final suggestedVersion = _suggestNextVersion(
      lastVersion ?? '0.0.0',
      currentVersion,
    );

    if (suggestedVersion != currentVersion) {
      print('  Current version in pubspec.yaml: $currentVersion');
      print('  Last released version: ${lastVersion ?? "none"}');
      print('  Suggested next version: $suggestedVersion');

      final useVersion = await _prompt(
        '  Update version to $suggestedVersion? (y/n/custom): ',
      );

      if (useVersion.toLowerCase() == 'y') {
        if (!dryRun) {
          _updatePubspecVersion(suggestedVersion);
          print('  ✓ Updated pubspec.yaml version to $suggestedVersion');
          currentVersion = suggestedVersion;
        } else {
          print(
            '  (dry run) Would update pubspec.yaml version to $suggestedVersion',
          );
        }
      } else if (useVersion.toLowerCase() != 'n') {
        // Custom version entered
        final customVersion = useVersion.trim();
        if (_isValidVersion(customVersion)) {
          if (!dryRun) {
            _updatePubspecVersion(customVersion);
            print('  ✓ Updated pubspec.yaml version to $customVersion');
            currentVersion = customVersion;
          } else {
            print(
              '  (dry run) Would update pubspec.yaml version to $customVersion',
            );
          }
        } else {
          print('  Error: Invalid version format. Should be in format: x.y.z');
          exit(1);
        }
      }
    }
  } else {
    // Verify version increment in non-interactive mode
    if (lastVersion != null &&
        !_isVersionIncremented(lastVersion, currentVersion)) {
      print(
        'Error: Version $currentVersion is not incremented from $lastVersion',
      );
      exit(1);
    }
  }

  // Check if CHANGELOG.md has an entry for the current version
  final changelogEntryExists = _changelogContainsVersion(currentVersion);

  if (!changelogEntryExists) {
    if (!nonInteractive) {
      print(
        '\n  CHANGELOG.md does not contain an entry for version $currentVersion',
      );
      print(
        '  You need to update the changelog with details about this release.',
      );
      print('  Recommended changelog format:');
      print('''
  ## [$currentVersion] - ${_getFormattedDate()}
  
  ### Added
  - New feature or functionality
  
  ### Changed
  - Changes to existing functionality
  
  ### Fixed
  - Bug fixes
  ''');

      final updateChangelog = await _prompt(
        '  Do you want to open CHANGELOG.md for editing? (y/n): ',
      );

      if (updateChangelog.toLowerCase() == 'y') {
        if (!dryRun) {
          await _openEditor('CHANGELOG.md');
          print('  Please update CHANGELOG.md and press Enter when done...');
          stdin.readLineSync();

          // Re-check after edit
          if (!_changelogContainsVersion(currentVersion)) {
            print(
              '  Error: CHANGELOG.md still does not contain an entry for version $currentVersion',
            );
            exit(1);
          }
          print('  ✓ CHANGELOG.md updated successfully');
        } else {
          print('  (dry run) Would open CHANGELOG.md for editing');
        }
      } else {
        print('  Error: CHANGELOG.md must be updated before release');
        exit(1);
      }
    } else {
      print(
        'Error: CHANGELOG.md does not contain an entry for version $currentVersion',
      );
      print(
        '       Update CHANGELOG.md or use interactive mode (default) for assistance.',
      );
      exit(1);
    }
  }

  print('  ✓ Version $currentVersion is valid and documented in CHANGELOG.md');

  // Step 3: Run tests
  print('\nStep 3/8: Running tests...');
  final testResult = await _runProcess('dart', ['test']);
  if (testResult.exitCode != 0) {
    print('Error: Tests failed. Fix test failures before release.');
    exit(1);
  }
  print('  ✓ All tests passed');

  // Step 4: Update documentation and version references
  print('\nStep 4/8: Updating documentation...');
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
  print('\nStep 5/8: Committing changes and creating tag...');
  final tagName = 'v$currentVersion';

  if (!dryRun) {
    // Check if any files were changed by the doc update or interactive mode
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
  print('\nStep 6/8: Pushing changes and tags...');
  if (!dryRun) {
    await _runProcess('git', ['push', 'origin', 'main']);
    await _runProcess('git', ['push', 'origin', tagName]);
    print('  ✓ Pushed changes and tag to remote repository');
  } else {
    print('  (dry run) Would push changes and tag to remote repository');
  }

  // Step 7: Publish to pub.dev
  print('\nStep 7/8: Publishing to pub.dev...');
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

  // Step 8: Next development cycle
  print('\nStep 8/8: Setting up next development cycle...');
  if (!dryRun && !nonInteractive) {
    final setupNext = await _prompt('  Set up next development cycle? (y/n): ');

    if (setupNext.toLowerCase() == 'y') {
      final nextDevVersion = _incrementPatchVersion(currentVersion) + '-dev';
      if (await _prompt('  Update version to $nextDevVersion? (y/n): ') ==
          'y') {
        _updatePubspecVersion(nextDevVersion);
        await _runProcess('git', ['add', 'pubspec.yaml']);
        await _runProcess('git', [
          'commit',
          '-m',
          'Start next development cycle on $nextDevVersion',
        ]);
        await _runProcess('git', ['push', 'origin', 'main']);
        print('  ✓ Development cycle initialized at version $nextDevVersion');
      }
    }
  } else if (!nonInteractive) {
    print('  (dry run) Would set up next development cycle');
  } else {
    print(
      '  Skipping next development cycle setup (use interactive mode for this step)',
    );
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
  print(
    '  --dry-run         Simulate the release process without making changes',
  );
  print(
    '  --non-interactive Skip interactive prompts (requires clean working directory)',
  );
  print('  --no-publish      Skip publishing to pub.dev');
  print('  --help            Show this help message');
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

/// Updates the version in pubspec.yaml
void _updatePubspecVersion(String newVersion) {
  final pubspecFile = File('pubspec.yaml');
  final content = pubspecFile.readAsStringSync();

  // Regex to match the version line with proper indentation
  final versionRegex = RegExp(
    r'version:\s*([0-9]+\.[0-9]+\.[0-9]+(?:[-+].+)?)',
  );
  final updatedContent = content.replaceFirst(
    versionRegex,
    'version: $newVersion',
  );

  pubspecFile.writeAsStringSync(updatedContent);
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
  // Extract base version without pre-release or build metadata
  final lastBase = lastVersion.split(RegExp(r'[-+]')).first;
  final currentBase = currentVersion.split(RegExp(r'[-+]')).first;

  final last = lastBase.split('.').map(int.parse).toList();
  final current = currentBase.split('.').map(int.parse).toList();

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

/// Checks if CHANGELOG.md contains an entry for the current version
bool _changelogContainsVersion(String version) {
  final changelog = File('CHANGELOG.md');

  if (!changelog.existsSync()) {
    return false;
  }

  final content = changelog.readAsStringSync();

  // Look for standard changelog format: ## [x.y.z] - date
  final versionRegex = RegExp(r'## *\[' + RegExp.escape(version) + r'\]');
  return versionRegex.hasMatch(content);
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

/// Gets today's date in YYYY-MM-DD format
String _getFormattedDate() {
  final now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
}

/// Suggests the next version based on the last released version and current version
String _suggestNextVersion(String lastVersion, String currentVersion) {
  // If current version is already incremented, use it
  if (lastVersion != currentVersion &&
      _isVersionIncremented(lastVersion, currentVersion)) {
    return currentVersion;
  }

  // Otherwise suggest a patch increment by default
  return _incrementPatchVersion(lastVersion);
}

/// Increments the patch version of a semantic version string
String _incrementPatchVersion(String version) {
  // Extract base version without pre-release or build metadata
  final baseVersion = version.split(RegExp(r'[-+]')).first;
  final parts = baseVersion.split('.').map(int.parse).toList();

  if (parts.length != 3) {
    return version; // Can't increment non-semver version
  }

  // Increment patch version
  parts[2]++;

  return '${parts[0]}.${parts[1]}.${parts[2]}';
}

/// Prompts the user for input with the given message
Future<String> _prompt(String message) async {
  stdout.write(message);
  return stdin.readLineSync() ?? '';
}

/// Opens the specified file in the default editor
Future<void> _openEditor(String filePath) async {
  String? command;
  List<String> args = [];

  // Determine platform-specific command to open default editor
  if (Platform.isWindows) {
    command = 'start';
    args = ['', filePath];
  } else if (Platform.isMacOS) {
    command = 'open';
    args = [filePath];
  } else if (Platform.isLinux) {
    command = 'xdg-open';
    args = [filePath];
  } else {
    throw UnsupportedError('Unsupported platform for opening editor');
  }

  await Process.run(command, args);
}

/// Validates if a string is a valid semantic version
bool _isValidVersion(String version) {
  // Basic semver validation (x.y.z with optional pre-release/build metadata)
  final regex = RegExp(r'^\d+\.\d+\.\d+(?:[-+].+)?$');
  return regex.hasMatch(version);
}
