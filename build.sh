#!/usr/bin/env bash
#
# This script builds the Rust crate in its directory into a staticlib XCFramework for iOS and macos.

BUILD_PROFILE=$1   # release or debug

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
WORKING_DIR=$THIS_DIR
REPO_ROOT=$THIS_DIR # change to ../ if is a workspace member

if [ -z $BUILD_PROFILE ]; then
	BUILD_PROFILE="release"
fi
case $BUILD_PROFILE in
  debug)
    ;;
  release)
    ;;
  *) echo "Unknown build profile: $BUILD_PROFILE"; exit 1;
esac

# build all required targets
for BUILD_TARGET in \
	aarch64-apple-ios-sim \
	x86_64-apple-ios \
	aarch64-apple-ios \
	x86_64-apple-darwin \
	aarch64-apple-darwin
do
	rustup target add $BUILD_TARGET
	if [ $BUILD_PROFILE == "release" ]; then
		cargo build --target $BUILD_TARGET --release
	else
		cargo build --target $BUILD_TARGET
	fi
done

cargo install uniffi_bindgen

UDL_FILE="${WORKING_DIR}/src/lib.udl"
UDL_NAMESPACE=$(grep --max-count=1 'namespace ' $UDL_FILE | cut -d ' ' -f 2)
FRAMEWORK_NAME="${UDL_NAMESPACE}FFI"
FRAMEWORK_FILENAME=$FRAMEWORK_NAME
CARGO="$HOME/.cargo/bin/cargo"

MANIFEST_PATH="$WORKING_DIR/Cargo.toml"

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "Could not locate Cargo.toml in $MANIFEST_PATH"
  exit 1
fi

CRATE_NAME=$(grep --max-count=1 '^name =' "$MANIFEST_PATH" | cut -d '"' -f 2)
if [[ -z "$CRATE_NAME" ]]; then
  echo "Could not determine crate name from $MANIFEST_PATH"
  exit 1
fi

LIB_NAME="lib${CRATE_NAME}.a"

TARGET_DIR="$REPO_ROOT/target"
TARGET_PKG_ROOT="$WORKING_DIR/generated/iOS/$UDL_NAMESPACE"
TARGET_SOURCES_ROOT="${TARGET_PKG_ROOT}/Sources"

rm -rf "$TARGET_PKG_ROOT"
mkdir -p $TARGET_SOURCES_ROOT

# generate package.swift
sed s/__0__/$UDL_NAMESPACE/g "$WORKING_DIR/misc/Package.swift" > "$TARGET_PKG_ROOT/Package.swift"

XCFRAMEWORK_ROOT="$TARGET_SOURCES_ROOT/$FRAMEWORK_FILENAME.xcframework"

# Start from a clean slate.
COMMON="$TARGET_DIR/common"

# Make common
rm -rf "$COMMON"
mkdir -p "$COMMON/Modules"
mkdir -p "$COMMON/Headers"
mkdir -p "$COMMON/Resources"

echo -e "framework module ${UDL_NAMESPACE}FFI {\n    header \"${UDL_NAMESPACE}FFI.h\"\n    export *\n}" > "$COMMON/Modules/module.modulemap"

# generate header and swift file with uniffi-bindgen and move to common
uniffi-bindgen generate "$WORKING_DIR/src/lib.udl" -l swift -o "$COMMON/Headers"

mkdir -p "$TARGET_SOURCES_ROOT/$UDL_NAMESPACE"
mv "$COMMON/Headers/${UDL_NAMESPACE}.swift" \
	"$TARGET_SOURCES_ROOT/$UDL_NAMESPACE/${UDL_NAMESPACE}.swift"
rm -rf "$COMMON"/Headers/*.modulemap

# empty info files
cp "$WORKING_DIR/misc/Info.plist" "$COMMON/Resources/"

# make framework for iOS hardware
rm -Rf "$TARGET_DIR/ios-arm64"
mkdir -p "$TARGET_DIR/ios-arm64"
cp -r "$COMMON" "$TARGET_DIR/ios-arm64/$FRAMEWORK_NAME.framework"
cp "$TARGET_DIR/aarch64-apple-ios/$BUILD_PROFILE/$LIB_NAME" "$TARGET_DIR/ios-arm64/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME"

# make framework for iOS simulator, with both platforms as a fat binary
rm -Rf "$TARGET_DIR/ios-arm64_x86_64-simulator"
mkdir -p "$TARGET_DIR/ios-arm64_x86_64-simulator"
cp -r "$COMMON" "$TARGET_DIR/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework"
lipo -create \
  -output "$TARGET_DIR/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" \
  "$TARGET_DIR/aarch64-apple-ios-sim/$BUILD_PROFILE/$LIB_NAME" \
  "$TARGET_DIR/x86_64-apple-ios/$BUILD_PROFILE/$LIB_NAME"

# make framework for macos, with both platforms as a fat binary
rm -Rf "$TARGET_DIR/macos-arm64_x86_64"
mkdir -p "$TARGET_DIR/macos-arm64_x86_64"
cp -r "$COMMON" "$TARGET_DIR/macos-arm64_x86_64/$FRAMEWORK_NAME.framework"
lipo -create \
  -output "$TARGET_DIR/macos-arm64_x86_64/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" \
  "$TARGET_DIR/aarch64-apple-darwin/$BUILD_PROFILE/$LIB_NAME" \
  "$TARGET_DIR/x86_64-apple-darwin/$BUILD_PROFILE/$LIB_NAME"

# Set up the metadata for the XCFramework as a whole.
xcodebuild -create-xcframework -framework "$TARGET_DIR/ios-arm64/$FRAMEWORK_NAME.framework" \
  -framework "$TARGET_DIR/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework" \
  -framework "$TARGET_DIR/macos-arm64_x86_64/$FRAMEWORK_NAME.framework" \
  -output "$XCFRAMEWORK_ROOT"

rm -rf "$COMMON"

# Zip it all up into a bundle for distribution.
# (cd "$WORKING_DIR" && zip -9 -r "$FRAMEWORK_FILENAME.xcframework.zip" "Sources/$FRAMEWORK_FILENAME.xcframework")
