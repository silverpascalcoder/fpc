# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2026-06-03
### Fixes
- (test_*_db program) update parameters to connect to database
- (test_*_db program) missing units for driver
- (uservicegererator unit) fix field types when setting parameters
### Known Issues (What is NOT working yet) 
- error in call to TDB.Initialize re host and database name

## [Unreleased] - 2026-06-02
### Known Issues (What is NOT working yet) 
- issue with line length in generated service unit (fixed in 2026-06-03)
- issue with test_*_db program missing units for driver (fixed in 2026-06-03)
- hardcoded to use Firebird and profile named 'main'
