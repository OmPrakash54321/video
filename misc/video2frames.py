import cv2
import os

# Function to split video into frames
def split_video_into_frames(video_path, output_folder):
    # Create output folder if it doesn't exist
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    # Capture the video
    vidcap = cv2.VideoCapture(video_path)
    
    success, image = vidcap.read()
    count = 0
    
    while success:
        # Save frame as JPEG file
        cv2.imwrite(os.path.join(output_folder, f"frame{count:04d}.jpg"), image)
        success, image = vidcap.read()
        print(f'Read a new frame: {success}, Frame number: {count}')
        count += 1

    vidcap.release()
    print(f'Total frames saved: {count}')

if __name__ == "__main__":
    # Example usage
    video_file = '1920x1080_60fps.mp4'  # Replace with your video file path
    output_directory = 'frames_1920x1080_30fps_c'      # Output folder for frames
    split_video_into_frames(video_file, output_directory)
