#!/bin/bash

# 1. Ensure output directories exist
mkdir -p coverage

# 2. Run tests and collect raw coverage data into the 'coverage' directory
#    (It creates raw JSON files like 'coverage/coverage-01.json')
dart test --coverage=coverage

# 3. Format the raw coverage data into a single LCOV file
#    The formatter automatically looks for the raw files dumped by dart test.
dart run coverage:format_coverage --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --packages=.dart_tool/package_config.json \
  --report-on=lib

# 4. Create html report with genhtml (install "brew install lcov" first)
genhtml coverage/lcov.info -o coverage/html