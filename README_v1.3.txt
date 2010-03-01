FORCAST GRISM SPECTRAL REDUCTION/ANALYSIS

This is a further test

FG_WIDGET v1.3 README

Last Update: February 17 2010
Luke Keller (Ithaca College: lkeller@ithaca.edu)
Casey Deen  (University of Texas, Austin)

INSTALLATION INSTRUCTIONS:

Download two files: fg_package_v1.3.tgz & DEMO_GRISM_DATA.tgz

Unix (including Max OS X)

    tar -zxf fg_package_v1.3.tgz (produces a directory called fg_package_v1.3)
    tar -zxf DEMO_GRISM_DATA.tgz (produces a directory called DEMO_GRISM_DATA)

    mv DEMO_GRISM_DATA fg_package_v1.3 (moves data into the same directory as
	the IDL code)
    
PC (and Mac)

    Use Zip or Stuffit to expand the file
    copy DEMO_GRISM_DATA into the fg_package_v1.3 directory

Make sure the directory (fg_package_v1.3) is FIRST in your IDL path either by manually adding it in your IDL path, by pointing IDL to it in the IDL
Path Preferences, or by running the IDL batch file 'fgstart':

IDL> @/yourpath/fg_package_v1.3/@fgstart.

The main files of interest are:

READMEv1.3          (you're reading it now)

fg_package_v1.3/DEMO_GRISM_DATA  
             
		    (contains FORCAST grism test data and a README)
 
fg_widget.pro       (starts the GUI up from the IDL command line):

IDL> fg_widget

NOTE: If you run fg_widget before setting up paths as above, you run
the risk of a train wreck with existing IDL routines on your system
(e.g. different versions of the Goddard Astrolib, different versions
of FORCAST data reduction software, versions of SPEXTOOL, etc.).

OVERVIEW:

FG_WIDGET (FORCAST Grism Widget) is a quick-look spectral extraction
tool originally designed for the preliminary lab testing of grisms in FORCAST.
This software is evolving into the FORCAST Grism in-flight Quick Look software that we will deliver with the FORCAST GRISM spectroscopy mode. FG_WIDGET 
is fully integrated into the FORCAST Data Reduction Pipeline 
(Drip) and is intended to provide tools for lab engineering and testing 
of the grism modes. Eventually the grism spectral data reduction/extraction
pipeline will also run in batch-maode.

The following functions are currently implemented:

1) Read and display FITS data including FORCAST FITS files. Augment FITS header
   keywords that are FORCAST grism-specific, but not yet integrated in the
   FORCAST FITS headers.

2) Run the DRIP to reduce the 2-D FORCAST data and display reduced images. 
Do quicklook and analysis of the 2-D images using the ATV FITS image
viewer.

3) Allow the user to select multiple regions of interest (ROI) on displayed
images with mouse drags.

4) Extract the ROI data and display it as a 1-D spectrum plot. This widget is 
xzoomplot.pro lifted from the IRTF SpexTool package (with many thanks to Mike
Cushing and Bill Vacca) and revised for use with FORCAST spectra. A combination
of key strokes and mouse actions allow zooming and other scrutiny of the spectrum including readouts of the pixel values. Type 'h' in the plot window for a listing of key strokes and their functions.

5) Repeat as many extractions as you like with multiple data files open.

6) Save extracted and plotted spectrum in a two-column ASCII file, a FITS table, and/or in PostScript format.

7) User-interactive wavelength calibration

8) Multiple spectral plots on the same axes

9) Gaussian fitting routines for spectral line/feature profiles

10) Baseline fitting routines for continuum subtraction

11) Extract all orders for cross-dispersed (G1xG2) mode in one click


OPERATING INSTRUCTIONS to load FORCAST test data and extract a spectrum
(these instructions demonstrate the data display and spectral extraction process, but do not use or even mention all of the features of the GUI):

0) IMPORTANT: See the beginning of this README for installation instructions
and IDL path setup prior to running fg_widget.

1) At the IDL prompt, type: 

IDL> fg_widget
 
2) Use 'File' pulldown menu to open a data file using the 'Open Forcast...' option, or use the 'Open File(s)' button

FOR a cross-dispersed (G1xG2) example, choose G1xG2/raw_spectrum.fits
FOR a long-slit (G1 only) example, choose G1/raw_spectrum.fits
 
3) Once you've loaded the data, click on the 'Reduce' button
 
4) FG_WIDGET will automaticaly display the reduced image in two small 
display boxes. Depending on the spectral format (long slit or cross-
dispersed) Display A or B will have the spectrogram (2-D spectrum image)
oriented with the dispersion direction roughly horizontal. CLick in
the image Display window (A or B) and re-size/move the blue Scale box
to adjust contrast. Image scale options are in the 'Scale' area in the
lower left of the GUI.

5) In the lower right of the GUI in the 'Extract' Region, click on 'New Box' 
   (also click the 'Show' and 'Top' buttons) 

6) A colored box will appear in the currently-selected image Display box
(A or B). Size the colored extraction box using left-click and drag to enclose the part of the image you want to extract to a 1-D spectrum.

7) Click the 'Extract' button in the lower left of the GUI 

8) Your spectrum should appear in the large plot window. This window has 
all of the functionality of 'xzoomplot.pro' used in SpeXTool and then some.
With the cursor in the plot window, click 'h' for a listing of functions.
  
9) Repeat steps 5-7 as many times as you like. To extract or view a particular 
ROI just press the 'Extract' button for that region.

OR use the 'Extract --> G1xG2' button to extract all orders at once.

10) To save your extracted spectrum, use the 'SAVE' button to the left
of the Extract button. Choose ASCII, PS, or FITS. The file format
is 4 columns (ASCII or FITS table): wave/pix, flux, flux_error, order

11) For line profile fitting, move your mouse cursor into the spectral plot window and press 'f'. This will create a new widget under the plot window notifying that you are now in fitting mode. There are three buttons - 'Fit Gauss', 'Baseline fit' and 'Exit Fit Mode'. 'Fit Gauss' button allows you to select a zoom region in the spectral plot window and fit a gaussian profile. 'Baseline Fit' is for continuum subtraction. When you click it, two new options show up - 'Fit Clicks' and 'Fit Data'. 'Fit Data' lets you select a region in the 1-D plot and fit a polynomial to it. 'Fit Clicks' lets you click on the 1-D plot and it fits a spline to it. You can chose to fit the clicked coordinates, or fit the data at the clicked wavelengths. After fitting, you will notice 'Subtract' button has appeared in the widget. Subtract button subtracts the continuum from the data and displays it for preview. Then 'Accept' button makes this your new default spectra.

12) For manual wavelength calibration, move your mouse cursor into the spectral plot window and press 'l'. This will create a new widget under the plot window notifying that you are now in wavecal mode. There are four buttons - 'Store', 'Undo Last', 'Calibrate', and 'Cancel'. Click in the plot window at a horizontal
pixel corresponding to a wavelength you know, enter the wavelength (microns)
in the 'Enter Corresponding Wavelength' window, then press 'Store'. Continue
entering wavelengths in this way (short to long), then press 'Calibrate'. The
horizontal axis will now read wavelengths in microns.

Use 'File'-->'Quit' to exit to the IDL prompt

FUNCTION UPDATE LIST (with status in parenthesis)*:

-- Auto extract all 6 FORCAST Grism modes (G1 and G1xG2 DONE. Other modes awaiting next round of lab tests)

-- Save and restore wavelength calibrations for all 6 FORCAST Grism modes (coding in progress)

-- Generate flatfield templates for both cross-dispersed modes (G1xG2 DONE)

-- Optimal extraction of spectra from the ROI (Fully coded, not integrated)

-- Rectify the spectral format using the appropriate fit and/or
   transformations (~50% coded, not integrated)

-- Reduce chopped, nodded, slit-scan mode spectra

*  Please send update requests to Luke Keller at lkeller@ithaca.edu
