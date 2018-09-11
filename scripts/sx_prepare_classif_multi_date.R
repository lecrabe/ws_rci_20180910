####################################################################################################
####################################################################################################
## Read, manipulate and write spatial vector data, Get GADM data
## Contact remi.dannunzio@fao.org 
## 2018/08/22
####################################################################################################
####################################################################################################


####################################################################################################
################################### PART I: GET GADM DATA
####################################################################################################

## Get GADM data, check object propreties
aoi         <- getData('GADM',path=gadm_dir , country= countrycode, level=1)

####################################################################################################
################################### PART II: CREATE A TILING OVER AN AREA OF INTEREST
####################################################################################################

### What grid size do we need ? 
grid_size <- 365000          ## in meters
grid_deg  <- grid_size/111320 ## in degree

### Create a set of regular SpatialPoints on the extent of the created polygons  
sqr <- SpatialPoints(makegrid(aoi,offset=c(0.5,0.5),cellsize = grid_deg))

### Convert points to a square grid
grid <- points2grid(sqr)

### Convert the grid to SpatialPolygonDataFrame
SpP_grd <- as.SpatialPolygons.GridTopology(grid)

sqr_df <- SpatialPolygonsDataFrame(Sr=SpP_grd,
                                   data=data.frame(rep(1,length(SpP_grd))),
                                   match.ID=F)

### Assign the right projection
proj4string(sqr_df) <- proj4string(aoi)
plot(sqr_df)

### Select a vector from location of another vector
sqr_df <- sqr_df[aoi,]

### Plot the results
plot(sqr_df,add=T,col="blue")
plot(aoi,add=T)


### Give the output a decent name, with unique ID
names(sqr_df) <- "tileID"

sqr_df@data$tileID <- row(sqr_df@data)[,1]

tile <- sqr_df[3,]

plot(tile,add=T,col="red")

base_sqr <- paste0("quart_SW_",countrycode)

writeOGR(obj=tile,
         dsn=paste(tile_dir,base_sqr,".kml",sep=""),
         layer=base_sqr,
         driver = "KML",
         overwrite_layer = T)

writeOGR(obj=tile,
         dsn=paste(tile_dir,base_sqr,".shp",sep=""),
         layer=base_sqr,
         driver = "ESRI Shapefile",
         overwrite_layer = T)


#################### CARTE 2003-2016 (0 no data, 1 forest, 2 non-forest, 3 loss, 4 gain)
carte_0316 <- paste0(gfc_dir,"carte_gfc_2003_2016_th",gfc_threshold,".tif")

system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               gfc_tc,
               gfc_ly,
               gfc_gn,
               carte_0316,
               "(C==1)*4+(C==0)*((B==0)*(A>0)*1+(B==0)*(A==0)*2+(B>0)*(B<=3)*2+(B>3)*3)"
))

#############################################################
### COUPER AUX LIMITES DU QUART SUD OUEST
carte_0316_sw <- paste0(gfc_dir,"carte_gfc_2003_2016_sw_th",gfc_threshold,".tif")

system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste(tile_dir,base_sqr,".shp",sep=""),
               carte_0316,
               carte_0316_sw,
               "tileID"
))

#### UTILISER L'APPLICATION SAED

the_map    <- carte_0316_sw
sae_dir    <- paste0(dirname(the_map),"/","sae_design_",substr(basename(the_map),1,nchar(basename(the_map))-4),"/")
point_file <- list.files(sae_dir,glob2rx("pts_*.csv"))
pts <- read.csv(paste0(sae_dir,point_file))

loss <- pts[pts$map_class ==3,]
write.csv(loss,paste0(sae_dir,"check_pertes.csv"),row.names = F)
