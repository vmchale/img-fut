import imgfut

import imageio
from PIL import Image
import numpy as np

from matplotlib import pyplot as plt

mod = imgfut.imgfut()

img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))

edges_img0 = mod.sobel_f32(img0)
blur_img0 = mod.mean_filter_f32(img0)
print(img0)
print(blur_img0)

plt.gray()
plt.imshow(edges_img0)

#  imageio.imwrite('frog-edges.png', Image.fromarray(np.array(edges_img0), 'F'))
#  imageio.imwrite('frog-blur.png', Image.fromarray(np.array(blur_img0), 'F'))
