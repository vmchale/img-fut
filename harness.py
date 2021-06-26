import timeit

setup = """
import imgfut
import imageio
import numpy as np

mod = imgfut.imgfut()

img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))
img_large = np.array(imageio.imread('data/large-frog.jpg', pilmode='F'))
"""

setup_scipy = """
import scipy.ndimage
import imageio
import numpy as np
from scipy2d import sobel2d
img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))
img_large = np.array(imageio.imread('data/large-frog.jpg', pilmode='F'))
"""

print('Prewitt (Futhark)', timeit.timeit('mod.prewitt_f32(img0)', setup=setup, number=1000), "ms")
print('Mean filter (Futhark)', timeit.timeit('mod.mean_filter_f32(img0)', setup=setup, number=1000), "ms")
print('Gaussian filter (Futhark)', timeit.timeit('mod.gaussian_filter_f32(img0)', setup=setup, number=1000), "ms")
print('Laplacian filter (Futhark)', timeit.timeit('mod.laplacian_filter_f32(img0)', setup=setup, number=1000), "ms")
print('Laplacian-of-Gaussian filter (Futhark)', timeit.timeit('mod.laplacian_gaussian_filter_f32(img0)', setup=setup, number=1000), "ms")
print('Prewitt (SciPy)', timeit.timeit('scipy.ndimage.prewitt(img0)', setup=setup_scipy, number=1000), "ms")
print('Mean Filter (SciPy)', timeit.timeit('scipy.ndimage.uniform_filter(img0, 7)', setup=setup_scipy, number=1000), "ms")
print('Gaussian Filter (SciPy)', timeit.timeit('scipy.ndimage.gaussian_filter(img0, 3)', setup=setup_scipy, number=1000), "ms")
print('Laplacian Filter (SciPy)', timeit.timeit('scipy.ndimage.laplace(img0)', setup=setup_scipy, number=1000), "ms")
print('Laplacian-of-Gaussian Filter (SciPy)', timeit.timeit('scipy.ndimage.gaussian_laplace(img0, 1.5)', setup=setup_scipy, number=1000), "ms")

print('Mean filter (Large, Futhark)', timeit.timeit('mod.mean_filter_f32(img_large)', setup=setup, number=1000), "ms")
print('Mean Filter (Large, SciPy)', timeit.timeit('scipy.ndimage.uniform_filter(img_large, 7)', setup=setup_scipy, number=1000), "ms")
print('Gaussian filter (Large, Futhark)', timeit.timeit('mod.gaussian_filter_f32(img_large)', setup=setup, number=1000), "ms")
print('Gaussian Filter (Large, SciPy)', timeit.timeit('scipy.ndimage.gaussian_filter(img_large, 3)', setup=setup_scipy, number=1000), "ms")
