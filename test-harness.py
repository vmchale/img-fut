import imgfut

import imageio
from PIL import Image
import numpy as np

mod = imgfut.imgfut()

img0 = np.array(imageio.imread('data/frog.png', pilmode='F'))

edges_img0 = mod.sobel_f32(img0)

imageio.imwrite('frog-edges.png', Image.fromarray(np.array(edges_img0), 'F'))
