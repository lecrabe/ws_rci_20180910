etat_1 <- "pas tre content"
etat_2 <- "en forme"

sprintf("je suis %s mais aussi %s",
        etat_1,
        etat_2)

nom <- c("desiree","abraham")
sample(nom,1)






system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               gfc_tc,
               gfc_ly,
            
               gfc_mp,
               "(B==0)*((A>0)*1+(A==0)*2)+(B>0)*((B<5)*2+(B>=5)*((B<=10)*3+(B>10)*1))"
))

