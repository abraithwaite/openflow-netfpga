import struct
from hwReg import readReg
import reg_defines_add_registers_nic as rd
from of_header import OFHeader
from socket import ntohl, ntohs, inet_aton, inet_ntoa

y = []
for i in xrange(9):
    y.append(long(readReg(rd.HDR_LAST_HEADERS_SEEN_0_REG() + 4*i)))
    print i, hex(y[len(y)-1])

s = struct.Struct(9 * 'L')
print s.size
mydata = s.pack(*y)
print [hex(x) for x in s.unpack(mydata)]

of = OFHeader(mydata)

print ""

for x in of.fields:
    print x[0], getattr(of, x[0])
