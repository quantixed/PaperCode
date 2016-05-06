#Wood et al. 2016

Two procedures were used for analysis of confocal images of hot-wiring endocytosis.

##CompileThresholdTraces

This file is a series of Igor functions that will process and present hot-wiring endocytosis movies. Igor will read in two traces per cell, cytoplasmic ROI of GFP fluorescence (g wave) and a count of GFP puncta after thresholding (p wave). The procedures will present the user with a simple interface to determine the min and max point on the g wave. Igor uses this to work out when rerouting to the plasma membrane occurred and offset waves accordingly. Igor does some other normalisation procedures too. Each experimental condition is coloured according to the stylesheet. There is an option to read in the data once more without the user interface in the case where min and max do not need to be respecified.

##ParseTimestampsFromOME

Images are captured using Volocity. The images are managed via an mvd database. These can be imported into FIJI using BioFormats. Typically we read out timestamps from BioFormats using [planeTimings](https://github.com/openmicroscopy/bioformats/commit/c10ef163b269873e918376e807844b9c662342b1) macro written for ImageJ by Curtis Rueden. However, this doesn't work well for more complex databases. This Igor procedure will parse a textload from the BioFormats window in FIJI to give timestamps for each movie. Time stamps are important for optogenetic activation movies and for accurate averaging.