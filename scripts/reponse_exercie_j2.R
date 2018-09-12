### 1/ Creer une AOI pour Bas-Sassandra
aoi         <- getData('GADM',path=gadm_dir , country= countrycode, level=1)
sub_aoi <- aoi[aoi$NAME_1 == "Bas-Sassandra",]

plot(aoi)
plot(sub_aoi,add=T,col="red")

writeOGR(sub_aoi,
         paste0(gadm_dir,"bas_sassandra.shp"),
         "bas_sassandra",
         "ESRI Shapefile",
         overwrite_layer = T)

### 2/ Decouper la carte ESA aux frontieres de l' AOI
system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(gadm_dir,"bas_sassandra.shp"),
               paste0(esa_dir,"esa_crop.tif"),
               paste0(esa_dir,"esa_bas_sassandra.tif"),
               "OBJECTID"
))

### 3/ Integrer la carte ESA dans un arbre de decision pour chaque polygone
my_classes <- c(0,1,2,3,4)
my_colors  <- col2rgb(c("black","purple","darkgreen","blue","grey"))
pct <- data.frame(cbind(my_classes,
                        my_colors[1,],
                        my_colors[2,],
                        my_colors[3,]))

write.table(pct,paste0(dd_dir,"color_table_exo.txt"),row.names = F,col.names = F,quote = F)

list_tiles <- list.files(seg_dir,pattern=glob2rx("seg*.tif"))
list_masks  <- list.files(seg_dir,pattern=glob2rx("mask*.tif"))

i <- 2
  
  the_tile     <- list_tiles[i]
  
  the_segments <- paste0(seg_dir,the_tile)
  
  #################### ALIGN PRODUCTS WITH SEGMENTS
  mask   <- the_segments
  proj   <- proj4string(raster(mask))
  extent <- extent(raster(mask))
  res    <- res(raster(mask))[1]
  
  
  #################### ALIGN GFC TREE COVER WITH SEGMENTS
  input  <- paste0(esa_dir,"esa_bas_sassandra.tif")
  ouput  <- paste0(dd_dir,"tmp_esa_tile.tif")
  
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
  
  
  
  #################### ZONAL FOR THE DATA MASK
  system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
                 paste0(seg_dir,list_masks[i]),
                 paste0(dd_dir,"stat_mask_tile.txt"),
                 the_segments,
                 1
  ))
  
  #################### ZONAL FOR ESA 
  system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
                 paste0(dd_dir,"tmp_esa_tile.tif"),
                 paste0(dd_dir,"stat_esa_tile.txt"),
                 the_segments,
                 200
  ))
  
  
  #################### READ THE ZONAL STATS
  df_esa     <- read.table(paste0(dd_dir,"stat_esa_tile.txt"))
  df_mask    <- read.table(paste0(dd_dir,"stat_mask_tile.txt"))
  
  names(df_esa)  <- c("clump_id","total_esa",paste0("esa_",0:200))
  names(df_mask) <- c("clump_id","total_mask",paste0("msk_",0:1))
  
  df_esa <- df_esa[,colSums(df_esa) != 0]
  
  ####### INITIATE THE OUT DATAFRAME
  df <- df_esa[,c("clump_id","total_esa")]
  
  ####### SETUP THE OUTPUT
  df$class  <- 0 
  
  ####### URBAIN == 1
  tryCatch({
    df[df_esa[,"esa_8"] >  10/100*df$total_esa , ]$class <- 1
  },error=function(e){cat("Not relevant\n")})
  
  ####### FOREST == 2
  tryCatch({
    df[df_esa[,"esa_8"] <=  10/100*df$total_esa & df_esa[,"esa_1"] >  30/100*df$total_esa, ]$class <- 2
    },error=function(e){cat("Not relevant\n")})
  
  ####### EAU == 3
  tryCatch({
    df[df_esa[,"esa_8"] <=  10/100*df$total_esa & df_esa[,"esa_1"] <=  30/100*df$total_esa & df_esa[,"esa_10"] >  10/100*df$total_esa, ]$class <- 3
  },error=function(e){cat("Not relevant\n")})
  
  ####### AUTRE == 3
  tryCatch({
    df[df_esa[,"esa_8"] <=  10/100*df$total_esa & df_esa[,"esa_1"] <=  30/100*df$total_esa & df_esa[,"esa_10"] <=  10/100*df$total_esa & df_esa[,"esa_0"]+df_esa[,"esa_200"] <=  5 /100*df$total_esa, ]$class <- 4
    },error=function(e){cat("Not relevant\n")})
  
  ####### NO DATA == 0
  tryCatch({
    df[df_mask$msk_0 > 0  , ]$class <- 0
  },error=function(e){cat("Not relevant\n")})
  
  table(df$class)
  
  write.table(df[,c("clump_id","total_esa","class")],
              paste0(dd_dir,"stat_reclass_esa.txt"),row.names = F,col.names = F)
  
  
  ################################################################################
  #################### Reclassify 
  system(sprintf("(echo %s; echo 1; echo 1; echo 3; echo 0) | oft-reclass  -oi %s  -um %s %s",
                 paste0(dd_dir,"stat_reclass_esa.txt"),
                 paste0(dd_dir,"tmp_reclass.tif"),
                 the_segments,
                 the_segments
  ))
  
  ################################################################################
  #################### CONVERT TO BYTE
  system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
                 paste0(dd_dir,"tmp_reclass.tif"),
                 paste0(dd_dir,"tmp_reclass_byte.tif")
  ))
  
  ################################################################################
  #################### Add pseudo color table to result
  system(sprintf("(echo %s) | oft-addpct.py %s %s",
                 paste0(dd_dir,"color_table_exo.txt"),
                 paste0(dd_dir,"tmp_reclass_byte.tif"),
                 paste0(dd_dir,"tmp_pct_decision_tree.tif")
  ))
  
  ################################################################################
  #################### COMPRESS
  system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
                 paste0(dd_dir,"tmp_pct_decision_tree.tif"),
                 paste0(dd_dir,"tile_",i,"_decision_tree.tif")
  ))
  
  system(sprintf("rm %s",
                 paste0(dd_dir,"tmp*.tif")))
  
  system(sprintf("rm %s",
                 paste0(dd_dir,"stat*.txt")))
  
#############################################################
### MERGE AS VRT
system(sprintf("gdalbuildvrt %s %s",
               paste0(dd_dir,"dd_map_esa.vrt"),
               paste0(dd_dir,"tile_*_decision_tree.tif")
))

################################################################################
#################### Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(dd_dir,"color_table_exo.txt"),
               paste0(dd_dir,"dd_map_esa.vrt"),
               paste0(dd_dir,"tmp_merge_pct.tif")
))

################################################################################
#################### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(dd_dir,"tmp_merge_pct.tif"),
               paste0(dd_dir,"dd_map_esa.tif")
))


#############################################################
### CLEAN
system(sprintf("rm %s",
               paste0(dd_dir,"tmp*.tif")
))

system(sprintf("rm %s",
               paste0(dd_dir,"tile_*.tif")
))
