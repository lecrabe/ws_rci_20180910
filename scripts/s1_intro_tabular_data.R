##########################################################################################
################## Read, manipulate and write tables
##########################################################################################

########################################################################################### 
# Contact: remi.dannunzio@fao.org
# Last update: 2018-08-22
##########################################################################################

### Make sure you have initialized your working environment by running first the script "s0_parameters.R"

### Read a table: "read.csv", "paste0" and "<-"
df    <- read.csv(paste0(tab_dir,"tc_gfc_2016.csv"))

### Summary of table columns: "str", "summary"
str(df)
summary(df)

### Display top and end of table: "head", "tail"
head(df)
tail(df,2)

### Display column names: "names"
names(df) 

### Extract one column: "$x" and [,"x"]
tc_area_10 <- df$th_10
tc_area_10 <- df[,"th_10"]
tc_area_10 <- df[,2]

### Test values
test1 <- df$Country == "Uganda"
test2 <- df$th_30 > 1000000

### Extract one line: ["x",]
gfc_country <- df[238,]

### Extract line conditionnally: ["x",]
gfc_set1 <- df[test1,]
gfc_set2 <- df[test2,]

### Length of a vector: "length"
length(test2)
length(gfc_set2$Country)

### Length of a table: "nrow"
nrow(gfc_set2)
nrow(gfc_set1)

### Download file from internet with known URL: "download.file"
download.file("https://raw.githubusercontent.com/datasets/country-codes/master/data/country-codes.csv",
              paste0(tab_dir,"continents.csv"))
cont <- read.csv(paste0(tab_dir,"continents.csv"))
names(cont)

### Make a subset of a table by columns, change names
cont <- cont[,c("official_name_en","CLDR.display.name","Region.Name","Sub.region.Name")]
names(cont)
names(cont) <- c("country","country_short","region","subregion")

### Merge datasets: "merge"
df1 <- merge(df,cont,by.x="Country",by.y="country_short",all.x=T)
head(df1)

### List of levels in a vector: "levels" and "as.factor" 
(regions <- levels(as.factor(df1$region)))

### Count occurence in table: "table"
table(df1$region)
table(df1$subregion,df1$region)

### Add numbers: "sum"
sum(df1$th_30)/1000000

### Make sum by factors: "tapply"
tapply(df1$th_30,df1$region,sum)
sum(tapply(df1$th_30,df1$region,sum)/1000000)

### Find missing values: "is.na"
df1[is.na(df1$region),]$Country

### Replace missing values: "%in%"
df1[df1$Country %in% c("Côte d'Ivoire","Democratic Republic of the Congo","Republic of Congo"),]$region <- "Africa"
df1[df1$Country %in% c("United Kingdom","Czech Republic","Bosnia and Herzegovina"),]$region <- "Europe"
df1[df1$Country %in% c("United States"),]$region <- "Americas"
df1[df1$Country %in% c("Taiwan"),]$region <- "Asia"
df1[df1$Country %in% c("Antarctica"),]$region <- "Others"
df1[is.na(df1$region),]$region <- "Others"
sum(tapply(df1$th_30,df1$region,sum)/1000000)

### Make sum by factors: "tapply"
tapply(df1$th_30,df1$region,sum)/1000000

### Calculate average tree cover
df1$pcloss_30 <-  df1$loss_30 / df1$th_30

### Check NAs and set them to zero
summary(df1$pcloss_30)
df1[is.na(df1$pcloss_30),]$pcloss_30 <- 0

### Plot as scatter
plot(df1$pcloss_30)

### Organize data by region
rate_avg <- tapply(df1$pcloss_30,df1$region,mean)
rate_std <- tapply(df1$pcloss_30,df1$region,sd)
rate_nb  <- tapply(df1$pcloss_30,df1$region,length)
dp <- data.frame(cbind(names(rate_avg),rate_nb,rate_avg,rate_std))

names(dp) <- c("region","nb","rate_avg","rate_std")
dp$nb <- as.numeric(dp$nb)
dp$rate_avg <- as.numeric(dp$rate_avg)
dp$rate_std <- as.numeric(dp$rate_std)

### Plot as bars
p <- ggplot(dp,aes(x=region,y=rate_avg))
p +  geom_bar(stat="identity") 

### Plot as bars with error bars
p +  
  geom_bar(stat="identity") + 
  aes(colour=region) +
  geom_errorbar(aes(ymax=rate_avg+1.96*rate_std/sqrt(nb), 
                    ymin=rate_avg-1.96*rate_std/sqrt(nb))
  ) + 
  theme_minimal()
