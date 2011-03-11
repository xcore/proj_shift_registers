SOURCE = main.xc
FLAGS = -Wall -g -O2 -I.. -I../shared -report -target=XK-1

ifeq "$(OS)" "Windows_NT"
DELETE = del
else
DELETE = rm -f
endif

basic.xe: ${SOURCE}
	xcc ${FLAGS} ${SOURCE} -o basic.xe

clean:
	$(DELETE) *.o *.a *.xi *.s *.xe *.xb
