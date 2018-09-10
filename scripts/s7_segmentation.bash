####################################################################################################
## Segmentation of the mosaic (bash)
## remi.dannunzio@fao.org
## 2018/08/21
####################################################################################################
####################################################################################################

cd ~/ws_uga_20180828/
home=`pwd`
workdir=$home"/data/mosaic_lsat/"
segdir=$home"/data/segments/"

#################### PERFORM SEGMENTATION USING THE OTB-SEG ALGORITHM
p1=3   # radius of smoothing (pixels)
p2=16  # radius of proximity (pixels)
p3=0.1 # radiance threshold 
p4=50  # iterations of algorithm
p5=5   # segment minimum size (pixels)


for input in `ls $workdir/*.tif`;
  do echo $input;
  
  otbcli_MeanShiftSmoothing      -in $input         -fout $workdir/tmp_smooth.tif   -foutpos $workdir/tmp_pos.tif -spatialr $p1 -ranger $p2 -thres $p3 -maxiter $p4;
  
  otbcli_LSMSSegmentation        -in $workdir/tmp_smooth.tif -inpos $workdir/tmp_pos.tif     -out $workdir/tmp_seg_lsm.tif -spatialr $p1 -ranger $p2 -minsize 0 -tmpdir $workdir -tilesizex 512 -tilesizey 512;
  
  otbcli_LSMSSmallRegionsMerging -in $workdir/tmp_smooth.tif -inseg $workdir/tmp_seg_lsm.tif -out $segdir/seg_${input##*/} -minsize $p5 -tilesizex 512 -tilesizey 512;
  
  rm $workdir/tmp*.tif;
  
  gdal_calc.py -A $input --co COMPRESS=LZW --overwrite --outfile=$segdir/mask_${input##*/} --calc="(A>0)";
  done;


