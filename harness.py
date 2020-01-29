import timeit

setup = """
import imgfut
import imageio
import numpy as np

mod = imgfut.imgfut()

img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))
"""

setup_scipy = """
from scipy.ndimage import sobel
import imageio
import numpy as np
img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))
"""

print('Sobel (Futhark)', timeit.timeit('mod.sobel_f32(img0)', setup=setup, number=100) * 10, "ms")
print('Sobel (SciPy)', timeit.timeit('sobel(img0)', setup=setup_scipy, number=100) * 10, "ms")
