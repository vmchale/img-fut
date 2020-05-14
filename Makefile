.PHONY: clean

imgfut.py: img-py.fut lib/github.com/vmchale/img-fut/img.fut futhark.pkg
	futhark pyopencl $< --library -o imgfut

clean:
	@rm -rf img img.c imgfut.py Pipfile.lock *.c *.c.h lib/github.com/diku-dk
