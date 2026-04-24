#!/usr/bin/env bash
# Foxtrot L4: delete 9 dead .swift.disabled / .swift.bak test files.
# Run from the repo root: /Users/zackjordan/code/CoverCraft
#
# After this succeeds, tell Claude "files gone" and it will update
# Package.swift to remove the matching 9 exclusion entries + commit.

set -euo pipefail

cd "$(dirname "$0")"

if [ ! -d .git ]; then
  echo "error: run from repo root (expected .git here)" >&2
  exit 1
fi

if [ "$(git branch --show-current)" != "fix/remediation-2026-04-20" ]; then
  echo "warning: not on fix/remediation-2026-04-20 (currently on $(git branch --show-current))" >&2
  read -r -p "continue anyway? [y/N] " ans
  [ "$ans" = "y" ] || exit 1
fi

FILES=(
  CoverCraftPackage/Tests/TestUtilities/TestUtilitiesValidation.swift.disabled
  CoverCraftPackage/Tests/CoverCraftSegmentationTests/SegmentationServiceTests.swift.bak
  CoverCraftPackage/Tests/CoverCraftSegmentationTests/MeshSegmentationTests.swift.bak
  CoverCraftPackage/Tests/CoverCraftFlatteningTests/FlatteningServiceTests.swift.disabled
  CoverCraftPackage/Tests/CoverCraftFeatureTests/CoverCraftFeatureTests.swift.disabled
  CoverCraftPackage/Tests/CoverCraftFeatureTests/MeshSegmentationServiceTests.swift.disabled
  CoverCraftPackage/Tests/CoverCraftFeatureTests/PatternFlattenerTests.swift.disabled
  CoverCraftPackage/Tests/CoverCraftFeatureTests/PatternExporterTests.swift.disabled
  CoverCraftPackage/Tests/MemoryTests/MemoryLeakTests.swift.disabled
)

echo "Will git rm the following ${#FILES[@]} files:"
for f in "${FILES[@]}"; do echo "  $f"; done
echo ""
read -r -p "proceed? [y/N] " ans
[ "$ans" = "y" ] || { echo "aborted"; exit 1; }

git rm "${FILES[@]}"

echo ""
echo "Done. ${#FILES[@]} files staged for deletion."
echo "Next: tell Claude to finish Foxtrot L4 (Package.swift exclusion cleanup + commit)."
