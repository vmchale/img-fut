import timeit

setup = """
import imgfut
import imageio
import numpy as np

mod = imgfut.imgfut()

img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))
"""

setup_scipy = """
import scipy.ndimage
import imageio
import numpy as np
img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))
"""

print('Sobel (Futhark)', timeit.timeit('mod.sobel_f32(img0)', setup=setup, number=1000), "ms")
print('Prewitt (Futhark)', timeit.timeit('mod.prewitt_f32(img0)', setup=setup, number=1000), "ms")
print('Mean filter (Futhark)', timeit.timeit('mod.mean_filter_f32(img0)', setup=setup, number=1000), "ms")
print('Sobel (SciPy)', timeit.timeit('scipy.ndimage.sobel(img0)', setup=setup_scipy, number=1000), "ms")
print('Prewitt (SciPy)', timeit.timeit('scipy.ndimage.prewitt(img0)', setup=setup_scipy, number=1000), "ms")
print('Mean Filter (SciPy)', timeit.timeit('scipy.ndimage.uniform_filter(img0, 7)', setup=setup_scipy, number=1000), "ms")
