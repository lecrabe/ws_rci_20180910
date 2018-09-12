####################################################################################################
####################################################################################################
## EXERCISE TAKEN FROM SWIRL() R PROGRAMMING MODULE 10 LAPPLY-SAPPLY
####################################################################################################
####################################################################################################

download.file("http://archive.ics.uci.edu/ml/machine-learning-databases/flags/flag.data",
              paste0(tab_dir,"flags.txt"),
              method="auto"
)

flags <- read.table(paste0(tab_dir,"flags.txt"),sep=",",header=F)

names(flags) <- c("name","landmass","zone","area","population","language","religion",
"bars","stripes","colours","red","green","blue","gold","white","black",
"orange","mainhue","circles","crosses","saltires","quarters","sunstars","crescent","triangle",
"icon","animate","text","topleft","botright")

head(flags)
dim(flags)
class(flags)

cls_list <- lapply(flags, class)
cls_list
class(cls_list)
as.character(cls_list)

cls_vect <- sapply(flags, class)
class(cls_vect)

sum(flags$orange)
flag_colors <- flags[, 11:17]
head(flag_colors)
lapply(flag_colors,sum)
sapply(flag_colors,sum)
sapply(flag_colors,mean)

flag_shapes <- flags[, 19:23]
lapply(flag_shapes,range)
shape_mat <- sapply(flag_shapes,range)
shape_mat
class(shape_mat)

unique_vals <- lapply(flags,unique)
unique_vals

sapply(unique_vals,length)
sapply(flags,unique)

lapply(unique_vals, function(elem) elem[2])