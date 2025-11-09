#!/bin/bash
# Local CI check script - runs all the same checks as GitHub Actions
# Run this before pushing to ensure CI will pass

set -e  # Exit on any error

echo "🔍 Running local CI checks..."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FAILED=0

# 1. TypeScript Check
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📘 1/5: TypeScript Type Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if npx tsc --noEmit; then
    echo -e "${GREEN}✓ TypeScript check passed${NC}"
else
    echo -e "${RED}✗ TypeScript check failed${NC}"
    FAILED=1
fi
echo ""

# 2. Rust Format Check
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🦀 2/5: Rust Format Check (cargo fmt)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd src-tauri
if cargo fmt --all -- --check; then
    echo -e "${GREEN}✓ Rust formatting is correct${NC}"
else
    echo -e "${YELLOW}⚠ Rust formatting issues found${NC}"
    echo "  Run: cd src-tauri && cargo fmt --all"
    FAILED=1
fi
cd ..
echo ""

# 3. Rust Clippy
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📎 3/5: Rust Linting (cargo clippy)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd src-tauri
if cargo clippy -- -D warnings; then
    echo -e "${GREEN}✓ Clippy found no issues${NC}"
else
    echo -e "${RED}✗ Clippy found warnings/errors${NC}"
    FAILED=1
fi
cd ..
echo ""

# 4. Build Frontend
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ 4/5: Build Frontend"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if npm run vite:build; then
    echo -e "${GREEN}✓ Frontend built successfully${NC}"
else
    echo -e "${RED}✗ Frontend build failed${NC}"
    FAILED=1
fi
echo ""

# 5. Build Rust (no packaging)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 5/5: Build Rust Backend"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd src-tauri
if cargo build --release; then
    echo -e "${GREEN}✓ Rust backend built successfully${NC}"
else
    echo -e "${RED}✗ Rust backend build failed${NC}"
    FAILED=1
fi
cd ..
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All CI checks passed!${NC}"
    echo "   You're good to push to GitHub."
    echo ""
    echo "   To push:"
    echo "   git add ."
    echo "   git commit -m 'your message'"
    echo "   git push origin main"
else
    echo -e "${RED}❌ Some CI checks failed${NC}"
    echo "   Fix the issues above before pushing."
    exit 1
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

