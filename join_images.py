import sys
import os
from PIL import Image

def join_images(left_path, right_path):
    try:
        # Open the images
        img_left = Image.open(left_path)
        img_right = Image.open(right_path)

        # Get directory of the first image
        output_dir = os.path.dirname(os.path.abspath(left_path))
        
        # Create new filename from the two input names (minus extensions)
        name1 = os.path.splitext(os.path.basename(left_path))[0]
        name2 = os.path.splitext(os.path.basename(right_path))[0]
        new_filename = f"{name1}_{name2}_joined.jpg"
        
        output_path = os.path.join(output_dir, new_filename)

        # Calculate dimensions
        w1, h1 = img_left.size
        w2, h2 = img_right.size
        combined_width = w1 + w2
        max_height = max(h1, h2)
        
        # Create canvas and paste
        new_img = Image.new("RGB", (combined_width, max_height))
        new_img.paste(img_left, (0, 0))
        new_img.paste(img_right, (w1, 0))

        # Save the result
        new_img.save(output_path)
        print(f"Success! Saved to: {output_path}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python join_images.py <left_image> <right_image>")
    else:
        join_images(sys.argv[1], sys.argv[2])