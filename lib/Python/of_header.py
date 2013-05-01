import struct
from socket import ntohl, ntohs, inet_aton, inet_ntoa

class OFHeader(object):
    def __init__(self, buildstruct=None):
        self.fields = (("OF_IN_PORT","H"),
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
        self.packed = struct.Struct("!" + "".join(x[1] for x in self.fields))
        if buildstruct is not None:
            self.unpacked = [x for x in self.packed.unpack(buildstruct)]
            self.OF_IN_PORT = ntohs(self.unpacked[0])
            self.OF_DL_SRC = tuple(hex(i) for i in self.unpacked[1:7])[::-1]
            self.OF_DL_DST = tuple(hex(i) for i in self.unpacked[7:13])[::-1]
            self.OF_VLAN_ID = hex(ntohs(self.unpacked[13]))
            self.OF_VLAN_PCP = hex(self.unpacked[14])
            self.OF_DL_TYPE = hex(ntohs(self.unpacked[15]))
            self.OF_NW_TOS = hex(self.unpacked[16])
            self.OF_NW_PROTO = hex(self.unpacked[17])
            self.OF_NW_SRC = inet_ntoa(struct.pack("I", self.unpacked[18]))
            self.OF_NW_DST = inet_ntoa(struct.pack("I", self.unpacked[19]))
            self.OF_TP_SRC = ntohs(self.unpacked[20])
            self.OF_TP_DST = ntohs(self.unpacked[21])
            self.OF_PADDING = ""


