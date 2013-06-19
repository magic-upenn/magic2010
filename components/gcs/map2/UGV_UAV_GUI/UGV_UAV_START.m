clear all;
UGV_UAV_COOP('initialize')

while(1)
    mapupdate(handles)
    UGV_UAV_COOP('update')
end