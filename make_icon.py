import sys
from PIL import Image, ImageDraw, ImageFilter

def create_mac_icon(input_path, output_path):
    # Load original image
    img = Image.open(input_path).convert("RGBA")
    # Resize to 824x824 to leave room for the drop shadow within a 1024x1024 canvas
    img = img.resize((824, 824), Image.Resampling.LANCZOS)
    
    # Create mask for rounded corners (corner radius 226/1024 * 824 = 181.8)
    mask = Image.new("L", (824, 824), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, 824, 824), radius=182, fill=255)
    
    # Apply mask
    rounded_img = Image.new("RGBA", (824, 824), (0, 0, 0, 0))
    rounded_img.paste(img, (0, 0), mask)
    
    # Create shadow
    shadow_offset_y = 20
    shadow_blur = 30
    shadow_color = (0, 0, 0, 80) # 30% opacity black
    
    shadow_canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_canvas)
    shadow_draw.rounded_rectangle(
        (100, 100 + shadow_offset_y, 924, 924 + shadow_offset_y), 
        radius=182, 
        fill=shadow_color
    )
    
    # Blur the shadow
    shadow_canvas = shadow_canvas.filter(ImageFilter.GaussianBlur(shadow_blur))
    
    # Paste the rounded image on top
    # 1024 - 824 = 200, so 100 padding on each side
    shadow_canvas.paste(rounded_img, (100, 100), rounded_img)
    
    # Save output
    shadow_canvas.save(output_path, "PNG")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 make_icon.py <input> <output>")
        sys.exit(1)
    create_mac_icon(sys.argv[1], sys.argv[2])
