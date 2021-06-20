import imgfut

import imageio
import numpy as np
import scipy.ndimage

from scipy2d import sobel2d

from matplotlib import pyplot as plt

mod = imgfut.imgfut()

img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))
img1 = np.array(imageio.imread('data/frog-squished.png', pilmode='F'))
img2 = np.array(imageio.imread('data/valve.png', pilmode='F'))

print ("processing...")
edges_img0 = mod.sobel_f32(img0)
blur_img0 = mod.mean_filter_f32(img0)
gauss_img0 = mod.gaussian_filter_f32(img0)
# don't seem to be the same... (inverted)
laplacian_img0 = mod.laplacian_filter_f32(img0)
laplacian_img0_scipy = scipy.ndimage.laplace(img0)
# don't seem to be the same... (inverted)
log_img0 = mod.laplacian_gaussian_filter_f32(img0)
log_img0_scipy = scipy.ndimage.gaussian_laplace(img0, 1.5)
# FFT stuff not working!
fft_blur_img1 = mod.fft_mean_filter_f32(img1)
fft_blur_img1_scipy = scipy.ndimage.fourier_uniform(img1, 0)
print ("done processing...")

plt.gray()
plt.imshow(laplacian_img0.get())
plt.show()
plt.imshow(laplacian_img0_scipy)
plt.show()
