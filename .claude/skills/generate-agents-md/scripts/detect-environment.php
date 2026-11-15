#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * @file
 * Detects the facts of a Drupal project that AGENTS.md describes.
 *
 * Run from the project root (the directory with composer.json). Prints JSON.
 * A value that cannot be detected is NULL or an empty list, never a guess.
 */

/**
 * Reads a JSON file into an array.
 *
 * @param string $path
 *   Absolute path of the file.
 *
 * @return array
 *   The decoded data, or an empty array when the file is missing or invalid.
 */
function read_json(string $path): array {
  if (!is_file($path)) {
    return [];
  }
  $data = json_decode((string) file_get_contents($path), TRUE);
  return is_array($data) ? $data : [];
}

/**
 * Reads a top-level scalar from YAML text without a YAML parser.
 *
 * @param string $content
 *   The YAML text.
 * @param string $key
 *   The top-level key.
 *
 * @return string|null
 *   The value, or NULL when the key is absent or not a scalar.
 */
function read_yaml_scalar(string $content, string $key): ?string {
  $pattern = '/^' . preg_quote($key, '/') . ':[ \t]*(.+)$/m';
  if (!preg_match($pattern, $content, $matches)) {
    return NULL;
  }
  $value = trim((string) preg_replace('/\s+#.*$/', '', $matches[1]));
  $value = trim($value, "\"'");
  return $value === '' ? NULL : $value;
}

/**
 * Returns the first of several relative paths that exists.
 *
 * @param string $root
 *   The project root.
 * @param string[] $candidates
 *   Paths relative to the project root.
 *
 * @return string|null
 *   The first existing path, or NULL.
 */
function first_existing(string $root, array $candidates): ?string {
  foreach ($candidates as $candidate) {
    if (file_exists($root . '/' . $candidate)) {
      return $candidate;
    }
  }
  return NULL;
}

/**
 * Lists the extensions (modules or themes) below a directory.
 *
 * @param string $root
 *   The project root.
 * @param string $directory
 *   Directory relative to the project root, e.g. web/themes/custom.
 *
 * @return array[]
 *   One entry per *.info.yml: name, path, base_theme, npm_scripts, sdc.
 */
function list_extensions(string $root, string $directory): array {
  $extensions = [];
  $info_files = glob($root . '/' . $directory . '/*/*.info.yml') ?: [];
  foreach ($info_files as $info_file) {
    $path = dirname($info_file);
    $package = read_json($path . '/package.json');
    $extensions[] = [
      'name' => basename($info_file, '.info.yml'),
      'path' => substr($path, strlen($root) + 1),
      'base_theme' => read_yaml_scalar((string) file_get_contents($info_file), 'base theme'),
      'npm_scripts' => array_keys($package['scripts'] ?? []),
      'sdc' => is_dir($path . '/components'),
    ];
  }
  return $extensions;
}

/**
 * Maps an installed Drupal core version to the hook style it supports.
 *
 * @param string|null $version
 *   The installed version of drupal/core, e.g. 11.2.4.
 *
 * @return string|null
 *   "oop" (11.2+), "oop_without_preprocess" (11.1), "procedural" (older),
 *   or NULL when the version is unknown.
 */
function hook_style(?string $version): ?string {
  if ($version === NULL || !preg_match('/^\d+\.\d+/', $version)) {
    return NULL;
  }
  if (version_compare($version, '11.2', '>=')) {
    return 'oop';
  }
  return version_compare($version, '11.1', '>=') ? 'oop_without_preprocess' : 'procedural';
}

$root = (string) getcwd();
$composer = read_json($root . '/composer.json');
if ($composer === []) {
  fwrite(STDERR, "No composer.json in $root. Run this script from the project root.\n");
  exit(1);
}

// Installed versions come from composer.lock; composer.json only has ranges.
$lock = read_json($root . '/composer.lock');
$installed = [];
foreach (array_merge($lock['packages'] ?? [], $lock['packages-dev'] ?? []) as $package) {
  $installed[$package['name']] = ltrim((string) $package['version'], 'v');
}
$require = ($composer['require'] ?? []) + ($composer['require-dev'] ?? []);

$webroot = $composer['extra']['drupal-scaffold']['locations']['web-root'] ?? NULL;
$webroot = is_string($webroot) ? trim(preg_replace('#^\./#', '', $webroot), '/') : NULL;
if ($webroot === NULL || $webroot === '') {
  $webroot = NULL;
  foreach (['web', 'docroot', 'public', 'html'] as $candidate) {
    if (is_dir($root . '/' . $candidate . '/core')) {
      $webroot = $candidate;
      break;
    }
  }
}

$environment = ['type' => 'none'];
$ddev_file = $root . '/.ddev/config.yaml';
if (is_file($ddev_file)) {
  $ddev = (string) file_get_contents($ddev_file);
  preg_match('/^database:\s*\n\s+type:\s*(\S+)\s*\n\s+version:\s*["\']?([^"\'\s]+)/m', $ddev, $database);
  $name = read_yaml_scalar($ddev, 'name');
  $environment = [
    'type' => 'ddev',
    'name' => $name,
    'url' => $name === NULL ? NULL : 'https://' . $name . '.ddev.site',
    'project_type' => read_yaml_scalar($ddev, 'type'),
    'docroot' => read_yaml_scalar($ddev, 'docroot'),
    'php_version' => read_yaml_scalar($ddev, 'php_version'),
    'webserver' => read_yaml_scalar($ddev, 'webserver_type'),
    'database' => $database ? $database[1] . ' ' . $database[2] : NULL,
    'nodejs_version' => read_yaml_scalar($ddev, 'nodejs_version'),
  ];
}
else {
  $compose_file = first_existing($root, ['compose.yaml', 'compose.yml', 'docker-compose.yaml', 'docker-compose.yml']);
  if ($compose_file !== NULL) {
    $environment = ['type' => 'docker-compose', 'file' => $compose_file];
  }
}

$core_version = $installed['drupal/core'] ?? NULL;
$workflows = array_map('basename', glob($root . '/.github/workflows/*.y*ml') ?: []);

$detected = [
  'webroot' => $webroot,
  'environment' => $environment,
  'drupal' => [
    'constraint' => $require['drupal/core-recommended'] ?? $require['drupal/core'] ?? NULL,
    'installed' => $core_version,
    'hooks' => hook_style($core_version),
  ],
  'php' => [
    'constraint' => $require['php'] ?? NULL,
    'platform' => $composer['config']['platform']['php'] ?? NULL,
  ],
  'drush' => $installed['drush/drush'] ?? NULL,
  'modules' => $webroot === NULL ? [] : array_column(list_extensions($root, $webroot . '/modules/custom'), 'name'),
  'themes' => $webroot === NULL ? [] : list_extensions($root, $webroot . '/themes/custom'),
  'config_sync' => first_existing($root, ['config/sync', 'config/default', 'sync']),
  'patches' => is_dir($root . '/patches') || isset($composer['extra']['patches']) || isset($composer['extra']['patches-file']),
  'ci' => array_values(array_filter([
    first_existing($root, ['.gitlab-ci.yml']),
    first_existing($root, ['bitbucket-pipelines.yml']),
    first_existing($root, ['.circleci/config.yml']),
    first_existing($root, ['Jenkinsfile']),
    $workflows === [] ? NULL : '.github/workflows/ (' . implode(', ', $workflows) . ')',
  ])),
  'tools' => [
    'phpcs' => isset($installed['drupal/coder']),
    'phpcs_config' => first_existing($root, ['phpcs.xml', 'phpcs.xml.dist', '.phpcs.xml', '.phpcs.xml.dist']),
    'phpstan' => isset($installed['phpstan/phpstan']),
    'phpstan_config' => first_existing($root, ['phpstan.neon', 'phpstan.neon.dist', 'phpstan.dist.neon']),
    'phpunit' => $installed['phpunit/phpunit'] ?? NULL,
    'phpunit_config' => first_existing($root, array_filter([
      'phpunit.xml',
      'phpunit.xml.dist',
      $webroot === NULL ? NULL : $webroot . '/core/phpunit.xml.dist',
    ])),
    'playwright_config' => first_existing($root, [
      'playwright.config.ts',
      'playwright.config.js',
      'tests/e2e/playwright.config.ts',
      'tests/e2e/playwright.config.js',
    ]),
  ],
];

echo json_encode($detected, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
