res_dir <- paste0(normalizePath("~/bfast_16_18/input/"),"/")
setwd(res_dir)
out_dir <- paste0(normalizePath("~/bfast_16_18/output/"),"/")

############### MAKE A LIST OF RESULTS
# list_thr <- list.files(res_dir,pattern = glob2rx(paste0("bfast_st_*threshold.tif")),recursive = T)
# list_res <- paste0(substr(list_thr,1,nchar(list_thr)-14),".tif")
# list_sub <- list_res[1:100]

system(sprintf("gdaltindex %s %s",
               paste0(out_dir,"index.shp"),
               paste0(res_dir,"*/*/*/*[0-9].tif")
               ))


####################  CREATE A VRT OUTPUT
system(sprintf("gdalbuildvrt %s %s",
               paste0(out_dir,"results_tmp.vrt"),
               paste0(res_dir,"*/*/*/*[0-9].tif")
))


## Compress final result
system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
               paste0(out_dir,"results_tmp.vrt"),
               paste0(out_dir,"results_tmp.tif")
))

####################  EXTRACT MAGNITUDE
system(sprintf("gdal_calc.py -A %s --A_band=1 -B %s --B_band=2 --co=COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               paste0(out_dir,"results_tmp.tif"),
               paste0(out_dir,"results_tmp.tif"),
               paste0(out_dir,"results_magnitude.tif"),
               paste0("(A>=2016)*(A<2018)*B")
)) 

####################  COMPUTE  STATS FOR MAGNITUDE
res   <- paste0(out_dir,"results_magnitude.tif")
stats <- paste0(out_dir,"stats_tmp.txt")

system(sprintf("gdalinfo -stats %s > %s",
               res,
               stats
))

s <- readLines(stats)
maxs_b2   <- as.numeric(unlist(strsplit(s[grepl("STATISTICS_MAXIMUM",s)],"="))[2])
mins_b2   <- as.numeric(unlist(strsplit(s[grepl("STATISTICS_MINIMUM",s)],"="))[2])
means_b2  <- as.numeric(unlist(strsplit(s[grepl("STATISTICS_MEAN",s)],"="))[2])
stdevs_b2 <- as.numeric(unlist(strsplit(s[grepl("STATISTICS_STDDEV",s)],"="))[2])

num_class <-9
eq.reclass <-   paste0('(A<=',(maxs_b2),")*", '(A>',(means_b2+(stdevs_b2*floor(num_class/2))),")*",num_class,"+" ,
                       paste( 
                         " ( A >",(means_b2+(stdevs_b2*1:(floor(num_class/2)-1))),") *",
                         " ( A <=",(means_b2+(stdevs_b2*2:floor(num_class/2))),") *",
                         (ceiling(num_class/2)+1):(num_class-1),"+",
                         collapse = ""), 
                       '(A<=',(means_b2+(stdevs_b2)),")*",
                       '(A>', (means_b2-(stdevs_b2)),")*1+",
                       '(A>=',(mins_b2),")*",
                       '(A<', (means_b2-(stdevs_b2*4)),")*",ceiling(num_class/2),"+",
                       paste( 
                         " ( A <",(means_b2-(stdevs_b2*1:(floor(num_class/2)-1))),") *",
                         " ( A >=",(means_b2-(stdevs_b2*2:floor(num_class/2))),") *",
                         2:(ceiling(num_class/2)-1),"+",
                         collapse = "")
)
eq.reclass2 <- as.character(substr(eq.reclass,1,nchar(eq.reclass)-2))

####################  COMPUTE THRESHOLDS LAYER
system(sprintf("gdal_calc.py -A %s --co=COMPRESS=LZW --type=Byte --overwrite --outfile=%s --calc=\"%s\"",
               res,
               paste0(out_dir,"tmp_results_magnitude.tif"),
               eq.reclass2
               
))     

####################  CREATE A PSEUDO COLOR TABLE
cols <- col2rgb(c("black","beige","yellow","orange","red","darkred","palegreen","green2","forestgreen",'darkgreen'))
pct <- data.frame(cbind(c(0:9),
                        cols[1,],
                        cols[2,],
                        cols[3,]
))

write.table(pct,paste0(out_dir,'color_table.txt'),row.names = F,col.names = F,quote = F)

################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(out_dir,'color_table.txt'),
               paste0(out_dir,"tmp_results_magnitude.tif"),
               paste0(out_dir,"tmp_results_magnitude_pct.tif")
))

## Compress final result
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(out_dir,"tmp_results_magnitude_pct.tif"),
               paste0(out_dir,"results_tmp_threshold.tif")
))

system(sprintf("rm -r -f %s",
               paste0(out_dir,"tmp*.tif"))
)

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
mask   <- paste0(out_dir,"results_tmp_threshold.tif")


#################### ALIGN
input  <- paste0(os_dir,"sst_ocs2016_raster_10m_version_janvier_2020.tif")
ouput  <- paste0(out_dir,"aligned_ocs.tif")

align(mask, input, output)

#################### ALIGNED
thresh  <- paste0(out_dir,"results_tmp_threshold.tif")
lc_map  <- paste0(out_dir,"aligned_ocs.tif")

#################### CREATE MAP AT THRESHOLD (0 no data, 1 forest, 2 non-forest, 3 loss, 4 gain)
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               thresh,
               lc_map,
               paste0(out_dir,"tmp_map_bfast.tif"),
               paste0(         # HORS LIMITES PAYS
                      "(B==0)*0+",
                      
                      
                      "((B>=20)*B+",               # NON FORET
                      
                      "((B>=11)*(B<=17))*(", 
                        "((A==4)+(A==5))*110+",    # DEFORESTATION
                        "((A==3))*100+",           # DEGRADATION
                        "((A<3)+(A>5))*B)",           # FORET
                      ")"
                      )
            ))

# ####################  CREATE A PSEUDO COLOR TABLE
# cols <- col2rgb(c("black",
#                   "darkgreen","grey","red","lightyellow",
#                   "lightblue"))
# 
# pct <- data.frame(cbind(c(0:5),
#                         cols[1,],
#                         cols[2,],
#                         cols[3,]
# ))
# 
# write.table(pct,paste0(out_dir,'color_table_map.txt'),row.names = F,col.names = F,quote = F)
# 
# ################################################################################
# ## Add pseudo color table to result
# system(sprintf("(echo %s) | oft-addpct.py %s %s",
#                paste0(out_dir,'color_table_map.txt'),
#                paste0(out_dir,"tmp_map_bfast.tif"),
#                paste0(out_dir,"tmp_map_bfast_pct.tif")
# ))

## Compress final result
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(out_dir,"tmp_map_bfast.tif"),
               paste0(out_dir,"results_civ_sst.tif")
))

system(sprintf("rm -r -f %s",
               paste0(out_dir,"tmp*.tif"))
)

