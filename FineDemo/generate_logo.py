#!/usr/bin/env python3
"""
Script to generate ClearFine logo files at different resolutions for iOS app.
This script creates the logo at 1x, 2x, and 3x resolutions.
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_logo(size, output_path):
    """Create the ClearFine logo at specified size"""
    # Calculate dimensions based on size
    width = int(size * 1.5)  # Width is 1.5 times the height
    height = size
    
    # Create a new image with navy blue background
    img = Image.new('RGBA', (width, height), (10, 20, 64, 255))
    draw = ImageDraw.Draw(img)
    
    # Try to load font - if not available, use default
    try:
        # For production, you would use a proper font file
        font_size = int(size * 0.4)
        font = ImageFont.truetype("Arial Bold.ttf", font_size)
    except IOError:
        # Use default font if the specified font is not available
        font = ImageFont.load_default()
    
    # Draw "ClearFine" text in cream color
    text = "ClearFine"
    text_color = (250, 242, 217, 255)  # Cream color
    
    # Calculate text position (centered)
    text_width = width * 0.8  # Approximate text width
    text_x = (width - text_width) / 2
    text_y = (height - font_size) / 2
    
    # Draw text
    draw.text((text_x, text_y), text, fill=text_color, font=font)
    
    # Draw green checkmark (simplified)
    check_size = int(size * 0.3)
    check_x = int(width * 0.55)
    check_y = int(height * 0.5)
    
    # Green color for checkmark
    green_color = (26, 204, 51, 255)
    
    # Draw a simple checkmark (V shape)
    points = [
        (check_x - check_size/2, check_y),
        (check_x - check_size/6, check_y + check_size/2),
        (check_x + check_size/2, check_y - check_size/2)
    ]
    draw.line(points, fill=green_color, width=int(size * 0.06))
    
    # Save the image
    img.save(output_path, "PNG")
    print(f"Created logo at {output_path}")

def main():
    """Generate logos at different resolutions"""
    # Create directory if it doesn't exist
    os.makedirs("Assets.xcassets/Logo.imageset", exist_ok=True)
    
    # Generate logos at different sizes
    create_logo(100, "Assets.xcassets/Logo.imageset/ClearFineLogo.png")      # 1x
    create_logo(200, "Assets.xcassets/Logo.imageset/ClearFineLogo@2x.png")   # 2x
    create_logo(300, "Assets.xcassets/Logo.imageset/ClearFineLogo@3x.png")   # 3x
    
    print("Logo generation complete!")

if __name__ == "__main__":
    main() 