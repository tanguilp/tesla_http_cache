# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project adheres to Semantic Versioning.

## [0.4.0] - 2025-05-17

### Added

- [`TeslaHTTPCache`] `stale-while-revalidate` is now supported

### Changed

- [`TeslaHTTPCache`] Error handling was modified and `TeslaHTTPCache` now always tries to find
a cached response observing the `stale-if-error` directive when it receives an error (in addition
to `500`, `502`, `503` and `504` HTTP error statuses as before)

## [0.3.2] - 2025-04-07

### Added

- [`TeslaHTTPCache`] Telemetry events now send the `%Tesla.Env{}` as part of the metadata

## [0.3.1] - 2024-05-19

### Fixed

- [`TeslaHTTPCache`] Take query parameters into account when caching

## [0.3.0] - 2023-06-22

### Changed

- [`TeslaHTTPCache`] Make `http_cache` an optional depedency

## [0.2.0] - 2023-04-25

### Changed

- [`TeslaHTTPCache`] Update to use `http_cache` `0.2.0`
- [`TeslaHTTPCache`] Options are now a map (was previously a keyword list)
