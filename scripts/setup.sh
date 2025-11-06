#!/bin/bash
# Setup script for voxtype development

set -e

echo "🚀 Setting up voxtype..."

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 18+ first."
    exit 1
fi
echo "✓ Node.js found: $(node --version)"

# Check Rust
if ! command -v rustc &> /dev/null; then
    echo "❌ Rust not found. Please install Rust from https://rustup.rs"
    exit 1
fi
echo "✓ Rust found: $(rustc --version)"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found. Please install npm."
    exit 1
fi
echo "✓ npm found: $(npm --version)"

# Install Node dependencies
echo ""
echo "📦 Installing Node.js dependencies..."
npm install

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo ""
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please edit .env and add your OPENAI_API_KEY"
fi

# Check for Linux dependencies
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo ""
    echo "🐧 Checking Linux dependencies..."
    
    MISSING_DEPS=()
    
    # Check for required packages
    if ! pkg-config --exists webkit2gtk-4.1 2>/dev/null; then
        MISSING_DEPS+=("webkit2gtk-4.1")
    fi
    
    if ! pkg-config --exists gtk+-3.0 2>/dev/null; then
        MISSING_DEPS+=("gtk3")
    fi
    
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        echo "⚠️  Missing system dependencies:"
        for dep in "${MISSING_DEPS[@]}"; do
            echo "   - $dep"
        done
        echo ""
        echo "Install with:"
        if command -v apt &> /dev/null; then
            echo "  sudo apt install -y libwebkit2gtk-4.1-dev build-essential curl wget file libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev"
        elif command -v dnf &> /dev/null; then
            echo "  sudo dnf install webkit2gtk4.1-devel openssl-devel curl wget file libappindicator-gtk3-devel librsvg2-devel"
        elif command -v pacman &> /dev/null; then
            echo "  sudo pacman -S webkit2gtk-4.1 base-devel curl wget file openssl appmenu-gtk-module libappindicator-gtk3 librsvg"
        fi
    else
        echo "✓ All required system dependencies found"
    fi
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Add your OpenAI API key to .env"
echo "  2. Run 'npm run dev' to start development"
echo "  3. Press Alt+Space to activate the overlay"
echo ""

