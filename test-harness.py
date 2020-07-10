import imgfut

import imageio
import numpy as np
import scipy.ndimage

from matplotlib import pyplot as plt

mod = imgfut.imgfut()

img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))
img1 = np.array(imageio.imread('data/frog-squished.png', pilmode='F'))
img2 = np.array(imageio.imread('data/valve.png', pilmode='F'))

print ("processing...")
edges_img0 = mod.sobel_f32(img0)
edges_img2 = mod.sobel_f32(img2)
edges_img0_scipy = scipy.ndimage.sobel(img0)
blur_img0 = mod.mean_filter_f32(img0)
gauss_img0 = mod.gaussian_filter_f32(img0)
laplacian_img0 = mod.laplacian_filter_f32(img0)
gauss_img0_scipy = scipy.ndimage.gaussian_filter(img0, 3)
log_img0 = mod.laplacian_gaussian_filter_f32(img0)
fft_blur_img1 = mod.fft_mean_filter_f32(img1)
fft_blur_img1_scipy = scipy.ndimage.fourier_uniform(img1, 0)
print ("done processing...")

plt.gray()
plt.imshow(edges_img0.get())
plt.show()
# lol this is inverted/wrong?
plt.imshow(edges_img0_scipy)
plt.show()
