#################### ALIGN PRODUCTS WITH SEGMENTS
mask   <- the_segments                     ##### CHANGER LA VALEUR
input  <- gfc_tc                           ##### CHANGER LA VALEUR
ouput  <- paste0(dd_dir,"tmp_tc_tile.tif") ##### CHANGER LA VALEUR


#################### CARACTERISTIQUES DU MASQUE
proj   <- proj4string(raster(mask))
extent <- extent(raster(mask))
res    <- res(raster(mask))[1]


#################### ALIGN GFC TREE COVER WITH SEGMENTS
system(sprintf("gdalwarp -co COMPRESS=LZW -t_srs \"%s\" -te %s %s %s %s -tr %s %s %s %s -overwrite",
               proj4string(raster(mask)),
               extent(raster(mask))@xmin,
               extent(raster(mask))@ymin,
               extent(raster(mask))@xmax,
               extent(raster(mask))@ymax,
               res(raster(mask))[1],
               res(raster(mask))[2],
               input,
               ouput
))