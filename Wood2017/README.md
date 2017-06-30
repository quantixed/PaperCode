# Wood et al. 2016

Two procedures were used for analysis of confocal images of hot-wiring endocytosis.

## CompileThresholdTraces

This file is a series of Igor functions that will process and present hot-wiring endocytosis movies. Igor will read in two traces per cell, cytoplasmic ROI of GFP fluorescence (g wave) and a count of GFP puncta after thresholding (p wave). The procedures will present the user with a simple interface to determine the min and max point on the g wave. Igor uses this to work out when rerouting to the plasma membrane occurred and offset waves accordingly. Igor does some other normalisation procedures too. Each experimental condition is coloured according to the stylesheet. There is an option to read in the data once more without the user interface in the case where min and max do not need to be respecified.

## ParseTimestampsFromOME

Images are captured using Volocity. The images are managed via an mvd database. These can be imported into FIJI using BioFormats. Typically we read out timestamps from BioFormats using [planeTimings](https://github.com/openmicroscopy/bioformats/commit/c10ef163b269873e918376e807844b9c662342b1) macro written for ImageJ by Curtis Rueden. However, this doesn't work well for more complex databases. This Igor procedure will parse a textload from the BioFormats window in FIJI to give timestamps for each movie. Time stamps are important for optogenetic activation movies and for accurate averaging.

## ColocAnalysis

A workflow to analyse colocalisation in IgorPro (IP7 only). Select Coloc Analysis... from the Macros menu. Then in the panel selects the TIFFs for channel 1 and 2, then (optionally) the output from [ComDet](https://github.com/ekatrukha/ComDet) (channel 1 and/or channel 2) and then specify an output directory. The result is a move called finalTIFF which shows:

- each channel in grayscale along with a red/green merge
- plots of pixel intensities from each channel
	- ch1 spots
	- ch2 spots
	- overlap between ch1 ch2
- a line plot to show the number of spots detected for each channel and the number of spots which coincide.

This procedure is actively maintained in [IgorImageTools](https://github.com/quantixed/IgorImageTools/). This is the version as used in the paper.

## CCVRotator

This will take a set of segmented EM images and extract features by comparing them with the original images. A directory of images with vesicle and coat segmented as white or black overwrite are used as segmented images. In the directory above are the originals. Running CCVRotator will pull out the white or black pixels by subtraction.

The location of these pixels is used to get eigenvectors and rotate the ellipse so that the semimajor axis is at x where y = 0 and the semiminor is at y where x = 0. Max of x and max of y are taken as the radii.