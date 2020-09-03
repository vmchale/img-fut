# img-fut

An image library in [Futhark](https://futhark-lang.org/) providing
multidimensional image processing à la
[scipy](https://docs.scipy.org/doc/scipy/reference/ndimage.html).

Documentation is [here](https://vmchale.github.io/img-fut/).

## Performance

When using the GPU, `img-fut` slightly outperforms
[SciPy](https://scipy.org/).

### Benchmarks

| Image Size | Filter | Backend | Time |
| ---------- | ------ | ------- | ---- |
| 400x300 | Mean Filter | img-fut | 0.6683 ms |
| 400x300 | Mean Filter | SciPy | 0.5669 ms |
| 1920x1236 | Mean Filter | img-fut | 8.480 ms |
| 1920x1235 | Mean Filter | SciPy | 19.41 ms |
