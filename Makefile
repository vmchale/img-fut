.PHONY: clean

imgfut.py: img.fut
	futhark pyopencl $< --library -o imgfut

clean:
	@rm -rf img img.c imgfut.py
