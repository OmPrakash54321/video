import os
import cv2
import numpy as np

def mse(imageA, imageB):
    # Compute the Mean Squared Error between two images
    err = np.sum((imageA.astype("float") - imageB.astype("float")) ** 2)
    err /= float(imageA.shape[0] * imageA.shape[1])
    return err

def grey_imgs(f):
    o = []
    for img in f:
        o.append(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY))
    return o

def get_imgs(file: str, count: int):
    print(f'{file=}')

    # Get the image path names in the dir
    frames = []
    for im in os.listdir(file):
        frames.append(im)

    # Sort the image paths so that they are in ascending order
    frames = sorted(frames)[:10]
    print(f'{frames}')

    # Append the images in the out list
    o = []
    for i in frames:
        o.append(cv2.imread(os.path.join(file, i)))

    return o

def compare_imgs(frames1: list[str], frames2: list[str]):
    for ind, (i, j) in enumerate(zip(frames1, frames2)):
        comb = np.hstack((i, j))
        comb = cv2.resize(comb, i.shape[:2])
        cv2.imshow(i, comb)
        cv2.waitKey(0)

def read_file(file: str):
    with open(file, "r") as f:
        im = f.read()
        print(im)

if __name__ == "__main__":
    f1_name = os.path.join(os.curdir, "frames_1920x1080_30fps_c")
    f2_name = os.path.join(os.curdir, "frames_1920x1080_60fps")
    # Get the images in the dir
    i1 = get_imgs(f1_name, 10)
    i2 = get_imgs(f2_name, 10)

    # Visually compare the images
    # Currenty the resolution is not proper
    # compare_imgs(i1, i2)
    
    # Convert images to grey scale to actually compare them based on pixel values.
    g1 = grey_imgs(i1)
    g2 = grey_imgs(i2)

    # Perform mse comparison
    for i, j in zip(g1, g2, strict=True):
        if mse(i, j) == 0:
            print(f'image same')
        else:
            print(f"images vary with error : {mse(i, j)}")