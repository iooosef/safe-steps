import cv2
import os
import sys

def extract_frames(video_path):
    # Open the video file
    vidcap = cv2.VideoCapture(video_path)
    
    if not vidcap.isOpened():
        print(f"Error: Could not open video {video_path}")
        return

    # Setup output directory (same dir as video)
    video_dir = os.path.dirname(os.path.abspath(video_path))
    video_name = os.path.splitext(os.path.basename(video_path))[0]
    output_folder = os.path.join(video_dir, f"{video_name}_frames")

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
        print(f"Creating folder: {output_folder}")

    count = 0
    success = True

    print("Extraction started...")

    while success:
        # read() returns (True/False, image_data)
        success, image = vidcap.read()
        
        if success:
            # Save frame as JPEG with 5-digit padding (e.g., frame_00001.jpg)
            # This keeps them sorted correctly for training or joining later
            file_path = os.path.join(output_folder, f"frame_{count:05d}.jpg")
            cv2.imwrite(file_path, image)
            
            if count % 100 == 0:
                print(f"Extracted {count} frames...")
            
            count += 1

    vidcap.release()
    print(f"Finished! Total frames: {count}")
    print(f"Saved to: {output_folder}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python extract_frames.py <path_to_video>")
    else:
        extract_frames(sys.argv[1])