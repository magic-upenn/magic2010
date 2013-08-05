#!/bin/bash

echo "<?xml version=\"1.0\"?>" > /tmp/calim.xml
echo "<opencv_storage>" >> /tmp/calim.xml

cat /tmp/lst.txt >> /tmp/calim.xml

echo "<images>" >> /tmp/calim.xml
echo "</images>" >> /tmp/calim.xml
echo "</opencv_storage>" >> /tmp/calim.xml


