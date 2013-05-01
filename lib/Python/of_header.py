import struct
from socket import ntohl, ntohs, inet_aton, inet_ntoa
import reg_defines_openflow as rd
from hwReg import readReg

OF_STRUCT = (("OF_IN_PORT","H"),
             ("OF_DL_SRC","B" * 6),
             ("OF_DL_DST","B" * 6),
             ("OF_VLAN_ID", "H"),
             ("OF_VLAN_PCP", "B"),
             ("OF_DL_TYPE", "H"),
             ("OF_NW_TOS", "B"),
             ("OF_NW_PROTO", "B"),
             ("OF_NW_SRC", "I"),
             ("OF_NW_DST", "I"),
             ("OF_TP_SRC", "H"),
             ("OF_TP_DST", "H"),
             ("OF_PADDING", "BBB"),
            )

class OFHeader(object):
    def __init__(self, buildstruct=None):

        self._struct = struct.Struct("!" + "".join(x[1] for x in OF_STRUCT))

        if buildstruct is not None:
            self.raw = [x for x in self._struct.unpack(buildstruct)]
            self.format()

    def makestruct(self):
        attrs = [i[0] for i in OF_STRUCT]
        for i in xrange(len(OF_STRUCT)):
            if i < 1:
                self.raw[i] = getattr(self, attrs[i], 0)
            elif 0 < i < 3:
                for j, x in enumerate(getattr(self, attrs[i], [0 for i in xrange(6)])):
                    self.raw[j+6*(i-1)] = x
            else:
                self.raw[i+10] = getattr(self, attrs[i], 0)



    def build(self, *args, **kwargs):
        ''' Expects kwargs that coorespond to OF_STRUCT with values to pack
            Values should all be ints with the exception of DL_SRC and DL_DST
            which should be tuples of ints
        '''
        for k,v in OF_STRUCT:
            if k in kwargs:
                setattr(self, k, kwargs.get(k))
        self.makestruct()
        self.format()

    def format(self):
        self.pretty = {}
        self.pretty['OF_IN_PORT'] = ntohs(self.raw[0])
        self.pretty['OF_DL_SRC'] = tuple(hex(i) for i in self.raw[1:7])[::-1]
        self.pretty['OF_DL_DST'] = tuple(hex(i) for i in self.raw[7:13])[::-1]
        self.pretty['OF_VLAN_ID'] = hex(ntohs(self.raw[13]))
        self.pretty['OF_VLAN_PCP'] = hex(self.raw[14])
        self.pretty['OF_DL_TYPE'] = hex(ntohs(self.raw[15]))
        self.pretty['OF_NW_TOS'] = hex(self.raw[16])
        self.pretty['OF_NW_PROTO'] = hex(self.raw[17])
        self.pretty['OF_NW_SRC'] = inet_ntoa(struct.pack("I", self.raw[18]))
        self.pretty['OF_NW_DST'] = inet_ntoa(struct.pack("I", self.raw[19]))
        self.pretty['OF_TP_SRC'] = ntohs(self.raw[20])
        self.pretty['OF_TP_DST'] = ntohs(self.raw[21])
        self.pretty['OF_PADDING'] = ""


def read_last_header():
    y = []
    for i in xrange(9):
        y.append(long(readReg(rd.HDR_LAST_HEADERS_SEEN_0_REG() + 4*i)))
        print i, hex(y[len(y)-1])

    s = struct.Struct(9 * 'L')
    mydata = s.pack(*y)
    of = OFHeader(mydata)
    return of

