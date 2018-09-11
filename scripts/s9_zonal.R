#############################################################
### Zonal stats per tile of the loss product
system(sprintf("python %s/oft-zonal_large_list.py -um %s -i %s -o %s -a %s",
               scriptdir, ## chemin jusqu'au script
               paste0(tile_dir,"tiling_system_",countrycode,".shp"), ## fichier zone (tif ou shp)
               gfc_ly, ## fichier dont on veut calculer les stats (raster)
               paste0(tile_dir,"gfc_tile.txt"), ## fichier sortie (table .txt)
               "tileID" ## attribut du fichier zone
))

df  <- read.table(paste0(tile_dir,"gfc_tile.txt"))
shp <- readOGR(paste0(tile_dir,"tiling_system_",countrycode,".shp"))
dbf <- shp@data
head(dbf)
head(df)

dbf$total <- df$V2
dbf$no_da <- df$V3
dbf$loss  <- rowSums(df[,c(17:19)])

shp@data <- dbf

selection <- shp[shp@data$loss > 10000,]
nrow(selection@data)

### Export 5 TILE as KML
base_sqr <- paste0("five_tile_",countrycode)
writeOGR(obj=selection[sample(1:nrow(selection@data),5),],
         dsn=paste(tile_dir,base_sqr,".kml",sep=""),
         layer=base_sqr,
         driver = "KML",
         overwrite_layer = T)