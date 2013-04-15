import reg_defines_openflow, sys

y = [x for x in dir(reg_defines_openflow) if 'OF_' in x]

z, w = [], []
for x in y:
    if '_POS' in x:
        z.append(x)
    else:
        w.append(x)
y = z + w

f = open(sys.argv[1])
for line in f:
    newline = ''
    for i in y:
        if newline:
            if i in newline:
                newline = newline.replace(i, str(getattr(reg_defines_openflow, i)()))
        else:
            if i in line:
                newline = line.replace(i, str(getattr(reg_defines_openflow, i)()))
            else:
                newline = line

    sys.stdout.write(newline.replace('`', ''))
