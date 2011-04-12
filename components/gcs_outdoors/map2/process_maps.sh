ls -1 *.tif | awk -F "." '{ print "-g", $1 ".txt", $1 ".tif", $1 ".g.tif" }' | xargs -L 1 geotifcp
