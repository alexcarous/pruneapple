# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-04

### Added
- **Native GUI:** Transitioned from a terminal-based script to a full native macOS application using SwiftUI.
- **100% Read-Only Scanning:** Fully safe execution model that only reads data and delegates any destructive actions to the macOS Finder.
- **APFS Physical Sizing:** Accurate physical disk usage calculations accounting for APFS clones and sparse files.
- **Background Status Indicator:** `MenuBarExtra` integration preventing App Nap during deep scans.
- **Interactive Visualizations:** Drill-down hierarchical tree and sunburst charts for interactive disk space exploration.
- **Safe Resolution Context Menu:** Includes "Reveal in Finder" action for safe file management.
- **Localized CSV Exports:** Privacy-conscious exports that adapt to local formatting rules to prevent spreadsheet corruption.
