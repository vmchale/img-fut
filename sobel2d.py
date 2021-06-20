import numpy as np
import scipy.ndimage

def sobel2d(img):
    dx = scipy.ndimage.sobel(img, 1)
    dy = scipy.ndimage.sobel(img, 0)
    mag = np.hypot(dx, dy)
    # normalize
    return mag * (1.0 / np.max(mag))
