import sys

myFile = open(sys.argv[1],'r')
writeFile = open(sys.argv[2],'w+')

myData = myFile.read()
myData = myData.replace('\r','')
sigsList = myData.split('\n')
sigsList.pop(0)

for instru in sigsList:
    instru = instru.split(',')
    instru = instru[2:]
    myStr = ''.join(instru)

    writeFile.write(myStr + '\n')

writeFile.close()
myFile.close()