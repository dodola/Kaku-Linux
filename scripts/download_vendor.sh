#!/usr/bin/env bash
set -euo pipefail

# This script downloads plugin dependencies bundled into the Kaku App.
# CLI tools (starship/git-delta/lazygit) are installed via Homebrew at init time.

VENDOR_DIR="$(cd "$(dirname "$0")/../assets/vendor" && pwd)"
mkdir -p "$VENDOR_DIR"

echo "[0/5] Cleaning legacy vendor binaries..."
rm -f "$VENDOR_DIR/starship" "$VENDOR_DIR/delta" "$VENDOR_DIR/zoxide"
rm -rf "$VENDOR_DIR/completions" "$VENDOR_DIR/man"
rm -f "$VENDOR_DIR/README.md" "$VENDOR_DIR/CHANGELOG.md" "$VENDOR_DIR/LICENSE"

echo "[1/5] Downloading Starship..."
STARSHIP_BIN="$VENDOR_DIR/starship"

OS_TYPE="$(uname -s)"
ARCH="$(uname -m)"

if [[ ! -f "$STARSHIP_BIN" ]]; then
	if [[ "$OS_TYPE" == "Darwin" ]]; then
		echo "Creating Universal Binary for Starship (macOS)..."
		URL_ARM64="https://github.com/starship/starship/releases/latest/download/starship-aarch64-apple-darwin.tar.gz"
		URL_X86_64="https://github.com/starship/starship/releases/latest/download/starship-x86_64-apple-darwin.tar.gz"

		mkdir -p "$VENDOR_DIR/tmp_starship"

		curl -L "$URL_ARM64" | tar -xz -C "$VENDOR_DIR/tmp_starship"
		mv "$VENDOR_DIR/tmp_starship/starship" "$VENDOR_DIR/tmp_starship/starship_arm64"

		curl -L "$URL_X86_64" | tar -xz -C "$VENDOR_DIR/tmp_starship"
		mv "$VENDOR_DIR/tmp_starship/starship" "$VENDOR_DIR/tmp_starship/starship_x86_64"

		lipo -create -output "$STARSHIP_BIN" \
			"$VENDOR_DIR/tmp_starship/starship_arm64" \
			"$VENDOR_DIR/tmp_starship/starship_x86_64"

		chmod +x "$STARSHIP_BIN"
		rm -rf "$VENDOR_DIR/tmp_starship"
	elif [[ "$OS_TYPE" == "Linux" ]]; then
		echo "Downloading Starship for Linux ($ARCH)..."
		if [[ "$ARCH" == "x86_64" ]]; then
			URL="https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz"
		elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
			URL="https://github.com/starship/starship/releases/latest/download/starship-aarch64-unknown-linux-gnu.tar.gz"
		else
			echo "Unsupported architecture: $ARCH"
			exit 1
		fi

		curl -L "$URL" | tar -xz -C "$VENDOR_DIR"
		chmod +x "$STARSHIP_BIN"
	else
		echo "Unsupported OS: $OS_TYPE"
		exit 1
	fi
else
	echo "Starship already exists, skipping."
fi

echo "[2/5] Cloning zsh-autosuggestions..."
AUTOSUGGEST_DIR="$VENDOR_DIR/zsh-autosuggestions"
if [[ ! -d "$AUTOSUGGEST_DIR" ]]; then
	git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGEST_DIR"
	rm -rf "$AUTOSUGGEST_DIR/.git"
else
	echo "zsh-autosuggestions already exists, skipping."
fi

echo "[3/5] Cloning zsh-syntax-highlighting..."
SYNTAX_DIR="$VENDOR_DIR/zsh-syntax-highlighting"
if [[ ! -d "$SYNTAX_DIR" ]]; then
	git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_DIR"
	rm -rf "$SYNTAX_DIR/.git"
else
	echo "zsh-syntax-highlighting already exists, skipping."
fi

echo "[4/5] Cloning zsh-completions..."
ZSH_COMPLETIONS_DIR="$VENDOR_DIR/zsh-completions"
if [[ ! -d "$ZSH_COMPLETIONS_DIR" ]]; then
	git clone --depth 1 https://github.com/zsh-users/zsh-completions.git "$ZSH_COMPLETIONS_DIR"
	rm -rf "$ZSH_COMPLETIONS_DIR/.git"
else
	echo "zsh-completions already exists, skipping."
fi

echo "[5/5] Cloning zsh-z..."
ZSH_Z_DIR="$VENDOR_DIR/zsh-z"
if [[ ! -d "$ZSH_Z_DIR" ]]; then
	git clone --depth 1 https://github.com/agkozak/zsh-z "$ZSH_Z_DIR"
	rm -rf "$ZSH_Z_DIR/.git"
else
	echo "zsh-z already exists, skipping."
fi

echo "Vendor dependencies downloaded to $VENDOR_DIR"
