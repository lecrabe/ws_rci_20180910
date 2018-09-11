#############################################################
### Zonal stats per tile of the loss product
system(sprintf("python %s/oft-zonal_large_list.py -um %s -i %s -o %s -a %s",
               scriptdir,
               paste0(tile_dir,"tiling_system_",countrycode,".shp"),
               gfc_ly,
               paste0(tile_dir,"gfc_tile.txt"),
               "tileID"
))

