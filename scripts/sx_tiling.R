##########################################################################################
################## Read, manipulate and write raster data
##########################################################################################

########################################################################################## 
# Contact: remi.dannunzio@fao.org
# Last update: 2018-08-24
##########################################################################################


#############################################################
### CREATE A FOREST MASK FOR MSPA ANALYSIS
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"sst_2016.tif"),
               paste0(lc_dir,"bnetd_2015.tif"),
               paste0(lc_dir,"sst_2016_mspa.tif"),
               paste0("(B==5)*0+(B<5)*((A==0)*1+(A>0)*2)")
))

### Aire d'interet : limites du pays
carte <- paste0(lc_dir,"sst_2016.tif")

system(sprintf("gdaltindex %s %s",
               paste0(lc_dir,"index.shp"),
               carte
               ))

aoi <- readOGR(paste0(lc_dir,"index.shp"))
proj4string(aoi)
bb <- extent(aoi)
### Taille de la grille en METRES
grid_size <- 10000          

### Creer la grille
SpP_grd <- as.SpatialPolygons.GridTopology(
  points2grid(
    SpatialPoints(
      makegrid(
        aoi,
        offset=c(0.5,0.5),
        cellsize = grid_size
      )
    )
  )
)

sqr_df <- SpatialPolygonsDataFrame(Sr=SpP_grd,
                                   data=data.frame(rep(1,length(SpP_grd))),
                                   match.ID=F)

### Assign the right projection
proj4string(sqr_df) <- proj4string(aoi)
plot(sqr_df)

names(sqr_df) <- "id"
writeOGR(sqr_df,
         paste0(lc_dir,"grille_10km.shp"),
         paste0(lc_dir,"grille_10km"),
         ("ESRI Shapefile"),
         overwrite_layer = T
)

dbf <- read.dbf(paste0(lc_dir,"foret.dbf"))
table(dbf$FORET_CL_I,dbf$NATURE)

system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(lc_dir,"foret.shp"),
               paste0(lc_dir,"sst_2016.tif"),
               paste0(lc_dir,"foret.tif"),
               "FORET_CL_I"
))


system(sprintf("python %s/oft-zonal_large_list.py -i %s -um %s -o %s -a %s",
               scriptdir,
               paste0(lc_dir,"foret.tif"),
               paste0(lc_dir,"grille_10km.shp"),
               paste0(lc_dir,"zonal_foret.txt"),
               "id"
))
### Select a vector from location of another vector
sqr_df_selected <- sqr_df[aoi,]

### Plot the results
plot(sqr_df_selected,add=T,col="blue")
plot(aoi,add=T)
time_products_global <- Sys.time() - time_start


