#!/usr/bin/env python3
"""
Generate a simple default avatar image for the Hosi Academy LMS
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_default_avatar(size=400, output_path='assets/images/default_avatar.png'):
    """
    Create a simple circular default avatar with a user icon

    Args:
        size: Size of the square image (default 400x400)
        output_path: Where to save the image
    """
    # Create a new image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Define colors (using professional blue/gray palette)
    bg_color = (59, 130, 246)  # Blue-500
    icon_color = (255, 255, 255, 255)  # White

    # Draw circular background
    circle_margin = 0
    draw.ellipse(
        [circle_margin, circle_margin, size - circle_margin, size - circle_margin],
        fill=bg_color
    )

    # Draw a simple user silhouette
    # Head circle
    head_radius = size // 8
    head_center_x = size // 2
    head_center_y = size // 3
    draw.ellipse(
        [
            head_center_x - head_radius,
            head_center_y - head_radius,
            head_center_x + head_radius,
            head_center_y + head_radius
        ],
        fill=icon_color
    )

    # Body (shoulders/torso arc)
    body_width = size // 2
    body_height = size // 3
    body_top = head_center_y + head_radius + (size // 20)
    draw.ellipse(
        [
            head_center_x - body_width // 2,
            body_top,
            head_center_x + body_width // 2,
            body_top + body_height
        ],
        fill=icon_color
    )

    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Save the image
    img.save(output_path, 'PNG')
    print(f"✓ Default avatar created successfully at: {output_path}")
    print(f"  Size: {size}x{size} pixels")
    print(f"  Format: PNG with transparency")

if __name__ == '__main__':
    import sys

    # Get the script directory to find the assets folder
    script_dir = os.path.dirname(os.path.abspath(__file__))
    assets_path = os.path.join(script_dir, 'assets', 'images', 'default_avatar.png')

    print("Creating default avatar for Hosi Academy LMS...")
    create_default_avatar(size=400, output_path=assets_path)
    print("\nDone! You can now run 'flutter pub get' and build the app.")
