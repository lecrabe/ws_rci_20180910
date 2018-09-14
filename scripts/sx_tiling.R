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


### Empreinte et Taille de la grille en METRES
aoi       <- readOGR(paste0(lc_dir,"index.shp"))
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
                                   data=data.frame(1:length(SpP_grd)),
                                   match.ID=F)

### Assign the right projection
proj4string(sqr_df) <- proj4string(aoi)
plot(sqr_df)

names(sqr_df) <- "id"
head(sqr_df)

writeOGR(sqr_df,
         paste0(lc_dir,"grille_10km.shp"),
         paste0(lc_dir,"grille_10km"),
         ("ESRI Shapefile"),
         overwrite_layer = T
)


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

system(sprintf("python %s/oft-zonal_large_list.py -i %s -um %s -o %s -a %s",
               scriptdir,
               paste0(lc_dir,"sst_2016_mspa_output.tif"),
               paste0(lc_dir,"grille_10km.shp"),
               paste0(lc_dir,"zonal_mspa.txt"),
               "id"
))


df_fcpn <- read.table(paste0(lc_dir,"zonal_foret.txt"))
df_mspa <- read.table(paste0(lc_dir,"zonal_mspa.txt"))

names(df_fcpn) <- c("id","total_fcpn",paste0("fcpn_",0:(ncol(df_fcpn)-3)))
names(df_mspa) <- c("id","total_mspa",paste0("mspa_",0:(ncol(df_mspa)-3)))

df_fcpn <- df_fcpn[,colSums(df_fcpn) != 0]
df_mspa <- df_mspa[,colSums(df_mspa) != 0]

head(df_fcpn)
head(df_mspa)

df_mspa$core <- rowSums(df_mspa[,names(df_mspa) %in% paste0("mspa_",c(17,117))])
df_mspa$islt <- rowSums(df_mspa[,names(df_mspa) %in% paste0("mspa_",c(9,109))])
df_mspa$perf <- df_mspa[,paste0("mspa_",c(105))]
df_mspa$edge <- rowSums(df_mspa[,names(df_mspa) %in% paste0("mspa_",c(3,103))])
df_mspa$loop <- rowSums(df_mspa[,names(df_mspa) %in% paste0("mspa_",c(65,67,69,165,167,169))])
df_mspa$brdg <- rowSums(df_mspa[,names(df_mspa) %in% paste0("mspa_",c(33,35,37,133,135,137))])
df_mspa$brch <- rowSums(df_mspa[,names(df_mspa) %in% paste0("mspa_",c(1,101))])
df_mspa$intr <- df_mspa[,paste0("mspa_",c(100))]
df_mspa$limt <- df_mspa[,paste0("mspa_",c(220))]
df_mspa$outs <- df_mspa[,paste0("mspa_",c(129))]

sqr_df <- readOGR(paste0(lc_dir,"grille_10km.shp"))
dbf <- data.frame(cbind(sqr_df@data,
             df_mspa[,c("total_mspa","core","islt","perf","edge","loop","brdg","brch","intr","limt","outs")],
             df_fcpn[,c("fcpn_1","fcpn_4")]))

sqr_df@data <- dbf
names(sqr_df)

### Select a vector from location of another vector
sqr_df_selected <- sqr_df[sqr_df$perf > 10000 & sqr_df$loop >0 & sqr_df$fcpn_1 >0 ,]
nrow(sqr_df_selected)

### Plot the results
plot(sqr_df)
plot(sqr_df_selected,add=T,col="red")
names(sqr_df_selected)

proj4string(sqr_df_selected)
out <- spTransform(sqr_df_selected,CRS('+init=epsg:4326'))
writeOGR(out[,"id"],
         paste0(lc_dir,"selection_20180914.kml"),
         paste0(lc_dir,"selection_20180914"),
         ("KML"),
         overwrite_layer = T
)
