#################### FONCITON ALIGNEMENT
align <- function(mask, input, output){
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
  ))}

#################### CANEVAS
mask   <- paste0(res_dir,"results_tmp_threshold.tif")


#################### ALIGN
input  <- paste0(os_dir,"rci_fnf_1990_2000_2015.tif")
ouput  <- paste0(res_dir,"aligned_ocs.tif")

align(mask, input, output)

#################### ALIGN
thresh  <- paste0(res_dir,"results_tmp_threshold.tif")
lc_map  <- paste0(res_dir,"aligned_ocs.tif")

#################### CREATE MAP 2000-2014 AT THRESHOLD (0 no data, 1 forest, 2 non-forest, 3 loss, 4 gain)
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               thresh,
               lc_map,
               paste0(res_dir,"tmp_map_bfast.tif"),
               paste0(         # HORS LIMITES PAYS
                      "(B==0)*0+(",
                      
                      
                      "((B==111)+(B==121)+(B==221)+(B==211))*(",            
                         "((A==8)+(A==9))*5 +",      # GAINS 
                          "(A<8)*2)+",               # NON FORET
                      
                      "((B==112)+(B==122)+(B==222)+(B==212))*(", 
                        "((A==4)+(A==5))*3+",    # DEFORESTATION
                        "((A==3))*4+",           # DEGRADATION
                        "((A<3)+(A>5))*1)",           # FORET
                      ")"
                      )
            ))

####################  CREATE A PSEUDO COLOR TABLE
cols <- col2rgb(c("black",
                  "darkgreen","grey","red","lightyellow",
                  "lightblue"))

pct <- data.frame(cbind(c(0:5),
                        cols[1,],
                        cols[2,],
                        cols[3,]
))

write.table(pct,paste0(res_dir,'color_table_map.txt'),row.names = F,col.names = F,quote = F)

################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(res_dir,'color_table_map.txt'),
               paste0(res_dir,"tmp_map_bfast.tif"),
               paste0(res_dir,"tmp_map_bfast_pct.tif")
))

## Compress final result
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(res_dir,"tmp_map_bfast_pct.tif"),
               paste0(res_dir,"results_civ_nerf.tif")
))

system(sprintf("rm -r -f %s",
               paste0(res_dir,"tmp*.tif"))
)
