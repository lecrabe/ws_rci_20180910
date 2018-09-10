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

## Get the list of countries from getData: "getData"
(gadm_list  <- data.frame(getData('ISO3')))
?getData

## Get GADM data, check object propreties
aoi         <- getData('GADM',path=gadm_dir , country= countrycode, level=1)

summary(aoi)
extent(aoi)
proj4string(aoi)

## Display the SPDF
plot(aoi)

##  Export the SpatialPolygonDataFrame as a ESRI Shapefile
writeOGR(aoi,
         paste0(gadm_dir,"gadm_",countrycode,"_l1.shp"),
         paste0("gadm_",countrycode,"_l1"),
         "ESRI Shapefile",
         overwrite_layer = T)


## Make a copy, subset the columns to 3 and export as KML
aoi_kml      <- aoi
aoi_kml@data <- aoi_kml@data[,c("OBJECTID","ISO","NAME_1")]

writeOGR(aoi_kml,
         paste0(gadm_dir,"gadm_",countrycode,".kml"),
         paste0("gadm_",countrycode),
         "KML",
         overwrite_layer = T)

## Check the values for the attribute column NAME_1
levels(as.factor(aoi$NAME_1))

## Select one province and export as KML
sub_aoi <- aoi[aoi$NAME_1 == "Abidjan",]

## Display the sub-shapefile on top of the previous one, in RED
plot(sub_aoi,
     add=T,
     col="red")

## Subset the columns to 2 and export as Shapefile
sub_aoi@data <- sub_aoi@data[,c("OBJECTID","ISO")]

writeOGR(sub_aoi,paste0(gadm_dir,"work_aoi_sub.shp"),"work_aoi_sub","ESRI Shapefile",overwrite_layer = T)


####################################################################################################
################################### PART II: CREATE A TILING OVER AN AREA OF INTEREST
####################################################################################################

### What grid size do we need ? 
grid_size <- 10000          ## in meters
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
sqr_df_selected <- sqr_df[aoi,]

### Plot the results
plot(sqr_df_selected,add=T,col="blue")
plot(aoi,add=T)

### Give the output a decent name, with unique ID
names(sqr_df_selected) <- "tileID"
sqr_df_selected@data$tileID <- row(sqr_df_selected@data)[,1]

### Check how many tiles will be created
nrow(sqr_df_selected@data)

### Make a subset of 10 tiles
subset <- sqr_df_selected[sample(1:nrow(sqr_df_selected@data),10),]
plot(subset,col="red",add=T)

### Export ONE TILE as KML
base_sqr <- paste0("one_tile_",countrycode)
writeOGR(obj=sqr_df_selected[sample(1:nrow(sqr_df_selected@data),1),],
         dsn=paste(tile_dir,base_sqr,".kml",sep=""),
         layer=base_sqr,
         driver = "KML",
         overwrite_layer = T)


### Generate random points
pts_rand <- spsample(sqr_df_selected,100,type = "random")
plot(pts_rand)

### Generate stratified points in the grid (1 per cell)
pts_strt <- spsample(sqr_df_selected,100,type = "stratified")
plot(pts_strt)

### Reproject in UTM 36
pts_utm <- spTransform(pts_rand,CRS("+init=epsg:32636"))
aoi_utm <- spTransform(aoi,CRS("+init=epsg:32636"))


### Convert the points into a SpatialPointDataFrame
spdf <- SpatialPointsDataFrame(pts_utm@coords,
                               as.data.frame(1:length(pts_utm)),
                               proj4string = CRS("+init=epsg:32636")
)
names(spdf@data) <- "pt_id"

### Extract polygon values by points
spdf@data$admin_units <- over(spdf,aoi_utm)$NAME_1


### Extract the DBF from a SPDF
dbf <- spdf@data
head(dbf)

### Spatial join of attributes
agg <- aggregate(x=   spdf["pt_id"],
                 by=  aoi_utm,
                 FUN= length)

aoi_utm@data$nb_pts <- agg$pt_id

aoi_utm@data[,c("NAME_1","nb_pts")]

### Can you find what the below syntax is equivalent to ?
dbf$district <- aggregate(x=aoi_utm["NAME_1"],
                           by=spdf,
                           FUN=first)$NAME_1

### Select only the tiles that do not fall in the water
sqr_df_selected$first <- aggregate(x=aoi["NAME_1"],
                                   by=sqr_df_selected,
                                   FUN=first)$NAME_1

tiles <- sqr_df_selected[-grep("Lake",sqr_df_selected$first),]
plot(tiles)

### Export as KML
base_sqr <- paste0("tiling_system_",countrycode)
writeOGR(obj=tiles,
         dsn=paste(tile_dir,base_sqr,".kml",sep=""),
         layer=base_sqr,
         driver = "KML",
         overwrite_layer = T)
