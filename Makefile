.PHONY: clean

imgfut.py: img-py.fut img.fut
	futhark pyopencl $< --library -o imgfut

clean:
	@rm -rf img img.c imgfut.py Pipfile.lock *.c *.c.h
