
CFLAGS = -g
CC = gcc
LDFLAGS = -lncurses

all: registers regdump show_stats

registers:
	$(NF_ROOT)/bin/nf_register_gen.pl --project openflow

regdump : regdump.o ../../../lib/C/common/nf2util.o ../../../lib/C/common/nf2util_proxy_common.o ../../../lib/C/common/nf2util.h ../lib/C/reg_defines_openflow.h

show_stats: show_stats.o ../../../lib/C/common/nf2util.o ../../../lib/C/common/nf2util_proxy_common.o ../../../lib/C/common/util.o ../lib/C/reg_defines_openflow.h ../../../lib/C/common/nf2util.h

clean :
	rm -f regdump show_stats *.o

