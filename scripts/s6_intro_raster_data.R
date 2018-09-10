##########################################################################################
################## Read, manipulate and write raster data
##########################################################################################

#############################################################a############################# 
# Contact: remi.dannunzio@fao.org
# Last update: 2018-08-22
##########################################################################################


### Read a raster: "raster"
r <- raster(paste0(esa_dir,"esa_crop.tif"))
proj4string(r)
extent(r)
res(r)*111320

### Crop to a given spatial extent: "extent" and "crop"
e  <- extent(32,33,0,1)
rc <- crop(r,e)
plot(rc)

### Use the options col and breaks to specify color palette
codes <- 0.5+c(-1:8,10)
classes <- c("trees","shrubs","grass","crops","flooded","sparse","bare","builtup","water")
cols <- c("black","darkgreen","brown","lightgreen","yellow","turquoise","lightyellow","grey","violet","blue","black")
plot(r,col=cols,breaks=codes)

### Draw random points on the raster: "sampleRandom"
###"xy=TRUE" 
tmp <- sampleRandom(rc,1000,xy=TRUE)

###Convert to a data frame
my_sample <- data.frame(tmp)

### Change column names
names(my_sample) <- c("x_coord","y_coord","value")
str(my_sample)

### Extract Latitude and Longitude as single vectors
x <- my_sample$x_coord
y <- my_sample$y_coord

### Diplay the points
plot(x,y)

### Delete the graphs
dev.off()

### Create an empty frame
plot(my_sample$x_coord,my_sample$y_coord,
     type="n",xlab="longitude",ylab="latitude")

### Add a raster to a graph : "rasterImage"
rasterImage(as.raster(rc),xmin(rc),ymin(rc),xmax(rc),ymax(rc))


### Add points to a graph: "points"
points(my_sample$x_coord,my_sample$y_coord)

### Identify each point uniquely: "row" and [,1]
my_sample$id <- row(my_sample)[,1]

head(my_sample)

### Create the logic list of points belonging to class "1" (trees)
table(my_sample$value)
list_logic <- my_sample$value == 1
head(list_logic)

### Points with trees
trees <- my_sample[list_logic,]
points(trees$x_coord,trees$y_coord,col="green")

### Resample a raster: "aggregate"
ra <- aggregate(rc,fact=2,fun=max)
res(ra)*111320

### Reclassify a raster: "cbind" and "aggregate"
rcl <- cbind(c(0:10,200),
             c(0,1,rep(2,8),3,0))
rcl
f_nf <- reclassify(rc,rcl)

### Plot with colors
plot(f_nf,
     col=c("black","darkgreen","grey","blue"),
     breaks=0.5+-1:3)

### Export a raster: "writeRaster"
writeRaster(f_nf,
            paste0(esa_dir,"fnf_zoom.tif"),
            options=c("COMPRESS=LZW"),
            overwrite=T,
            datatype='INT2S')

### Values of a raster: "freq"
freq(rc)
