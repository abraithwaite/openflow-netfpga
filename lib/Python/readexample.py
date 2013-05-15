import struct
from hwReg import readReg
import reg_defines_openflow as rd
from of_header import OFHeader, OF_STRUCT
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

for x in OF_STRUCT:
    print x[0], of.pretty.get(x[0], 0)
