####################################################################################
####### Object: Google Drive to Local Drive    
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/10/22                                    
###################################################################################

###################################################################################
#### Parameters
###################################################################################

#### Root directory

####################################################################################################################
####### LOAD AUTHORIZATION KEY FOR "DRIVE" AND DOWNLOAD RESULTS
####################################################################################################################

#### Select a basename for the archives to transfer
setwd("/home/dannunzio/downloads/")

#### OBTENIR L'URL POUR AUTORISATION
system(sprintf("echo %s | drive init","aucune"))

#### INITIALISER LE DRIVE
system(sprintf("echo %s | drive init",auth_key))

#### POUSSER DE SEPAL VERS LE DRIVE
system(sprintf("drive push civ_desiree_2_2013_2019_ndfi/"))

#### TIRER DU DRIVE VERS SEPAL
system(sprintf("drive pull civ_desiree_2_2013_2019_ndfi/"))
