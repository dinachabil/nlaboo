import os
from PIL import Image

SRC = "assets/icons/logo.png"

SIZES = [16, 32, 64, 128, 256, 512, 1024]
ASSETS_DIR = "assets/icons"
ANDROID_DIR = "android/app/src/main/res"
IOS_DIR = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
WEB_DIR = "web/icons"
MACOS_DIR = "macos/Runner/Assets.xcassets/AppIcon.appiconset"

# Ensure directory exists (utility function)


def ensure_dir(path):
    os.makedirs(path, exist_ok=True)


# Save resized icon to path


def save_icon(img, path, size):
    img_resized = img.resize((size, size), Image.LANCZOS)
    img_resized.save(path, format="PNG")


# Main icon generation logic


def main():
    img = Image.open(SRC).convert("RGBA")

    # 1. Standard sizes in assets/icons/
    ensure_dir(ASSETS_DIR)
    for sz in SIZES:
        save_icon(img, f"{ASSETS_DIR}/logo_{sz}.png", sz)

    # 2. Android mipmap icons
    android_map = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, sz in android_map.items():
        ensure_dir(f"{ANDROID_DIR}/{folder}")
        save_icon(img, f"{ANDROID_DIR}/{folder}/ic_launcher.png", sz)

    # 3. iOS icons
    ios_map = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    ensure_dir(IOS_DIR)
    for fname, sz in ios_map.items():
        save_icon(img, f"{IOS_DIR}/{fname}", sz)

    # 4. Web icons
    web_map = {
        "Icon-192.png": 192,
        "Icon-512.png": 512,
        "Icon-maskable-192.png": 192,
        "Icon-maskable-512.png": 512,
        "favicon.png": 64,
    }
    ensure_dir(WEB_DIR)
    for fname, sz in web_map.items():
        save_icon(img, f"{WEB_DIR}/{fname}", sz)

    # 5. macOS desktop icons
    macos_map = {
        "app_icon_16.png": 16,
        "app_icon_32.png": 32,
        "app_icon_64.png": 64,
        "app_icon_128.png": 128,
        "app_icon_256.png": 256,
        "app_icon_512.png": 512,
        "app_icon_1024.png": 1024,
    }
    ensure_dir(MACOS_DIR)
    for fname, sz in macos_map.items():
        save_icon(img, f"{MACOS_DIR}/{fname}", sz)

    print("All icons generated.")
# Entry point


if __name__ == "__main__":
    main()

