import struct
from socket import ntohl, ntohs, inet_aton, inet_ntoa, htons
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

OF_ACTION_STRUCT = OF_STRUCT[:-1] + (("OF_ACTION_CTRL", "I"),) + (("OF_PADDING", "BBB"),)

OF_ACTION_CTRL = {x[0]: 1 << i for i, x in enumerate(OF_STRUCT)}

class OFHeader(object):
    def __init__(self, buildstruct=None):

        self._struct = struct.Struct("!" + "".join(x[1] for x in OF_STRUCT))

        if (buildstruct is not None):
            self.to_raw(buildstruct)

    def makestruct(self):
        #attrs = [i[0] for i in OF_STRUCT]
        self.raw = []
        for i in xrange(len(OF_STRUCT)):
            if i < 1:
                self.raw.append(getattr(self, OF_STRUCT[i][0], 0))
            elif 0 < i < 3:
                for j, x in enumerate(getattr(self, OF_STRUCT[i][0], [0 for i in xrange(6)])):
                    #self.raw[j+6*(i-1)] = x
                    self.raw.append(x)
            else:
                #self.raw[i+10] = getattr(self, attrs[i], 0)
                if (OF_STRUCT[i][1] == "H"):
                    self.raw.append(htons(getattr(self, OF_STRUCT[i][0], 0)))
                elif (OF_STRUCT[i][1] == "I"):
                    # Wow, this is ugly.  Looking for a better way to do what I want which
                    # is get a plain int from the formatted address
                    self.raw.append(int(struct.unpack("I",
                        inet_aton(getattr(self, OF_STRUCT[i][0], "0.0.0.0")))[0]))
                else:
                    self.raw.append(getattr(self, OF_STRUCT[i][0], 0))

        # Append the padding
        for i in xrange(len(OF_STRUCT[-1][1])-1):
            self.raw.append(0)

        self.packed = self._struct.pack(*self.raw)

    def to_raw(self, initstruct):
        self.raw = [x for x in self._struct.unpack(initstruct)]
        self.format()

    def build(self, *args, **kwargs):
        ''' Expects kwargs that coorespond to OF_STRUCT with values to pack
            Values should all be ints with the exception of DL_SRC and DL_DST
            which should be tuples of ints, and NW_SRC, NW_DST which are ipv4
            formatted addresses
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

    def serialize(self):
        ''' Takes the packed struct and serializes it into 32 bit chunks for use
            with registers '''
        return struct.unpack("I" * 9, self.packed)

    def serialize_str(self):
        return ["{:08x}".format(x) for x in self.serialize()]

def read_last_header():
    y = []
    for i in xrange(9):
        y.append(long(readReg(rd.HDR_LAST_HEADERS_SEEN_0_REG() + 4*i)))
        print i, hex(y[len(y)-1])

    s = struct.Struct(9 * 'L')
    mydata = s.pack(*y)
    of = OFHeader(mydata)
    return of

