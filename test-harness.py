import imgfut

import imageio
import numpy as np

from matplotlib import pyplot as plt

mod = imgfut.imgfut()

img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))

print ("processing...")
edges_img0 = mod.sobel_f32(img0)
blur_img0 = mod.mean_filter_f32(img0)
print ("done processing...")

plt.gray()
plt.imshow(edges_img0)
plt.show()
