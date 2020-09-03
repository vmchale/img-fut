# img-fut

An image library in [Futhark](https://futhark-lang.org/) providing
multidimensional image processing à la
[scipy](https://docs.scipy.org/doc/scipy/reference/ndimage.html).

Documentation is [here](https://vmchale.github.io/img-fut/).

## Performance

When using the GPU, `img-fut` outperforms
[SciPy](https://scipy.org/) on large images and performs similarly for small
images.

### Benchmarks

| Image Size | Filter | Backend | Time |
| ---------- | ------ | ------- | ---- |
| 400x300 | Mean Filter | img-fut | 0.6683 ms |
| 400x300 | Mean Filter | SciPy | 0.5669 ms |
| 400x300 | Sobel | img-fut | 0.7041 ms |
| 400x300 | Sobel | SciPy | 0.6732 ms |
| 400x300 | Gaussian | img-fut | 1.805 ms |
| 400x300 | Gaussian | SciPy | 2.899 ms |
| 1920x1236 | Mean Filter | img-fut | 8.480 ms |
| 1920x1236 | Mean Filter | SciPy | 19.41 ms |
| 1920x1236 | Sobel | img-fut | 7.104 ms |
| 1920x1236 | Sobel | SciPy | 21.30 ms |
| 1920x1236 | Gaussian | img-fut | 28.82 ms |
| 1920x1236 | Gaussian | SciPy | 61.22 ms |
