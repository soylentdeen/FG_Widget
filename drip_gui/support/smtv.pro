;+
;
; SPECIAL NOTE :
; ATV was written originally by Aaron Barth (with contributions from others). 
; A full description and the current publically available version 
; can be found at http://www.physics.uci.edu/~barth/atv/
; The work of the original developers is here fully acknowledged.
; A version of ATV was then incorporated into SMART by the SMART
; development team. Within SMART this was originally called ATV. 
; At the request of Aaron Barth and to prevent possible version
; conflicts with subsequent releases of ATV the SMART specific version
; has been re-named SMTV. 
;
;
; NAME:
;       SMTV
; 
; PURPOSE: 
;       Interactive display of 2-D or 3-D images.
;
; CATEGORY: 
;       Image display.
;
; CALLING SEQUENCE:
;       smtv [,array_name OR fits_file] [,min = min_value] [,max=max_value] 
;           [,/linear] [,/log] [,/histeq] [,/block]
;           [,/align] [,/stretch] [,header = header]
;
; REQUIRED INPUTS:
;       None.  If smtv is run with no inputs, the window widgets
;       are realized and images can subsequently be passed to smtv
;       from the command line or from the pull-down file menu.
;
; OPTIONAL INPUTS:
;       array_name: a 2-D or 3-D data array to display
;          OR
;       fits_file:  a fits file name, enclosed in single quotes
;
; KEYWORDS:
;       min:        minimum data value to be mapped to the color table
;       max:        maximum data value to be mapped to the color table
;       linear:     use linear stretch
;       log:        use log stretch 
;       histeq:     use histogram equalization
;       block:      block IDL command line until SMTV terminates
;       align:      align image with previously displayed image
;       stretch:    keep same min and max as previous image
;       header:     FITS image header (string array) for use with data array
;       
; OUTPUTS:
;       None.  
; 
; COMMON BLOCKS:
;       smtv_state:  contains variables describing the display state
;       smtv_images: contains the internal copies of the display image
;       smtv_color:  contains colormap vectors
;       smtv_pdata:  contains plot and text annotation information
;
; RESTRICTIONS:
;       Requires IDL version 5.1 or greater.
;       Requires Craig Markwardt's cmps_form.pro routine.
;       Requires the GSFC IDL astronomy user's library routines.
;       Some features may not work under all operating systems.
;
; SIDE EFFECTS:
;       Modifies the color table.
;
; EXAMPLE:
;       To start smtv running, just enter the command 'smtv' at the idl
;       prompt, either with or without an array name or fits file name 
;       as an input.  Only one smtv window will be created at a time,
;       so if one already exists and another image is passed to smtv
;       from the idl command line, the new image will be displayed in 
;       the pre-existing smtv window.
;
; MODIFICATION HISTORY:
;       Written by Aaron J. Barth, with contributions by 
;       Douglas Finkbeiner, Michael Liu, David Schlegel, and
;       Wesley Colley.  First released 17 December 1998.
;
;       26-April-2002: H.Roe added capability to handle 3-d stacks
;                      of images.
;
;       01-Sept-2003: J. Brauher added new features including:
;
;                    -Full integration of multi-plane imaging
;                    -Additional color tables
;                    -Draw arrow on image
;                    -Rectangular box statistics
;                    -Pixel table widget
;                    -Overplot DS9 region files
;                    -"Zoom" menu
;                    -Image rotations and inversions
;                    -Writefits
;                    -PS lineplots
;                    -PS photometry radial profile
;                    -Statistics and photometry text output files
;                    -Pixel slice through 3D image (Value vs. plane #)
;                    -Pixel histogram plot
;                    -Change x-y lineplot range
;<<<<<<< smtv_jb.pro
;                    -WCS grid overlay
;                    -Region overplots and statistics
;                    -Vector plot
;                    -Plot 1D Gaussian fit to image columns/rows
;                    -"WriteImage" option for JPEG,TIFF,PNG,BMP,PICT
;                    -Download Archive image for DSS, 2MASS, IRAS  
;=======
;       25-June-2003: K. Schawinski-Guiton added features:
;>>>>>>> smtv_ks.pro
;
;<<<<<<< smtv_jb.pro
;
;       This version is 2.0
;=======
;                    -Wavsamp overplot option
;                    -Extraction overplot option
;                    -Mosaic option for image cubes
;                    -ImExam3d, to analyse image cubes
;
;       This version is 1.5
;>>>>>>> smtv_ks.pro
;
;       For the most current version, revision history, instructions,
;       list of known bugs, and further information, go to:
;              http://www.astro.caltech.edu/~barth/atv
;
;
;       9 May 2005 Peter Hall, Cornell University
;       Changed routine "smtv_gettrack" :
;       1. Converted variables to double precision to improve accuracy.
;       2. Changed "Position Angle" calculation to convert
;          from degrees to radians for trigonometric functions. 
;       3. Added division by Dec to offset RA calculation.
;       4. Added display of "Wavesamp Offset".
;
;
;       29 August 2005 Peter Hall and David Whelan, Cornell University.
;       Multiple changes :  
;       1. Added check to radial profile calculator that all values are finite.
;          (Mantis Bug number 193)
;       2. In smtv_event ensured that header is read from right
;          dataset in multiple stack. (Mantis Bug number 194)
;          Also clarified rubric to ensure parameters fully described. 
;          (Mantis Bug number 194)
;       3. Updated call to sm_mosaic.pro to pass in the bmask for
;          mosaicing. (Mantis Bug number 194)
;       4. Disallowed mosaiced images from being rotated: added
;          warning message. (Mantis Bug number 194)
;       5. Disallowed images without FITS astrometery keywords
;          (IE. SH, LL, LH) from being rotated: added warning message.
;          (Mantis Bug number 194)
;       6. Commented out WCS Grid plotting option. (Mantis Bug number 194)
;       7. Taken out "ReadFits" reading option, "WCS Grid" overplot option,
;          "Add to PM" writing option, "Archive Image" reading option,
;          and MouseMode "LinePlot" option. (Mantis Bug number 194)
;       8. Created a larger array size for the Help file. (Mantis Bug number 194)
;       9. Added "FILETEXT" case to "smtv_writeimage_event" 
;          to prevent crash during writing. Tided up wording. (Mantis Bug number 194)
;      10. Error traps in writePS and WriteFits included. (Mantis Bug number 194)

;----------------------------------------------------------------------
;        smtv startup, initialization, and shutdown routines
;----------------------------------------------------------------------

pro smtv_initcommon

; Routine to initialize the smtv common blocks.  Use common blocks so
; that other IDL programs can access the smtv internal data easily.

common smtv_state, state
common smtv_color, r_vector, g_vector, b_vector
common smtv_pdata, nplot, maxplot, plot_ptr
common smtv_images, $
  main_image, $
  main_image_stack, $
  main_image_backup, $
  names_stack, $
  header_stack, $
  display_image, $
  scaled_image, $
  blink_image1, $
  blink_image2, $
  blink_image3, $
  unblink_image, $  
  sl_wavelength, $
  sh_wavelength, $
  ll_wavelength, $
  lh_wavelength, $
  sl_offset, $
  sh_offset, $
  ll_offset, $
  lh_offset, $
  bmask_image_stack, $
  bmask_image, $
  pan_image


state = {                   $
          version: '2.0', $              ; version # of this release
          head_ptr: ptr_new(), $         ; pointer to image header
          astr_ptr: ptr_new(), $         ; pointer to astrometry info structure
          wcstype: 'none', $             ; coord info type (none/angle/lambda)
          equinox: 'J2000', $            ; equinox of coord system
          display_coord_sys: 'RA--', $   ; coord system displayed
          display_equinox: 'J2000', $    ; equinox of displayed coords
          display_base60: 1B, $          ; Display RA,dec in base 60?
          imagename: '', $               ; image file name
          bitdepth: 8, $                 ; 8 or 24 bit color mode?
          screen_ysize: 1000, $          ; vertical size of screen
          base_id: 0L, $                 ; id of top-level base
          base_min_size: [512L, 300L], $ ; min size for top-level base
          draw_base_id: 0L, $            ; id of base holding draw window
          draw_window_id: 0L, $          ; window id of draw window
          draw_widget_id: 0L, $          ; widget id of draw widget
          track_window_id: 0L, $         ; widget id of tracking window
          pan_widget_id: 0L, $           ; widget id of pan window
          pan_window_id: 0L, $           ; window id of pan window
          active_window_id: 0L, $        ; user's active window outside smtv
          info_base_id: 0L, $            ; id of base holding info bars
          location_bar_id: 0L, $         ; id of (x,y,value) label
          wave_bar_id: 0L, $             ; id of wavelength label
          bmask_bar_id: 0L, $            ; id of the bmask label
          coord_bar_id: 0L, $            ; id of coordinate label
          woffset_bar_id: 0L, $          ; id of wavesamp offset label   ; PH 9 May 2005
          wcs_bar_id: 0L, $              ; id of WCS label widget
          min_text_id: 0L,  $            ; id of min= widget
          max_text_id: 0L, $             ; id of max= widget
          menu_ids: lonarr(35), $        ; list of top menu items
          colorbar_base_id: 0L, $        ; id of colorbar base widget
          colorbar_widget_id: 0L, $      ; widget id of colorbar draw widget
          colorbar_window_id: 0L, $      ; window id of colorbar
          colorbar_height: 6L, $         ; height of colorbar in pixels
          ncolors: 0B, $                 ; image colors (!d.table_size - 9)
          box_color: 2, $                ; color for pan box and zoom x
          brightness: 0.5, $             ; initial brightness setting
          contrast: 0.5, $               ; initial contrast setting
          keyboard_text_id: 0L, $        ; id of keyboard input widget
          image_min: 0.0, $              ; min(main_image)
          image_max: 0.0, $              ; max(main_image)
          min_value: 0.0, $              ; min data value mapped to colors
          max_value: 0.0, $              ; max data value mapped to colors
          draw_window_size: [512L, 512L], $    ; size of main draw window
          track_window_size: 121L, $     ; size of tracking window
          pan_window_size: 121L, $       ; size of pan window
          pan_scale: 0.0, $              ; magnification of pan image
          image_size: [0L,0L,0L], $      ; [0:1] gives size of main_image
                                         ; [0:2] gives size of main_image_stack
          cur_image_num: 0L, $           ; gives current image number in
                                         ; main_image_stack
          curimnum_base_id: 0L, $        ; id of cur_image_num base widget
          curimnum_text_id: 0L, $        ; id of cur_image_num textbox widget
          curimnum_slidebar_id: 0L, $    ; id of cur_image_num slider widget
          scale_mode_droplist_id: 0L, $  ; id of scale droplist widget
          curimnum_minmaxmode: 'Constant', $  ; mode for determining min/max
                                         ; of display when changing curimnum
          invert_colormap: 0L, $         ; 0=normal, 1=inverted
          coord: [0L, 0L],  $            ; cursor position in image coords
          plot_coord: [0L, 0L], $        ; cursor position when a plot
                                         ; is initiated
          vector_coord1: [0L, 0L], $     ; 1st cursor position in vector plot  
          vector_coord2: [0L, 0L], $     ; 2nd cursor position in vector plot
          plot_type:'', $                ; plot type for plot window
          scaling: 0L, $                 ; 0=linear, 1=log, 2=histeq
          offset: [0L, 0L], $            ; offset to viewport coords
          base_pad: [0L, 0L], $          ; padding around draw base
          zoom_level: 0L, $              ; integer zoom level, 0=normal
          zoom_factor: 1.0, $            ; magnification factor = 2^zoom_level
          rot_angle: 0.0, $              ; current image rotation angle
          invert_image: 'none', $        ; 'none', 'x', 'y', 'xy' image invert
          centerpix: [0L, 0L], $         ; pixel at center of viewport
          cstretch: 0B, $                ; flag = 1 while stretching colors
          pan_offset: [0L, 0L], $        ; image offset in pan window
          frame: 1L, $                   ; put frame around ps output?
          framethick: 6, $               ; thickness of frame
          lineplot_widget_id: 0L, $      ; id of lineplot widget
          lineplot_window_id: 0L, $      ; id of lineplot window
          lineplot_base_id: 0L, $        ; id of lineplot top-level base
          lineplot_size: [600L, 500L], $ ; size of lineplot window
          lineplot_min_size: [100L, 0L], $ ; min size of lineplot window
          lineplot_pad: [0L, 0L], $      ; padding around lineplot window
          lineplot_xmin_id: 0L, $        ; id of xmin for lineplot windows
          lineplot_xmax_id: 0L, $        ; id of xmax for lineplot windows
          lineplot_ymin_id: 0L, $        ; id of ymin for lineplot windows
          lineplot_ymax_id: 0L, $        ; id of ymax for lineplot windows
          lineplot_xmin: 0.0, $          ; xmin for lineplot windows
          lineplot_xmax: 0.0, $          ; xmax for lineplot windows
          lineplot_ymin: 0.0, $          ; ymin for lineplot windows
          lineplot_ymax: 0.0, $          ; ymax for lineplot windows
          lineplot_xmin_orig: 0.0, $     ; original xmin saved from histplot
          lineplot_xmax_orig: 0.0, $     ; original xmax saved from histplot
          holdrange_base_id: 0L, $       ; base id for 'Hold Range' button
          holdrange_butt_id: 0L, $       ; button id for 'Hold Range' button
          holdrange_value: 1., $         ; 0=HoldRange Off, 1=HoldRange On
          histbutton_base_id: 0L, $      ; id of histogram button base
          histplot_binsize_id: 0L, $     ; id of binsize for histogram plot
          x1_pix_id: 0L, $               ; id of x1 pixel for histogram plot
          x2_pix_id: 0L, $               ; id of x2 pixel for histogram plot
          y1_pix_id: 0L, $               ; id of y1 pixel for histogram plot
          y2_pix_id: 0L, $               ; id of y2 pixel for histogram plot
          binsize: 0.0, $                ; binsize for histogram plots
          reg_ids_ptr: ptr_new(), $      ; ids for region form widget
          writeimage_ids_ptr: ptr_new(),$; ids for writeimage form widget
          writeformat: 'JPEG', $         ; format for WriteImage
          cursorpos: lonarr(2), $        ; cursor x,y for photometry & stats
          centerpos: fltarr(2), $        ; centered x,y for photometry
          cursorpos_id: 0L, $            ; id of cursorpos widget
          centerpos_id: 0L, $            ; id of centerpos widget
          centerbox_id: 0L, $            ; id of centeringboxsize widget
          radius_id: 0L, $               ; id of radius widget
          innersky_id: 0L, $             ; id of inner sky widget
          outersky_id: 0L, $             ; id of outer sky widget
          magunits: 0, $                 ; 0=counts, 1=magnitudes
          skytype: 0, $                  ; 0=idlphot,1=median,2=no sky subtract
          photzpt: 25.0, $               ; magnitude zeropoint
          skyresult_id: 0L, $            ; id of sky widget
          photresult_id: 0L, $           ; id of photometry result widget
          fwhm_id: 0L, $                 ; id of fwhm widget
          radplot_widget_id: 0L, $       ; id of radial profile widget
          radplot_window_id: 0L, $       ; id of radial profile window
          photzoom_window_id: 0L, $      ; id of photometry zoom window
          photzoom_size: 190L, $         ; size in pixels of photzoom window
          showradplot_id: 0L, $          ; id of button to show/hide radplot
          photwarning_id: 0L, $          ; id of photometry warning widget
          photwarning: ' ', $            ; photometry warning text
          centerboxsize: 5L, $           ; centering box size
          r: 5L, $                       ; aperture photometry radius
          innersky: 10L, $               ; inner sky radius
          outersky: 20L, $               ; outer sky radius
          headinfo_base_id: 0L, $        ; headinfo base widget id
          pixtable_base_id: 0L, $        ; pixel table base widget id
          pixtable_tbl_id: 0L, $         ; pixel table widget_table id
          stats_base_id: 0L, $           ; base widget for image stats
          stat_xyresize_button_id: 0L, $ ; widget id for stats resize checkbox
          stat_xyresize: 1, $            ; 1=keep x&y sizes equal for box stats
                                         ; 0=allow rectangular box stats
          xstatboxsize: 11L, $           ; x box size for statistics
          ystatboxsize: 11L, $           ; y box size for statistics
          stat_npix_id: 0L, $            ; widget id for # pixels in stats box
          xstatbox_id: 0L, $             ; widget id for pix in x-dir stat box
          ystatbox_id: 0L, $             ; widget id for pix in y-dir stat box
          statxcenter_id: 0L, $          ; widget id for stat box x center
          statycenter_id: 0L, $          ; widget id for stat box y center
          statbox_min_id: 0L, $          ; widget id for stat min box
          statbox_max_id: 0L, $          ; widget id for stat max box
          statbox_mean_id: 0L, $         ; widget id for stat mean box
          statbox_median_id: 0L, $       ; widget id for stat median box
          statbox_stdev_id: 0L, $        ; widget id for stat stdev box
          statzoom_size: 300, $          ; size of statzoom window
          statzoom_widget_id: 0L, $      ; widget id for stat zoom window
          statzoom_window_id: 0L, $      ; window id for stat zoom window
          showstatzoom_id: 0L, $         ; widget id for show/hide button
          pan_pixmap: 0L, $              ; window id of pan pixmap
          default_autoscale: 1, $        ; autoscale images by default?
          current_dir: '', $             ; current readfits directory
          graphicsdevice: '', $          ; screen device
            
          newrefresh: 0, $               ; refresh since last blink?
;<<<<<<< smtv_jb.pro
          window_title: 'smtv:', $        ; string for top level title
          title_blink1: '', $            ; window title for 1st blink image
          title_blink2: '', $            ; window title for 2nd blink image
          title_blink3: '', $            ; window title for 3rd blink image
          title_extras: '', $            ; extras for image title
          blinks: 0B, $                   ; remembers which images are blinked
;        }
;=======
;          blinks: 0B ,$                  ; remembers which images are blinked
          wavsamp: 0 ,$                  ; whether to draw wavsamp?
          oplot: 0, $                    ; whether to overplot
          wavsampfile: '', $             ; location of wavsampfile
          smart: 0S, $                   ; whether smtv is run in smart
          bmask:0S, $                    ; If a bmask is passed
          mosaic: 0S, $                  ; whether the 3D stack is viewed as mosaic    
          im_slider1: 0L, $              ; widget id of image 1 slider
          im_slider2: 0L, $              ; widget id of image 2 slider
          screen1: 0L, $                 ; widget id of 1st stat3d screen
          screen2: 0L, $                 ; widget id of 2nd stat3d screen
          screen3: 0L, $                 ; widget id of mosaic screen
          stat3dbox: [0L, 0L], $         ; box size of stat3d window
          stat3dcenter: [0L, 0L], $      ; box center of stat3d window
          stat3d_done: 0L, $             ; widget id of done button
          stat3d_refresh: 0L, $          ; widget id of refresh button
          data_table: 0L, $              ; data table for stat3d 
          s3sel: [0L, 0L, 0L, 0L, 0L],$  ; draw box
          stat3dminmax: [0L, 0L, 0L, 0L],$; stat3d info for box
          lines_done: 0L, $              ; widget id of done button
          lines_gauss: 0L, $             ; widget id of gauss button
          lines_plot_screen: 0L, $       ; widget id of screen
          imin: 0L, $                    ; min control
          imax: 0L, $                    ; max control
          gaussmin: 0L, $                ; widget id of min button
          gaussmax: 0L, $                ; widget id of max button
          linesbox: [0L, 0L, 0L, 0L, 0L]$; start & end of line
;>>>>>>> smtv_ks.pro
        } 

nplot = 0
maxplot = 5000
plot_ptr = ptrarr(maxplot+1)  ; The 0th element isn't used.

blink_image1 = 0
blink_image2 = 0
blink_image3 = 0

;swfdsdf

end

;---------------------------------------------------------------------

pro smtv_startup

; This routine initializes the smtv internal variables, and creates and
; realizes the window widgets.  It is only called by the smtv main
; program level, when there is no previously existing smtv window.

common smtv_state
common smtv_color
common smtv_images
; Read in a color table to initialize !d.table_size
; As a bare minimum, we need the 8 basic colors used by SMTV_ICOLOR(),
; plus 2 more for a color map.

loadct, 0, /silent
if (!d.table_size LT 12) then begin
    message, 'Too few colors available for color table'
    smtv_shutdown
endif

; Initialize the common blocks
smtv_initcommon

state.ncolors = !d.table_size - 9
if (!d.n_colors LE 256) then begin
    state.bitdepth = 8 
endif else begin
    state.bitdepth = 24
    device, decomposed=0
endelse

state.graphicsdevice = !d.name

state.screen_ysize = (get_screen_size())[1]

; Get the current window id
smtv_getwindow


; Define the widgets.  For the widgets that need to be modified later
; on, save their widget ids in state variables

base = widget_base(title = 'smtv', $
                   /column, /base_align_right, $
                   app_mbar = top_menu, $
                   uvalue = 'smtv_base', $
                   /tlb_size_events)
state.base_id = base

tmp_struct = {cw_pdmenu_s, flags:0, name:''}

top_menu_desc = [ $
                  {cw_pdmenu_s, 1, 'File'}, $ ; file menu;
;This line commented out to remove "ReadFits" menu option ;DGW 29 August 2005
;                  {cw_pdmenu_s, 0, 'ReadFits'}, $       ;DGW 29 August 2005
                  {cw_pdmenu_s, 0, 'WriteFits'}, $
                  {cw_pdmenu_s, 0, 'WritePS'},  $
                  {cw_pdmenu_s, 0, 'WriteImage'}, $
                  {cw_pdmenu_s, 2, 'Quit'}, $
                  {cw_pdmenu_s, 1, 'ColorMap'}, $ ; color menu
                  {cw_pdmenu_s, 0, 'Grayscale'}, $
                  {cw_pdmenu_s, 0, 'Blue-White'}, $
                  {cw_pdmenu_s, 0, 'Red-Orange'}, $
                  {cw_pdmenu_s, 0, 'Green-White'}, $
                  {cw_pdmenu_s, 0, 'Red-Purple'}, $
                  {cw_pdmenu_s, 0, 'Blue-Red'}, $
                  {cw_pdmenu_s, 0, 'Rainbow'}, $
                  {cw_pdmenu_s, 0, 'Rainbow18'}, $
                  {cw_pdmenu_s, 0, 'BGRY'}, $
                  {cw_pdmenu_s, 0, 'GRBW'}, $
                  {cw_pdmenu_s, 0, 'Standard Gamma-II'}, $
                  {cw_pdmenu_s, 0, 'Prism'}, $
                  {cw_pdmenu_s, 0, '16 Level'}, $
                  {cw_pdmenu_s, 0, 'Stern Special'}, $
                  {cw_pdmenu_s, 0, 'Haze'}, $
                  {cw_pdmenu_s, 0, 'Blue-Pastel-Red'}, $
                  {cw_pdmenu_s, 0, 'Mac'}, $
                  {cw_pdmenu_s, 0, 'Blue-Red 2'}, $
                  {cw_pdmenu_s, 2, 'SMTV Special'}, $
                  {cw_pdmenu_s, 1, 'Scaling'}, $ ; scaling menu
                  {cw_pdmenu_s, 0, 'Linear'}, $
                  {cw_pdmenu_s, 0, 'Log'}, $
                  {cw_pdmenu_s, 2, 'HistEq'}, $
                  {cw_pdmenu_s, 1, 'Labels'}, $ ; labels menu
                  {cw_pdmenu_s, 0, 'TextLabel'}, $
                  {cw_pdmenu_s, 0, 'Arrow'}, $
                  {cw_pdmenu_s, 0, 'Contour'}, $
                  {cw_pdmenu_s, 0, 'Compass'}, $
                  {cw_pdmenu_s, 0, 'ScaleBar'}, $
;<<<<<<< smtv_jb.pro
                  {cw_pdmenu_s, 0, 'Region'}, $
; This line commented out to remove "WCS Grid" menu option. ;DGW 29 August 2005
; Can be re-instated if "WCS Grid" required but will need modification. ;DGW 29 August 2005
;                 {cw_pdmenu_s, 0, 'WCS Grid'}, $                 ;DGW 29 August 2005
;=======
                  {cw_pdmenu_s, 0, 'Draw Extraction'}, $
                  {cw_pdmenu_s, 0, 'Draw Wavsamp'}, $
;>>>>>>> smtv_ks.pro
                  {cw_pdmenu_s, 0, 'EraseLast'}, $
                  {cw_pdmenu_s, 2, 'EraseAll'}, $
                  {cw_pdmenu_s, 1, 'Blink'}, $
                  {cw_pdmenu_s, 0, 'SetBlink1'}, $
                  {cw_pdmenu_s, 0, 'SetBlink2'}, $
                  {cw_pdmenu_s, 2, 'SetBlink3'}, $
                  {cw_pdmenu_s, 1, 'Zoom'}, $
                  {cw_pdmenu_s, 0, 'Zoom In'}, $
                  {cw_pdmenu_s, 0, 'Zoom Out'}, $
                  {cw_pdmenu_s, 0, '1/16'}, $
                  {cw_pdmenu_s, 0, '1/8'}, $
                  {cw_pdmenu_s, 0, '1/4'}, $
                  {cw_pdmenu_s, 0, '1/2'}, $
                  {cw_pdmenu_s, 0, '1'}, $
                  {cw_pdmenu_s, 0, '2'}, $
                  {cw_pdmenu_s, 0, '4'}, $
                  {cw_pdmenu_s, 0, '8'}, $
                  {cw_pdmenu_s, 0, '16'}, $
                  {cw_pdmenu_s, 0, '-------------'}, $
                  {cw_pdmenu_s, 0, 'Center'}, $
                  {cw_pdmenu_s, 0, '-------------'}, $
                  {cw_pdmenu_s, 0, 'None'}, $
                  {cw_pdmenu_s, 0, 'Invert X'}, $
                  {cw_pdmenu_s, 0, 'Invert Y'}, $
                  {cw_pdmenu_s, 0, 'Invert X & Y'}, $
                  {cw_pdmenu_s, 0, '-------------'}, $
                  {cw_pdmenu_s, 0, 'Rotate'}, $
                  {cw_pdmenu_s, 0, '0 deg'}, $
                  {cw_pdmenu_s, 0, '90 deg'}, $
                  {cw_pdmenu_s, 0, '180 deg'}, $
                  {cw_pdmenu_s, 2, '270 deg'}, $
                  {cw_pdmenu_s, 1, 'ImageInfo'}, $    ;info menu
                  {cw_pdmenu_s, 0, 'Photometry'}, $
                  {cw_pdmenu_s, 0, 'Statistics'}, $
                  {cw_pdmenu_s, 0, 'ImageHeader'}, $
                  {cw_pdmenu_s, 0, 'Pixel Table'}, $
                  {cw_pdmenu_s, 0, 'Load Regions'}, $
;<<<<<<< smtv_jb.pro
                  {cw_pdmenu_s, 0, 'Save Regions'}, $
;This line commented out to remove "Archive Image" menu option DGW 29 August 2005
;                  {cw_pdmenu_s, 0, 'Archive Image'}, $       ;DGW 29 August 2005
;=======
                  {cw_pdmenu_s, 0, 'Mosaic'}, $
;This line commented out to remove "Add toPM" menu option DGW 29 August 2005
;                  {cw_pdmenu_s, 0, 'Add to PM'}, $      ;DGW 29 August 2005
;>>>>>>> smtv_ks.pro
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 0, 'RA,dec (J2000)'}, $
                  {cw_pdmenu_s, 0, 'RA,dec (B1950)'}, $
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 0, 'RA,dec (J2000) deg'}, $
                  {cw_pdmenu_s, 0, 'Galactic'}, $
                  {cw_pdmenu_s, 0, 'Ecliptic (J2000)'}, $
                  {cw_pdmenu_s, 2, 'Native'}, $
                  {cw_pdmenu_s, 1, 'Help'}, $         ; help menu
                  {cw_pdmenu_s, 2, 'SMTV Help'} $
                ]

top_menu = cw_pdmenu(top_menu, top_menu_desc, $
                     ids = state.menu_ids, $
                     /mbar, $
                     /help, $
                     /return_name, $
                     uvalue = 'top_menu')

track_base =    widget_base(base, /row)
state.info_base_id = widget_base(track_base, /column, /base_align_right)
buttonbar_base = widget_base(base, column=2, /base_align_center)

state.curimnum_base_id = widget_base(base, $
                                     /base_align_right, column=3, $
                                     frame = 1, xsize=1, ysize=1, map=0)

state.draw_base_id = widget_base(base, $
                                 /column, /base_align_left, $
                                 uvalue = 'draw_base', $
                                 frame = 2, /tracking_events)

state.colorbar_base_id = widget_base(base, $
                                     uvalue = 'cqolorbar_base', $
                                     /column, /base_align_left, $
                                     frame = 2)

min_base = widget_base(state.info_base_id, /row)

state.min_text_id = cw_field(min_base, $
                             uvalue = 'min_text', $
                             /floating,  $
                             title = 'Min=', $
                             value = state.min_value,  $
                             /return_events, $
                             xsize = 12)

state.max_text_id = cw_field(state.info_base_id, $
                             uvalue = 'max_text', $
                             /floating,  $
                             title = 'Max=', $
                             value = state.max_value, $
                             /return_events, $
                             xsize = 12)

tmp_string = string(1000, 1000, 1.0e-10, $
;                     format = '("(",i5,",",i5,") ",g10.5)')  ; PH 29 Aug. 2005
                     format = '("Pixel Pos(x,y)/Mag: ", "(",i5,",",i5,") ",g10.5)') ; PH 29 Aug. 2005

state.location_bar_id = widget_label (state.info_base_id, $
                                      value = tmp_string,  $
                                      uvalue = 'location_bar',  frame = 1)

tmp_string = string('??', -1., $
;                   format = '("Module: ", a10, "  ", g10.5)')           ; PH 29 Aug. 2005
                   format = '("Module/Wavelength: ", a10, "  ", g10.5)') ; PH 29 Aug. 2005
state.wave_bar_id = widget_label (state.info_base_id, $
                                      value = tmp_string,  $
                                      uvalue = 'wave_bar',  frame = 1)

tmp_string = string("",-1, $
                   format = '("Bmask: ", a10, "   ", g10.5)' )
state.bmask_bar_id = widget_label(state.info_base_id, $
                                      value = tmp_string,  $
                                      uvalue = 'bmask_bar',  frame = 1)

tmp_string = string( !Values.f_nan,  !Values.f_nan, $
;                   format = '("RA: ", g15.10, " DEC: ", g15.10)')       ; PH 29 Aug. 2005
                   format = '("RA_SLT: ", g15.10, " DEC_SLT: ", g15.10)'); PH 29 Aug. 2005
state.coord_bar_id = widget_label (state.info_base_id, $
                                      value = tmp_string,  $
                                      uvalue = 'coord_bar',  frame = 1)


tmp_string = string("",-1.0, $                                            ; PH 29 Aug. 2005
                   format = '("Wavesamp Offset: ", a8, g15.10)')          ; PH 29 Aug. 2005
state.woffset_bar_id = widget_label (state.info_base_id, $                ; PH 9 May 2005
                                      value = tmp_string,  $              ; PH 9 May 2005
                                      uvalue = 'woffset_bar',  frame = 1) ; PH 9 May 2005

;tmp_string = string(12, 12, 12.001, -60, 60, 60.01, ' J2000', $ ; PH 29 Aug. 2005
;        format = '(i2,":",i2,":",f6.3,"  ",i3,":",i2,":",f5.2," ",a6)' )  ; PH 29 Aug. 2005
tmp_string = string(12, 12, 12.001, -60, 60, 60.01, ' J2000', $                        ; PH 29 Aug. 2005
        format = '("WCS Data: ", i2,":",i2,":",f6.3,"  ",i3,":",i2,":",f5.2," ",a6)' ) ; PH 29 Aug. 2005

state.wcs_bar_id = widget_label (state.info_base_id, $
                                 value = tmp_string,  $
                                 uvalue = 'wcs_bar',  frame = 1)

state.pan_widget_id = widget_draw(track_base, $
                                  xsize = state.pan_window_size, $
                                  ysize = state.pan_window_size, $
                                  frame = 2, uvalue = 'pan_window', $
                                  /button_events, /motion_events)

track_window = widget_draw(track_base, $
                           xsize=state.track_window_size, $
                           ysize=state.track_window_size, $
                           frame=2, uvalue='track_window')

modebase = widget_base(buttonbar_base, /row, /base_align_center)
;<<<<<<< smtv_jb.pro
;modelist = ['Color', 'Zoom', 'Blink', 'ImExam', 'Region', 'Vector']
;=======
;modelist = ['Color', 'Zoom', 'Blink', 'LinePlot', 'ImExam', 'ImExam3D']
;>>>>>>> smtv_ks.pro

; This line commented out to remove "Lineplot" menu option.        ;DGW 29 August 2005
; Can be re-instated if "Lineplot" required but will need modification. ;DGW 29 August 2005
;modelist = ['Color', 'Zoom', 'Blink', 'ImExam','ImExam3D','LinePlot','Vector','Region']   ; DGW 29 August 2005
modelist = ['Color', 'Zoom', 'Blink', 'ImExam','ImExam3D','Vector','Region']               ; DGW 29 August 2005
mode_droplist_id = widget_droplist(modebase, $
                                   frame = 1, $
                                   title = 'MouseMode:', $
                                   uvalue = 'mode', $
                                   value = modelist)

button_base = widget_base(buttonbar_base, row=2, /base_align_right)

invert_button = widget_button(button_base, $
                              value = 'Invert', $
                              uvalue = 'invert')

restretch_button = widget_button(button_base, $
                             value = 'Restretch', $
                             uvalue = 'restretch_button')

autoscale_button = widget_button(button_base, $
                                 uvalue = 'autoscale_button', $
                                 value = 'AutoScale')

fullrange_button = widget_button(button_base, $
                                 uvalue = 'full_range', $
                                 value = 'FullRange')

state.keyboard_text_id = widget_text(button_base, $
                                     /all_events, $
                                     scr_xsize = 1, $
                                     scr_ysize = 1, $
                                     units = 0, $
                                     uvalue = 'keyboard_text', $
                                     value = '')
zoomin_button = widget_button(button_base, $
                              value = 'ZoomIn', $
                              uvalue = 'zoom_in')

zoomout_button = widget_button(button_base, $
                               value = 'ZoomOut', $
                               uvalue = 'zoom_out')

zoomone_button = widget_button(button_base, $
                               value = 'Zoom1', $
                               uvalue = 'zoom_one')

center_button = widget_button(button_base, $
                              value = 'Center', $
                              uvalue = 'center')
done_button = widget_button(button_base, $
                            value = 'Done', $
                            uvalue = 'done')

state.curimnum_text_id = cw_field(state.curimnum_base_id, $
                             uvalue = 'curimnum_text', $
                             /long,  $
                             /row, $
                             title = 'Image #=', $
                             value = state.cur_image_num, $
                             /return_events, $
                             xsize = 5)

state.curimnum_slidebar_id = widget_slider(state.curimnum_base_id, $
                            /drag, $ 
                            max = 1, $
                            min = 0, $
                            scr_xsize = 150L, $
                            sensitive = 0, $
                            scroll = 1L, $
                            /suppress_value, $
                            uvalue = 'curimnum_slidebar', $
                            value = 0, $
                            vertical = 0)

modelist = ['Constant', 'AutoScale', 'Min/Max']
state.scale_mode_droplist_id = widget_droplist(state.curimnum_base_id, $
                                   uvalue = 'curimnum_minmaxmode', $
                                   value = modelist)

; Set widget y size for small screens
state.draw_window_size[1] = state.draw_window_size[1] < $
  (state.screen_ysize - 300)

state.draw_widget_id = widget_draw(state.draw_base_id, $
                                   uvalue = 'draw_window', $
                                   /motion_events,  /button_events, $
                                   scr_xsize = state.draw_window_size[0], $
                                   scr_ysize = state.draw_window_size[1]) 

state.colorbar_widget_id = widget_draw(state.colorbar_base_id, $
                                       uvalue = 'colorbar', $
                                       scr_xsize = state.draw_window_size[0], $
                                       scr_ysize = state.colorbar_height)

; Create the widgets on screen

widget_control, base, /realize
widget_control, state.pan_widget_id, draw_motion_events = 0

; Make the "Image # =" and Scale droplist widgets insensitive until
; image is loaded

;widget_control, state.scale_mode_droplist_id, sensitive = 0
;widget_control, state.curimnum_text_id, sensitive = 0

; get the window ids for the draw widgets

widget_control, track_window, get_value = tmp_value
state.track_window_id = tmp_value
widget_control, state.draw_widget_id, get_value = tmp_value
state.draw_window_id = tmp_value
widget_control, state.pan_widget_id, get_value = tmp_value
state.pan_window_id = tmp_value
widget_control, state.colorbar_widget_id, get_value = tmp_value
state.colorbar_window_id = tmp_value

; set the event handlers

widget_control, top_menu, event_pro = 'smtv_topmenu_event'
widget_control, state.draw_widget_id, event_pro = 'smtv_draw_color_event'
widget_control, state.draw_base_id, event_pro = 'smtv_draw_base_event'
widget_control, state.keyboard_text_id, event_pro = 'smtv_keyboard_event'
widget_control, state.pan_widget_id, event_pro = 'smtv_pan_event'

; Find window padding sizes needed for resizing routines.
; Add extra padding for menu bar, since this isn't included in 
; the geometry returned by widget_info.
; Also add extra padding for margin (frame) in draw base.

basegeom = widget_info(state.base_id, /geometry)
drawbasegeom = widget_info(state.draw_base_id, /geometry)

;state.base_pad[0] = basegeom.xsize - drawbasegeom.xsize $
;  + (2 * basegeom.margin)
;state.base_pad[1] = basegeom.ysize - drawbasegeom.ysize + 30 $
;  + (2 * basegeom.margin)

;state.base_min_size = [state.base_pad[0] + state.base_min_size[0], $
;                       state.base_pad[1] + 100]

; Initialize the vectors that hold the current color table.
; See the routine smtv_stretchct to see why we do it this way.

r_vector = bytarr(state.ncolors)
g_vector = bytarr(state.ncolors)
b_vector = bytarr(state.ncolors)

smtv_getct, 0
state.invert_colormap = 0

; Create a pixmap window to hold the pan image
window, /free, xsize=state.pan_window_size, ysize=state.pan_window_size, $
  /pixmap
state.pan_pixmap = !d.window
smtv_resetwindow

smtv_colorbar

; improvements as of v1.4:
widget_control, state.base_id, tlb_get_size=tmp_event
state.base_pad = tmp_event - state.draw_window_size

;load wavelength & coords files

;check if there
defsysv, '!sm_sl_wavesamp_wave_f', exists = i

if (i eq 1) then begin
   print,'Defining wavesamps..'
   sl_wavelength=readfits(!sm_sl_wavesamp_wave_f)
   sh_wavelength=readfits(!sm_sh_wavesamp_wave_f)
   ll_wavelength=readfits(!sm_ll_wavesamp_wave_f)
   lh_wavelength=readfits(!sm_lh_wavesamp_wave_f)

   sl_offset=readfits(!sm_sl_wavesamp_offset_f)
   sh_offset=readfits(!sm_sh_wavesamp_offset_f)
   ll_offset=readfits(!sm_ll_wavesamp_offset_f)
   lh_offset=readfits(!sm_lh_wavesamp_offset_f)
endif else begin
    res = dialog_message('WARNING: Smart is not running. Some features might not work.', /error, dialog_parent=state.base_id)
endelse

;if state.smart eq 1 then

end

;--------------------------------------------------------------------

pro smtv_colorbar

; Routine to tv the colorbar at the bottom of the smtv window

common smtv_state

smtv_setwindow, state.colorbar_window_id

xsize = (widget_info(state.colorbar_widget_id, /geometry)).xsize

b = congrid( findgen(state.ncolors), xsize) + 8
c = replicate(1, state.colorbar_height)
a = b # c

tv, a

smtv_resetwindow

end

;--------------------------------------------------------------------

pro smtv_shutdown, windowid

; routine to kill the smtv window(s) and clear variables to conserve
; memory when quitting smtv.  The windowid parameter is used when
; smtv_shutdown is called automatically by the xmanager, if smtv is
; killed by the window manager.

common smtv_images
common smtv_state
common smtv_color
common smtv_pdata

; Kill top-level base if it still exists
if (xregistered ('smtv')) then widget_control, state.base_id, /destroy

; Destroy all pointers to plots and their heap variables
if (nplot GT 0) then begin
    smtverase, /norefresh
endif

if (size(state, /tname) EQ 'STRUCT') then begin
    if (!d.name EQ state.graphicsdevice) then wdelete, state.pan_pixmap
    if (ptr_valid(state.head_ptr)) then ptr_free, state.head_ptr
    if (ptr_valid(state.astr_ptr)) then ptr_free, state.astr_ptr
endif

delvarx, plot_ptr
delvarx, main_image
delvarx, display_image
delvarx, scaled_image
delvarx, blink_image1
delvarx, blink_image2
delvarx, blink_image3
delvarx, unblink_image
delvarx, pan_image
delvarx, r_vector
delvarx, g_vector
delvarx, b_vector
delvarx, state

return    
end

;--------------------------------------------------------------------
;                  main smtv event loops
;--------------------------------------------------------------------

pro smtv_topmenu_event, event

; Event handler for top menu

common smtv_state
common smtv_images

widget_control, event.id, get_uvalue = event_name

if (!d.name NE state.graphicsdevice and event_name NE 'Quit') then return
if (state.bitdepth EQ 24) then true = 1 else true = 0

; Need to get active window here in case mouse goes to menu from top
; of smtv window without entering the main base
smtv_getwindow

case event_name of
    
; File menu options:
    'ReadFits': begin
        smtv_readfits, newimage=newimage

        if (newimage EQ 1) then begin
            smtv_getstats
            smtv_settitle
            state.zoom_level =  0
            state.zoom_factor = 1.0
            if (state.default_autoscale EQ 1) then smtv_autoscale
            smtv_set_minmax
            smtv_displayall
        endif
    end
    'WriteFits': smtv_writefits
    'WritePS' : smtv_writeps
    'WriteImage': smtv_writeimage
    'Quit':     smtv_shutdown
; ColorMap menu options:            
    'Grayscale': smtv_getct, 0
    'Blue-White': smtv_getct, 1
    'GRBW': smtv_getct, 2
    'Red-Orange': smtv_getct, 3
    'BGRY': smtv_getct, 4
    'Standard Gamma-II': smtv_getct, 5
    'Prism': smtv_getct, 6
    'Red-Purple': smtv_getct, 7
    'Green-White': smtv_getct, 8
    'Blue-Red': smtv_getct, 11
    '16 Level': smtv_getct, 12
    'Rainbow': smtv_getct, 13
    'Stern Special': smtv_getct, 15
    'Haze' : smtv_getct, 16
    'Blue-Pastel-Red': smtv_getct, 17
    'Mac': smtv_getct, 25
    'Plasma': smtv_getct, 32
    'Blue-Red 2': smtv_getct, 33
    'Rainbow18': smtv_getct, 38
    'SMTV Special': smtv_makect, event_name
; Scaling options:
    'Linear': begin
        state.scaling = 0
        smtv_displayall
    end
    'Log': begin
        state.scaling = 1
        smtv_displayall
    end

    'HistEq': begin
        state.scaling = 2
        smtv_displayall
    end

; Label options:
    'TextLabel': smtv_textlabel
    'Arrow': smtv_arrowlabel
    'Contour': smtv_oplotcontour
    'Compass': smtv_setcompass
    'ScaleBar': smtv_setscalebar
;<<<<<<< smtv_jb.pro
    'Region': smtv_regionlabel
    'WCS Grid': smtv_wcsgridlabel
;=======
    'Draw Extraction': BEGIN
        IF (state.oplot EQ 0) THEN BEGIN
            state.oplot=1
            smtv_displaymain
        ENDIF ELSE BEGIN
            state.oplot=0
            smtv_displaymain
        ENDELSE
    END
    'Draw Wavsamp': BEGIN
        IF (state.wavsamp EQ 0) THEN BEGIN
            state.wavsamp=1
            smtv_displaymain
        ENDIF ELSE BEGIN
            state.wavsampfile=''
            state.wavsamp=0
            smtv_displaymain
        ENDELSE
    END
;>>>>>>> smtv_ks.pro
    'EraseLast': smtverase, 1
    'EraseAll': begin 
        smtverase
        state.wavsamp=0
        state.oplot=0
        smtv_refresh
    end
; Blink options:
    'SetBlink1': begin   
        smtv_setwindow, state.draw_window_id
        blink_image1 = tvrd(true = true) 
        state.title_blink1 = state.window_title
    end
    'SetBlink2': begin   
        smtv_setwindow, state.draw_window_id
        blink_image2 = tvrd(true = true)
        state.title_blink2 = state.window_title
    end
    'SetBlink3': begin   
        smtv_setwindow, state.draw_window_id
        blink_image3 = tvrd(true = true)
        state.title_blink3 = state.window_title
    end

; Zoom options:
    'Zoom In': smtv_zoom, 'in'
    'Zoom Out': smtv_zoom, 'out'
    '1/16': smtv_zoom, 'onesixteenth'
    '1/8': smtv_zoom, 'oneeighth
    '1/4': smtv_zoom, 'onefourth'
    '1/2': smtv_zoom, 'onehalf'
    '1': smtv_zoom, 'one'
    '2': smtv_zoom, 'two'
    '4': smtv_zoom, 'four'
    '8': smtv_zoom, 'eight'
    '16': smtv_zoom, 'sixteen'
    'Center': begin
        state.centerpix = round(state.image_size[0:1] / 2.)
        smtv_refresh
    end
    'None': smtv_invert, 'none'
    'Invert X': smtv_invert, 'x'
    'Invert Y': smtv_invert, 'y'
    'Invert X & Y': smtv_invert, 'xy'
    'Rotate': smtv_rotate, '0', /get_angle
    '0 deg': smtv_rotate, '0'
    '90 deg': smtv_rotate, '90'
    '180 deg': smtv_rotate, '180'
    '270 deg': smtv_rotate, '270'

; Info options:
    'Photometry': smtv_apphot
    'ImageHeader': smtv_headinfo
    'Statistics': smtv_showstats
    'Pixel Table': smtv_pixtable
    'Load Regions': smtv_regionfilelabel
    'Save Regions': smtv_saveregion
    'Archive Image': smtv_getimage

; Coordinate system options:
    '--------------':
    'RA,dec (J2000)': BEGIN 
       state.display_coord_sys = 'RA--'
       state.display_equinox = 'J2000'
       state.display_base60 = 1B
       smtv_gettrack             ; refresh coordinate window
    END 
    'RA,dec (B1950)': BEGIN 
       state.display_coord_sys = 'RA--'
       state.display_equinox = 'B1950'
       state.display_base60 = 1B
       smtv_gettrack             ; refresh coordinate window
    END
    'RA,dec (J2000) deg': BEGIN 
       state.display_coord_sys = 'RA--'
       state.display_equinox = 'J2000'
       state.display_base60 = 0B
       smtv_gettrack             ; refresh coordinate window
    END 
    'Galactic': BEGIN 
       state.display_coord_sys = 'GLON'
       smtv_gettrack             ; refresh coordinate window
    END 
    'Ecliptic (J2000)': BEGIN 
       state.display_coord_sys = 'ELON'
       state.display_equinox = 'J2000'
       smtv_gettrack             ; refresh coordinate window
    END 
    'Native': BEGIN 
       IF (state.wcstype EQ 'angle') THEN BEGIN 
          state.display_coord_sys = strmid((*state.astr_ptr).ctype[0], 0, 4)
          state.display_equinox = state.equinox
          smtv_gettrack          ; refresh coordinate window
       ENDIF 
    END 
    
    'Mosaic': BEGIN
                                ;check that image is indeed a stacked image
        IF ((state.image_size)[2] GT 1) THEN BEGIN
            IF (state.mosaic EQ 0) THEN BEGIN
                main_image_backup=main_image_stack
;                main_image=SM_MOSAIC(main_image_stack)                         ;DGW 29 August 2005
                main_image=SM_MOSAIC(main_image_stack,bmask_image_stack,bmask_mosaic=bmask_mosaic)    ;DGW 29 August 2005
                main_image_stack=main_image 
                bmask_image = bmask_mosaic                                                            ;DGW 29 August 2005
                widget_control, state.curimnum_base_id,map=0,xsize=1,ysize=1
                state.mosaic=1
            ENDIF ELSE BEGIN
                main_image_stack = main_image_backup
                main_image = main_image_stack[*, *, 0]
                state.image_size = (size(main_image_stack))[1:3]
                state.cur_image_num = 0
                widget_control,state.curimnum_base_id,map=1,xsize=585,ysize=45
                widget_control, state.curimnum_text_id, sensitive = 1, $
                                set_value = 0
                widget_control, state.curimnum_slidebar_id, sensitive = 1, $
                                set_value = 0, set_slider_min = 0, $
                                set_slider_max = state.image_size[2]-1
                widget_control, state.scale_mode_droplist_id, sensitive = 1
                state.mosaic=0
            ENDELSE               
            smtv_getstats
            smtv_settitle
            state.zoom_level =  0
            state.zoom_factor = 1.0
            if (state.default_autoscale EQ 1) then smtv_autoscale
            smtv_set_minmax
            smtv_displayall
        ENDIF ELSE BEGIN
                                ;image is not a 3D image
        ENDELSE
    END
    
    'Add to PM':smtv_addtopm

; Help options:            
    'SMTV Help': smtv_help
    
    else: print, 'Unknown event in file menu!'
endcase

; Need to test whether smtv is still alive, since the quit option
; might have been selected.        
if (xregistered('smtv', /noshow)) then smtv_resetwindow

end

;--------------------------------------------------------------------

pro smtv_addtopm

@smart_proj
   common smtv_state
   common smtv_images

   dims = size(main_image,/dimensions)

   ;;Build the data record
   rec = {smart_dr, $
          id:state.imagename, $
          files:ptr_new('none'), $
          noise:ptr_new(fltarr(dims[0],dims[1])), $
          data:ptr_new(main_image), $
          bmask:ptr_new(fltarr(dims[0],dims[1])), $
          header:state.head_ptr, $
          stacked:'no', $
          stackid:0, $
          datatype:'ARCHIVEIMAGE', $
          idea:ptr_new('none') $
         }


   if xregistered('pmw') then begin
      sel=widget_info(smp_wList,/LIST_SELECT)
      if sel eq -1 then dump=dialog_message('Please select a dataset',/info) else begin
         if not XRegistered('smartproj_show') then $
           (*smp_list)[sel[0]] -> Show
         (*smp_list)[sel[0]] -> Add, data_record=ptr_new(rec),/skip_preset_bcd
      endelse
   endif
end

;--------------------------------------------------------------------

pro smtv_draw_color_event, event

; Event handler for color mode

common smtv_state
common smtv_images

if (!d.name NE state.graphicsdevice) then return

case event.type of
    0: begin           ; button press
        if (event.press EQ 1) then begin
            state.cstretch = 1
            smtv_stretchct, event.x, event.y, /getmouse
            smtv_colorbar
        endif else begin
            smtv_zoom, 'none', /recenter
        endelse
    end
    1: begin
        state.cstretch = 0  ; button release
        if (state.bitdepth EQ 24) then smtv_refresh
        smtv_draw_motion_event, event
    end
    2: begin                ; motion event
        if (state.cstretch EQ 1) then begin
            smtv_stretchct, event.x, event.y, /getmouse 
            if (state.bitdepth EQ 24) then smtv_refresh, /fast
        endif else begin 
            smtv_draw_motion_event, event
        endelse
    end 
endcase

widget_control, state.keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro smtv_draw_zoom_event, event

; Event handler for zoom mode

common smtv_state
 
if (!d.name NE state.graphicsdevice) then return

if (event.type EQ 0) then begin 
    case event.press of
        1: smtv_zoom, 'in', /recenter
        2: smtv_zoom, 'none', /recenter
        4: smtv_zoom, 'out', /recenter
    endcase
endif

if (event.type EQ 2) then smtv_draw_motion_event, event

widget_control, state.keyboard_text_id, /sensitive, /input_focus

end

;---------------------------------------------------------------------

pro smtv_draw_blink_event, event

; Event handler for blink mode

common smtv_state
common smtv_images

if (!d.name NE state.graphicsdevice) then return
if (state.bitdepth EQ 24) then true = 1 else true = 0

case event.type of
    0: begin                    ; button press
        smtv_setwindow, state.draw_window_id
                                ; define the unblink image if needed
        if ((state.newrefresh EQ 1) AND (state.blinks EQ 0)) then begin
            unblink_image = tvrd(true = true)
            state.newrefresh = 0
        endif
        
        case event.press of
            1: if n_elements(blink_image1) GT 1 then begin
              tv, blink_image1, true = true
              widget_control, state.base_id, $
                tlb_set_title = state.title_blink1
               endif
            2: if n_elements(blink_image2) GT 1 then begin
              tv, blink_image2, true = true
              widget_control, state.base_id, $
                tlb_set_title = state.title_blink2              
               endif
            4: if n_elements(blink_image3) GT 1 then begin
              tv, blink_image3, true = true  
              widget_control, state.base_id, $
                tlb_set_title = state.title_blink3              
               endif
            else: event.press = 0 ; in case of errors
        endcase
        state.blinks = (state.blinks + event.press) < 7
    end
    
    1: begin                    ; button release
        if (n_elements(unblink_image) EQ 0) then return ; just in case
        smtv_setwindow, state.draw_window_id
        state.blinks = (state.blinks - event.release) > 0

        case state.blinks of
            0: begin 
               tv, unblink_image, true = true
               widget_control, state.base_id, $
                 tlb_set_title = state.window_title   
            end
            1: if n_elements(blink_image1) GT 1 then begin
                 tv, blink_image1, true = true 
                 widget_control, state.base_id, $
                   tlb_set_title = state.title_blink1                  
               endif else begin
                 tv, unblink_image, true = true
               endelse
            2: if n_elements(blink_image2) GT 1 then begin
                 tv, blink_image2, true = true 
                 widget_control, state.base_id, $
                   tlb_set_title = state.title_blink2
               endif else begin
                 tv, unblink_image, true = true
               endelse 
           3: if n_elements(blink_image1) GT 1 then begin
                tv, blink_image1, true = true
                widget_control, state.base_id, $
                  tlb_set_title = state.title_blink1
              endif else if n_elements(blink_image2) GT 1 then begin
                tv, blink_image2, true = true
              endif else begin
                tv, unblink_image, true = true
            endelse
            4: if n_elements(blink_image3) GT 1 then begin
                 tv, blink_image3, true = true 
                 widget_control, state.base_id, $
                   tlb_set_title = state.window_title
               endif else begin
                 tv, unblink_image, true = true
               endelse
            5: if n_elements(blink_image1) GT 1 then begin
                tv, blink_image1, true = true 
                widget_control, state.base_id, $
                  tlb_set_title = state.title_blink1
            endif else if n_elements(blink_image3) GT 1 then begin
                tv, blink_image3, true = true
            endif else begin
                tv, unblink_image, true = true
            endelse 
            6: if n_elements(blink_image2) GT 1 then begin
                tv, blink_image2, true = true
                widget_control, state.base_id, $
                  tlb_set_title = state.title_blink2
            endif else if n_elements(blink_image4) GT 1 then begin
                tv, blink_image4, true = true
                widget_control, state.base_id, $
                  tlb_set_title = state.title_blink3
            endif else begin
                tv, unblink_image, true = true
            endelse
            else: begin         ; check for errors
                state.blinks = 0
                tv, unblink_image, true = true
            end
        endcase
    end
    2: smtv_draw_motion_event, event ; motion event
endcase

widget_control, state.keyboard_text_id, /sensitive, /input_focus
smtv_resetwindow

end

;-------------------------------------------------------------------

pro smtv_draw_phot_event, event

; Event handler for ImExam mode

common smtv_state
common smtv_images

if (!d.name NE state.graphicsdevice) then return

if (event.type EQ 0) then begin
    case event.press of
        1: smtv_apphot
        2: smtv_zoom, 'none', /recenter
        4: smtv_showstats
        else: 
    endcase
endif

if (event.type EQ 2) then smtv_draw_motion_event, event

widget_control, state.draw_widget_id, /clear_events
widget_control, state.keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------
;<<<<<<< smtv_jb.pro

pro smtv_draw_region_event, event

; Event handler for Region mode
common smtv_state
common smtv_images

if (!d.name NE state.graphicsdevice) then return

if (event.type EQ 0) then begin
    case event.press of
        1: smtv_regionlabel
        2: 
        4: 
        else: 
    endcase
endif

if (event.type EQ 2) then smtv_draw_motion_event, event

widget_control, state.draw_widget_id, /clear_events
widget_control, state.keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro smtv_draw_motion_event, event

; Event handler for motion events in draw window

common smtv_state

if (!d.name NE state.graphicsdevice) then return

tmp_event = [event.x, event.y]            
state.coord = $
  round( (0.5 >  ((tmp_event / state.zoom_factor) + state.offset) $
          < (state.image_size[0:1] - 0.5) ) - 0.5)
smtv_gettrack

;if smtv_pixtable on, then create a 5x5 array of pixel values and the 
;X & Y location strings that are fed to the pixel table 

if (xregistered('smtv_pixtable', /noshow)) then smtv_pixtable_update

end

;--------------------------------------------------------------------
;=======
pro smtv_draw_phot_event, event

; Event handler for ImExam mode

common smtv_state
common smtv_images

if (!d.name NE state.graphicsdevice) then return

if (event.type EQ 0) then begin
    case event.press of
        1: smtv_apphot
        2: smtv_zoom, 'none', /recenter
        4: smtv_showstats
        else: 
    endcase
endif

if (event.type EQ 2) then smtv_draw_motion_event, event

widget_control, state.draw_widget_id, /clear_events
widget_control, state.keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro smtv_draw_phot3d_event, event

; Event handler for ImExam3d mode

common smtv_state
common smtv_images


if (!d.name NE state.graphicsdevice) then return
if (not (xregistered('smtv_showstats3d', /noshow)) and state.image_size[2] ge 2) then begin
    if (event.type EQ 0) then begin
        case event.press of
            1: begin
                ;start new box
                if (state.s3sel[4] eq 0) then begin
                    state.s3sel[4]=1

                    state.s3sel[0]=state.coord[0]
                    state.s3sel[1]=state.coord[1]
                endif else if (state.s3sel[4] eq 1) then begin
                    state.s3sel[4]=2
                    
                    state.s3sel[2]=state.coord[0]
                    state.s3sel[3]=state.coord[1]

                    ;calculate box size
                    xsize=abs(state.s3sel[2]-state.s3sel[0])
                    ysize=abs(state.s3sel[3]-state.s3sel[1])
                    
                    if (state.s3sel[1] lt state.s3sel[3]) then begin
                        tmp=state.s3sel[1]
                        state.s3sel[1]=state.s3sel[3]
                        state.s3sel[3]=tmp
                    endif
                        
                    if (state.s3sel[0] gt state.s3sel[2]) then begin
                        tmp=state.s3sel[0]
                        state.s3sel[0]=state.s3sel[2]
                        state.s3sel[2]=tmp
                    endif

                    ;get draw widget id, draw box 
                    smtv_setwindow, state.draw_window_id
                    s=state.s3sel
                    r=[0, 0, s[0], s[1], s[0]+xsize, s[1], s[2], s[3], s[0], s[1]-ysize]
                    smtv_display_box, r

                    if (xsize mod 2) eq 0 then xsize=xsize+1
                    if (ysize mod 2) eq 0 then ysize=ysize+1

                    state.stat3dbox[0]=xsize
                    state.stat3dbox[1]=ysize

                    ;calculate center
                    state.stat3dcenter[0]=round((state.s3sel[0]+state.s3sel[2])/2)
                    state.stat3dcenter[1]=round((state.s3sel[1]+state.s3sel[3])/2)

                    ;launch stat3d
                    smtv_showstats3d

                    ;done, reset state
                    state.s3sel[4]=0
                endif
            end
            2: begin 
                state.stat3dcenter=state.cursorpos
                state.stat3dbox=[11,11]

                smtv_showstats3d
            end
            4: begin
                state.stat3dcenter=state.cursorpos
                state.stat3dbox=[11,11]

                smtv_showstats3d
            end
            else: 
        endcase
    endif
endif

if (event.type EQ 2) then smtv_draw_motion_event, event

widget_control, state.draw_widget_id, /clear_events
widget_control, state.keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------
;>>>>>>> smtv_ks.pro

pro smtv_draw_vector_event, event

; Check for left button press/depress, then get coords at point 1 and 
; point 2.  Call smtv_lineplot.  Calculate vector distance between
; endpoints and plot Vector Distance vs. Pixel Value with smtv_vectorplot

common smtv_state
common smtv_images

if (!d.name NE state.graphicsdevice) then return

smtv_setwindow, state.draw_window_id

case event.type of
    0: begin           ; button press
        if (event.press EQ 1) then begin
          state.vector_coord1[0] = state.coord[0]
          state.vector_coord1[1] = state.coord[1]

        endif else begin

        endelse
    end
    1: begin           ; button release
        state.vector_coord2[0] = state.coord[0]
        state.vector_coord2[1] = state.coord[1]
;        smtv_refresh         
;        plots,[state.vector_coord1[0],state.vector_coord2[0]], $
;              [state.vector_coord1[1],state.vector_coord2[1]],/device
        smtv_draw_motion_event, event
        smtv_vectorplot
    end
    2:  smtv_draw_motion_event, event  ; motion event
    else:
endcase

widget_control, state.draw_widget_id, /clear_events
widget_control, state.keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro smtv_draw_base_event, event

; event handler for exit events of main draw base.  There's no need to
; define enter events, since as soon as the pointer enters the draw
; window the motion event will make the text widget sensitive again.
; Enter/exit events are often generated incorrectly, anyway.

common smtv_state

if (event.enter EQ 0) then begin
    widget_control, state.keyboard_text_id, sensitive = 0
endif

end

;----------------------------------------------------------------------

pro smtv_keyboard_event, event

; Event procedure for keyboard input when the cursor is in the 
; main draw window.

common smtv_state

eventchar = string(event.ch)

if (!d.name NE state.graphicsdevice and eventchar NE 'q') then return

case eventchar of
    '1': smtv_move_cursor, eventchar
    '2': smtv_move_cursor, eventchar
    '3': smtv_move_cursor, eventchar
    '4': smtv_move_cursor, eventchar
    '6': smtv_move_cursor, eventchar
    '7': smtv_move_cursor, eventchar
    '8': smtv_move_cursor, eventchar
    '9': smtv_move_cursor, eventchar
    'r': smtv_rowplot
    'c': smtv_colplot
    's': smtv_surfplot
    't': smtv_contourplot
    'g': smtv_regionlabel
    'h': smtv_histplot
    'j': smtv_gaussrowplot
    'k': smtv_gausscolplot
    'l': if (state.image_size[2] gt 1) then begin 
           smtv_slice3dplot 
         endif else begin
           smtv_message, 'Image must be 3D for pixel slice', $
             msgtype='error', /window
           return
         endelse
    'p': smtv_apphot
    'i': smtv_showstats
    'z': smtv_pixtable
    'q': smtv_shutdown
    else:  ;any other key press does nothing
endcase

if (xregistered('smtv', /noshow)) then $
  widget_control, state.keyboard_text_id, /clear_events

end

;--------------------------------------------------------------------

pro smtv_pan_event, event

; event procedure for moving the box around in the pan window

common smtv_state

if (!d.name NE state.graphicsdevice) then return

case event.type of
    0: begin                     ; button press
        widget_control, state.pan_widget_id, draw_motion_events = 1
        smtv_pantrack, event
    end
    1: begin                     ; button release
        widget_control, state.pan_widget_id, draw_motion_events = 0
        widget_control, state.pan_widget_id, /clear_events
        smtv_pantrack, event
        smtv_refresh
    end
    2: begin
        smtv_pantrack, event     ; motion event
        widget_control, state.pan_widget_id, /clear_events
    end
    else:
endcase

end

;--------------------------------------------------------------------

pro smtv_draw_linesplot_event, event

common smtv_state

case event.press of

    1: begin
        case state.linesbox[4] of
            ;1st press, take down first point
            0: begin                
                state.linesbox[0]=state.coord[0]
                state.linesbox[1]=state.coord[1]
                state.linesbox[4]=1
            end

           ;2nd press, take down second point, reset
            1: begin
                state.linesbox[2]=state.coord[0]
                state.linesbox[3]=state.coord[1]    
                state.linesbox[4]=0         
                
                ;plot line
                smtv_setwindow, state.draw_window_id
                smtv_display_box, [0., 0., state.linesbox[0], state.linesbox[1], $
                                  state.linesbox[0], state.linesbox[1], $ 
                                  state.linesbox[2], state.linesbox[3], $
                                  state.linesbox[0], state.linesbox[1]]
                
                ;run plot window
                smtv_linesplot
            end
        endcase
        
        if (state.oplot eq 1) then thick= zoom*0.02
    end
    else: begin
    end
endcase

if (event.type EQ 2) then smtv_draw_motion_event, event

widget_control, state.draw_widget_id, /clear_events
widget_control, state.keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro smtv_event, event

; Main event loop for smtv top-level base, and for all the buttons.

common smtv_state
common smtv_images
common smtv_color

widget_control, event.id, get_uvalue = uvalue

if (!d.name NE state.graphicsdevice and uvalue NE 'done') then return

; Get currently active window
smtv_getwindow

case uvalue of

    'smtv_base': begin     
        c = where(tag_names(event) EQ 'ENTER', count)
        if (count EQ 0) then begin       ; resize event
            smtv_resize
            smtv_refresh
        endif
    end

    'mode': case event.index of
        0: widget_control, state.draw_widget_id, $
          event_pro = 'smtv_draw_color_event'
        1: widget_control, state.draw_widget_id, $
          event_pro = 'smtv_draw_zoom_event'
        2: widget_control, state.draw_widget_id, $
          event_pro = 'smtv_draw_blink_event'
        3: widget_control, state.draw_widget_id, $
;<<<<<<< smtv_jb.pro
          event_pro = 'smtv_draw_phot_event'
        6: widget_control, state.draw_widget_id, $         DGW 29 August 2005
          event_pro = 'smtv_draw_region_event'
        5: widget_control, state.draw_widget_id, $         DGW 29 August 2005
          event_pro = 'smtv_draw_vector_event'
;=======
          ;event_pro = 'smtv_draw_linesplot_event'
;        5: widget_control, state.draw_widget_id, $        DGW 29 August 2005
;          event_pro = 'smtv_draw_linesplot_event'         DGW 29 August 2005
          ;event_pro = 'smtv_draw_phot_event'
        4: widget_control, state.draw_widget_id, $
          event_pro = 'smtv_draw_phot3d_event'
;>>>>>>> smtv_ks.pro
        else: print, 'Unknown mouse mode!'
    endcase

    'invert': begin                  ; invert the color table
        state.invert_colormap = abs(state.invert_colormap - 1)

        r_vector = reverse(r_vector)
        g_vector = reverse(g_vector)
        b_vector = reverse(b_vector)

        smtv_stretchct, state.brightness, state.contrast
        if (state.bitdepth EQ 24) then smtv_refresh
    end
    
    'restretch_button': smtv_restretch

    'min_text': begin     ; text entry in 'min = ' box
        smtv_get_minmax, uvalue, event.value
        smtv_displayall
    end

    'max_text': begin     ; text entry in 'max = ' box
        smtv_get_minmax, uvalue, event.value
        smtv_displayall
    end

    'curimnum_text':begin    ; text entry in 'Image #=' box

; Check event.value
; If event.value < 0 then image=current image
; If event.value > MAX(#planes in 3D) then image=current image
; Change value in "Image # =" box back to current image when outside limits
; Issue warning popup to enter value between 0 and top image plane

      IF (event.value ge 0 AND $
          event.value lt (state.image_size[2])) THEN BEGIN

        state.cur_image_num = event.value
        widget_control, state.curimnum_text_id, $
                                set_value = string(state.cur_image_num)
        widget_control, state.curimnum_slidebar_id, $
                                set_value = state.cur_image_num
        main_image = main_image_stack[*, *, state.cur_image_num]
        bmask_image = bmask_image_stack[*, *, state.cur_image_num]
;<<<<<<< smtv_jb.pro
;        smtv_getstats, /align
;=======
        state.imagename = names_stack[state.cur_image_num]
        state.head_ptr=ptr_new(*header_stack[state.cur_image_num])
        smtv_getstats,/align
;>>>>>>> smtv_ks.pro
        case state.curimnum_minmaxmode of
         'Min/Max': begin
           state.min_value = state.image_min
           state.max_value = state.image_max
         end
         'AutoScale': smtv_autoscale
         'Constant': donothingvariable = 0
         else: print, 'Unknown Min/Max mode for changing cur_image_num!'
        endcase
        state.title_extras = strcompress('Plane ' +string(state.cur_image_num))
        smtv_settitle
        smtv_set_minmax
        smtv_displayall

      ENDIF ELSE BEGIN
        state.cur_image_num = state.cur_image_num
        widget_control, state.curimnum_text_id, $
                                set_value = string(state.cur_image_num)
        text_warn = 'Please enter a value between 0 and ' + $
                     strcompress(string(state.image_size[2] -1))
        smtv_message, text_warn, msgtype='error', /window
      ENDELSE

    end

    'curimnum_slidebar':begin    ; slidebar controlling cur_image_num
        state.cur_image_num = event.value
        widget_control, state.curimnum_text_id, $
                                set_value = string(state.cur_image_num)
        widget_control, state.curimnum_slidebar_id, $
                                set_value = state.cur_image_num
        main_image = main_image_stack[*, *, state.cur_image_num]
        bmask_image = bmask_image_stack[*,*, state.cur_image_num]
;<<<<<<< smtv_jb.pro
;        smtv_getstats, /align
;=======
        state.imagename = names_stack[state.cur_image_num]

;        state.head_ptr=ptr_new(*header_stack[state.cur_image_num]) ; PH 29 Aug. 2005 
        smtv_setheader, *header_stack[state.cur_image_num]          ; PH 29 Aug. 2005

        smtv_getstats,/align
;>>>>>>> smtv_ks.pro
        case state.curimnum_minmaxmode of
         'Min/Max': begin
           state.min_value = state.image_min
           state.max_value = state.image_max
         end
         'AutoScale': smtv_autoscale
         'Constant': donothingvariable = 0
         else: print, 'Unknown Min/Max mode for changing cur_image_num!'
        endcase
        state.title_extras = strcompress('Plane ' +string(state.cur_image_num))
        smtv_settitle
        smtv_set_minmax
        smtv_displayall
    end

    'curimnum_minmaxmode': case event.index of
        2: begin
             state.curimnum_minmaxmode = 'Min/Max'
             state.min_value = state.image_min
             state.max_value = state.image_max
             smtv_set_minmax
             smtv_displayall
        end
        1: begin
             state.curimnum_minmaxmode = 'AutoScale'
             smtv_autoscale
             smtv_set_minmax
             smtv_displayall
        end
        0: state.curimnum_minmaxmode = 'Constant'
        else: print, 'Unknown Min/Max mode for changing cur_image_num!'
    endcase

    'autoscale_button': begin   ; autoscale the image
        smtv_autoscale
        smtv_displayall
    end

    'full_range': begin    ; display the full intensity range
        state.min_value = state.image_min
        state.max_value = state.image_max
        if state.min_value GE state.max_value then begin
            state.min_value = state.max_value - 1
            state.max_value = state.max_value + 1
        endif
        smtv_set_minmax
        smtv_displayall
    end
    
    'zoom_in':  smtv_zoom, 'in'         ; zoom buttons
    'zoom_out': smtv_zoom, 'out'
    'zoom_one': smtv_zoom, 'one'

    'center': begin   ; center image and preserve current zoom level
        state.centerpix = round(state.image_size[0:1] / 2.)
        smtv_refresh
    end

    'done':  smtv_shutdown

    else:  print, 'No match for uvalue....'  ; bad news if this happens

endcase
end

;----------------------------------------------------------------------

pro smtv_message, msg_txt, msgtype=msgtype, window=window

; Routine to display an error or warning message.  Message can be
; displayed either to the IDL command line or to a popup window,
; depending on whether /window is set.
; msgtype must be 'warning', 'error', or 'information'.

common smtv_state

if (n_elements(window) EQ 0) then window = 0

if (window EQ 1) then begin  ; print message to popup window
    case msgtype of
        'warning': t = dialog_message(msg_txt, dialog_parent = state.base_id)
        'error': t = $
          dialog_message(msg_txt,/error,dialog_parent=state.base_id)
        'information': t = $
          dialog_message(msg_txt,/information,dialog_parent=state.base_id)
        else: 
    endcase
endif else begin           ;  print message to IDL console
    message = strcompress(strupcase(msgtype) + ': ' + msg_txt)
    print, message
endelse

end

;-----------------------------------------------------------------------
;      main smtv routines for scaling, displaying, cursor tracking...
;-----------------------------------------------------------------------

pro smtv_displayall

; Call the routines to scale the image, make the pan image, and
; re-display everything.  Use this if the scaling changes (log/
; linear/ histeq), or if min or max are changed, or if a new image is
; passed to smtv.  If the display image has just been moved around or
; zoomed without a change in scaling, then just call smtv_refresh
; rather than this routine.

smtv_scaleimage
smtv_makepan
smtv_settitle
smtv_refresh

end

;---------------------------------------------------------------------

pro smtv_refresh, fast = fast

; Make the display image from the scaled_image, and redisplay the pan
; image and tracking image. 
; The /fast option skips the steps where the display_image is
; recalculated from the main_image.  The /fast option is used in 24
; bit color mode, when the color map has been stretched but everything
; else stays the same.

common smtv_state
common smtv_images

smtv_getwindow
if (not(keyword_set(fast))) then begin
    smtv_getoffset
    smtv_getdisplay
    smtv_displaymain
    smtv_plotall
endif else begin
    smtv_displaymain
endelse

; redisplay the pan image and plot the boundary box
smtv_setwindow, state.pan_pixmap
erase
tv, pan_image, state.pan_offset[0], state.pan_offset[1]
smtv_resetwindow

smtv_setwindow, state.pan_window_id
if (not(keyword_set(fast))) then erase
tv, pan_image, state.pan_offset[0], state.pan_offset[1]
smtv_resetwindow
smtv_drawbox, /norefresh

if (state.bitdepth EQ 24) then smtv_colorbar

; redisplay the tracking image
if (not(keyword_set(fast))) then smtv_gettrack

smtv_resetwindow

state.newrefresh = 1
end

;--------------------------------------------------------------------

pro smtv_getdisplay

; make the display image from the scaled image by applying the zoom
; factor and matching to the size of the draw window, and display the
; image.

common smtv_state
common smtv_images

widget_control, /hourglass   

display_image = bytarr(state.draw_window_size[0], state.draw_window_size[1])

view_min = round(state.centerpix - $
                  (0.5 * state.draw_window_size / state.zoom_factor))
view_max = round(view_min + state.draw_window_size / state.zoom_factor)

view_min = (0 > view_min < (state.image_size[0:1] - 1)) 
view_max = (0 > view_max < (state.image_size[0:1] - 1)) 

newsize = round( (view_max - view_min + 1) * state.zoom_factor) > 1
startpos = abs( round(state.offset * state.zoom_factor) < 0)

tmp_image = congrid(scaled_image[view_min[0]:view_max[0], $
                                 view_min[1]:view_max[1]], $
                    newsize[0], newsize[1])


xmax = newsize[0] < (state.draw_window_size[0] - startpos[0])
ymax = newsize[1] < (state.draw_window_size[1] - startpos[1])

display_image[startpos[0], startpos[1]] = tmp_image[0:xmax-1, 0:ymax-1]
delvarx, tmp_image

end

;-----------------------------------------------------------------------

PRO smtv_display_box, r

;Draws a box specified by array r, which contains the coordinates of
;the vertices

COMMON smtv_state
COMMON smtv_images

pos  = round(state.offset * state.zoom_factor)
zoom = state.zoom_factor
color= !P.COLOR

thick = zoom*0.02
;if (state.oplot eq 1) then thick= zoom*0.02

;shifts in position
dx   = -pos(0)
dy   = -pos(1)

;rescaling rectangle
r = r*zoom

;subtract 0.5 as wavesamp assumes 0 is lh corner of pixel and
;idl assumes 0 is centre of bottom pixel
r=r-0.5
 

;plot the rectangle
PLOTS, [r(2)+dx, r(4)+dx], [r(3)+dy, r(5)+dy], THICK=thick, COLOR=color, /DEVICE
PLOTS, [r(4)+dx, r(6)+dx], [r(5)+dy, r(7)+dy], THICK=thick, COLOR=color, /DEVICE
PLOTS, [r(6)+dx, r(8)+dx], [r(7)+dy, r(9)+dy], THICK=thick, COLOR=color, /DEVICE
PLOTS, [r(8)+dx, r(2)+dx], [r(9)+dy, r(3)+dy], THICK=thick, COLOR=color, /DEVICE

END

;-----------------------------------------------------------------------

pro smtv_oplot
;#> .dc1
;Overplots rectangles on extractions based on data array defined by a 
;system variable pointer.
;#<

common smtv_state

if (ptr_valid(!sm_smtv_cext)) then  begin
                                ;extract data from pointer
    data=*!sm_smtv_cext
                                ;count nr. of entries in WAVSAMP file
    num = N_ELEMENTS(data.x0)
    
    for i=0, num-1 do begin
        r=[data.xcenter(i), data.ycenter(i), $
           data.x0(i), data.y0(i), $
           data.x1(i), data.y1(i), $ 
           data.x2(i), data.y2(i), $
           data.x3(i), data.y3(i)]
                                ;display the box
        smtv_display_box, r
    endfor
endif else begin
    res=dialog_message('ERROR: No valid extraction data to oplot in SMTV')
    state.oplot=0
endelse
end

;-----------------------------------------------------------------------

PRO smtv_loadrectangles

;loads rectangles from WAVSAMP file

COMMON smtv_state

;If the file has a header, try to load standard WAVSAMP file
file = state.wavsampfile
IF (ptr_valid(state.head_ptr) AND state.wavsampfile EQ '') THEN BEGIN
    h = *(state.head_ptr)
    chnlnum = SXPAR(h, 'CHNLNUM', COUNT=count)

    ;There is a header and it contains a channel number
    ;=>load default wavsamp files
    IF (count GT 0 AND chnlnum GE 0 AND chnlnum LE 3) THEN BEGIN

        ;if smtv is run in smart, load from system variables
        IF (state.smart EQ 1) THEN BEGIN
            IF (chnlnum EQ 0) THEN file=!sm_sl_wavesamp_f
            IF (chnlnum EQ 1) THEN file=!sm_sh_wavesamp_f
            IF (chnlnum EQ 2) THEN file=!sm_ll_wavesamp_f
            IF (chnlnum EQ 3) THEN file=!sm_lh_wavesamp_f
        ENDIF ELSE BEGIN
            path='/home/data/SMART/wavsamp/'
            IF (chnlnum EQ 0) THEN file=path+'WAVSAMP_sl_04apr00_011016.tbl'
            IF (chnlnum EQ 1) THEN file=path+'irs_sh_wavsamp.tbl'
            IF (chnlnum EQ 2) THEN file=path+'WAVSAMP_ll_25feb00_011016.tbl'
            IF (chnlnum EQ 3) THEN file=path+'irs_b3'
        ENDELSE

       ;checking that default files exist
        test=FILE_TEST(file)
        IF (test EQ 0) THEN BEGIN
            res=DIALOG_MESSAGE('Default WAVSAMP file not found!', $
                               DIALOG_PARENT=state.base_id, $
                               /ERROR)             
            state.wavsampfile=''
            state.wavsamp=0       
            RETURN
        ENDIF       
        state.wavsampfile=file
    ENDIF

    ;There is a header but it doesnt contain a channel number
    ;=>let user load wavsamp file
    IF (count EQ 0) THEN BEGIN
        file = DIALOG_PICKFILE(FILTER = '*.*', $
                               DIALOG_PARENT = state.base_id, $
                               /MUST_EXIST, $
                               /READ, $
                               PATH = state.current_dir, $
                               GET_PATH = tmp_dir, $
                               TITLE = 'Select WAVSAMP file')
        state.wavsampfile = file
        IF (tmp_dir NE '') THEN state.current_dir = tmp_dir
        IF (file EQ '') THEN BEGIN
            state.wavsampfile=''
            state.wavsamp=0
            RETURN
        ENDIF
    ENDIF

ENDIF

;If the file doesn't have a header, let user load file
IF (NOT ptr_valid(state.head_ptr) AND state.wavsampfile EQ '') THEN BEGIN
    file = DIALOG_PICKFILE(FILTER = '*.*', $
                           DIALOG_PARENT = state.base_id, $
                           /MUST_EXIST, $
                           /READ, $
                           PATH = state.current_dir, $
                           GET_PATH = tmp_dir, $
                           TITLE = 'Select WAVSAMP file')
    state.wavsampfile = file
    IF (tmp_dir NE '') THEN state.current_dir = tmp_dir
    IF (file EQ '') THEN BEGIN
        state.wavsampfile=''
        state.wavsamp=0
        RETURN
    ENDIF
ENDIF          

res = sm_read_wavsamp(file , data, header)

;if the reading wasn't succesful, quit
IF (res EQ 1) THEN  BEGIN
    res1=DIALOG_MESSAGE('ERROR: Problem reading file '+file, $
                        DIALOG_PARENT = state.base_id, $
                        /ERROR)
    state.wavsampfile=''
    state.wavsamp=0
    RETURN
ENDIF

;count nr. of entries in WAVSAMP file
num = N_ELEMENTS(data.x0)

FOR i=0, num-1 DO BEGIN
    r=[data.xcenter(i), data.ycenter(i), $
       data.x0(i), data.y0(i), $
       data.x1(i), data.y1(i), $ 
       data.x2(i), data.y2(i), $
       data.x3(i), data.y3(i)]
    ;display the box
    smtv_display_box, r
ENDFOR

END

;-----------------------------------------------------------------------

FUNCTION smtv_mosaic, image

;get information on images
image_info=SIZE(image)

n_images=image_info(3)     ;number of images
x_size=image_info(1)       ;x-size of images
y_size=image_info(2)       ;y-size of images

;determine layout of final image by determining the smallest square possible.
square_size=1              ;size of the smallest square
n_last_row=0               ;number of images in last row

;determine size of square
i=0             ;counter
WHILE square_size*square_size LT n_images DO BEGIN
    square_size=square_size+1
ENDWHILE

;create array which will contain mosaic
mosaic=DBLARR(square_size*x_size, square_size*y_size)

;fill array up

k=0            ;counter
;rows
FOR i=0,square_size-1 DO BEGIN
    ;check if all images have been placed yet
    IF (k GT n_images-1) THEN BREAK
    
    ;columns
    FOR j=0, square_size-1 DO BEGIN
        mosaic(i*x_size:(i+1)*x_size-1,j*y_size:(j+1)*y_size-1 )=image(*, *, k)
        k=k+1
        IF (k GT n_images-1) THEN BREAK
    ENDFOR
ENDFOR

;rotate into position
mosaic=ROTATE(mosaic, 3)

RETURN, mosaic
END

;--------------------------------------------------------------------

pro smtv_displaymain

; Display the main image and overplots

common smtv_state
common smtv_images

smtv_setwindow, state.draw_window_id
tv, display_image
;change:
IF (state.wavsamp EQ 1) THEN smtv_loadrectangles
IF (state.oplot EQ 1) THEN smtv_oplot

smtv_resetwindow

end

;--------------------------------------------------------------------

pro smtv_getoffset

common smtv_state

; Routine to calculate the display offset for the current value of
; state.centerpix, which is the central pixel in the display window.

state.offset = $
  round( state.centerpix - $
         (0.5 * state.draw_window_size / state.zoom_factor) )

end

;----------------------------------------------------------------------

pro smtv_makepan

; Make the 'pan' image that shows a miniature version of the full image.

common smtv_state
common smtv_images

sizeratio = state.image_size[1] / state.image_size[0]

if (sizeratio GE 1) then begin
    state.pan_scale = float(state.pan_window_size) / float(state.image_size[1])
endif else begin
    state.pan_scale = float(state.pan_window_size) / float(state.image_size[0])
endelse

tmp_image = $
  scaled_image[0:state.image_size[0]-1, 0:state.image_size[1]-1]

pan_image = $
  congrid(tmp_image, round(state.pan_scale * state.image_size[0])>1, $
          round(state.pan_scale * state.image_size[1])>1 )

state.pan_offset[0] = round((state.pan_window_size - (size(pan_image))[1]) / 2)
state.pan_offset[1] = round((state.pan_window_size - (size(pan_image))[2]) / 2)

end

;----------------------------------------------------------------------


pro smtv_move_cursor, direction

; Use keypad arrow keys to step cursor one pixel at a time.
; Get the new track image, and update the cursor position.

common smtv_state
common smtv_images

i = 1L

case direction of
    '2': state.coord[1] = max([state.coord[1] - i, 0])
    '4': state.coord[0] = max([state.coord[0] - i, 0])
    '8': state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
    '6': state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    '7': begin
        state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
        state.coord[0] = max([state.coord[0] - i, 0])
    end
    '9': begin
        state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
        state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    end
    '3': begin
        state.coord[1] = max([state.coord[1] - i, 0])
        state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    end
    '1': begin
        state.coord[1] = max([state.coord[1] - i, 0])
        state.coord[0] = max([state.coord[0] - i, 0])
    end

endcase

newpos = (state.coord - state.offset + 0.5) * state.zoom_factor

smtv_setwindow,  state.draw_window_id
tvcrs, newpos[0], newpos[1], /device
smtv_resetwindow

smtv_gettrack

; If pixel table widget is open, update pixel values and cursor position
if (xregistered('smtv_pixtable', /noshow)) then smtv_pixtable_update

; Prevent the cursor move from causing a mouse event in the draw window
widget_control, state.draw_widget_id, /clear_events

smtv_resetwindow

end

;----------------------------------------------------------------------

pro smtv_set_minmax

; Updates the min and max text boxes with new values.

common smtv_state

widget_control, state.min_text_id, set_value = string(state.min_value)
widget_control, state.max_text_id, set_value = string(state.max_value)

end

;----------------------------------------------------------------------

pro smtv_get_minmax, uvalue, newvalue

; Change the min and max state variables when user inputs new numbers
; in the text boxes. 

common smtv_state

case uvalue of
    
    'min_text': begin
        if (newvalue LT state.max_value) then begin
            state.min_value = newvalue
        endif
    end

    'max_text': begin
        if (newvalue GT state.min_value) then begin
            state.max_value = newvalue
        endif
    end
        
endcase

smtv_set_minmax

end

;--------------------------------------------------------------------

pro smtv_zoom, zchange, recenter = recenter
common smtv_state

; Routine to do zoom in/out and recentering of image.  The /recenter
; option sets the new display center to the current cursor position.

case zchange of
    'in':    state.zoom_level = (state.zoom_level + 1) < 6
    'out':   state.zoom_level = (state.zoom_level - 1) > (-6) 
    'onesixteenth': state.zoom_level =  -4
    'oneeighth': state.zoom_level =  -3
    'onefourth': state.zoom_level =  -2
    'onehalf': state.zoom_level =  -1
    'one':   state.zoom_level =  0
    'two':   state.zoom_level =  1
    'four':  state.zoom_level =  2
    'eight': state.zoom_level =  3
    'sixteen': state.zoom_level = 4
    'none':  ; no change to zoom level: recenter on current mouse position
    else:  print,  'problem in smtv_zoom!'
endcase

state.zoom_factor = 2.^state.zoom_level

if (n_elements(recenter) GT 0) then begin
    state.centerpix = state.coord
    smtv_getoffset
endif

smtv_refresh

if (n_elements(recenter) GT 0) then begin
    newpos = (state.coord - state.offset + 0.5) * state.zoom_factor
    smtv_setwindow,  state.draw_window_id
    tvcrs, newpos[0], newpos[1], /device 
    smtv_resetwindow
    smtv_gettrack
endif

smtv_resetwindow

end

;-----------------------------------------------------------------------

pro smtv_invert, ichange
common smtv_state
common smtv_images

; Routine to do image axis-inversion (X,Y,X&Y)

case ichange of
    'x': begin
         if ptr_valid(state.head_ptr) then begin
           if (state.invert_image eq 'none') then $
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 1, /silent
           if (state.invert_image eq 'x') then return
           if (state.invert_image eq 'y') then begin
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 2, /silent             
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 1, /silent
           endif
           if (state.invert_image eq 'xy') then $
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 2, /silent   

           head = *(state.head_ptr)
           smtv_setheader, head

         endif else begin
           if (state.invert_image eq 'none') then $
             main_image = reverse(main_image)
           if (state.invert_image eq 'x') then return
           if (state.invert_image eq 'y') then begin
             main_image = reverse(main_image,2)
             main_image = reverse(main_image)   
           endif
           if (state.invert_image eq 'xy') then $
             main_image = reverse(main_image,2)
         endelse

         state.invert_image = 'x' 
    end
    'y': begin
         if ptr_valid(state.head_ptr) then begin
           if (state.invert_image eq 'none') then $
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 2, /silent
           if (state.invert_image eq 'y') then return
           if (state.invert_image eq 'x') then begin
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 1, /silent             
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 2, /silent
           endif
           if (state.invert_image eq 'xy') then $
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 1, /silent   

           head = *(state.head_ptr)
           smtv_setheader, head

         endif else begin
           if (state.invert_image eq 'none') then $
             main_image=reverse(main_image,2)
           if (state.invert_image eq 'x') then begin
             main_image = reverse(main_image)
             main_image=reverse(main_image,2)
           endif
           if (state.invert_image eq 'y') then return
           if (state.invert_image eq 'xy') then $
             main_image = reverse(main_image)
         endelse

         state.invert_image = 'y'
    end
    'xy': begin
         if ptr_valid(state.head_ptr) then begin
           if (state.invert_image eq 'none') then begin
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 1, /silent
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 2, /silent
           endif
           if (state.invert_image eq 'x') then $
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 2, /silent
           if (state.invert_image eq 'y') then $
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 1, /silent             
           if (state.invert_image eq 'xy') then return

           head = *(state.head_ptr)
           smtv_setheader, head

         endif else begin
           if (state.invert_image eq 'none') then begin
             main_image = reverse(main_image)
             main_image = reverse(main_image,2)
           endif
           if (state.invert_image eq 'x') then $
             main_image = reverse(main_image,2)
           if (state.invert_image eq 'y') then $
             main_image = reverse(main_image)
           if (state.invert_image eq 'xy') then return
         endelse

         state.invert_image = 'xy'
    end
    'none': begin ; do not invert; revert to normal (X,Y) axes view
         if ptr_valid(state.head_ptr) then begin
           if (state.invert_image eq 'none') then return
           if (state.invert_image eq 'x') then $
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 1, /silent
           if (state.invert_image eq 'y') then $
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 2, /silent             
           if (state.invert_image eq 'xy') then begin
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 1, /silent
             hreverse, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), 2, /silent
           endif

           head = *(state.head_ptr)
           smtv_setheader, head

         endif else begin
           if (state.invert_image eq 'none') then return
           if (state.invert_image eq 'x') then $
             main_image = reverse(main_image)
           if (state.invert_image eq 'y') then $
             main_image = reverse(main_image,2)
           if (state.invert_image eq 'xy') then begin
             main_image = reverse(main_image)
             main_image = reverse(main_image,2)
           endif
         endelse

         state.invert_image = 'none'
    end
    else:  print,  'problem in smtv_invert!'
endcase

;Redisplay inverted image with current zoom, update pan, and refresh image
smtv_displayall

;make sure that the image arrays are updated for line/column plots, etc.
smtv_resetwindow

end

;------------------------------------------------------------------

pro smtv_rotate, rchange, get_angle=get_angle
common smtv_state
common smtv_images

; Routine to do image rotation

;--------------------------------------------------- PH 29 Aug. 2005

; Block rotation of mosaiced images

test1 = 0
test2 = 0

if (state.image_size[0] gt 128) then begin                   
    smtv_message, 'You cannot rotate a Mosaiced image',msgtype='error',/window
    test1 = 1
endif                         

if(test1 eq 0) then begin

; Block rotation of SH, LL & LH images
; (Necessary astrometry information is not in header)

test_head = *(state.head_ptr)
module = 'XX'

; Check for CHNLNUM tag

module_num_tmp=sxpar(test_head, 'CHNLNUM', count=count1)
if (count1 ge 1) then begin
    module_num = sxpar(test_head, 'CHNLNUM')
    if (module_num eq 0) then module = 'SL'
    if (module_num eq 1) then module = 'SH'
    if (module_num eq 2) then module = 'LL'
    if (module_num eq 3) then module = 'LH'
endif

; Check for SLT_TYPE tag

if(count1 eq 0) then begin
    module_tmp=sxpar(test_head, 'SLT_TYPE', count=count2)
    if (count2 ge 1) then begin
        module = sxpar(test_head, 'SLT_TYPE') 
    endif
endif

if (module eq 'SL') then test2 = 1

if (test2 eq 0) then begin 
    smtv_message, 'Must have correct astrometery keywords in header to rotate', msgtype='error',/window
endif   

if (test2 eq 1) then begin

;--------------------------------------------------- PH 29 Aug. 2005

; If /get_angle set, create widget to enter rotation angle

widget_control, /hourglass

if (keyword_set(get_angle)) then begin

  formdesc = ['0, float, 0.0, label_left=Rotation Angle: ', $
              '1, base, , row', $
              '0, button, Cancel, quit', $
              '0, button, Rotate, quit']    

  textform = cw_form(formdesc, /column, title = 'Rotate')

  if (textform.tag2 eq 1) then return
  if (textform.tag3 eq 1) then rchange = textform.tag0

endif

case rchange of
    '0': begin ; do not rotate original - back to 0 degrees rotation
         tmp_rot_angle = (state.rot_angle - 0.)

         if ptr_valid(state.head_ptr) then $
           hrot, main_image, *(state.head_ptr), $
             main_image, *(state.head_ptr), tmp_rot_angle, -1, -1, 1, mis=0 $
         else $
           main_image = rot(main_image,tmp_rot_angle,/interp)

         state.rot_angle = 0.
    end
    '90': begin ; rotate original 90 degrees
          tmp_rot_angle = (state.rot_angle - 90.)

          if ptr_valid(state.head_ptr) then $
            hrot, main_image, *(state.head_ptr), $
              main_image, *(state.head_ptr), tmp_rot_angle, -1, -1, 1, mis=0 $
          else $
            main_image = rot(main_image,tmp_rot_angle,/interp)

          state.rot_angle = 90.
    end
    '180': begin ; rotate original 180 degrees
           tmp_rot_angle = (state.rot_angle - 180.)

           if ptr_valid(state.head_ptr) then $
             hrot, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), tmp_rot_angle, -1, -1, 1, mis=0 $
           else $
             main_image = rot(main_image,tmp_rot_angle,/interp)

           state.rot_angle = 180.
    end
    '270': begin ; rotate original image 270 degrees
           tmp_rot_angle = (state.rot_angle - 270.)

           if ptr_valid(state.head_ptr) then $
             hrot, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), tmp_rot_angle, -1, -1, 1, mis=0 $
           else $
             main_image = rot(main_image,tmp_rot_angle,/interp)

           state.rot_angle = 270.
    end
    else:  begin
           tmp_rot_angle = (state.rot_angle - rchange)

           if ptr_valid(state.head_ptr) then $
             hrot, main_image, *(state.head_ptr), $
               main_image, *(state.head_ptr), tmp_rot_angle, -1, -1, 1, mis=0 $
           else $
             main_image = rot(main_image, tmp_rot_angle,/interp)

           state.rot_angle = rchange
    end

endcase

;Update header information after rotation if header is present
if ptr_valid(state.head_ptr) then begin
  head = *(state.head_ptr)
  smtv_setheader, head
endif

;Redisplay inverted image with current zoom, update pan, and refresh image
smtv_displayall

;make sure that the image arrays are updated for line/column plots, etc.
smtv_resetwindow

endif                       ;  PH 29 Aug. 2005
endif                       ;  PH 29 Aug. 2005

end

;------------------------------------------------------------------

pro smtv_getimage

common smtv_state
common smtv_images

; Retrieve DSS, 2MASS, or IRAS image from STSCI/ESO/IRSA archives and 
; load into SMTV.

formdesc = ['0, text, , label_left=Object Name: , width=15', $
            '0, label, OR, CENTER', $
            '0, text, , label_left=RA (Deg J2000): , width=15', $
            '0, text, , label_left=DEC (Deg J2000): , width=15', $
            '0, float, 10.0, label_left=Imsize (Arcminutes): ', $
            '0, droplist, DSS-STSCI|DSS-ESO|2MASS-IRSA|IRAS-IRSA, label_left=Archive:, set_value=0 ', $
            '0, droplist, 1st Generation|2nd Generation Blue|2nd Generation Red|2nd Generation Near-IR|J|H|K_s|12um|25um|60um|100um, label_left=Band:, set_value=0 ', $
            '0, button, SIMBAD|NED, set_value=0, exclusive', $
            '1, base, , row', $
            '0, button, Cancel, quit', $
            '0, button, Retrieve, quit']    

archiveform = cw_form(formdesc, /column, title = 'Get Archive Image')

if (archiveform.tag9 eq 1) then return

if (archiveform.tag10 eq 1) then begin

; First do error checking so that archive and band match

  if (strcompress(archiveform.tag0,/remove_all) eq '' AND $
      strcompress(archiveform.tag2,/remove_all) eq '' AND $
      strcompress(archiveform.tag3,/remove_all) eq '') then begin
      smtv_message,'Enter Target or Coordinates', msgtype='error', /window
    return
  endif

  if (archiveform.tag5 eq 0 OR $
      archiveform.tag5 eq 1 AND $
      archiveform.tag6 ne 0 AND $
      archiveform.tag6 ne 1 AND $
      archiveform.tag6 ne 2 AND $
      archiveform.tag6 ne 3) then begin
      smtv_message,'Select Appropriate Band for DSS', msgtype='error',/window
    return
  endif

  if (archiveform.tag5 eq 2 AND $
      archiveform.tag6 ne 4 AND $
      archiveform.tag6 ne 5 AND $
      archiveform.tag6 ne 6)then begin
      smtv_message,'Select Appropriate Band for 2MASS', msgtype='error',/window
    return
  endif

  if (archiveform.tag5 eq 3 AND $
      archiveform.tag6 ne 7 AND $
      archiveform.tag6 ne 8 AND $
      archiveform.tag6 ne 9 AND $
      archiveform.tag6 ne 10) then begin
      smtv_message,'Select Appropriate Band for IRAS', msgtype='error',/window
    return
  endif

  if (archiveform.tag4 lt 0.0) then begin
    smtv_message, 'Image Size must be > 0', msgtype='error', /window
    return
  endif
 
; Set image size defaults.  For IRAS ISSA images, imsize must be 0.5,
; 1.0, 2.5, 5.0, or 12.5

  if (strcompress(archiveform.tag4, /remove_all) ne '') then $
    imsize = float(strcompress(archiveform.tag4, /remove_all)) $
  else $
    imsize = 10.0

  if (archiveform.tag5 eq 3) then begin
    if (strcompress(archiveform.tag4, /remove_all) ne '') then begin
      imsize = float(strcompress(archiveform.tag4, /remove_all)) 
      imsize = imsize / 60.
      diff_halfdeg = abs(0.5 - imsize)
      diff_deg = abs(1.0 - imsize)
      diff_2halfdeg = abs(2.5 - imsize)
      diff_5deg = abs(5.0 - imsize)
      diff_12halfdeg = abs(12.5 - imsize)

      diff_arr = [diff_halfdeg, diff_deg, diff_2halfdeg, diff_5deg, $
                  diff_12halfdeg]

      imsize_iras = [0.5, 1.0, 2.5, 5.0, 12.5]
      index_min = where(diff_arr eq min(diff_arr))
      imsize = imsize_iras[index_min]
    endif else begin
      imsize = 1.0
    endelse
  endif

  if (archiveform.tag5 eq 0 OR archiveform.tag5 eq 1) then begin
    if (archiveform.tag4 gt 60.0) then begin
      smtv_message, 'DSS Image Size must be <= 60.0 Arcminutes', $
        msgtype='error', /window
      return
    endif
  endif

  widget_control, /hourglass
  image_str = ''

  if (strcompress(archiveform.tag0, /remove_all) ne '') then $
    image_str=strcompress(archiveform.tag0, /remove_all)

  if (strcompress(archiveform.tag2, /remove_all) ne '') then $
    ra_tmp=double(strcompress(archiveform.tag2, /remove_all))

  if (strcompress(archiveform.tag3, /remove_all) ne '') then $
    dec_tmp=double(strcompress(archiveform.tag3, /remove_all))

  if (strcompress(archiveform.tag0, /remove_all) ne '') then $
    target=image_str $
  else $
    target=[ra_tmp,dec_tmp]

  case archiveform.tag6 of 

  0: band='1'
  1: band='2b'
  2: band='2r'
  3: band='2i'
  4: band='j'
  5: band='h'
  6: band='k'
  7: band='12'
  8: band='25'
  9: band='60'
 10: band='100'
  endcase

  case archiveform.tag5 of 

  0: begin
    if (archiveform.tag7 eq 0) then $
      querydss, target, tmpim, hdr, imsize=imsize, survey=band, /stsci $
    else $
      querydss, target, tmpim, hdr, imsize=imsize, survey=band, /stsci, /ned
  end

  1: begin
    if (archiveform.tag7 eq 0) then $
      querydss, target, tmpim, hdr, imsize=imsize, survey=band, /eso $
    else $
      querydss, target, tmpim, hdr, imsize=imsize, survey=band, /eso, /ned
  end

  2: begin
    if (archiveform.tag7 eq 0) then $
      query2mass, target, tmpim, hdr, imsize=imsize, band=band $
    else $
      query2mass, target, tmpim, hdr, imsize=imsize, band=band, /ned
  end

  3: begin
    if (archiveform.tag7 eq 0) then $
      queryiras, target, tmpim, hdr, imsize=imsize, band=band $
    else $
      queryiras, target, tmpim, hdr, imsize=imsize, band=band, /ned
  end
  endcase

  smtv,tmpim,head=hdr
endif


;Reset image rotation angle to 0 and inversion to none
state.rot_angle = 0.
state.invert_image = 'none'

;Make pan image and set image to current zoom/stretch levels
smtv_makepan
smtv_refresh

;make sure that the image arrays are updated for line/column plots, etc.
smtv_resetwindow

end

;------------------------------------------------------------------


pro smtv_pixtable

; Create a table widget that will show a 5x5 array of pixel values
; around the current cursor position

if (not(xregistered('smtv_pixtable', /noshow))) then begin

  common smtv_state
  common smtv_images

  state.pixtable_base_id = $
    widget_base(/base_align_right, $
                 group_leader = state.base_id, $
                 /column, $
                 title = 'smtv pixel table')

  state.pixtable_tbl_id = widget_table(state.pixtable_base_id,   $
                   value=[0,0], xsize=5, ysize=5, row_labels='', $ 
                   column_labels='', alignment=2, /resizeable_columns)

  pixtable_done = widget_button(state.pixtable_base_id, $
                                value = 'Done', $
                                uvalue = 'pixtable_done')

  widget_control, state.pixtable_base_id, /realize
  xmanager, 'smtv_pixtable', state.pixtable_base_id, /no_block

endif

end

;---------------------------------------------------------------------

pro smtv_pixtable_event, event

common smtv_state

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'pixtable_done': widget_control, event.top, /destroy
    else:
endcase

end

;--------------------------------------------------------------------

pro smtv_pixtable_update

  common smtv_state
  common smtv_images

  zcenter = (0 > state.coord < state.image_size[0:1])

;Check and adjust the zcenter if the cursor is near the edges of the image

  if (zcenter[0] le 2) then zcenter[0] = 2
  if (zcenter[0] gt (state.image_size[0]-3)) then $
      zcenter[0] =  state.image_size[0] - 3

  if (zcenter[1] le 2) then zcenter[1] = 2
  if (zcenter[1] gt (state.image_size[1]-3)) then $
      zcenter[1] = state.image_size[1] - 3 

  pix_values = dblarr(5,5)
  row_labels = strarr(5)
  column_labels = strarr(5)
  boxsize=2

  xmin = 0 > (zcenter[0] - boxsize)
  xmax = (zcenter[0] + boxsize) < (state.image_size[0] - 1) 
  ymin = 0 > (zcenter[1] - boxsize) 
  ymax = (zcenter[1] + boxsize) < (state.image_size[1] - 1)

  row_labels = [strcompress(string(ymax),/remove_all),   $
                strcompress(string(ymin+3),/remove_all), $
                strcompress(string(ymin+2),/remove_all), $
                strcompress(string(ymin+1),/remove_all), $
                strcompress(string(ymin),/remove_all)]

  column_labels = [strcompress(string(xmin),/remove_all),   $
                   strcompress(string(xmin+1),/remove_all), $
                   strcompress(string(xmin+2),/remove_all), $
                   strcompress(string(xmin+3),/remove_all), $
                   strcompress(string(xmax),/remove_all)]

  pix_values = main_image[xmin:xmax, ymin:ymax]
  pix_values = reverse(pix_values, 2, /overwrite)

  widget_control, state.pixtable_tbl_id, set_value = pix_values, $
          column_labels=column_labels, row_labels=row_labels

end

;--------------------------------------------------------------------

pro smtv_autoscale

; Routine to auto-scale the image.  

common smtv_state 
common smtv_images

widget_control, /hourglass

if (n_elements(main_image) LT 5.e5) then begin
    med = median(main_image)
    sig = stddev(main_image)
endif else begin   ; resample big images before taking median, to save memory
    boxsize = 10
    rx = state.image_size[0] mod boxsize
    ry = state.image_size[1] mod boxsize
    nx = state.image_size[0] - rx
    ny = state.image_size[1] - ry
    tmp_img = rebin(main_image[0: nx-1, 0: ny-1], $
                    nx/boxsize, ny/boxsize, /sample)
    med = median(tmp_img)
    sig = stddev(temporary(tmp_img))
endelse

state.max_value = (med + (10 * sig)) < state.image_max
state.min_value = (med - (2 * sig))  > state.image_min

if (finite(state.min_value) EQ 0) then state.min_value = state.image_min
if (finite(state.max_value) EQ 0) then state.max_value = state.image_max

if (state.min_value GE state.max_value) then begin
    state.min_value = state.min_value - 1
    state.max_value = state.max_value + 1
endif

smtv_set_minmax

end  

;--------------------------------------------------------------------

pro smtv_restretch

; Routine to restretch the min and max to preserve the display
; visually but use the full color map linearly.  Written by DF, and
; tweaked and debugged by AJB.  It doesn't always work exactly the way
; you expect (especially in log-scaling mode), but mostly it works fine.

common smtv_state

sx = state.brightness
sy = state.contrast

if state.scaling EQ 2 then return ; do nothing for hist-eq mode

IF state.scaling EQ 0 THEN BEGIN 
    sfac = (state.max_value-state.min_value)
    state.max_value = sfac*(sx+sy)+state.min_value
    state.min_value = sfac*(sx-sy)+state.min_value
ENDIF 

IF state.scaling EQ 1 THEN BEGIN

    offset = state.min_value - $
      (state.max_value - state.min_value) * 0.01

    sfac = alog10((state.max_value - offset) / (state.min_value - offset))
    state.max_value = 10.^(sfac*(sx+sy)+alog10(state.min_value - offset)) $
      + offset
    state.min_value = 10.^(sfac*(sx-sy)+alog10(state.min_value - offset)) $
      + offset
    
ENDIF 

; do this differently for 8 or 24 bit color, to prevent flashing
if (state.bitdepth EQ 8) then begin
    smtv_set_minmax
    smtv_displayall
    state.brightness = 0.5      ; reset these
    state.contrast = 0.5
    smtv_stretchct, state.brightness, state.contrast
endif else begin
    state.brightness = 0.5      ; reset these
    state.contrast = 0.5
    smtv_stretchct, state.brightness, state.contrast
    smtv_set_minmax
    smtv_displayall
endelse

end

;---------------------------------------------------------------------

function smtv_wcsstring, lon, lat, ctype, equinox, disp_type, disp_equinox, $
            disp_base60

; Routine to return a string which displays cursor coordinates.
; Allows choice of various coordinate systems.
; Contributed by D. Finkbeiner, April 2000.
; 29 Sep 2000 - added degree (RA,dec) option DPF

; ctype - coord system in header
; disp_type - type of coords to display

headtype = strmid(ctype[0], 0, 4)

; need numerical equinox values
IF (equinox EQ 'J2000') THEN num_equinox = 2000.0 ELSE $
  IF (equinox EQ 'B1950') THEN num_equinox = 1950.0 ELSE $
  num_equinox = float(equinox)

IF (disp_equinox EQ 'J2000') THEN num_disp_equinox = 2000.0 ELSE $
  IF (disp_equinox EQ 'B1950') THEN num_disp_equinox = 1950.0 ELSE $
  num_disp_equinox = float(equinox)

; first convert lon,lat to RA,dec (J2000)
CASE headtype OF 
    'GLON': euler, lon, lat, ra, dec, 2 ; J2000
    'ELON': BEGIN 
        euler, lon, lat, ra, dec, 4 ; J2000
        IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END 
    'RA--': BEGIN    
        ra = lon
        dec = lat
        IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END 
ENDCASE  

; Now convert RA,dec (J2000) to desired display coordinates:  

IF (disp_type[0] EQ 'RA--') THEN BEGIN ; generate (RA,dec) string 
   disp_ra  = ra
   disp_dec = dec
   IF num_disp_equinox NE 2000.0 THEN precess, disp_ra, disp_dec, $
     2000.0, num_disp_equinox

   IF disp_base60 THEN BEGIN ; (hh:mm:ss) format
      
      neg_dec  = disp_dec LT 0
      radec, disp_ra, abs(disp_dec), ihr, imin, xsec, ideg, imn, xsc
      wcsstring = string(ihr, imin, xsec, ideg, imn, xsc, disp_equinox, $
         format = '(i2.2,":",i2.2,":",f6.3,"   ",i2.2,":",i2.2,":",f5.2," ",a6)' )
      if (strmid(wcsstring, 6, 1) EQ ' ') then $
        strput, wcsstring, '0', 6
      if (strmid(wcsstring, 21, 1) EQ ' ') then $
        strput, wcsstring, '0', 21
      IF neg_dec THEN strput, wcsstring, '-', 14

   ENDIF ELSE BEGIN ; decimal degree format

      wcsstring = string(disp_ra, disp_dec, disp_equinox, $
                         format='("Deg ",F9.5,",",F9.5,a6)')
   ENDELSE 
ENDIF 
     

IF disp_type[0] EQ 'GLON' THEN BEGIN ; generate (l,b) string
    euler, ra, dec, l, b, 1
    
    wcsstring = string(l, b, format='("Galactic (",F9.5,",",F9.5,")")')
ENDIF 

IF disp_type[0] EQ 'ELON' THEN BEGIN ; generate (l,b) string
    
    disp_ra = ra
    disp_dec = dec
    IF num_disp_equinox NE 2000.0 THEN precess, disp_ra, disp_dec, $
      2000.0, num_disp_equinox
    euler, disp_ra, disp_dec, lam, bet, 3
    
    wcsstring = string(lam, bet, format='("Ecliptic (",F9.5,",",F9.5,")")')
ENDIF 

return, wcsstring
END

;----------------------------------------------------------------------

function smtv_wavestring

; function to return string with wavelength info for spectral images

common smtv_state

cd = (*state.astr_ptr).cd[0,0]
crpix = (*state.astr_ptr).crpix[0]
crval = (*state.astr_ptr).crval[0]

cunit = sxpar(*state.head_ptr, 'cunit1')
cunit = strcompress(string(cunit), /remove_all)
if (cunit NE '0') then begin
    cunit = strcompress(strupcase(strmid(cunit,0,1)) + strmid(cunit,1), $
                        /remove_all)
endif else begin
    cunit = ''
endelse

shifta = float(sxpar(*state.head_ptr, 'SHIFTA1'))

wavelength = crval + ((state.coord[0] - crpix) * cd) + (shifta * cd)
wstring = string(wavelength, format='(F8.2)')

wavestring = strcompress('Wavelength:  ' + wstring + ' ' + cunit)

return, wavestring

end

;--------------------------------------------------------------------


function smtv_make_coords, ra, dec, pa, chan

common smtv_state

x_size=128 ;state.image_size(0)
y_size=128 ;state.image_size(1)

;load map


end

;--------------------------------------------------------------------


pro smtv_gettrack

; Create the image to display in the track window that tracks
; cursor movements.  Also update the coordinate display and the
; (x,y) and pixel value.

common smtv_state
common smtv_images


; Get x and y for center of track window

zcenter = (0 > state.coord < state.image_size[0:1])

track = bytarr(11,11)
boxsize=5
xmin = 0 > (zcenter[0] - boxsize)
xmax = (zcenter[0] + boxsize) < (state.image_size[0] - 1) 
ymin = 0 > (zcenter[1] - boxsize) 
ymax = (zcenter[1] + boxsize) < (state.image_size[1] - 1)

startx = abs( (zcenter[0] - boxsize) < 0 )
starty = abs( (zcenter[1] - boxsize) < 0 ) 

track[startx,starty] = scaled_image[xmin:xmax,ymin:ymax]
track_image = rebin(track, $
                    state.track_window_size, state.track_window_size, $
                    /sample)

smtv_setwindow, state.track_window_id
tv, track_image

; Overplot an X on the central pixel in the track window, to show the
; current mouse position

; Changed central x to be green always
plots, [0.46, 0.54], [0.46, 0.54], /normal, color = state.box_color, psym=0
plots, [0.46, 0.54], [0.54, 0.46], /normal, color = state.box_color, psym=0

; update location bar with x, y, and pixel value


chan=-1
wave=-1.
module='??'
if state.bmask eq 1 then bmask_value=bmask_image[state.coord[0],state.coord[1]] $
else bmask_value=-1

d_ra=!values.f_nan
d_dec=!values.f_nan
ra=0.
dec=0.
pa=0.

;check if there
defsysv, '!sm_sl_wavesamp_wave_f', exists = i


if (i eq 1) then begin
;get wavelength if available
    if (ptr_valid(state.head_ptr)) then begin
        h=(*state.head_ptr)
        
                                ;check for CHNLNUM tag
        chnl_tmp=sxpar(h, 'CHNLNUM', count=count1)
        if (count1 eq 1) then begin
            chan = sxpar(h, 'CHNLNUM')
        endif

                                ;check for SLT_TYPE tag
        chnl_tmp=sxpar(h, 'SLT_TYPE', count=count2)
        
        if (count2 eq 1) then begin
            tmp = sxpar(h, 'SLT_TYPE') ;
            
            if (tmp eq 'SL') then chan = 0
            if (tmp eq 'SH') then chan = 1
            if (tmp eq 'LL') then chan = 2
            if (tmp eq 'LH') then chan = 3
        endif

        if (chan eq -1) then begin
            wave = -1.
            module = '??'
        endif

                                    ;check for RA_SLT tag
        chnl_tmp=sxpar(h, 'RA_SLT', count=count3)

                                    ;check for RA_RQST tag
        chnl_tmp=sxpar(h, 'RA_RQST', count=count4)

        if (count3 eq 1) then begin
;            ra=sxpar(h, 'RA_SLT')               ; PH 9 May 2005 
;            dec=sxpar(h, 'DEC_SLT')             ; PH 9 May 2005 
;            pa=sxpar(h, 'PA_SLT')               ; PH 9 May 2005 
            ra  = double(sxpar(h, 'RA_SLT'))     ; PH 9 May 2005 
            dec = double(sxpar(h, 'DEC_SLT'))    ; PH 9 May 2005 
            pa  = double(sxpar(h, 'PA_SLT'))     ; PH 9 May 2005 
        endif
            
        if (count3 ne 1) and (count4 eq 1) then begin
;            ra=sxpar(h, 'RA_RQST')              ; PH 9 May 2005 
;            dec=sxpar(h, 'DEC_RQST')            ; PH 9 May 2005 
;            pa=sxpar(h, 'PA_RQST')              ; PH 9 May 2005 
            ra  = double(sxpar(h, 'RA_RQST'))    ; PH 9 May 2005 
            dec = double(sxpar(h, 'DEC_RQST'))   ; PH 9 May 2005 
            pa  = double(sxpar(h, 'PA_RQST'))    ; PH 9 May 2005 
        endif 


        ;if mosaic change coords
        if (state.mosaic eq 1) then begin
            im_size = size(main_image_backup)
            x = state.coord[0] mod im_size(1)
            y = state.coord[1] mod im_size(2)
        endif else begin 
            x = state.coord[0] 
            y = state.coord[1]
        endelse

        d=1.
;        arcsertodegconst = double(57.29578/206264.8) ; PH 9 May 2005 
        arcsertodegconst = double(1.0/3600.0)         ; PH 9 May 2005 

        if (chan eq 0) then begin
            wave = sl_wavelength(x, y)
            module = 'SL'
            d=double(sl_offset(x,y)*arcsertodegconst)
        endif
        if (chan eq 1) then begin
            wave = sh_wavelength(x, y)
            module = 'SH'
            d=double(sh_offset(x,y)*arcsertodegconst)
        endif
        if (chan eq 2) then begin
            wave = ll_wavelength(x, y)
            module = 'LL'
            d=double(ll_offset(x,y)*arcsertodegconst)
        endif
        if (chan eq 3) then begin
            wave = lh_wavelength(x, y)
            module = 'LH'
            d=double(lh_offset(x,y)*arcsertodegconst)
        endif

; convert "pa" to radians for trignometric functions (sin & cos); PH 9 May 2005 

        degtorad = double((2.0 * double(!pi)) / 360.0)          ; PH 9 May 2005 
        pa_rad   = double(pa * degtorad)                        ; PH 9 May 2005 

        if state.mosaic eq 0 then begin
;           d_ra=ra+cos(pa)*d                                   ; PH 9 May 2005 
;           d_dec=dec+sin(pa)*d                                 ; PH 9 May 2005 

            if(abs(dec) gt 89) then begin                       ; PH 9 May 2005 
                d_ra  = -1                                      ; PH 9 May 2005 
                d_dec = -1                                      ; PH 9 May 2005 
            endif else begin                                    ; PH 9 May 2005 

                d_dec = double(dec + (double(sin(pa_rad)) * d)) ; PH 9 May 2005 
                d_dec_rad = double(d_dec * degtorad)            ; PH 9 May 2005 
                d_ra = double(ra + ((double(cos(pa_rad)) * d) / double(cos(d_dec_rad)))) ; PH 9 May 2005

            endelse                                             ; PH 9 May 2005 

        endif else begin
          d_ra=-1
          d_dec=-1 
       endelse

    endif
endif;prepare RA, DEC



wav_string = string(module, wave, $
;                   format = '("Module: ", a10, "  ", g10.5)')           ; PH 29 Aug. 2005 
                   format = '("Module/Wavelength: ", a10, "  ", g10.5)') ; PH 29 Aug. 2005 

;coord_string = string(d_ra, d_dec, $                                 ; PH 29 Aug. 2005 
;                      format = '("RA: ", g15.10, " DEC: ", g15.10)') ; PH 29 Aug. 2005 

coord_string = string(d_ra, d_dec, $                                         ; PH 29 Aug. 2005 
                      format = '("RA_SLT: ", g15.10, " DEC_SLT: ", g15.10)') ; PH 29 Aug. 2005 

bmask_string = string("", bmask_value, $
                   format = '("Bmask: ", a10, "   ", g10.5)')

loc_string = string(state.coord[0], $
                    state.coord[1], $
                    main_image[state.coord[0], $
                    state.coord[1]], $
;                    format = '("(",i5,",",i5,") ",g10.5)')                        ; PH 29 Aug. 2005 
                    format = '("Pixel Pos(x,y)/Mag: ", "(",i5,",",i5,") ",g10.5)') ; PH 29 Aug. 2005 

woffset_string = string(d, $                                             ; PH 9 May 2005 
                      format = '("Wavesamp Offset:         ", g15.10)')  ; PH 9 May 2005 

widget_control, state.location_bar_id, set_value = loc_string
widget_control, state.wave_bar_id, set_value = wav_string
widget_control, state.bmask_bar_id, set_value = bmask_string
widget_control, state.coord_bar_id, set_value = coord_string
widget_control, state.woffset_bar_id, set_value = woffset_string         ; PH 9 May 2005 

; Update coordinate display

if (state.wcstype EQ 'angle') then begin
    xy2ad, state.coord[0], state.coord[1], *(state.astr_ptr), lon, lat

    wcsstring = smtv_wcsstring(lon, lat, (*state.astr_ptr).ctype,  $
                              state.equinox, state.display_coord_sys, $
                              state.display_equinox, state.display_base60)

;    widget_control, state.wcs_bar_id, set_value = wcsstring               ; PH 29 Aug. 2005 
    widget_control, state.wcs_bar_id, set_value = "WCS Data: " + wcsstring ; PH 29 Aug. 2005 

endif    

if (state.wcstype EQ 'lambda') then begin
    wavestring = smtv_wavestring()
    widget_control, state.wcs_bar_id, set_value = wavestring
endif

smtv_resetwindow

end

;----------------------------------------------------------------------

pro smtv_drawbox, norefresh=norefresh

; routine to draw the box on the pan window, given the current center
; of the display image.

common smtv_state
common smtv_images

smtv_setwindow, state.pan_window_id

view_min = round(state.centerpix - $
        (0.5 * state.draw_window_size / state.zoom_factor)) 
view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1

; Create the vectors which contain the box coordinates

box_x = float((([view_min[0], $
                 view_max[0], $
                 view_max[0], $
                 view_min[0], $
                 view_min[0]]) * state.pan_scale) + state.pan_offset[0]) 

box_y = float((([view_min[1], $
                 view_min[1], $
                 view_max[1], $
                 view_max[1], $
                 view_min[1]]) * state.pan_scale) + state.pan_offset[1]) 

; Redraw the pan image and overplot the box
if (not(keyword_set(norefresh))) then $
    device, copy=[0,0,state.pan_window_size, state.pan_window_size, 0, 0, $
                  state.pan_pixmap]

plots, box_x, box_y, /device, color = state.box_color, psym=0

smtv_resetwindow

end

;----------------------------------------------------------------------

pro smtv_pantrack, event

; routine to track the view box in the pan window during cursor motion

common smtv_state

; get the new box coords and draw the new box

tmp_event = [event.x, event.y] 

newpos = state.pan_offset > tmp_event < $
  (state.pan_offset + (state.image_size[0:1] * state.pan_scale))

state.centerpix = round( (newpos - state.pan_offset ) / state.pan_scale)

smtv_drawbox
smtv_getoffset

end

;----------------------------------------------------------------------

pro smtv_resize

; Routine to resize the draw window when a top-level resize event
; occurs.  Completely overhauled by AB for v1.4.

common smtv_state


widget_control, state.base_id, tlb_get_size=tmp_event

window = (state.base_min_size > tmp_event)

newbase = window - state.base_pad

newxsize = (tmp_event[0] - state.base_pad[0]) > $
  (state.base_min_size[0] - state.base_pad[0]) 
newysize = (tmp_event[1] - state.base_pad[1]) > $
  (state.base_min_size[1] - state.base_pad[1])

widget_control, state.draw_widget_id, $
  scr_xsize = newxsize, scr_ysize = newysize
widget_control, state.colorbar_widget_id, $
  scr_xsize = newxsize, scr_ysize = state.colorbar_height

state.draw_window_size = [newxsize, newysize]

smtv_colorbar

widget_control, state.base_id, /clear_events


end

;----------------------------------------------------------------------

pro smtv_scaleimage

; Create a byte-scaled copy of the image, scaled according to
; the state.scaling parameter.  Add a padding of 5 pixels around the
; image boundary, so that the tracking window can always remain
; centered on an image pixel even if that pixel is at the edge of the
; image.    

common smtv_state
common smtv_images

; Since this can take some time for a big image, set the cursor 
; to an hourglass until control returns to the event loop.

widget_control, /hourglass

delvarx, scaled_image 

case state.scaling of
    0: scaled_image = $                 ; linear stretch
      bytscl(main_image, $
             /nan, $
             min=state.min_value, $
             max=state.max_value, $
             top = state.ncolors - 1) + 8
    
    1: begin                            ; log stretch
        offset = state.min_value - $
          (state.max_value - state.min_value) * 0.01

        scaled_image = $        
          bytscl( alog10(main_image - offset), $
                  min=alog10(state.min_value - offset), /nan, $
                  max=alog10(state.max_value - offset),  $
                  top=state.ncolors - 1) + 8   
    end
    

    2: scaled_image = $                 ; histogram equalization
      bytscl(hist_equal(main_image, $
                        minv = state.min_value, $    
                        maxv = state.max_value), $
             /nan, top = state.ncolors - 1) + 8
    
endcase


end

;----------------------------------------------------------------------

pro smtv_getstats, align=align

; Get basic image stats: min and max, and size.
; set align keyword to preserve alignment of previous image

common smtv_state
common smtv_images

; this routine operates on main_image, which is in the
; smtv_images common block

widget_control, /hourglass

state.image_size[0:1] = [ (size(main_image))[1], (size(main_image))[2] ]

state.image_min = min(main_image, max=maxx, /nan)
state.image_max = maxx

if (state.min_value GE state.max_value) then begin
    state.min_value = state.min_value - 1
    state.max_value = state.max_value + 1
endif

; zero the current display position on the center of the image,
; unless user selected /align keyword

state.coord = round(state.image_size[0:1] / 2.)
IF NOT keyword_set(align) THEN state.centerpix = round(state.image_size[0:1] / 2.)
smtv_getoffset

; Clear all plot annotations
smtverase, /norefresh  

end

;-------------------------------------------------------------------

pro smtv_setwindow, windowid

; replacement for wset.  Reads the current active window first.
; This should be used when the currently active window is an external
; (i.e. non-smtv) idl window.  Use smtv_setwindow to set the window to
; one of the smtv window, then display something to that window, then
; use smtv_resetwindow to set the current window back to the currently
; active external window.  Make sure that device is not set to
; postscript, because if it is we can't display anything.

common smtv_state

if (!d.name NE 'PS') then begin
    state.active_window_id = !d.window
    wset, windowid
endif

end

;---------------------------------------------------------------------

pro smtv_resetwindow

; reset to current active window

common smtv_state

; The empty command used below is put there to make sure that all
; graphics to the previous smtv window actually get displayed to screen
; before we wset to a different window.  Without it, some line
; graphics would not actually appear on screen.

if (!d.name NE 'PS') then begin
    empty
    wset, state.active_window_id
endif

end

;------------------------------------------------------------------

pro smtv_getwindow

; get currently active window id

common smtv_state

if (!d.name NE 'PS') then begin
    state.active_window_id = !d.window
endif
end

;--------------------------------------------------------------------
;    Fits file reading routines
;--------------------------------------------------------------------

pro smtv_readfits, fitsfilename=fitsfilename, newimage=newimage

widget_control,/hourglass

; Read in a new image when user goes to the File->ReadFits menu.
; Do a reasonable amount of error-checking first, to prevent unwanted
; crashes. 

common smtv_state
common smtv_images

newimage = 0
cancelled = 0
if (n_elements(fitsfilename) EQ 0) then window = 1 else window = 0

; If fitsfilename hasn't been passed to this routine, get filename
; from dialog_pickfile.
if (n_elements(fitsfilename) EQ 0) then begin
    fitsfile = $
      dialog_pickfile(filter = '*.fits', $
                      dialog_parent = state.base_id, $
                      /must_exist, $
                      /read, $
                      path = state.current_dir, $
                      get_path = tmp_dir, $
                      title = 'Select Fits Image')        
    if (tmp_dir NE '') then state.current_dir = tmp_dir
    if (fitsfile EQ '') then return ; 'cancel' button returns empty string
endif else begin
    fitsfile = fitsfilename
endelse

; Get fits header so we know what kind of image this is.
head = headfits(fitsfile)

; Check validity of fits file header 
if (n_elements(strcompress(head, /remove_all)) LT 2) then begin
    smtv_message, 'File does not appear to be a valid fits image!', $
      window = window, msgtype = 'error'
    return
endif
if (!ERR EQ -1) then begin
    smtv_message, $
      'Selected file does not appear to be a valid FITS image!', $
      msgtype = 'error', window = window
    return
endif

; Two system variable definitions are needed in order to run fits_info
defsysv,'!TEXTOUT',1
defsysv,'!TEXTUNIT',0

; Find out if this is a fits extension file, and how many extensions
fits_info, fitsfile, n_ext = numext, /silent
instrume = strcompress(string(sxpar(head, 'INSTRUME')), /remove_all)
origin = strcompress(sxpar(head, 'ORIGIN'), /remove_all)
naxis = sxpar(head, 'NAXIS')

; Make sure it's not a 1-d spectrum
if (numext EQ 0 AND naxis LT 2) then begin
    smtv_message, 'Selected file is not a 2-d or 3-d FITS image!', $
      window = window, msgtype = 'error'
    return
endif

state.title_extras = ''

; Now call the subroutine that knows how to read in this particular
; data format:

if ((numext GT 0) AND (instrume NE 'WFPC2')) then begin
    smtv_fitsext_read, fitsfile, numext, head, cancelled
endif else if ((instrume EQ 'WFPC2') AND (naxis EQ 3)) then begin
    smtv_wfpc2_read, fitsfile, head, cancelled
endif else if ((naxis EQ 3) AND (origin EQ '2MASS')) then begin
    smtv_2mass_read, fitsfile, head, cancelled
endif else begin
    smtv_plainfits_read, fitsfile, head, cancelled
endelse

if (cancelled EQ 1) then return

; Make sure it's a 2-d or 3-d image
    if ( (size(main_image))[0] NE 2 AND (size(main_image))[0] NE 3) then begin
        smtv_message, 'Selected file is not a 2-D or 3-D fits image!', $
          msgtype = 'error', window = window
          print, 'ERROR: Input data must be a 2-d or 3-d array!'    
          main_image = fltarr(512, 512)
          newimage = 1
          return
    endif else begin
        if (size(main_image))[0] EQ 2 THEN begin
            newimage = 1
            state.image_size = [(size(main_image_stack))[1:2], 1]
            state.imagename = ''
            state.title_extras = ''
            smtv_setheader, header

            widget_control, state.curimnum_base_id,map=0,xsize=1,ysize=1

;            widget_control, state.curimnum_text_id, sensitive = 0, $
;                     set_value = 0
;            widget_control, state.curimnum_slidebar_id, sensitive = 0, $
;                     set_value = 0, set_slider_min = 0, set_slider_max = 0
;            widget_control, state.scale_mode_droplist_id, sensitive = 0


        endif else begin ; case of 3-d stack of images [x,y,n]
            main_image_stack = main_image
            image=main_image
            main_image = main_image_stack[*, *, 0]
            state.image_size = (size(main_image_stack))[1:3]
            state.cur_image_num = 0
            newimage = 1
            state.imagename = ''
            state.title_extras = $
              strcompress('Plane ' + string(state.cur_image_num))
            smtv_setheader, header
;<<<<<<< smtv_jb.pro
;=======
            if keyword_set(imname) then begin
               names_stack = imname
               state.imagename = imname[0]
            endif else begin
               state.imagename=''
               names_stack=strarr(n_elements(image[0,0,*]))
            endelse

            if (keyword_set(header)) then begin
               header_stack = header
               header=(*header[0])
            endif else begin
               for i = 0, (size(image))[3] - 1 do begin
                  mkhdr,hdr,image[*,*,i]
                  if i eq 0 then outhead=ptr_new(hdr) else $
                    outhead = [outhead,ptr_new(hdr)]
                  header_stack = outhead
                  header = (*outhead[0])
               endfor
            endelse

            widget_control,state.curimnum_base_id,map=1,xsize=585,ysize=45
;>>>>>>> smtv_ks.pro

            widget_control,state.curimnum_base_id,map=1, $
              xsize=state.draw_window_size[0],ysize=45

            widget_control, state.curimnum_text_id, sensitive = 1, $
                     set_value = 0
            widget_control, state.curimnum_slidebar_id, sensitive = 1, $
                     set_value = 0, set_slider_min = 0, $
                     set_slider_max = state.image_size[2]-1
            widget_control, state.scale_mode_droplist_id, sensitive = 1

        endelse
    endelse

; improvements as of v1.4:
widget_control, state.base_id, tlb_get_size=tmp_event
state.base_pad = tmp_event - state.draw_window_size


widget_control, /hourglass

state.imagename = fitsfile
smtv_setheader, head
newimage = 1

;Reset image rotation angle to 0 and inversion to none
state.rot_angle = 0.
state.invert_image = 'none'

end

;----------------------------------------------------------
;  Subroutines for reading specific data formats
;---------------------------------------------------------------

pro smtv_fitsext_read, fitsfile, numext, head, cancelled

; Fits reader for fits extension files

common smtv_state
common smtv_images

numlist = ''
for i = 1, numext do begin
    numlist = strcompress(numlist + string(i) + '|', /remove_all)
endfor

numlist = strmid(numlist, 0, strlen(numlist)-1)

droptext = strcompress('0, droplist, ' + numlist + $
                       ', label_left=Select Extension:, set_value=0')

formdesc = ['0, button, Read Primary Image, quit', $
            '0, label, OR:', $
            droptext, $
            '0, button, Read Fits Extension, quit', $
            '0, button, Cancel, quit']

textform = cw_form(formdesc, /column, $
                   title = 'Fits Extension Selector')

if (textform.tag4 EQ 1) then begin  ; cancelled 
    cancelled = 1
    return                         
endif

if (textform.tag3 EQ 1) then begin   ;extension selected
    extension = long(textform.tag2) + 1
endif else begin
    extension = 0               ; primary image selected
endelse

; Make sure it's not a fits table: this would make mrdfits crash
head = headfits(fitsfile, exten=extension)
xten = strcompress(sxpar(head, 'XTENSION'), /remove_all)
if (xten EQ 'BINTABLE') then begin
    smtv_message, 'File appears to be a FITS table, not an image.', $
      msgtype='error', /window
    cancelled = 1
    return
endif

if (extension GE 1) then begin
    state.title_extras = strcompress('Extension ' + string(extension))
endif else begin
    state.title_extras = 'Primary Image'
endelse

; Read in the image
delvarx, main_image
main_image = mrdfits(fitsfile, extension, head, /silent, /fscale) 

end

;----------------------------------------------------------------

pro smtv_plainfits_read, fitsfile, head, cancelled

common smtv_images

; Fits reader for plain fits files, no extensions.

delvarx, main_image
;main_image = mrdfits(fitsfile, 0, head, /silent, /fscale) 
main_image = readfits(fitsfile, exten_no=0, head, /silent)

end

;------------------------------------------------------------------

pro smtv_wfpc2_read, fitsfile, head, cancelled
    
; Fits reader for 4-panel HST WFPC2 images

common smtv_state
common smtv_images

droptext = strcompress('0, droplist,PC|WF2|WF3|WF4|Mosaic,' + $
                       'label_left = Select WFPC2 CCD:, set_value=0')

formdesc = [droptext, $
            '0, button, Read WFPC2 Image, quit', $
            '0, button, Cancel, quit']

textform = cw_form(formdesc, /column, title = 'WFPC2 Chip Selector')

if (textform.tag2 EQ 1) then begin ; cancelled
    cancelled = 1
    return                      
endif

ccd = long(textform.tag0) + 1

widget_control, /hourglass
if (ccd LE 4) then begin
    delvarx, main_image
    wfpc2_read, fitsfile, main_image, head, num_chip = ccd
endif

if (ccd EQ 5) then begin
    delvarx, main_image
    wfpc2_read, fitsfile, main_image, head, /batwing
endif
        
case ccd of
    1: state.title_extras = 'PC1'
    2: state.title_extras = 'WF2'
    3: state.title_extras = 'WF3'
    4: state.title_extras = 'WF4'
    5: state.title_extras = 'Mosaic'
    else: state.title_extras = ''
endcase

end

;----------------------------------------------------------------------

pro smtv_2mass_read, fitsfile, head, cancelled
    
; Fits reader for 3-plane 2MASS Extended Source J/H/Ks data cube
common smtv_state
common smtv_images

droptext = strcompress('0, droplist,J|H|Ks,' + $
                       'label_left = Select 2MASS Band:, set_value=0')

formdesc = [droptext, $
            '0, button, Read 2MASS Image, quit', $
            '0, button, Cancel, quit']

textform = cw_form(formdesc, /column, title = '2MASS Band Selector')

if (textform.tag2 EQ 1) then begin ; cancelled
    cancelled = 1
    return                     
endif

delvarx, main_image
main_image = mrdfits(fitsfile, 0, head, /silent, /fscale) 

band = long(textform.tag0) 
main_image = main_image[*,*,band]    ; fixed 11/28/2000

case textform.tag0 of
    0: state.title_extras = 'J Band'
    1: state.title_extras = 'H Band'
    2: state.title_extras = 'Ks Band'
    else: state.title_extras = ''
endcase

; fix ctype2 in header to prevent crashes when running xy2ad routine:
if (strcompress(sxpar(head, 'CTYPE2'), /remove_all) EQ 'DEC---SIN') then $
  sxaddpar, head, 'CTYPE2', 'DEC--SIN'

end

;-----------------------------------------------------------------------
;     Routines for creating output graphics
;-----------------------------------------------------------------------

pro smtv_writefits

; Writes image to a FITS file
; If a 3D image, the option to save either the current 2D display or
; the entire cube is possible 

common smtv_state
common smtv_images

; Get filename to save image
;stop
filename = dialog_pickfile(filter = '*.fits', $ 
                           file = 'smtv.fits', $
                           dialog_parent =  state.base_id, $
                           path = state.current_dir, $
                           get_path = tmp_dir, $
                           /write)

IF (tmp_dir NE '') THEN state.current_dir = tmp_dir

IF (strcompress(filename, /remove_all) EQ '') then RETURN   ; cancel

IF (filename EQ state.current_dir) then BEGIN
  smtv_message, 'Must indicate filename to save.', msgtype = 'error', /window
  return
ENDIF
;stop

;----------------------------------------DGW 29 August 2005
;Error trap code taken from smtv_writePS
tmp_result = findfile(filename, count = nfiles)

result = ''
if (nfiles GT 0) then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = strmid(filename, strpos(filename, '/') + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
                             /default_no, $
                             dialog_parent = state.base_id, $
                             /question)                 
endif

if (strupcase(result) EQ 'NO') then return
;----------------------------------------DGW 29 August 2005

header=(*state.head_ptr)

IF (state.image_size[2] eq 1) THEN BEGIN
    ;stop
  writefits, filename, main_image,header

ENDIF ELSE BEGIN
    ;stop
  formdesc = ['0, button, Write Current Image Plane, quit', $
              '0, button, Write All Image Planes, quit', $
              '0, button, Cancel, quit']

  textform = cw_form(formdesc, /column, $
                     title = 'Select Image to Write')

  IF (textform.tag0 eq 1) THEN writefits, filename, main_image,header
  IF (textform.tag1 eq 1) THEN writefits, filename, main_image_stack
  IF (textform.tag2 eq 1) THEN return

ENDELSE

end

;-----------------------------------------------------------------------

pro smtv_saveimage, file, bmp=bmp, png=png, pict=pict, jpeg=jpeg, tiff=tiff, $
  quality=quality, dither=dither, cube=cube, quiet=quiet


; This program is a copy of Liam E. Gumley's SAVEIMAGE program,
; modified for use with SMTV.

;------------------------------------------------------------------------
;- CHECK INPUT
;------------------------------------------------------------------------

;- Check arguments
if (n_params() ne 1) then message, 'Usage: SMTV_SAVEIMAGE, FILE'
if (n_elements(file) eq 0) then message, 'Argument FILE is undefined'
if (n_elements(file) gt 1) then message,'Argument FILE must be a scalar string'

;- Check keywords
output = 'JPEG'
if keyword_set(bmp)  then output = 'BMP'
if keyword_Set(png)  then output = 'PNG'
if keyword_set(pict) then output = 'PICT'
if keyword_set(jpeg) then output = 'JPEG'
if keyword_set(tiff) then output = 'TIFF'
if (n_elements(quality) eq 0) then quality = 75

;- Check for TVRD capable device
if ((!d.flags and 128)) eq 0 then message, 'Unsupported graphics device'

;- Check for open window
if (!d.flags and 256) ne 0 then begin
  if (!d.window lt 0) then message, 'No graphics windows are open'
endif

;- Get display depth
depth = 8
if (!d.n_colors gt 256) then depth = 24

;-------------------------------------------------------------------------
;- GET CONTENTS OF GRAPHICS WINDOW
;-------------------------------------------------------------------------

;- Handle window devices (other than the Z buffer)
if (!d.flags and 256) ne 0 then begin

  ;- Copy the contents of the current display to a pixmap
  current_window = !d.window
  xsize = !d.x_size
  ysize = !d.y_size
  window, /free, /pixmap, xsize=xsize, ysize=ysize, retain=2
  device, copy=[0, 0, xsize, ysize, 0, 0, current_window]

  ;- Set decomposed color mode for 24-bit displays
  version = float(!version.release)
  if (depth gt 8) then begin
    if (version gt 5.1) then device, get_decomposed=entry_decomposed
    device, decomposed=1
  endif

endif

;- Read the pixmap contents into an array
if (depth gt 8) then begin
  image = tvrd(order=0, true=1)
endif else begin
  image = tvrd(order=0)
endelse

;- Handle window devices (other than the Z buffer)
if (!d.flags and 256) ne 0 then begin

  ;- Restore decomposed color mode for 24-bit displays
  if (depth gt 8) then begin
    if (version gt 5.1) then begin
      device, decomposed=entry_decomposed
    endif else begin
      device, decomposed=0
      if (keyword_set(quiet) eq 0) then $
        print, 'Decomposed color was turned off'
    endelse
  endif

  ;- Delete the pixmap
  wdelete, !d.window
  wset, current_window

endif

;- Get the current color table
tvlct, r, g, b, /get

;- If an 8-bit image was read, reduce the number of colors
if (depth le 8) then begin
  reduce_colors, image, index
  r = r[index]
  g = g[index]
  b = b[index]
endif

;-----------------------------------------------------------------------
;- WRITE OUTPUT FILE
;-----------------------------------------------------------------------

case 1 of

  ;- Save the image in 8-bit output format
  (output eq 'BMP') or $
  (output eq 'PICT') or (output eq 'PNG') : begin

    if (depth gt 8) then begin

      ;- Convert 24-bit image to 8-bit
      case keyword_set(cube) of
        0 : image = color_quan(image, 1, r, g, b, colors=256, $
              dither=keyword_set(dither))
        1 : image = color_quan(image, 1, r, g, b, cube=6)
      endcase

      ;- Sort the color table from darkest to brightest
      table_sum = total([[long(r)], [long(g)], [long(b)]], 2)
      table_index = sort(table_sum)
      image_index = sort(table_index)
      r = r[table_index]
      g = g[table_index]
      b = b[table_index]
      oldimage = image
      image[*] = image_index[temporary(oldimage)]

    endif

    ;- Save the image
    case output of
      'BMP'  : write_bmp,  file, image, r, g, b
      'PNG'  : write_png,  file, image, r, g, b
      'PICT' : write_pict, file, image, r, g, b
    endcase

  end

  ;- Save the image in 24-bit output format
  (output eq 'JPEG') or (output eq 'TIFF') : begin

    ;- Convert 8-bit image to 24-bit
    if (depth le 8) then begin
      info = size(image)
      nx = info[1]
      ny = info[2]
      true = bytarr(3, nx, ny)
      true[0, *, *] = r[image]
      true[1, *, *] = g[image]
      true[2, *, *] = b[image]
      image = temporary(true)
    endif

    ;- If TIFF format output, reverse image top to bottom
    if (output eq 'TIFF') then image = reverse(temporary(image), 3)

    ;- Write the image
    case output of
      'JPEG' : write_jpeg, file, image, true=1, quality=quality
      'TIFF' : write_tiff, file, image, 1
    endcase

  end

endcase

;- Print information for the user
if (keyword_set(quiet) eq 0) then $
  print, file, output, format='("Created ",a," in ",a," format")'

end

;----------------------------------------------------------------------

pro smtv_writeimage_event, event

common smtv_state

CASE event.tag OF

  'FORMAT': BEGIN

    widget_control,(*state.writeimage_ids_ptr)[2], get_value=filename
    tagpos = strpos(filename, '.', /reverse_search)
    filename = strmid(filename,0,tagpos)

    CASE event.value OF

    '0': BEGIN
      filename = filename + '.jpg'
      widget_control,(*state.writeimage_ids_ptr)[2], set_value=filename
      state.writeformat = 'JPEG'
    END

    '1': BEGIN
      filename = filename + '.tiff'
      widget_control,(*state.writeimage_ids_ptr)[2], set_value=filename
      state.writeformat = 'TIFF'
    END

    '2': BEGIN
      filename = filename + '.bmp'
      widget_control,(*state.writeimage_ids_ptr)[2], set_value=filename
      state.writeformat = 'BMP'
    END

    '3': BEGIN
      filename = filename + '.pict'
      widget_control,(*state.writeimage_ids_ptr)[2], set_value=filename
      state.writeformat = 'PICT'
    END

    '4': BEGIN
      filename = filename + '.png'
      widget_control,(*state.writeimage_ids_ptr)[2], set_value=filename
      state.writeformat = 'PNG'
    END

    ENDCASE
  END

  'FILE': BEGIN
;------------------------------------------PH 29 Aug. 2005
    widget_control,(*state.writeimage_ids_ptr)[2], get_value=filename
    spawn, 'pwd', directory
    slash_pos = strpos(filename, '/', /reverse_search)
    if(slash_pos eq -1) then begin
        filename = directory + '/' + filename
    endif else begin
        filename = strmid(filename, slash_pos)
        filename = directory + filename
    endelse
;    filename = dialog_pickfile(/write)
    directory = dialog_pickfile(/write, file=filename)
    slash_pos = strpos(directory, '/', /reverse_search)
    final_pos = strpos(directory, '', /reverse_search)
    if (slash_pos eq final_pos) then begin
        widget_control,(*state.writeimage_ids_ptr)[2], get_value=filename
        test1 = strpos(filename, '/')
        if(test1 eq -1) then begin
        endif else begin 
            slash_pos = strpos(filename, '/', /reverse_search)
            filename = strmid(filename, slash_pos+1)
        endelse
        filename = directory + filename
    endif else begin
        filename = directory
    endelse
    widget_control,(*state.writeimage_ids_ptr)[2], set_value=filename
;------------------------------------------PH 29 Aug. 2005
  END

  'FILETEXT': BEGIN ; PH 29 Aug. 2005
  END               ; PH 29 Aug. 2005

  'WRITE' : BEGIN

    smtv_setwindow, state.draw_window_id

    widget_control,(*state.writeimage_ids_ptr)[0]
    widget_control,(*state.writeimage_ids_ptr)[2], get_value=filename
    filename = filename[0]

    ;----------------------------------------DGW 29 August 2005
    ;Error trap code taken from smtv_writePS
    tmp_result = findfile(filename, count = nfiles)
    
    result = ''
    if (nfiles GT 0) then begin
        mesg = strarr(2)
        mesg[0] = 'Overwrite existing file:'
        tmp_string = strmid(filename, strpos(filename, '/') + 1)
        mesg[1] = strcompress(tmp_string + '?', /remove_all)
        result =  dialog_message(mesg, $
                                 /default_no, $
                                 dialog_parent = state.base_id, $
                                 /question)                 
    endif

    if (strupcase(result) EQ 'NO') then return
    ;----------------------------------------DGW 29 August 2005

    CASE state.writeformat OF

    'JPEG': smtv_saveimage, filename, /jpeg
    'TIFF': smtv_saveimage, filename, /tiff
    'BMP': smtv_saveimage, filename, /bmp
    'PICT': smtv_saveimage, filename, /pict
    'PNG': smtv_saveimage, filename, /png
    ENDCASE

    smtv_resetwindow
    state.writeformat = 'JPEG'  

    if ptr_valid(state.writeimage_ids_ptr) then $
      ptr_free, state.writeimage_ids_ptr
    widget_control, event.top, /destroy
  END

  'QUIT': BEGIN
     state.writeformat = 'JPEG'
     if ptr_valid(state.writeimage_ids_ptr) then $
       ptr_free, state.writeimage_ids_ptr
     widget_control, event.top, /destroy
  END
ENDCASE

end

;----------------------------------------------------------------------

pro smtv_writeimage

; Front-end widget to write display image to output

common smtv_state
common smtv_images

writeimagebase = widget_base(/row)

;formdesc = ['0, droplist, JPEG|TIFF|BMP|PICT|PNG,label_left=Format:,set_value=0, TAG=format ', $
;            '1, base, , row', $
;            '0, button, Filename:, TAG=file ', $    ; PH 29 Aug. 2005
;            '2, text, smtv.jpg, width=15', $        ; PH 29 Aug. 2005
;            '2, text, smtv.jpg, width=50, label_left=File Name:, TAG=filetext', $
;            '1, base, , row', $
;            '0, button, Cancel, quit, TAG=quit ', $    ; PH 29 Aug. 2005
;            '0, button, WriteImage, quit, TAG=write']  ; PH 29 Aug. 2005
;            '0, button, WriteImage, quit, TAG=write', $
;            '0, button, Cancel, quit, TAG=quit ']


formdesc = ['0, droplist, JPEG|TIFF|BMP|PICT|PNG,label_left=FileFormat:,set_value=0, TAG=format ', $
            '1, base, , row', $
            '0, button, Choose..., TAG=file ', $
            '2, text, smtv.jpg, width=50, TAG=filetext', $
            '1, base, , row', $
            '0, button, WriteImage, quit, TAG=write', $
            '0, button, Cancel, quit, TAG=quit ']



writeimageform = cw_form(writeimagebase,formdesc,/column, $
      title='SMTV WriteImage', IDS=writeimage_ids_ptr) 

widget_control, writeimagebase, /realize

writeimage_ids_ptr = $
  writeimage_ids_ptr(where(widget_info(writeimage_ids_ptr,/type) eq 3 OR $
  widget_info(writeimage_ids_ptr,/type) eq 8 OR $
  widget_info(writeimage_ids_ptr,/type) eq 1))

if ptr_valid(state.writeimage_ids_ptr) then ptr_free,state.writeimage_ids_ptr
state.writeimage_ids_ptr = ptr_new(writeimage_ids_ptr)

xmanager, 'smtv_writeimage', writeimagebase

end

;----------------------------------------------------------------------

pro smtv_writeps

; Writes a postscript file of the current display.
; Calls cmps_form to get postscript file parameters.

common smtv_state
common smtv_images
common smtv_color

widget_control, /hourglass

view_min = round(state.centerpix - $
                  (0.5 * state.draw_window_size / state.zoom_factor))
view_max = round(view_min + state.draw_window_size / state.zoom_factor)

xsize = (state.draw_window_size[0] / state.zoom_factor) > $
  (view_max[0] - view_min[0] + 1)
ysize = (state.draw_window_size[1] / state.zoom_factor) > $
  (view_max[1] - view_min[1] + 1)


aspect = float(ysize) / float(xsize)
fname = strcompress(state.current_dir + 'smtv.ps', /remove_all)

tvlct, rr, gg, bb, 8, /get
forminfo = cmps_form(cancel = canceled, create = create, $
                     aspect = aspect, parent = state.base_id, $
                     /preserve_aspect, $
                     xsize = 6.0, ysize = 6.0 * aspect, $
                     /color, $
                     /nocommon, papersize='Letter', $
                     bits_per_pixel=8, $
                     filename = fname, $
                     button_names = ['Create PS File'])

if (canceled) then return
if (forminfo.filename EQ '') then return
tvlct, rr, gg, bb, 8

tmp_result = findfile(forminfo.filename, count = nfiles)

;----------------------------------------------DGW 29 August 2005
;This error trap prevents the user from attempting to write a file
;without including a filename
final_pos = strpos(formInfo.filename, '', /reverse_search)
slash_pos = strpos(formInfo.filename, '/', /reverse_search)
if final_pos eq slash_pos then begin
    smtv_message, 'You did not include a file name', msgtype='error',/window
    return
endif
;----------------------------------------------DGW 29 August 2005

result = ''
if (nfiles GT 0) then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = strmid(forminfo.filename, strpos(forminfo.filename, '/') + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
                             /default_no, $
                             dialog_parent = state.base_id, $
                             /question)                 
endif

if (strupcase(result) EQ 'NO') then return
    
widget_control, /hourglass

screen_device = !d.name

; In 8-bit mode, the screen color table will have fewer than 256
; colors.  Stretch out the existing color table to 256 colors for the
; postscript plot.

set_plot, 'ps'

device, _extra = forminfo

tvlct, rr, gg, bb, 8, /get

rn = congrid(rr, 248)
gn = congrid(gg, 248)
bn = congrid(bb, 248)

tvlct, temporary(rn), temporary(gn), temporary(bn), 8

; Make a full-resolution version of the display image, accounting for
; scalable pixels in the postscript output

newdisplay = bytarr(xsize, ysize)

startpos = abs(round(state.offset) < 0)

view_min = (0 > view_min < (state.image_size[0:1] - 1)) 
view_max = (0 > view_max < (state.image_size[0:1] - 1)) 

dimage = bytscl(scaled_image[view_min[0]:view_max[0], $
                                 view_min[1]:view_max[1]], $
                    top = 247, min=8, max=(!d.table_size-1)) + 8


newdisplay[startpos[0], startpos[1]] = temporary(dimage)

; if there's blank space around the image border, keep it black
tv, newdisplay
smtv_plotall

if (state.frame EQ 1) then begin    ; put frame around image
    plot, [0], [0], /nodata, position=[0,0,1,1], $
      xrange=[0,1], yrange=[0,1], xstyle=5, ystyle=5, /noerase
    boxx = [0,0,1,1,0,0]
    boxy = [0,1,1,0,0,1]
    oplot, boxx, boxy, color=0, thick=state.framethick
endif

tvlct, temporary(rr), temporary(gg), temporary(bb), 8


device, /close
set_plot, screen_device


end

;----------------------------------------------------------------------
;       routines for defining the color maps
;----------------------------------------------------------------------

pro smtv_stretchct, brightness, contrast,  getmouse = getmouse

; routine to change color stretch for given values of 
; brightness and contrast.
; Complete rewrite 2000-Sep-21 - Doug Finkbeiner
; This routine is now shorter and easier to understand.  

common smtv_state
common smtv_color

; if GETMOUSE then assume mouse positoin passed; otherwise ignore
; inputs

if (keyword_set(getmouse)) then begin 
   state.brightness = brightness/float(state.draw_window_size[0])
   state.contrast = contrast/float(state.draw_window_size[1])
endif

x = state.brightness*(state.ncolors-1)
y = state.contrast*(state.ncolors-1) > 2   ; Minor change by AJB 
high = x+y & low = x-y
diff = (high-low) > 1

slope = float(state.ncolors-1)/diff ;Scale to range of 0 : nc-1
intercept = -slope*low
p = long(findgen(state.ncolors)*slope+intercept) ;subscripts to select
tvlct, r_vector[p], g_vector[p], b_vector[p], 8

end

;------------------------------------------------------------------

pro smtv_initcolors

; Load a simple color table with the basic 8 colors in the lowest 
; 8 entries of the color table.  Also set top color to white.

common smtv_state

rtiny   = [0, 1, 0, 0, 0, 1, 1, 1]
gtiny = [0, 0, 1, 0, 1, 0, 1, 1]
btiny  = [0, 0, 0, 1, 1, 1, 0, 1]
tvlct, 255*rtiny, 255*gtiny, 255*btiny

tvlct, [255],[255],[255], !d.table_size-1

end

;--------------------------------------------------------------------

pro smtv_getct, tablenum

; Read in a pre-defined color table, and invert if necessary.

common smtv_color
common smtv_state
common smtv_images


loadct, tablenum, /silent,  bottom=8
tvlct, r, g, b, 8, /get

smtv_initcolors

r = r[0:state.ncolors-2]
g = g[0:state.ncolors-2]
b = b[0:state.ncolors-2]

if (state.invert_colormap EQ 1) then begin
r = reverse(r)
g = reverse(g)
b = reverse(b)
endif

r_vector = r
g_vector = g
b_vector = b

smtv_stretchct, state.brightness, state.contrast
if (state.bitdepth EQ 24 AND (n_elements(pan_image) GT 10) ) then $
  smtv_refresh

end

;--------------------------------------------------------------------


function smtv_polycolor, p

; Routine to return an vector of length !d.table_size-8,
; defined by a 5th order polynomial.   Called by smtv_makect
; to define new color tables in terms of polynomial coefficients.

common smtv_state

x = findgen(256)

y = p[0] + x * p[1] + x^2 * p[2] + x^3 * p[3] + x^4 * p[4] + x^5 * p[5]

w = where(y GT 255, nw)
if (nw GT 0) then y(w) = 255

w =  where(y LT 0, nw)
if (nw GT 0) then y(w) = 0

z = congrid(y, state.ncolors)

return, z
end

;----------------------------------------------------------------------

pro smtv_makect, tablename

; Define new color tables here.  Invert if necessary.

common smtv_state
common smtv_color

case tablename of
    'SMTV Special': begin
        r = smtv_polycolor([39.4609, $
                           -5.19434, $
                           0.128174, $
                           -0.000857115, $
                           2.23517e-06, $
                           -1.87902e-09])
        
        g = smtv_polycolor([-15.3496, $
                           1.76843, $
                           -0.0418186, $
                           0.000308216, $
                           -6.07106e-07, $
                           0.0000])
        
        b = smtv_polycolor([0.000, $ 
                           12.2449, $
                           -0.202679, $
                           0.00108027, $
                           -2.47709e-06, $
                           2.66846e-09])

   end

; add more color table definitions here as needed...
    else: return

endcase

if (state.invert_colormap EQ 1) then begin
r = reverse(r)
g = reverse(g)
b = reverse(b)
endif

r_vector = temporary(r)
g_vector = temporary(g)
b_vector = temporary(b)

smtv_stretchct, state.brightness, state.contrast
if (state.bitdepth EQ 24) then smtv_refresh

end

;----------------------------------------------------------------------

function smtv_icolor, color

; Routine to reserve the bottom 8 colors of the color table
; for plot overlays and line plots.

if (n_elements(color) EQ 0) then return, 1

ncolor = N_elements(color)

; If COLOR is a string or array of strings, then convert color names
; to integer values
if (size(color,/tname) EQ 'STRING') then begin ; Test if COLOR is a string
    
; Detemine the default color for the current device
    if (!d.name EQ 'X') then defcolor = 7 $ ; white for X-windows
    else defcolor = 0           ; black otherwise
    
    icolor = 0 * (color EQ 'black') $
      + 1 * (color EQ 'red') $
      + 2 * (color EQ 'green') $
      + 3 * (color EQ 'blue') $
      + 4 * (color EQ 'cyan') $
      + 5 * (color EQ 'magenta') $
      + 6 * (color EQ 'yellow') $
      + 7 * (color EQ 'white') $
      + defcolor * (color EQ 'default')
    
endif else begin
    icolor = long(color)
endelse

return, icolor
end 
 
;---------------------------------------------------------------------
;    routines dealing with image header, title, and related info
;--------------------------------------------------------------------

pro smtv_settitle

; Update title bar with the image file name

common smtv_state

if (strlen(state.imagename) EQ 0) then begin
    if (strlen(state.title_extras) EQ 0) then begin
        state.window_title = 'smtv'
    endif else begin
        state.window_title = strcompress('smtv:  ' + state.title_extras)
    endelse
endif else begin
    slash = strpos(state.imagename, '/')
    ; inserted untested code for MacOS and Windows delimiters
    if (slash EQ -1) then slash = strpos(state.imagename, '\')
    if (slash EQ -1) then slash = strpos(state.imagename, ':')

    if (slash NE -1) then name = strmid(state.imagename, slash+1) $
      else name = state.imagename
    state.window_title = strcompress('smtv:  '+name + '  ' + state.title_extras)
endelse

widget_control, state.base_id, tlb_set_title = state.window_title

end

;----------------------------------------------------------------------

pro smtv_setheader, head

; Routine to keep the image header using a pointer to a 
; heap variable.  If there is no header (i.e. if smtv has just been
; passed a data array rather than a filename), then make the
; header pointer a null pointer.  Get astrometry info from the 
; header if available.  If there's no astrometry information, set 
; state.astr_ptr to be a null pointer.

common smtv_state

; Kill the header info window when a new image is read in

if (xregistered('smtv_headinfo')) then begin
    widget_control, state.headinfo_base_id, /destroy
endif

if (xregistered('smtv_stats')) then begin
    widget_control, state.stats_base_id, /destroy
endif

if (n_elements(head) LE 1) then begin
; If there's no image header...
    state.wcstype = 'none'
    ptr_free, state.head_ptr
    state.head_ptr = ptr_new()
    ptr_free, state.astr_ptr
    state.astr_ptr = ptr_new()
    widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    return
endif

ptr_free, state.head_ptr
state.head_ptr = ptr_new(head)

; Get astrometry information from header, if it exists
ptr_free, state.astr_ptr        ; kill previous astrometry info
state.astr_ptr = ptr_new()
extast, head, astr, noparams

; No valid astrometry in header
if (noparams EQ -1) then begin 
    widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    state.wcstype = 'none'
    return
endif

; coordinate types that we can't use:
if ( (strcompress(string(astr.ctype[0]), /remove_all) EQ 'PIXEL') $
     or (strcompress(string(astr.ctype[0]), /remove_all) EQ '') ) then begin
    widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    state.wcstype = 'none'
    return
endif

; Image is a 2-d calibrated spectrum (probably from stis):
if (astr.ctype[0] EQ 'LAMBDA') then begin
    state.wcstype = 'lambda'
    state.astr_ptr = ptr_new(astr)
    widget_control, state.wcs_bar_id, set_value = '                 '
    return
endif

; Good astrometry info in header:
state.wcstype = 'angle'
widget_control, state.wcs_bar_id, set_value = '                 '

; Check for GSS type header  
if strmid( astr.ctype[0], 5, 3) EQ 'GSS' then begin
    hdr1 = head
    gsss_STDAST, hdr1
    extast, hdr1, astr, noparams
endif

; Create a pointer to the header info
state.astr_ptr = ptr_new(astr)

; Get the equinox of the coordinate system
equ = get_equinox(head, code)
if (code NE -1) then begin
    if (equ EQ 2000.0) then state.equinox = 'J2000'
    if (equ EQ 1950.0) then state.equinox = 'B1950'
    if (equ NE 2000.0 and equ NE 1950.0) then $
      state.equinox = string(equ, format = '(f6.1)')
endif else begin
    IF (strmid(astr.ctype[0], 0, 4) EQ 'GLON') THEN BEGIN 
        state.equinox = 'J2000' ; (just so it is set)
    ENDIF ELSE BEGIN                          
        ptr_free, state.astr_ptr    ; clear pointer
        state.astr_ptr = ptr_new()
        state.equinox = 'J2000'
        state.wcstype = 'none'
        widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    ENDELSE 
endelse

; Set default display to native system in header
state.display_equinox = state.equinox
state.display_coord_sys = strmid(astr.ctype[0], 0, 4)

end

;---------------------------------------------------------------------


pro smtv_headinfo

common smtv_state

; If there's no header, kill the headinfo window and exit this
; routine.
if (not(ptr_valid(state.head_ptr))) then begin
    if (xregistered('smtv_headinfo')) then begin
        widget_control, state.headinfo_base_id, /destroy
    endif

    smtv_message, 'No header information available for this image!', $
      msgtype = 'error', /window
    return
endif


; If there is header information but not headinfo window,
; create the headinfo window.
if (not(xregistered('smtv_headinfo', /noshow))) then begin

    headinfo_base = $
      widget_base(/base_align_right, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'smtv image header information', $
                  uvalue = 'headinfo_base')
    state.headinfo_base_id = headinfo_base

    h = *(state.head_ptr)

    headinfo_text = widget_text(headinfo_base, $
                            /scroll, $
                            value = h, $
                            xsize = 85, $
                            ysize = 24)
    
    headinfo_done = widget_button(headinfo_base, $
                              value = 'Done', $
                              uvalue = 'headinfo_done')

    widget_control, headinfo_base, /realize
    xmanager, 'smtv_headinfo', headinfo_base, /no_block

endif


end

;---------------------------------------------------------------------

pro smtv_headinfo_event, event

common smtv_state

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'headinfo_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------
;             routines to do plot overlays
;----------------------------------------------------------------------

pro smtv_plot1plot, iplot
common smtv_pdata
common smtv_state

; Plot a point or line overplot on the image

smtv_setwindow, state.draw_window_id

widget_control, /hourglass

oplot, [(*(plot_ptr[iplot])).x], [(*(plot_ptr[iplot])).y], $
  _extra = (*(plot_ptr[iplot])).options

smtv_resetwindow
state.newrefresh=1
end

;----------------------------------------------------------------------

pro smtv_plot1text, iplot
common smtv_pdata
common smtv_state

; Plot a text overlay on the image
smtv_setwindow, state.draw_window_id

widget_control, /hourglass

xyouts, (*(plot_ptr[iplot])).x, (*(plot_ptr[iplot])).y, $
  (*(plot_ptr[iplot])).text, _extra = (*(plot_ptr[iplot])).options

smtv_resetwindow
state.newrefresh=1
end

;----------------------------------------------------------------------

pro smtv_plot1arrow, iplot
common smtv_pdata
common smtv_state

; Plot a arrow overlay on the image
smtv_setwindow, state.draw_window_id

widget_control, /hourglass

arrow, (*(plot_ptr[iplot])).x1, (*(plot_ptr[iplot])).y1, $
  (*(plot_ptr[iplot])).x2, (*(plot_ptr[iplot])).y2, $
  _extra = (*(plot_ptr[iplot])).options, /data

smtv_resetwindow
state.newrefresh=1
end

;----------------------------------------------------------------------

function smtv_degperpix, hdr 
             
; This program calculates the pixel scale (deg/pixel) and returns the value

common smtv_state

On_error,2                      ;Return to caller
 
extast, hdr, bastr, noparams    ;extract astrom params in deg.
 
a = bastr.crval[0]
d = bastr.crval[1]

factor = 60.0                   ;conversion factor from deg to arcmin
d1 = d + (1/factor)             ;compute x,y of crval + 1 arcmin

proj = strmid(bastr.ctype[0],5,3)

case proj of 
    'GSS': gsssadxy, bastr, [a,a], [d,d1], x, y
    else:  ad2xy, [a,a], [d,d1], bastr, x, y 
endcase

dmin = sqrt( (x[1]-x[0])^2 + (y[1]-y[0])^2 ) ;det. size in pixels of 1 arcmin

; Convert to degrees per pixel and return scale
degperpix = 1. / dmin / 60.

return, degperpix
end

;----------------------------------------------------------------------

function smtv_wcs2pix, coords, coord_sys=coord_sys, line=line

common smtv_state

; check validity of state.astr_ptr and state.head_ptr before
; proceeding to grab wcs information

if ptr_valid(state.astr_ptr) then begin
  ctype = (*state.astr_ptr).ctype
  equinox = state.equinox
  disp_type = state.display_coord_sys
  disp_equinox = state.display_equinox
  disp_base60 = state.display_base60
  bastr = *(state.astr_ptr)

; function to convert an SMTV region from wcs coordinates to pixel coordinates
  degperpix = smtv_degperpix(*(state.head_ptr))

; need numerical equinox values
  IF (equinox EQ 'J2000') THEN num_equinox = 2000.0 ELSE $
    IF (equinox EQ 'B1950') THEN num_equinox = 1950.0 ELSE $
    num_equinox = float(equinox)

  headtype = strmid(ctype[0], 0, 4)
  n_coords = n_elements(coords)
endif

case coord_sys of

'j2000': begin
  if (strpos(coords[0], ':')) ne -1 then begin
    ra_arr = strsplit(coords[0],':',/extract)
    dec_arr = strsplit(coords[1],':',/extract)
    ra = ten(float(ra_arr[0]), float(ra_arr[1]), float(ra_arr[2])) * 15.0
    dec = ten(float(dec_arr[0]), float(dec_arr[1]), float(dec_arr[2]))
    if (keyword_set(line)) then begin
      ra1_arr = strsplit(coords[2],':',/extract)
      dec1_arr = strsplit(coords[3],':',/extract)
      ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), float(ra1_arr[2])) * 15.0
      dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), float(dec1_arr[2]))
    endif
  endif else begin  ; coordinates in degrees
    ra=float(coords[0])
    dec=float(coords[1])
    if (keyword_set(line)) then begin
      ra1=float(coords[2])
      dec1=float(coords[3])  
    endif
  endelse

  if (not keyword_set(line)) then begin
    if (n_coords ne 6) then $
      coords[2:n_coords-2] = strcompress(string(float(coords[2:n_coords-2]) / $
                               (degperpix * 60.)),/remove_all) $
    else $
      coords[2:n_coords-3] = strcompress(string(float(coords[2:n_coords-3]) / $
                               (degperpix * 60.)),/remove_all)
  endif

end

'b1950': begin
  if (strpos(coords[0], ':')) ne -1 then begin
    ra_arr = strsplit(coords[0],':',/extract)
    dec_arr = strsplit(coords[1],':',/extract)
    ra = ten(float(ra_arr[0]), float(ra_arr[1]), float(ra_arr[2])) * 15.0
    dec = ten(float(dec_arr[0]), float(dec_arr[1]), float(dec_arr[2]))
    precess, ra, dec, 1950.0, 2000.0
    if (keyword_set(line)) then begin
      ra1_arr = strsplit(coords[2],':',/extract)
      dec1_arr = strsplit(coords[3],':',/extract)
      ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), float(ra1_arr[2])) * 15.0
      dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), float(dec1_arr[2]))
      precess, ra1, dec1, 1950.0,2000.0
    endif
  endif else begin  ; convert B1950 degrees to J2000 degrees
    ra = float(coords[0])
    dec = float(coords[1]) 
    precess, ra, dec, 1950.0, 2000.0
    if (keyword_set(line)) then begin
      ra1=float(coords[2])
      dec1=float(coords[3])
      precess, ra1, dec1, 1950., 2000.0 
    endif
  endelse

  if (not keyword_set(line)) then begin
    if (n_coords ne 6) then $
      coords[2:n_coords-2] = strcompress(string(float(coords[2:n_coords-2]) / $
                               (degperpix * 60.)),/remove_all) $
    else $
      coords[2:n_coords-3] = strcompress(string(float(coords[2:n_coords-3]) / $
                               (degperpix * 60.)),/remove_all)
  endif
end

'galactic': begin  ; convert galactic to J2000 degrees
  euler, float(coords[0]), float(coords[1]), ra, dec, 2
  if (not keyword_set(line)) then begin
    if (n_coords ne 6) then $
      coords[2:n_coords-2] = strcompress(string(float(coords[2:n_coords-2]) / $
                                 (degperpix * 60.)),/remove_all) $
    else $
      coords[2:n_coords-3] = strcompress(string(float(coords[2:n_coords-3]) / $
                               (degperpix * 60.)),/remove_all)
  endif else begin
    euler, float(coords[2]), float(coords[3]), ra1, dec1, 2
  endelse
end

'ecliptic': begin  ; convert ecliptic to J2000 degrees
  euler, float(coords[0]), float(coords[1]), ra, dec, 4
  if (not keyword_set(line)) then begin
    if (n_coords ne 6) then $ 
      coords[2:n_coords-2] = strcompress(string(float(coords[2:n_coords-2]) / $
                               (degperpix * 60.)),/remove_all) $
    else $
      coords[2:n_coords-3] = strcompress(string(float(coords[2:n_coords-3]) / $
                               (degperpix * 60.)),/remove_all)
  endif else begin
    euler, float(coords[2]), float(coords[3]), ra1, dec1, 4
  endelse
end

'current': begin
    ra_arr = strsplit(coords[0],':',/extract)
    dec_arr = strsplit(coords[1],':',/extract)
    ra = ten(float(ra_arr[0]), float(ra_arr[1]), float(ra_arr[2])) * 15.0
    dec = ten(float(dec_arr[0]), float(dec_arr[1]), float(dec_arr[2]))
    if (not keyword_set(line)) then begin
      coords[2] = strcompress(string(float(coords[2]) / $
                               (degperpix * 60.)),/remove_all)
      if (n_coords gt 3) then $
        coords[3] = strcompress(string(float(coords[3]) / $
                               (degperpix * 60.)),/remove_all)
    endif else begin
      ra1_arr = strsplit(coords[2],':',/extract)
      dec1_arr = strsplit(coords[3],':',/extract)
      ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), float(ra1_arr[2])) * 15.0
      dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), float(dec1_arr[2]))
    endelse
    
    if (num_equinox ne 2000.) then begin
      precess, ra, dec, num_equinox, 2000.
    if (keyword_set(line)) then precess, ra1, dec1, num_equinox, 2000.
    endif

end

'pixel': begin
; Do nothing when pixel.  Will pass pixel coords array back.
end

else: 

endcase

if (ptr_valid(state.astr_ptr) AND coord_sys ne 'pixel') then begin

  if (num_equinox ne 2000) then begin
    precess, ra, dec, 2000., num_equinox
    if (keyword_set(line)) then precess, ra1, dec1, 2000., num_equinox
  endif

  proj = strmid(ctype[0],5,3)

  case proj of 
      'GSS': begin
         gsssadxy, bastr, ra, dec, x, y
         if (keyword_set(line)) then gsssadxy, bastr, ra1, dec1, x1, y1
       end
      else: begin
        ad2xy, ra, dec, bastr, x, y 
        if (keyword_set(line)) then ad2xy, ra1, dec1, bastr, x1, y1 
       end
  endcase

  coords[0] = strcompress(string(x),/remove_all)
  coords[1] = strcompress(string(y),/remove_all)
  if (keyword_set(line)) then begin
    coords[2] = strcompress(string(x1),/remove_all)
    coords[3] = strcompress(string(y1),/remove_all)
  endif
endif

return, coords
END

;----------------------------------------------------------------------

pro smtv_plot1region, iplot
common smtv_pdata
common smtv_state

; Plot a region overlay on the image
smtv_setwindow, state.draw_window_id

widget_control, /hourglass

reg_array = (*(plot_ptr[iplot])).reg_array
n_reg = n_elements(reg_array)

for i=0, n_reg-1 do begin
  open_parenth_pos = strpos(reg_array[i],'(')
  close_parenth_pos = strpos(reg_array[i],')')   
  reg_type = strcompress(strmid(reg_array[i],0,open_parenth_pos),/remove_all)
  length = close_parenth_pos - open_parenth_pos
  coords_str = strcompress(strmid(reg_array[i], open_parenth_pos+1, $
                           length-1),/remove_all)
  coords_arr = strsplit(coords_str,',',/extract) 
  n_coords = n_elements(coords_arr)
  color_begin_pos = strpos(strlowcase(reg_array[i]), 'color')
  text_pos = strpos(strlowcase(reg_array[i]), 'text')

  if (color_begin_pos ne -1) then begin
    color_equal_pos = strpos(reg_array[i], '=', color_begin_pos)
   endif

  text_begin_pos = strpos(reg_array[i], '{')

; Text for region
  if (text_begin_pos ne -1) then begin
    text_end_pos = strpos(reg_array[i], '}')
    text_len = (text_end_pos-1) - (text_begin_pos)
    text_str = strmid(reg_array[i], text_begin_pos+1, text_len)
    color_str = ''

; Color & Text for region
    if (color_begin_pos ne -1) then begin
    ; Compare color_begin_pos to text_begin_pos to tell which is first
      
      case (color_begin_pos lt text_begin_pos) of
        0: begin
             ;text before color
           color_str = strcompress(strmid(reg_array[i], color_equal_pos+1, $
                       strlen(reg_array[i])), /remove_all)
        end
        1: begin
             ;color before text
           len_color = (text_pos-1) - color_equal_pos
           color_str = strcompress(strmid(reg_array[i], color_equal_pos+1, $
                                   len_color), /remove_all)
        end
      endcase
    endif

  endif else begin

; Color but no text for region
    if (color_begin_pos ne -1) then begin
      color_str = strcompress(strmid(reg_array[i], color_equal_pos+1, $
                  strlen(reg_array[i])), /remove_all)

; Neither color nor text for region
    endif else begin
      color_str = ''
    endelse

    text_str = ''

  endelse

  index_j2000 = where(strlowcase(coords_arr) eq 'j2000')
  index_b1950 = where(strlowcase(coords_arr) eq 'b1950')
  index_galactic = where(strlowcase(coords_arr) eq 'galactic')
  index_ecliptic = where(strlowcase(coords_arr) eq 'ecliptic')

  index_coord_system = where(strlowcase(coords_arr) eq 'j2000') AND $
                       where(strlowcase(coords_arr) eq 'b1950') AND $
                       where(strlowcase(coords_arr) eq 'galactic') AND $
                       where(strlowcase(coords_arr) eq 'ecliptic')

  index_coord_system = index_coord_system[0]

if (index_coord_system ne -1) then begin

; Check that a WCS region is not overplotted on image with no WCS
  if (NOT ptr_valid(state.astr_ptr)) then begin
    smtv_message, 'WCS Regions cannot be displayed on image without WCS', $
      msgtype='error', /window
    return
  endif

  case strlowcase(coords_arr[index_coord_system]) of
  'j2000': begin
     if (strlowcase(reg_type) ne 'line') then $
       coords_arr = smtv_wcs2pix(coords_arr, coord_sys='j2000') $
     else $
       coords_arr = smtv_wcs2pix(coords_arr, coord_sys='j2000', /line) 
   end
  'b1950': begin
     if (strlowcase(reg_type) ne 'line') then $
       coords_arr = smtv_wcs2pix(coords_arr, coord_sys='b1950') $
     else $
       coords_arr = smtv_wcs2pix(coords_arr, coord_sys='b1950', /line)
   end
  'galactic': begin
     if (strlowcase(reg_type) ne 'line') then $
       coords_arr = smtv_wcs2pix(coords_arr, coord_sys='galactic') $
     else $
       coords_arr = smtv_wcs2pix(coords_arr, coord_sys='galactic', /line)
   end
  'ecliptic': begin
     if (strlowcase(reg_type) ne 'line') then $
       coords_arr = smtv_wcs2pix(coords_arr, coord_sys='ecliptic') $
     else $
       coords_arr = smtv_wcs2pix(coords_arr, coord_sys='ecliptic', /line)
   end
  else: 
  endcase
endif else begin

  if (strpos(coords_arr[0], ':')) ne -1 then begin

; Check that a WCS region is not overplotted on image with no WCS
    if (NOT ptr_valid(state.astr_ptr)) then begin
      smtv_message, 'WCS Regions cannot be displayed on image without WCS', $
        msgtype='error', /window
      return
    endif

    if (strlowcase(reg_type) ne 'line') then $
      coords_arr = smtv_wcs2pix(coords_arr,coord_sys='current') $
    else $
      coords_arr = smtv_wcs2pix(coords_arr,coord_sys='current', /line)
  endif else begin
    if (strlowcase(reg_type) ne 'line') then $
      coords_arr = smtv_wcs2pix(coords_arr,coord_sys='pixel') $
    else $
      coords_arr = smtv_wcs2pix(coords_arr,coord_sys='pixel', /line)
  endelse

endelse

  CASE strlowcase(color_str) OF

  'red':     (*(plot_ptr[iplot])).options.color = '1'
  'black':   (*(plot_ptr[iplot])).options.color = '0'
  'green':   (*(plot_ptr[iplot])).options.color = '2'
  'blue':    (*(plot_ptr[iplot])).options.color = '3'
  'cyan':    (*(plot_ptr[iplot])).options.color = '4'
  'magenta': (*(plot_ptr[iplot])).options.color = '5'
  'yellow':  (*(plot_ptr[iplot])).options.color = '6'
  'white':   (*(plot_ptr[iplot])).options.color = '7'
  ELSE:      (*(plot_ptr[iplot])).options.color = '1'

  ENDCASE

  smtv_setwindow,state.draw_window_id
  smtv_plotwindow  
  
  case strlowcase(reg_type) of

    'circle': begin
        xcenter = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
                   state.zoom_factor
        ycenter = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
                   state.zoom_factor

        radius = float(coords_arr[2]) * state.zoom_factor
        tvcircle, radius, xcenter, ycenter, /device, $
          _extra = (*(plot_ptr[iplot])).options

        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(plot_ptr[iplot])).options, /device
    end
    'box': begin
        angle = 0 ; initialize angle to 0
        if (n_coords ge 4) then begin
          xcenter = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
                     state.zoom_factor
          ycenter = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
                     state.zoom_factor
          xwidth = float(coords_arr[2]) * state.zoom_factor
          ywidth = float(coords_arr[3]) * state.zoom_factor
          if (n_coords ge 5) then angle = float(coords_arr[4])
        endif
        width_arr = [xwidth,ywidth]  
        ; angle = -angle because tvbox rotates clockwise
        tvbox, width_arr, xcenter, ycenter, angle=-angle, $
          _extra = (*(plot_ptr[iplot])).options

        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(plot_ptr[iplot])).options, /device
    end
    'ellipse': begin
        angle = 0 ; initialize angle to 0
        if (n_coords ge 4) then begin
          xcenter = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
                     state.zoom_factor
          ycenter = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
                     state.zoom_factor
          xradius = float(coords_arr[2]) * state.zoom_factor
          yradius = float(coords_arr[3]) * state.zoom_factor
          if (n_coords ge 5) then angle = float(coords_arr[4])
        endif

       ; Correct angle for default orientation used by tvellipse
        angle=angle+180.

        if (xcenter ge 0.0 and ycenter ge 0.0) then $
          tvellipse, xradius, yradius, xcenter, ycenter, angle, $
            _extra = (*(plot_ptr[iplot])).options

        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(plot_ptr[iplot])).options, /device
    end
    'polygon': begin
       n_vert = n_elements(coords_arr) / 2
       xpoints = fltarr(n_vert)
       ypoints = fltarr(n_vert)
       for vert_i = 0, n_vert - 1 do begin
         xpoints[vert_i] = coords_arr[vert_i*2]
         ypoints[vert_i] = coords_arr[vert_i*2+1]
       endfor

       if (xpoints[0] ne xpoints[n_vert-1] OR $
           ypoints[0] ne ypoints[n_vert-1]) then begin
         xpoints1 = fltarr(n_vert+1)
         ypoints1 = fltarr(n_vert+1)
         xpoints1[0:n_vert-1] = xpoints
         ypoints1[0:n_vert-1] = ypoints
         xpoints1[n_vert] = xpoints[0]
         ypoints1[n_vert] = ypoints[0]
         xpoints = xpoints1
         ypoints = ypoints1
       endif

       xcenter = total(xpoints) / n_elements(xpoints)
       ycenter = total(ypoints) / n_elements(ypoints)

       plots, xpoints, ypoints,  $
           _extra = (*(plot_ptr[iplot])).options         

       if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
         alignment=0.5, _extra = (*(plot_ptr[iplot])).options, /device
    end
    'line': begin
        x1 = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
                    state.zoom_factor
        y1 = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
                    state.zoom_factor
        x2 = (float(coords_arr[2]) - state.offset[0] + 0.5) * $
                    state.zoom_factor
        y2 = (float(coords_arr[3]) - state.offset[1] + 0.5) * $
                    state.zoom_factor

        xpoints = [x1,x2]
        ypoints = [y1,y2]
        xcenter = total(xpoints) / n_elements(xpoints)
        ycenter = total(ypoints) / n_elements(ypoints)

        plots, xpoints, ypoints, /device, $
          _extra = (*(plot_ptr[iplot])).options

        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(plot_ptr[iplot])).options, /device
    end
    else: begin

    end

    endcase

endfor

smtv_resetwindow
state.newrefresh=1
end

;----------------------------------------------------------------------

pro smtv_plot1contour, iplot
common smtv_pdata
common smtv_state

; Overplot contours on the image

smtv_setwindow, state.draw_window_id
widget_control, /hourglass

xrange = !x.crange
yrange = !y.crange

; The following allows for 2 conditions, depending upon whether X and Y
; are set

dims = size( (*(plot_ptr[iplot])).z,/dim )

if (size( (*(plot_ptr[iplot])).x,/N_elements ) EQ dims[0] $
    AND size( (*(plot_ptr[iplot])).y,/N_elements) EQ dims[1] ) then begin
    
    contour, (*(plot_ptr[iplot])).z, (*(plot_ptr[iplot])).x, $
      (*(plot_ptr[iplot])).y, $
      position=[0,0,1,1], xrange=xrange, yrange=yrange, $
      xstyle=5, ystyle=5, /noerase, $
      _extra = (*(plot_ptr[iplot])).options
    
endif else begin
    
    contour, (*(plot_ptr[iplot])).z, $
      position=[0,0,1,1], xrange=xrange, yrange=yrange, $
      xstyle=5, ystyle=5, /noerase, $
      _extra = (*(plot_ptr[iplot])).options
          
endelse

smtv_resetwindow
state.newrefresh=1
end

;---------------------------------------------------------------------

pro smtv_plot1compass, iplot

; Uses idlastro routine arrows to plot compass arrows.

common smtv_pdata
common smtv_state

smtv_setwindow, state.draw_window_id

widget_control, /hourglass

arrows, *(state.head_ptr), $
  (*(plot_ptr[iplot])).x, $
  (*(plot_ptr[iplot])).y, $
  thick = (*(plot_ptr[iplot])).thick, $
  charsize = (*(plot_ptr[iplot])).charsize, $
  arrowlen = (*(plot_ptr[iplot])).arrowlen, $
  color = (*(plot_ptr[iplot])).color, $
  notvertex = (*(plot_ptr[iplot])).notvertex, $
  /data

smtv_resetwindow
state.newrefresh=1
end

;---------------------------------------------------------------------

pro smtv_plot1scalebar, iplot

; uses modified version of idlastro routine arcbar to plot a scalebar

common smtv_pdata
common smtv_state

smtv_setwindow, state.draw_window_id
widget_control, /hourglass

; routine arcbar doesn't recognize color=0, because it uses 
; keyword_set to check the color.  So we need to set !p.color = 0
; to get black if the user wants color=0

!p.color = 0

smtv_arcbar, *(state.head_ptr), $
  (*(plot_ptr[iplot])).arclen, $
  position = (*(plot_ptr[iplot])).position, $
  thick = (*(plot_ptr[iplot])).thick, $
  size = (*(plot_ptr[iplot])).size, $
  color = (*(plot_ptr[iplot])).color, $
  seconds = (*(plot_ptr[iplot])).seconds, $
  /data

smtv_resetwindow
state.newrefresh=1
end

;----------------------------------------------------------------------

pro smtv_arcbar, hdr, arclen, LABEL = label, SIZE = size, THICK = thick, $
                DATA =data, COLOR = color, POSITION = position, $
                NORMAL = normal, SECONDS=SECONDS

common smtv_state

; This is a copy of the IDL Astronomy User's Library routine 'arcbar',
; abbreviated for smtv and modified to work with zoomed images.  For
; the revision history of the original arcbar routine, look at
; arcbar.pro in the pro/astro subdirectory of the IDL Astronomy User's
; Library.

; Modifications for smtv:
; Modified to work with zoomed SMTV images, AJB Jan. 2000 
; Moved text label upwards a bit for better results, AJB Jan. 2000

On_error,2                      ;Return to caller
 
extast, hdr, bastr, noparams    ;extract astrom params in deg.
 
if N_params() LT 2 then arclen = 1 ;default size = 1 arcmin

if not keyword_set( SIZE ) then size = 1.0
if not keyword_set( THICK ) then thick = !P.THICK
if not keyword_set( COLOR ) then color = !P.COLOR

a = bastr.crval[0]
d = bastr.crval[1]
if keyword_set(seconds) then factor = 3600.0d else factor = 60.0
d1 = d + (1/factor)             ;compute x,y of crval + 1 arcmin

proj = strmid(bastr.ctype[0],5,3)

case proj of 
    'GSS': gsssadxy, bastr, [a,a], [d,d1], x, y
    else:  ad2xy, [a,a], [d,d1], bastr, x, y 
endcase

dmin = sqrt( (x[1]-x[0])^2 + (y[1]-y[0])^2 ) ;det. size in pixels of 1 arcmin

if (!D.FLAGS AND 1) EQ 1 then begin ;Device have scalable pixels?
    if !X.s[1] NE 0 then begin
        dmin = convert_coord( dmin, 0, /DATA, /TO_DEVICE) - $ 
          convert_coord(    0, 0, /DATA, /TO_DEVICE) ;Fixed Apr 97
        dmin = dmin[0]
    endif else dmin = dmin/sxpar(hdr, 'NAXIS1' ) ;Fixed Oct. 96
endif else  dmin = dmin * state.zoom_factor    ; added by AJB Jan. '00

dmini2 = round(dmin * arclen)

if keyword_set(NORMAL) then begin
    posn = convert_coord(position,/NORMAL, /TO_DEVICE) 
    xi = posn[0] & yi = posn[1]
endif else if keyword_set(DATA) then begin
    posn = convert_coord(position,/DATA, /TO_DEVICE) 
    xi = posn[0] & yi = posn[1]
endif else begin
    xi = position[0]   & yi = position[1]
endelse         


xf = xi + dmini2
dmini3 = dmini2/10       ;Height of vertical end bars = total length/10.

plots,[xi,xf],[yi,yi], COLOR=color, /DEV, THICK=thick
plots,[xf,xf],[ yi+dmini3, yi-dmini3 ], COLOR=color, /DEV, THICK=thick
plots,[xi,xi],[ yi+dmini3, yi-dmini3 ], COLOR=color, /DEV, THICK=thick

if not keyword_set(Seconds) then begin
    if (!D.NAME EQ 'PS') and (!P.FONT EQ 0) then $ ;Postscript Font?
      arcsym='!9'+string(162B)+'!X' else arcsym = "'" 
endif else begin
    if (!D.NAME EQ 'PS') and (!P.FONT EQ 0) then $ ;Postscript Font?
      arcsym = '!9'+string(178B)+'!X' else arcsym = "''" 
endelse
if not keyword_set( LABEL) then begin
    if (arclen LT 1) then arcstr = string(arclen,format='(f4.2)') $
    else arcstr = string(arclen)
    label = strtrim(arcstr,2) + arcsym 
endif

; AJB modified this to move the numerical label upward a bit: 5/8/2000
xyouts,(xi+xf)/2, (yi+(dmini2/10)), label, SIZE = size,COLOR=color,$
  /DEV, alignment=.5, CHARTHICK=thick

return
end

;----------------------------------------------------------------------

pro smtv_plotwindow
common smtv_state

smtv_setwindow, state.draw_window_id

; Set plot window
xrange=[state.offset[0], $
 state.offset[0] + state.draw_window_size[0] / state.zoom_factor] - 0.5
yrange=[state.offset[1], $
 state.offset[1] + state.draw_window_size[1] / state.zoom_factor] - 0.5

plot, [0], [0], /nodata, position=[0,0,1,1], $
 xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, /noerase

smtv_resetwindow
end

;----------------------------------------------------------------------

pro smtv_plotall
common smtv_state
common smtv_pdata

; Routine to overplot all line, text, and contour plots

if (nplot EQ 0) then return

smtv_plotwindow

for iplot = 1, nplot do begin
    case (*(plot_ptr[iplot])).type of
        'points'  : smtv_plot1plot, iplot
        'text'    : smtv_plot1text, iplot
        'arrow'   : smtv_plot1arrow, iplot
        'contour' : smtv_plot1contour, iplot
        'compass' : smtv_plot1compass, iplot
        'scalebar': smtv_plot1scalebar, iplot
;<<<<<<< smtv_jb.pro
        'region'  : smtv_plot1region, iplot
        'wcsgrid' : smtv_plot1wcsgrid, iplot
;=======
        'colorbar': smtv_plot1colorbar, iplot
;>>>>>>> smtv_ks.pro
        else      : print, 'Problem in smtv_plotall!'   
    endcase
endfor

end

;----------------------------------------------------------------------

pro smtvplot, x, y, _extra = options
common smtv_pdata
common smtv_state

; Routine to read in line plot data and options, store in a heap
; variable structure, and plot the line plot

if (not(xregistered('smtv', /noshow))) then begin
    print, 'You need to start SMTV first!'
    return
endif

if (N_params() LT 1) then begin
   print, 'Too few parameters for SMTVPLOT.'
   return
endif

if (n_elements(options) EQ 0) then options = {color: 'red'}

if (nplot LT maxplot) then begin
   nplot = nplot + 1

;  convert color names to index numbers, and set default=red
   c = where(tag_names(options) EQ 'COLOR', count)
   if (count EQ 0) then options = create_struct(options, 'color', 'red')
   options.color = smtv_icolor(options.color)

   pstruct = {type: 'points',   $     ; points
              x: x,             $     ; x coordinate
              y: y,             $     ; y coordinate
              options: options  $     ; plot keyword options
             }

   plot_ptr[nplot] = ptr_new(pstruct)

   smtv_plotwindow
   smtv_plot1plot, nplot

endif else begin
   print, 'Too many calls to SMTVPLOT.'
endelse

end

;----------------------------------------------------------------------

pro smtvxyouts, x, y, text, _extra = options
common smtv_pdata
common smtv_state

; Routine to read in text overplot string and options, store in a heap
; variable structure, and overplot the text

if (not(xregistered('smtv', /noshow))) then begin
    print, 'You need to start SMTV first!'
    return
endif

if (N_params() LT 3) then begin
   print, 'Too few parameters for SMTVXYOUTS'
   return
endif

if (n_elements(options) EQ 0) then options = {color: 'red'}

if (nplot LT maxplot) then begin
   nplot = nplot + 1

;  convert color names to index numbers, and set default=red
   c = where(tag_names(options) EQ 'COLOR', count)
   if (count EQ 0) then options = create_struct(options, 'color', 'red')
   options.color = smtv_icolor(options.color)

;  set default font to 1
   c = where(tag_names(options) EQ 'FONT', count)
   if (count EQ 0) then options = create_struct(options, 'font', 1)

   pstruct = {type: 'text',   $       ; type of plot 
              x: x,             $     ; x coordinate
              y: y,             $     ; y coordinate
              text: text,       $     ; text to plot
              options: options  $     ; plot keyword options
             }

   plot_ptr[nplot] = ptr_new(pstruct)

   smtv_plotwindow
   smtv_plot1text, nplot

endif else begin
   print, 'Too many calls to SMTVPLOT.'
endelse

end

;----------------------------------------------------------------------

pro smtvarrow, x1, y1, x2, y2, _extra = options
common smtv_pdata
common smtv_state

; Routine to read in arrow overplot options, store in a heap
; variable structure, and overplot the arrow

if (not(xregistered('smtv', /noshow))) then begin
    print, 'You need to start SMTV first!'
    return
endif

if (N_params() LT 4) then begin
   print, 'Too few parameters for SMTVARROW'
   return
endif

if (n_elements(options) EQ 0) then options = {color: 'red'}

if (nplot LT maxplot) then begin
   nplot = nplot + 1

;  convert color names to index numbers, and set default=red
   c = where(tag_names(options) EQ 'COLOR', count)
   if (count EQ 0) then options = create_struct(options, 'color', 'red')
   options.color = smtv_icolor(options.color)

   pstruct = {type: 'arrow',   $       ; type of plot 
              x1: x1,             $     ; x1 coordinate
              y1: y1,             $     ; y1 coordinate
              x2: x2,             $     ; x2 coordinate
              y2: y2,             $     ; y2 coordinate     
              options: options  $     ; plot keyword options
             }

   plot_ptr[nplot] = ptr_new(pstruct)

   smtv_plotwindow
   smtv_plot1arrow, nplot

endif else begin
   print, 'Too many calls to SMTVPLOT.'
endelse

end

;----------------------------------------------------------------------

pro smtvregionfile, region_file
common smtv_state
common smtv_pdata

; Routine to read in region filename, store in a heap variable
; structure, and overplot the regions

if (not(xregistered('smtv', /noshow))) then begin
    print, 'You need to start SMTV first!'
    return
endif

if (nplot LT maxplot) then begin
   nplot = nplot + 1

options = {color: 'green'}
options.color = smtv_icolor(options.color)

readfmt, region_file, 'a200', reg_array, /silent

pstruct = {type:'region', $            ; type of plot
           reg_array: reg_array, $     ; array of regions to plot
           options: options $          ; plot keyword options
          }

plot_ptr[nplot] = ptr_new(pstruct)

smtv_plotwindow
smtv_plot1region, nplot

endif else begin
  print, 'Too many calls to SMTVPLOT.'
endelse

end

;----------------------------------------------------------------------

pro smtv_regionlabel_event, event

; Event handler for smtv_regionlabel.  Region plot structure created from
; information in form widget.  Plotting routine smtv_plot1region is
; then called.

common smtv_state
common smtv_pdata

  CASE event.tag OF
  
  'REG_OPT' : BEGIN
       CASE event.value OF
         '0' : BEGIN
             widget_control,(*state.reg_ids_ptr)[3],Sensitive=1 
             widget_control,(*state.reg_ids_ptr)[4],Sensitive=1
             widget_control,(*state.reg_ids_ptr)[5],Sensitive=1
             widget_control,(*state.reg_ids_ptr)[6],Sensitive=1
             widget_control,(*state.reg_ids_ptr)[7],Sensitive=0         
             widget_control,(*state.reg_ids_ptr)[8],Sensitive=0
             widget_control,(*state.reg_ids_ptr)[9],Sensitive=0         
             widget_control,(*state.reg_ids_ptr)[10],Sensitive=0  
             widget_control,(*state.reg_ids_ptr)[11],Sensitive=0
         END
         '1' : BEGIN
             widget_control,(*state.reg_ids_ptr)[3],Sensitive=1 
             widget_control,(*state.reg_ids_ptr)[4],Sensitive=1
             widget_control,(*state.reg_ids_ptr)[5],Sensitive=1
             widget_control,(*state.reg_ids_ptr)[6],Sensitive=1
             widget_control,(*state.reg_ids_ptr)[7],Sensitive=0         
             widget_control,(*state.reg_ids_ptr)[8],Sensitive=0
             widget_control,(*state.reg_ids_ptr)[9],Sensitive=0         
             widget_control,(*state.reg_ids_ptr)[10],Sensitive=0
             widget_control,(*state.reg_ids_ptr)[11],Sensitive=1         
         END
         '2' : BEGIN
             widget_control,(*state.reg_ids_ptr)[3],Sensitive=1 
             widget_control,(*state.reg_ids_ptr)[4],Sensitive=1
             widget_control,(*state.reg_ids_ptr)[5],Sensitive=1
             widget_control,(*state.reg_ids_ptr)[6],Sensitive=1
             widget_control,(*state.reg_ids_ptr)[7],Sensitive=0
             widget_control,(*state.reg_ids_ptr)[8],Sensitive=0
             widget_control,(*state.reg_ids_ptr)[9],Sensitive=0         
             widget_control,(*state.reg_ids_ptr)[10],Sensitive=0
             widget_control,(*state.reg_ids_ptr)[11],Sensitive=1
         END
         '3' : BEGIN
             widget_control,(*state.reg_ids_ptr)[3],Sensitive=0 
             widget_control,(*state.reg_ids_ptr)[4],Sensitive=0
             widget_control,(*state.reg_ids_ptr)[5],Sensitive=0
             widget_control,(*state.reg_ids_ptr)[6],Sensitive=0
             widget_control,(*state.reg_ids_ptr)[7],Sensitive=1
             widget_control,(*state.reg_ids_ptr)[8],Sensitive=1
             widget_control,(*state.reg_ids_ptr)[9],Sensitive=1         
             widget_control,(*state.reg_ids_ptr)[10],Sensitive=1  
             widget_control,(*state.reg_ids_ptr)[11],Sensitive=0
         END
           ELSE:
     ENDCASE

 END

   'QUIT': BEGIN
         if ptr_valid(state.reg_ids_ptr) then ptr_free, state.reg_ids_ptr
         widget_control, event.top, /destroy
     END

   'DRAW': BEGIN
       IF (nplot LT maxplot) then begin

         nplot = nplot + 1

         reg_type = ['circle','box','ellipse','line']
         reg_color = ['red','black','green','blue','cyan','magenta', $
                      'yellow','white']
         coords_type = ['Pixel', 'J2000','B1950', $
                        'Galactic','Ecliptic', 'Native']
         reg_index = widget_info((*state.reg_ids_ptr)[0], /droplist_select)
         color_index = widget_info((*state.reg_ids_ptr)[1], /droplist_select)
         coords_index = widget_info((*state.reg_ids_ptr)[2], /droplist_select) 
         widget_control,(*state.reg_ids_ptr)[3],get_value=xcenter 
         widget_control,(*state.reg_ids_ptr)[4],get_value=ycenter           
         widget_control,(*state.reg_ids_ptr)[5],get_value=xwidth
         widget_control,(*state.reg_ids_ptr)[6],get_value=ywidth
         widget_control,(*state.reg_ids_ptr)[7],get_value=x1            
         widget_control,(*state.reg_ids_ptr)[8],get_value=y1
         widget_control,(*state.reg_ids_ptr)[9],get_value=x2       
         widget_control,(*state.reg_ids_ptr)[10],get_value=y2
         widget_control,(*state.reg_ids_ptr)[11],get_value=angle
         widget_control,(*state.reg_ids_ptr)[12],get_value=thick
         widget_control,(*state.reg_ids_ptr)[13],get_value=text_str
         text_str = strcompress(text_str[0],/remove_all)
  
         CASE reg_type[reg_index] OF 

         'circle': BEGIN
           region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
             ycenter + ', ' + xwidth  
           if (coords_index ne 0 and coords_index ne 5) then $
             region_str = region_str + ', ' + coords_type[coords_index]
           region_str = region_str + ') # color=' + reg_color[color_index]
         END

         'box': BEGIN
           region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
             ycenter + ', ' + xwidth + ', ' + ywidth + ', ' + angle 
           if (coords_index ne 0 and coords_index ne 5) then $
             region_str = region_str + ', ' + coords_type[coords_index]
           region_str = region_str + ') # color=' + reg_color[color_index]
         END

         'ellipse': BEGIN
           region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
             ycenter + ', ' + xwidth + ', ' + ywidth + ', ' + angle
           if (coords_index ne 0 and coords_index ne 5) then $
             region_str = region_str + ', ' + coords_type[coords_index]
           region_str = region_str + ') # color=' + reg_color[color_index]
         END

         'line': BEGIN
           region_str = reg_type[reg_index] + '(' + x1 + ', ' + y1 + ', ' + $
             x2 + ', ' + y2
           if (coords_index ne 0 and coords_index ne 5) then $
             region_str = region_str + ', ' + coords_type[coords_index]
           region_str = region_str + ') # color=' + reg_color[color_index]
         END
         ENDCASE

         if (text_str ne '') then region_str = region_str + $
            'text={' + text_str + '}'

         options = {color: reg_color[color_index], $
                    thick:thick}
         options.color = smtv_icolor(options.color)

         pstruct = {type:'region', $          ;type of plot
                    reg_array:[region_str], $ ;region array to plot
                    options: options $
                    }

         plot_ptr[nplot] = ptr_new(pstruct)

         smtv_plotwindow
         smtv_plot1region, nplot

       ENDIF ELSE BEGIN
         print, 'Too many calls to SMTVPLOT.'
       ENDELSE

;       if ptr_valid(state.reg_ids_ptr) then ptr_free, state.reg_ids_ptr
;       widget_control, event.top, /destroy

     END

  ELSE:
  ENDCASE

end

;----------------------------------------------------------------------

pro smtv_wcsgrid, _extra = options

common smtv_state
common smtv_pdata

; Routine to read in wcs overplot options, store in a heap variable
; structure, and overplot the grid

if (not(xregistered('smtv', /noshow))) then begin
    print, 'You need to start SMTV first!'
    return
endif

if (nplot LT maxplot) then begin
   nplot = nplot + 1

; set default font to 1
  c = where(tag_names(options) EQ 'FONT', count)
  if (count EQ 0) then options = create_struct(options, 'font', 1)

pstruct = {type:'wcsgrid', $            ; type of plot
           options: options $           ; plot keyword options
          }

plot_ptr[nplot] = ptr_new(pstruct)

smtv_plotwindow
smtv_plot1wcsgrid, nplot

endif else begin
  print, 'Too many calls to SMTVPLOT.'
endelse

end

;----------------------------------------------------------------------
pro smtv_plot1wcsgrid,iplot

   common smtv_pdata
   common smtv_state
   common smtv_images

   if (NOT ptr_valid(state.astr_ptr)) then begin
      smtv_message, 'WCS Regions cannot be displayed on image without WCS', $
        msgtype='error', /window
      return
   endif

   smtv_setwindow, state.draw_window_id
   neglatflag=0
   nx = state.image_size[0]
   ny = state.image_size[1]

   ;;Get the drawing device coordinates
   lowerleft = round( (0.5 >  (([0,0] / state.zoom_factor) + state.offset)< (state.image_size[0:1] - 0.5) ) - 0.5)
   upperright = round( (0.5 >  (([state.draw_window_size] / state.zoom_factor) $
                                + state.offset)< (state.image_size[0:1] - 0.5) ) - 0.5)
   x0 = lowerleft[0]+(0.1*(upperright[0]-lowerleft[0]))
   y0 = lowerleft[1]+(0.1*(upperright[1]-lowerleft[1]))
   xmax = lowerleft[0]+(0.95*(upperright[0]-lowerleft[0]))
   ymax = lowerleft[1]+(0.95*(upperright[1]-lowerleft[1]))

   ;;Transform them to longitude and latitude
   xy2ad,lowerleft[0],lowerleft[1],*(state.astr_ptr),drlon0,drlat0
   xy2ad,upperright[0],upperright[1],*(state.astr_ptr),drlonmax,drlatmax
   xy2ad,x0,x0,*(state.astr_ptr),lon0,lat0 ;;Same variables, just different naming
   xy2ad,xmax,ymax,*(state.astr_ptr), lonmax, latmax

   ;;Temporary
   ;if lat0 lt 0 and latmax lt 0 then begin
   ;    tempo = lat0
   ;    lat0 = abs(latmax)
   ;    latmax = abs(tempo)
   ;    neglatflag = 1
   ;endif

   ;;Get the sexadecimal coordinates of the draw window
   radec, lon0, lat0, hr0, min0, sec0, deg0, arcmin0, arcsec0
   radec, lonmax, latmax, hrmax, minmax, secmax, degmax, arcminmax, arcsecmax

   ;;We want the floor in longitude since west goes down!
   nicelon0 = (360./24.)*ten(hr0,min0,floor(sec0))
   nicelon0sxd = [hr0,min0,floor(sec0)]
   nicelat0 = ten(deg0,arcmin0,floor(arcsec0))
   nicelat0sxd = [deg0,arcmin0,floor(arcsec0)]
   ;;Transform to decimal degrees.
   nicelonmax = (360./24.)*ten(hrmax,minmax,round(secmax))
   nicelatmax = ten(degmax,arcminmax,round(arcsecmax))

   ;;This step finds which is the biggest step up (either Hr, min or
   ;;sec or deg arcmin arcsec) and assign the number of ticks.
   lonsteps = [hr0-hrmax,min0-minmax,floor(sec0-secmax)]
   latsteps = [degmax-deg0,arcminmax-arcmin0,round(arcsecmax-arcsec0)]
   ilongstep = where(lonsteps ne 0.0,cntlongstep)
   ilatstep = where(latsteps ne 0.0,cntlatstep)
   ;;Hummm, there seems to be no increments.....
   if (cntlongstep eq 0 or cntlatstep eq 0) then begin
       print,'Error in coordinates, smtv_plot1wcsgrid'
       return
   endif
   if cntlongstep eq 1 then dmaxlon=lonsteps[2]
   if cntlongstep eq 2 then dmaxlon=lonsteps[1]
   if cntlongstep eq 3 then dmaxlon=lonsteps[0]
   if cntlatstep eq 1 then dmaxlat=latsteps[2]
   if cntlatstep eq 2 then dmaxlat=latsteps[1]
   if cntlatstep eq 3 then dmaxlat=latsteps[0]
   nxticks = dmaxlon
   nyticks = abs(dmaxlat)
   ;;This references between the fields not equal to 0 and a regular
   ;;index
   lonindex = -cntlongstep + 3
   latindex = -cntlatstep + 3

   ;;Assign a value (increment 1) to all the tick marks.
   case lonindex of
       2: begin
           for i = 0, nxticks - 1 do begin
               if i eq 0 then begin
                   nicelonv = nicelon0sxd 
               endif else begin
                   nicelonv = [ [nicelonv],[nicelon0sxd] ]
                   nicelonv[lonindex,i] = nicelon0sxd[lonindex]-i
               endelse
           endfor
       end
   endcase
   case latindex of
       2:begin
           for i = 0, nyticks - 1 do begin
               if i eq 0 then begin
                   nicelsmtv = nicelat0sxd
               endif else begin
                   nicelsmtv = [ [nicelsmtv],[nicelat0sxd] ]
                   nicelsmtv[latindex,i] = nicelat0sxd[latindex]+i
               endelse
           endfor
       end
       1:begin
           nicelsmtv = [ [-25,17,40], $
                        [-25,17,20], $
                        [-25,17,00] ]
           ;;ndivisions = 15
           ;;for i = 0, 14 do begin
               ;;if i eq 0 then begin
                   ;;nicelsmtv = nicelat0sxd
               ;;endif else begin
                   ;;nicelsmtv = [ [nicelsmtv],[nicelat0sxd] ]
                   ;;nicelsmtv[2,i] = nicelat0sxd[2;]+i
               ;;endelse                   
           ;;endfor           
       end
   endcase

   if neglatflag eq 1 then nicelsmtv = nicelsmtv*(-1)

   ;;Now that we have the "nice" coordinates, build the x and y
   ;;vectors for plotting
   for i = 0, n_elements(nicelonv[0,*]) - 1  do begin
       nlon = (360./24.)*ten(nicelonv[0,i],nicelonv[1,i],nicelonv[2,i])
       nlat = ten(nicelsmtv[0,0],nicelsmtv[1,0],nicelsmtv[2,0])
       ad2xy,nlon,nlat,*(state.astr_ptr),x,dump
       if i eq 0 then nxvect = x else nxvect = [nxvect,x]
       if i eq 0 then lontick = nlon else lontick = [lontick,nlon]
       if i eq 0 then xtickname = '0'+strtrim(string(nicelonv[0,i]),2)+'h'+strtrim(string(nicelonv[1,i]),2)+'m'+strtrim(string(nicelonv[2,i]),2)+'s' $
         else begin
           tempxtickname = strtrim(string(nicelonv[1,i]),2)+'m'+strtrim(string(nicelonv[2,i]),2)+'s'
           xtickname = [xtickname,tempxtickname]
       endelse
   endfor
   for i = 0, n_elements(nicelsmtv[0,*]) - 1  do begin
       nlon = (360./24.)*ten(nicelonv[0,0],nicelonv[1,0],nicelonv[2,0])
       nlat = ten(nicelsmtv[0,i],nicelsmtv[1,i],nicelsmtv[2,i])
       ad2xy,nlon,nlat,*(state.astr_ptr),dump,y
       if i eq 0 then nyvect=y else nyvect=[nyvect,y]
       if i eq 0 then lattick = nlat else lattick = [lattick,nlat]
       if (i eq 0) then ytickname = strtrim(string(nicelsmtv[0,i]),2)+'d'+strtrim(string(nicelsmtv[1,i]),2)+"'" +strtrim(string(nicelsmtv[2,i]),2)+"''" $
         else begin
           tempytickname = strtrim(string(nicelsmtv[1,i]),2)+"'"+strtrim(string(nicelsmtv[2,i]),2)+"''"
           ytickname = [ytickname,tempytickname]
       endelse
   endfor

   ;;This is derived from translation/contraction change of coordinates
   xtickv = (lontick - drlon0 - 0.11*(drlonmax-drlon0))/(0.79*(drlonmax-drlon0))
   ytickv = (lattick - drlat0 - 0.13*(drlatmax-drlat0))/(0.77*(drlatmax-drlat0))
   xticks = n_elements(xtickv) - 1
   yticks = n_elements(ytickv) - 1
   plot,[0,1],[0,1],/normal,/nodata,/noerase,position=[0.11,0.13,0.90,0.90],color=0, $
     xticks = xticks,xtickv=xtickv,xtickname=xtickname,xminor=10, $
     yticks = yticks,ytickv=ytickv,ytickname=ytickname,yminor=4, $
     charsize=0.9,xtitle = 'RA (J2000)', ytitle = 'DEC (J2000)'

   ;stop   
end
;----------------------------------------------------------------------
pro smtvcontour, z, x, y, _extra = options
common smtv_pdata
common smtv_state

; Routine to read in contour plot data and options, store in a heap
; variable structure, and overplot the contours.  Data to be contoured
; need not be the same dataset displayed in the smtv window, but it
; should have the same x and y dimensions in order to align the
; overplot correctly.

if (not(xregistered('smtv', /noshow))) then begin
    print, 'You need to start SMTV first!'
    return
endif

if (N_params() LT 1) then begin
   print, 'Too few parameters for SMTVCONTOUR.'
   return
endif

if (n_params() EQ 1 OR n_params() EQ 2) then begin
    x = 0
    y = 0
endif

if (n_elements(options) EQ 0) then options = {c_color: 'red'}

if (nplot LT maxplot) then begin
   nplot = nplot + 1

;  convert color names to index numbers, and set default=red
   c = where(tag_names(options) EQ 'C_COLOR', count)
   if (count EQ 0) then options = create_struct(options, 'c_color', 'red')
   options.c_color = smtv_icolor(options.c_color)

   pstruct = {type: 'contour',  $     ; type of plot
              z: z,             $     ; z values
              x: x,             $     ; x coordinate
              y: y,             $     ; y coordinate
              options: options  $     ; plot keyword options
             }

   plot_ptr[nplot] = ptr_new(pstruct)

   smtv_plotwindow
   smtv_plot1contour, nplot

endif else begin
   print, 'Too many calls to SMTVCONTOUR.'
endelse

end

;----------------------------------------------------------------------

pro smtvcolorbar,_extra=options

   common smtv_pdata
   common smtv_state

   if (not(xregistered('smtv', /noshow))) then begin
      print, 'You need to start SMTV first!'
      return
   endif

   if (nplot lt maxplot) then begin
      nplot=nplot+1;

      pstruct = {type:'colorbar', $
                 options: options $
                };
      plot_ptr[nplot] = ptr_new(pstruct);

      smtv_plotwindow
      smtv_plot1colorbar, nplot

   endif else begin
      print,'Too many calls to SMTVCOLORBAR'
   endelse
end

;----------------------------------------------------------------------

pro smtv_plot1colorbar,iplot
   common smtv_pdata
   common smtv_state

   smtv_setwindow, state.draw_window_id
   wsize = state.draw_window_size
   widget_control, /hourglass

   position = (*(plot_ptr[iplot])).options.position
   range = (*(plot_ptr[iplot])).options.range
   minrange=range[0]
   maxrange=range[1]
   invertcolors = (*(plot_ptr[iplot])).options.invertcolors
   color = (*(plot_ptr[iplot])).options.color
   title = (*(plot_ptr[iplot])).options.title
   format = (*(plot_ptr[iplot])).options.format
   charsize=1
   ticklen=0.2
   font = !P.Font
   minor = 2
   divisions=(*(plot_ptr[iplot])).options.divisions

   xstart = position[0]
   ystart = position[1]

   xsize = (position(2) - position(0))
   ysize = (position(3) - position(1))

   csize = ceil((position[2]-position[0])*wsize[0])

   b = congrid( findgen(state.ncolors), csize) + 8
   c = replicate(1,ceil(ysize*wsize[1]))
   a = b # c
   if invertcolors then a=reverse(a,1)
   tv, a,xstart,ystart,xsize=xsize,ysize=ysize,/normal

   PLOT, [minrange,maxrange], [minrange,maxrange], /NODATA, XTICKS=divisions, $
     YTICKS=1, XSTYLE=1, YSTYLE=1, TITLE=title, $
     POSITION=position, COLOR=color, CHARSIZE=charsize, /NOERASE, $
     YTICKFORMAT='(A1)', XTICKFORMAT=format, XTICKLEN=ticklen, $
     XRANGE=[minrange, maxrange], FONT=font, XMinor=minor, _EXTRA=extra
   
   ;stop
   smtv_resetwindow
   state.newrefresh=1

end

;----------------------------------------------------------------------

pro smtverase, nerase, norefresh = norefresh
common smtv_pdata

; Routine to erase line plots from SMTVPLOT, text from SMTVXYOUTS,
; arrows from SMTVARROW and contours from SMTVCONTOUR.

if (n_params() LT 1) then begin
    nerase = nplot
endif else begin
    if (nerase GT nplot) then nerase = nplot
endelse

for iplot = nplot - nerase + 1, nplot do begin
    ptr_free, plot_ptr[iplot]
    plot_ptr[iplot] = ptr_new()
endfor

nplot = nplot - nerase

if (NOT keyword_set(norefresh)) then smtv_refresh

end

;----------------------------------------------------------------------

pro smtv_textlabel

; widget front end for smtvxyouts

formdesc = ['0, text, , label_left=Text: , width=15', $
            '0, integer, 0, label_left=x: ', $
            '0, integer, 0, label_left=y: ', $
            '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
            '0, float, 2.0, label_left=Charsize: ', $
            '0, integer, 1, label_left=Charthick: ', $
            '0, integer, 0, label_left=Orientation: ', $
            '1, base, , row', $
            '0, button, Cancel, quit', $
            '0, button, DrawText, quit']
            
textform = cw_form(formdesc, /column, $
                   title = 'smtv text label')

if (textform.tag9 EQ 1) then begin
; switch red and black indices
    case textform.tag3 of
        0: labelcolor = 1
        1: labelcolor = 0
        else: labelcolor = textform.tag3
    endcase

    smtvxyouts, textform.tag1, textform.tag2, textform.tag0, $
      color = labelcolor, charsize = textform.tag4, $
      charthick = textform.tag5, orientation = textform.tag6
endif

end

;---------------------------------------------------------------------

pro smtv_arrowlabel

; widget front end for smtvarrow

formdesc = ['0, integer, 0, label_left=x1: ', $
            '0, integer, 0, label_left=y1: ', $
            '0, integer, 0, label_left=x2: ', $
            '0, integer, 0, label_left=y2: ', $
            '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
            '0, float, 1.0, label_left=Arrowthick: ', $
            '0, float, 1.0, label_left=Arrowheadthick: ', $
            '1, base, , row', $
            '0, button, Cancel, quit', $
            '0, button, DrawArrow, quit']
            
textform = cw_form(formdesc, /column, $
                   title = 'smtv arrow')

if (textform.tag9 EQ 1) then begin
; switch red and black indices
    case textform.tag4 of
        0: labelcolor = 1
        1: labelcolor = 0
        else: labelcolor = textform.tag4
    endcase

    smtvarrow, textform.tag0, textform.tag1, textform.tag2, textform.tag3, $
      color = labelcolor, thick = textform.tag5, $
      hthick = textform.tag6

endif

end

;---------------------------------------------------------------------

pro smtv_regionfilelabel

; Routine to load region files into SMTV

common smtv_state
common smtv_images

region_file = dialog_pickfile(/read, filter='*.reg')

;set up an array of strings

if (region_file ne '') then smtvregionfile, region_file $
else return

end

;---------------------------------------------------------------------

pro smtv_regionlabel

; Widget front-end for plotting individual regions on image

if (not(xregistered('smtv_regionlabel', /noshow))) then begin
  common smtv_state
  common smtv_images

  regionbase = widget_base(/row)

  formdesc = ['0, droplist, circle|box|ellipse|line,label_left=Region:, set_value=0, TAG=reg_opt ', $
              '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0, TAG=color_opt ', $
              '0, droplist, Pixel|RA Dec (J2000)|RA Dec (B1950)|Galactic|Ecliptic|Native,label_left=Coords:, set_value=0, TAG=coord_opt ', $
              '0, text, 0, label_left=xcenter: , width=15', $
              '0, text, 0, label_left=ycenter: , width=15', $
              '0, text, 0, label_left=xwidth: , width=15', $
              '0, text, 0, label_left=ywidth: , width=15', $
              '0, text, 0, label_left=x1: , width=15', $
              '0, text, 0, label_left=y1: , width=15', $
              '0, text, 0, label_left=x2: , width=15', $
              '0, text, 0, label_left=y2: , width=15', $
              '0, text, 0.0, label_left=Angle: ', $
              '0, integer, 1, label_left=Thick: ', $
              '0, text,  , label_left=Text: ', $
              '1, base, , row', $
              '0, button, Done, quit, TAG=quit ', $
              '0, button, DrawRegion, quit, TAG=draw']

  regionform = cw_form(regionbase,formdesc, /column,title = 'smtv region',$
                 IDS=reg_ids_ptr)

  widget_control, regionbase, /REALIZE

  reg_ids_ptr = reg_ids_ptr(where(widget_info(reg_ids_ptr,/type) eq 3 OR $
     widget_info(reg_ids_ptr,/type) eq 8))

  if ptr_valid(state.reg_ids_ptr) then ptr_free,state.reg_ids_ptr

  state.reg_ids_ptr = ptr_new(reg_ids_ptr)

  widget_control,(*state.reg_ids_ptr)[6],sensitive=0
  widget_control,(*state.reg_ids_ptr)[7],sensitive=0
  widget_control,(*state.reg_ids_ptr)[8],sensitive=0
  widget_control,(*state.reg_ids_ptr)[9],sensitive=0
  widget_control,(*state.reg_ids_ptr)[10],sensitive=0
  widget_control,(*state.reg_ids_ptr)[11],sensitive=0
  widget_control,(*state.reg_ids_ptr)[3], Set_Value = $
    strcompress(string(state.coord[0]), /remove_all)
  widget_control,(*state.reg_ids_ptr)[4], Set_Value = $
    strcompress(string(state.coord[1]), /remove_all)
  widget_control,(*state.reg_ids_ptr)[7], Set_Value = $
    strcompress(string(state.coord[0]), /remove_all)
  widget_control,(*state.reg_ids_ptr)[8], Set_Value = $
    strcompress(string(state.coord[1]), /remove_all)

  xmanager, 'smtv_regionlabel', regionbase

endif else begin
  widget_control,(*state.reg_ids_ptr)[3], Set_Value = $
    strcompress(string(state.coord[0]), /remove_all)
  widget_control,(*state.reg_ids_ptr)[4], Set_Value = $
    strcompress(string(state.coord[1]), /remove_all)
  widget_control,(*state.reg_ids_ptr)[7], Set_Value = $
    strcompress(string(state.coord[0]), /remove_all)
  widget_control,(*state.reg_ids_ptr)[8], Set_Value = $
    strcompress(string(state.coord[1]), /remove_all)
endelse

end

;---------------------------------------------------------------------

pro smtv_wcsgridlabel

; Front-end widget for WCS labels

formdesc = ['0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Grid Color:, set_value=7 ', $
            '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Label Color:, set_value=2 ', $ 
            '0, float, 1.0, label_left=Charsize: ', $
            '0, integer, 1, label_left=Charthick: ', $
            '1, base, , row', $
            '0, button, Cancel, quit', $
            '0, button, DrawGrid, quit']

gridform=cw_form(formdesc, /column, title = 'SMTV WCS Grid')

gridcolor = gridform.tag0
wcslabelcolor = gridform.tag1

if (gridform.tag6 eq 1) then begin
; switch red and black indices
  case gridform.tag0 of 
    0: gridcolor = 1
    1: gridcolor = 0
    else: gridcolor = gridform.tag0
  endcase

  case gridform.tag1 of
    0: wcslabelcolor = 1
    1: wcslabelcolor = 0
    else: wcslabelcolor = gridform.tag1
  endcase

smtv_wcsgrid, gridcolor=gridcolor, wcslabelcolor=wcslabelcolor, $
  charsize=gridform.tag2, charthick=gridform.tag3

endif

end

;---------------------------------------------------------------------

pro smtv_oplotcontour

; widget front end for smtvcontour

common smtv_state
common smtv_images

minvalstring = strcompress('0, float, ' + string(state.min_value) + $
                           ', label_left=MinValue: , width=15 ')
maxvalstring = strcompress('0, float, ' + string(state.max_value) + $
                           ', label_left=MaxValue: , width=15')

formdesc = ['0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
;            '0, float, 1.0, label_left=Charsize: ', $
;            '0, integer, 1, label_left=Charthick: ', $
            '0, droplist, solid|dotted|dashed|dashdot|dashdotdotdot|longdash, label_left=Linestyle: , set_value=0', $
            '0, integer, 1, label_left=LineThickness: ', $
            minvalstring, $
            maxvalstring, $
            '0, integer, 6, label_left=NLevels: ', $
            '1, base, , row,', $
            '0, button, Cancel, quit', $
            '0, button, DrawContour, quit']
            
cform = cw_form(formdesc, /column, $
                   title = 'smtv text label')


if (cform.tag8 EQ 1) then begin
; switch red and black indices
    case cform.tag0 of
        0: labelcolor = 1
        1: labelcolor = 0
        else: labelcolor = cform.tag0
    endcase

    smtvcontour, main_image, c_color = labelcolor, $
;      c_charsize = cform.tag1, c_charthick = cform.tag2, $
      c_linestyle = cform.tag1, $
      c_thick = cform.tag2, $
      min_value = cform.tag3, max_value = cform.tag4, $, 
      nlevels = cform.tag5
endif

end

;---------------------------------------------------------------------

pro smtv_setcompass

; Routine to prompt user for compass parameters

common smtv_state
common smtv_images
common smtv_pdata

if (nplot GE maxplot) then begin
    smtv_message, 'Total allowed number of overplots exceeded.', $
      msgtype = 'error', /window
    return
endif
    

if (state.wcstype NE 'angle') then begin 
    smtv_message, 'Cannot get coordinate info for this image!', $
      msgtype = 'error', /window
    return
endif

view_min = round(state.centerpix - $
        (0.5 * state.draw_window_size / state.zoom_factor)) 
view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1

xpos = string(round(view_min[0] + 0.15 * (view_max[0] - view_min[0])))
ypos = string(round(view_min[1] + 0.15 * (view_max[1] - view_min[1])))

xposstring = strcompress('0,integer,'+xpos+',label_left=XCenter: ')
yposstring = strcompress('0,integer,'+ypos+',label_left=YCenter: ')

formdesc = [ $
             xposstring, $
             yposstring, $
             '0, droplist, Vertex of Compass|Center of Compass, label_left = Coordinates Specify:, set_value=0', $
             '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
             '0, integer, 1, label_left=LineThickness: ', $
             '0, float, 1, label_left=Charsize: ', $
             '0, float, 3.5, label_left=ArrowLength: ', $
             '1, base, , row,', $
             '0, button, Cancel, quit', $
             '0, button, DrawCompass, quit']
            
cform = cw_form(formdesc, /column, $
                   title = 'smtv compass properties')

if (cform.tag8 EQ 1) then return

cform.tag0 = 0 > cform.tag0 < (state.image_size[0] - 1)
cform.tag1 = 0 > cform.tag1 < (state.image_size[1] - 1)

; switch red and black indices
case cform.tag3 of
    0: labelcolor = 1
    1: labelcolor = 0
    else: labelcolor = cform.tag3
endcase

pstruct = {type: 'compass',  $  ; type of plot
           x: cform.tag0,         $ 
           y: cform.tag1,         $
           notvertex: cform.tag2, $
           color: labelcolor, $
           thick: cform.tag4, $
           charsize: cform.tag5, $
           arrowlen: cform.tag6 $
          }

nplot = nplot + 1
plot_ptr[nplot] = ptr_new(pstruct)

smtv_plotwindow
smtv_plot1compass, nplot

end

;---------------------------------------------------------------------

pro smtv_setscalebar

; Routine to prompt user for scalebar parameters

common smtv_state
common smtv_images
common smtv_pdata

if (nplot GE maxplot) then begin
    smtv_message, 'Total allowed number of overplots exceeded.', $
      msgtype = 'error', /window
    return
endif
    

if (state.wcstype NE 'angle') then begin 
    smtv_message, 'Cannot get coordinate info for this image!', $
      msgtype = 'error', /window
    return
endif

view_min = round(state.centerpix - $
        (0.5 * state.draw_window_size / state.zoom_factor)) 
view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1

xpos = string(round(view_min[0] + 0.75 * (view_max[0] - view_min[0])))
ypos = string(round(view_min[1] + 0.15 * (view_max[1] - view_min[1])))

xposstring = strcompress('0,integer,'+xpos+',label_left=X (left end of bar): ')
yposstring = strcompress('0,integer,'+ypos+',label_left=Y (center of bar): ')

formdesc = [ $
             xposstring, $
             yposstring, $
             '0, float, 5.0, label_left=BarLength: ', $
             '0, droplist, arcsec|arcmin, label_left=Units:,set_value=0', $
             '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
             '0, integer, 1, label_left=LineThickness: ', $
             '0, float, 1, label_left=Charsize: ', $
             '1, base, , row,', $
             '0, button, Cancel, quit', $
             '0, button, DrawScalebar, quit']
            
cform = cw_form(formdesc, /column, $
                   title = 'smtv scalebar properties')

if (cform.tag8 EQ 1) then return

; switch red and black indices
case cform.tag4 of
    0: labelcolor = 1
    1: labelcolor = 0
    else: labelcolor = cform.tag4
endcase


cform.tag0 = 0 > cform.tag0 < (state.image_size[0] - 1)
cform.tag1 = 0 > cform.tag1 < (state.image_size[1] - 1)
cform.tag3 = abs(cform.tag3 - 1)  ; set default to be arcseconds

arclen = cform.tag2
if (float(round(arclen)) EQ arclen) then arclen = round(arclen)

pstruct = {type: 'scalebar',  $  ; type of plot
           arclen: arclen, $
           seconds: cform.tag3, $
           position: [cform.tag0,cform.tag1], $ 
           color: labelcolor, $
           thick: cform.tag5, $
           size: cform.tag6 $
          }

nplot = nplot + 1
plot_ptr[nplot] = ptr_new(pstruct)

smtv_plotwindow
smtv_plot1scalebar, nplot

end

;---------------------------------------------------------------------

pro smtv_saveregion

; Save currently displayed regions to a file

common smtv_state
common smtv_pdata

reg_savefile = dialog_pickfile(file='smtv.reg', filter='*.reg', /write) 

if (reg_savefile ne '') then begin 
  openw, lun, reg_savefile, /get_lun

  for iplot = 1, nplot do begin
    if ((*(plot_ptr[iplot])).type eq 'region') then begin
      n_regions = n_elements((*(plot_ptr[iplot])).reg_array)
      for n = 0, n_regions - 1 do begin
        printf, lun, strcompress((*(plot_ptr[iplot])).reg_array[n],/remove_all)
      endfor
    endif
  endfor

  close, lun
  free_lun, lun
endif else begin
  return
endelse

end

;---------------------------------------------------------------------
;          routines for drawing in the lineplot window
;---------------------------------------------------------------------

pro smtv_lineplot_init

; This routine creates the window for line plots

common smtv_state

state.lineplot_base_id = $
  widget_base(group_leader = state.base_id, $
              /row, $
;              mbar=mbar, $
              /base_align_right, $
              title = 'smtv plot', $
              /tlb_size_events, $
              uvalue = 'lineplot_base')

state.lineplot_widget_id = $
  widget_draw(state.lineplot_base_id, $
              frame = 0, $
              scr_xsize = state.lineplot_size[0], $
              scr_ysize = state.lineplot_size[1], $
              uvalue = 'lineplot_window')

lbutton_base = $
  widget_base(state.lineplot_base_id, $
              /base_align_bottom, $
              /column, frame=2)

;filemenu_base = widget_button(mbar, value='File')
;lineplot_ps = $
;  widget_button(filemenu_base, $
;                value = 'Create PS', $
;                uvalue = 'lineplot_ps')

;lineplot_done = widget_button(filemenu_base, value='Exit', $
;                  uvalue = 'lineplot_done')

state.histbutton_base_id = $
  widget_base(lbutton_base, $
              /base_align_bottom, $
              /column, map=1)

state.x1_pix_id = $
    cw_field(state.histbutton_base_id, $
             /return_events, $
             /floating, $
             title = 'X1:', $
             uvalue = 'lineplot_newrange', $
             xsize = 8)

state.x2_pix_id = $
    cw_field(state.histbutton_base_id, $
             /return_events, $
             /floating, $
             title = 'X2:', $
             uvalue = 'lineplot_newrange', $
             xsize = 8)

state.y1_pix_id = $
    cw_field(state.histbutton_base_id, $
             /return_events, $
             /floating, $
             title = 'Y1:', $
             uvalue = 'lineplot_newrange', $
             xsize = 8)

state.y2_pix_id = $
    cw_field(state.histbutton_base_id, $
             /return_events, $
             /floating, $
             title = 'Y2:', $
             uvalue = 'lineplot_newrange', $
             xsize = 8)

state.histplot_binsize_id = $
    cw_field(state.histbutton_base_id, $
             /return_events, $
             /floating, $
             title = 'Bin:', $
             uvalue = 'lineplot_newrange', $
             xsize = 8)

state.lineplot_xmin_id = $
  cw_field(lbutton_base, $
           /return_events, $
           /floating, $
           title = 'XMin:', $
           uvalue = 'lineplot_newrange', $
           xsize = 8)

state.lineplot_xmax_id = $
  cw_field(lbutton_base, $
           /return_events, $
           /floating, $
           title = 'XMax:', $
           uvalue = 'lineplot_newrange', $
           xsize = 8)

state.lineplot_ymin_id = $
  cw_field(lbutton_base, $
           /return_events, $
           /floating, $
           title = 'YMin:', $
           uvalue = 'lineplot_newrange', $
           xsize = 8)

state.lineplot_ymax_id = $
  cw_field(lbutton_base, $
           /return_events, $
           /floating, $
           title = 'YMax:', $
           uvalue = 'lineplot_newrange', $
           xsize = 8)


state.holdrange_base_id = $
  widget_base(lbutton_base, $
              row = 1, $
              /nonexclusive, frame=1)

state.holdrange_butt_id = $
  widget_button(state.holdrange_base_id, $
                value = 'Hold Ranges', $
                uvalue = 'lineplot_holdrange')

lineplot_fullrange = $
  widget_button(lbutton_base, $
                value = 'AutoScale', $
                uvalue = 'lineplot_fullrange')

lineplot_ps = $
  widget_button(lbutton_base, $
                value = 'Create PS', $
                uvalue = 'lineplot_ps')

lineplot_done = $
  widget_button(lbutton_base, $
                value = 'Done', $
                uvalue = 'lineplot_done')

widget_control, state.lineplot_base_id, /realize
widget_control, state.holdrange_butt_id, set_button=state.holdrange_value

widget_control, state.lineplot_widget_id, get_value = tmp_value
state.lineplot_window_id = tmp_value

lbuttgeom = widget_info(lbutton_base, /geometry)
state.lineplot_min_size[1] = lbuttgeom.ysize

basegeom = widget_info(state.lineplot_base_id, /geometry)
drawgeom = widget_info(state.lineplot_widget_id, /geometry)

state.lineplot_pad[0] = basegeom.xsize - drawgeom.xsize
state.lineplot_pad[1] = basegeom.ysize - drawgeom.ysize
    
xmanager, 'smtv_lineplot', state.lineplot_base_id, /no_block

smtv_resetwindow
end

;--------------------------------------------------------------------

pro smtv_rowplot, ps=ps, update=update

common smtv_state
common smtv_images

if (not (keyword_set(ps))) then begin

; Only initialize plot window and plot ranges to the min/max ranges
; when rowplot window is not already present, plot window is present
; but last plot was not a rowplot, or last plot was a rowplot but the
; 'Hold Range' button is not selected.  Otherwise, use the values
; currently in the min/max boxes

  if (not (xregistered('smtv_lineplot', /noshow))) then begin
    smtv_lineplot_init

    widget_control,state.lineplot_xmin_id, $
      set_value=0

    state.lineplot_xmin = 0.0

    widget_control,state.lineplot_xmax_id, $
      set_value=state.image_size[0]

    state.lineplot_xmax = state.image_size[0]

    widget_control,state.lineplot_ymin_id, $
      set_value=min(main_image[*,state.coord[1]])

    state.lineplot_ymin = min(main_image[*,state.coord[1]])

    widget_control,state.lineplot_ymax_id, $
      set_value=max(main_image[*,state.coord[1]])

    state.lineplot_ymax = max(main_image[*,state.coord[1]]) 

  endif

  widget_control, state.histbutton_base_id, map=0
  widget_control, state.holdrange_butt_id, sensitive=1

  if (state.plot_type ne 'rowplot' OR $
      state.holdrange_value eq 0) then begin

    widget_control,state.lineplot_xmin_id, $
      set_value=0

    state.lineplot_xmin = 0.0

    widget_control,state.lineplot_xmax_id, $
      set_value=state.image_size[0]

    state.lineplot_xmax = state.image_size[0]

    widget_control,state.lineplot_ymin_id, $
      set_value=min(main_image[*,state.coord[1]])

    state.lineplot_ymin = min(main_image[*,state.coord[1]])

    widget_control,state.lineplot_ymax_id, $
      set_value=max(main_image[*,state.coord[1]])

    state.lineplot_ymax = max(main_image[*,state.coord[1]]) 

  endif

  state.plot_type = 'rowplot'
  smtv_setwindow, state.lineplot_window_id
  erase

; must store the coordinates in state structure if you want to make a
; PS plot because state.coord array will change if you move cursor
; before pressing 'Create PS' button

  if (not (keyword_set(update))) then state.plot_coord = state.coord

  plot, main_image[*, state.plot_coord[1]], $
    xst = 3, yst = 3, psym = 10, $
    title = strcompress('Plot of row ' + $
                      string(state.plot_coord[1])), $
    xtitle = 'Column', $
    ytitle = 'Pixel Value', $
    color = 7, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

endif else begin 

  plot, main_image[*, state.plot_coord[1]], $
    xst = 3, yst = 3, psym = 10, $
    title = strcompress('Plot of row ' + $
                      string(state.plot_coord[1])), $
    xtitle = 'Column', $
    ytitle = 'Pixel Value', $
    color = 0, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

endelse

if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  smtv_resetwindow
endif

end

;--------------------------------------------------------------------

pro smtv_colplot, ps=ps, update=update

common smtv_state
common smtv_images

if (not (keyword_set(ps))) then begin

; Only initialize plot window and plot ranges to the min/max ranges
; when colplot window is not already present, plot window is present
; but last plot was not a colplot, or last plot was a colplot but the
; 'Hold Range' button is not selected.  Otherwise, use the values
; currently in the min/max boxes

  if (not (xregistered('smtv_lineplot', /noshow))) then begin
    smtv_lineplot_init

    widget_control,state.lineplot_xmin_id, $
      set_value=0

    state.lineplot_xmin = 0.0

    widget_control,state.lineplot_xmax_id, $
      set_value=state.image_size[1]

    state.lineplot_xmax = state.image_size[1]

    widget_control,state.lineplot_ymin_id, $
      set_value=min(main_image[state.coord[0], *])

    state.lineplot_ymin = min(main_image[state.coord[0], *])

    widget_control,state.lineplot_ymax_id, $
      set_value=max(main_image[state.coord[0], *])

    state.lineplot_ymax = max(main_image[state.coord[0], *]) 

  endif

  widget_control, state.histbutton_base_id, map=0
  widget_control, state.holdrange_butt_id, sensitive=1

  if (state.plot_type ne 'colplot' OR $
      state.holdrange_value eq 0) then begin

    widget_control,state.lineplot_xmin_id, $
      set_value=0

    state.lineplot_xmin = 0.0

    widget_control,state.lineplot_xmax_id, $
      set_value=state.image_size[1]

    state.lineplot_xmax = state.image_size[1]

    widget_control,state.lineplot_ymin_id, $
      set_value=min(main_image[state.coord[0], *])

    state.lineplot_ymin = min(main_image[state.coord[0], *])

    widget_control,state.lineplot_ymax_id, $
      set_value=max(main_image[state.coord[0], *])

    state.lineplot_ymax = max(main_image[state.coord[0], *]) 

  endif

  state.plot_type = 'colplot'
  smtv_setwindow, state.lineplot_window_id
  erase

; must store the coordinates in state structure if you want to make a
; PS plot because state.coord array will change if you move cursor
; before pressing 'Create PS' button

  if (not (keyword_set(update))) then state.plot_coord = state.coord

  plot, main_image[state.plot_coord[0], *], $
    xst = 3, yst = 3, psym = 10, $
    title = strcompress('Plot of column ' + $
                      string(state.plot_coord[0])), $
    xtitle = 'Row', $
    ytitle = 'Pixel Value', $
    color = 7, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

endif else begin 

  plot, main_image[state.plot_coord[0], *], $
    xst = 3, yst = 3, psym = 10, $
    title = strcompress('Plot of column ' + $
                      string(state.plot_coord[0])), $
    xtitle = 'Row', $
    ytitle = 'Pixel Value', $
    color = 0, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

endelse

if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  smtv_resetwindow
endif

end

;--------------------------------------------------------------------

pro smtv_gaussrowplot, ps=ps, update=update

common smtv_state
common smtv_images

if (not (keyword_set(ps))) then begin

; Only initialize plot window and plot ranges to the min/max ranges
; when gaussrowplot window is not already present or plot window is present
; but last plot was not a gaussrowplot.  Otherwise, use the values
; currently in the min/max boxes

  if (not (xregistered('smtv_lineplot', /noshow))) then begin
    smtv_lineplot_init
  endif

  widget_control, state.histbutton_base_id, map=0
  widget_control, state.holdrange_butt_id, sensitive=0

  state.plot_type = 'gaussrowplot'
  smtv_setwindow, state.lineplot_window_id
  erase

; must store the coordinates in state structure if you want to make a
; PS plot because state.coord array will change if you move cursor
; before pressing 'Create PS' button

  if (not (keyword_set(update))) then state.plot_coord = state.coord

  x2=long((state.plot_coord[0]+10.) < (state.image_size[0]-1.))
  x1=long((state.plot_coord[0]-10.) > 0.)
  y2=long((state.plot_coord[1]+2.) < (state.image_size[1]-1))
  y1=long((state.plot_coord[1]-2.) > 0.)
  x=fltarr(x2-x1+1)
  y=fltarr(x2-x1+1)

  n_x = x2-x1+1
  n_y = y2-y1+1

  for i=0, n_x - 1 do begin
    x[i]=x1+i
    y[i]=total(main_image[x[i],y1:y2])/(n_y)
  endfor

  x_interp=interpol(x,1000)
  y_interp=interpol(y,1000)
  yfit=gaussfit(x_interp,y_interp,a,nterms=4)
  peak = a[0]
  center = a[1]
  fwhm = a[2] * 2.354
  bkg = min(yfit)

  if (not (keyword_set(update))) then begin

    widget_control,state.lineplot_xmin_id, $
      set_value=x[0]

    state.lineplot_xmin = x[0]

    widget_control,state.lineplot_xmax_id, $
      set_value=x[n_x-1]

    state.lineplot_xmax = x[n_x-1]
  
    widget_control,state.lineplot_ymin_id, $
      set_value=min(y)

    state.lineplot_ymin = min(y)

    widget_control,state.lineplot_ymax_id, $
      set_value=(max(y) > max(yfit))

    state.lineplot_ymax = max(y) > max(yfit)

  endif

  title_str = 'Rows ' + $
              strcompress(string(y1),/remove_all) + $
              '-' + strcompress(string(y2),/remove_all) + $
              '   Center=' + strcompress(string(center,format='(f10.2)'),/remove_all) + $
              '   Peak=' + strcompress(string(peak,format='(f10.2)'),/remove_all) + $
              '   FWHM=' + strcompress(string(fwhm,format='(f10.2)'),/remove_all) + $
              '   Bkg=' + strcompress(string(bkg,format='(f10.2)'),/remove_all)

  plot,x,y,psym=1,/ynozero, title = title_str, xtitle='Column (pixels)', $
    ytitle='Pixel Value', $
    color = 7, xst = 3, yst = 3, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

  oplot, x_interp, yfit

endif else begin

  x2=long((state.plot_coord[0]+10.) < (state.image_size[0]-1.))
  x1=long((state.plot_coord[0]-10.) > 0.)
  y2=long((state.plot_coord[1]+2.) < (state.image_size[1]-1))
  y1=long((state.plot_coord[1]-2.) > 0.)
  x=fltarr(x2-x1+1)
  y=fltarr(x2-x1+1)

  n_x = x2-x1+1
  n_y = y2-y1+1

  for i=0, n_x - 1 do begin
    x[i]=x1+i
    y[i]=total(main_image[x[i],y1:y2])/(n_y)
  endfor

  x_interp=interpol(x,1000)
  y_interp=interpol(y,1000)
  yfit=gaussfit(x_interp,y_interp,a,nterms=4)
  peak = a[0]
  center = a[1]
  fwhm = a[2] * 2.354
  bkg = min(yfit) 

  title_str = 'Rows ' + $
              strcompress(string(y1),/remove_all) + $
              '-' + strcompress(string(y2),/remove_all) + $
              ' Ctr=' + strcompress(string(center,format='(f10.2)'),/remove_all) + $
              ' Pk=' + strcompress(string(peak,format='(f10.2)'),/remove_all) + $
              ' FWHM=' + strcompress(string(fwhm,format='(f10.2)'),/remove_all) + $
              ' Bkg=' + strcompress(string(bkg,format='(f10.2)'),/remove_all)

  plot,x,y,psym=1,/ynozero, title = title_str, xtitle='Column (pixels)', $
    ytitle='Pixel Value', $
    color = 0, xst = 3, yst = 3, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

  oplot, x_interp, yfit

endelse

if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  smtv_resetwindow
endif

end

;--------------------------------------------------------------------

pro smtv_gausscolplot, ps=ps, update=update

common smtv_state
common smtv_images

if (not (keyword_set(ps))) then begin

; Only initialize plot window and plot ranges to the min/max ranges
; when gausscolplot window is not already present or plot window is present
; but last plot was not a gausscolplot.  Otherwise, use the values
; currently in the min/max boxes

  if (not (xregistered('smtv_lineplot', /noshow))) then begin
    smtv_lineplot_init
  endif

  widget_control, state.histbutton_base_id, map=0
  widget_control, state.holdrange_butt_id, sensitive=0

  state.plot_type = 'gausscolplot'
  smtv_setwindow, state.lineplot_window_id
  erase

; must store the coordinates in state structure if you want to make a
; PS plot because state.coord array will change if you move cursor
; before pressing 'Create PS' button

  if (not (keyword_set(update))) then state.plot_coord = state.coord

  x2=long((state.plot_coord[1]+10.) < (state.image_size[1]-1.))
  x1=long((state.plot_coord[1]-10.) > 0.)
  y2=long((state.plot_coord[0]+2.) < (state.image_size[0]-1))
  y1=long((state.plot_coord[0]-2.) > 0.)
  x=fltarr(x2-x1+1)
  y=fltarr(x2-x1+1)

  n_x = x2-x1+1
  n_y = y2-y1+1

  for i=0, n_x - 1 do begin
    x[i]=x1+i
    y[i]=total(main_image[y1:y2,x[i]])/(n_y)
  endfor

  x_interp=interpol(x,1000)
  y_interp=interpol(y,1000)
  yfit=gaussfit(x_interp,y_interp,a,nterms=4)
  peak = a[0]
  center = a[1]
  fwhm = a[2] * 2.354
  bkg = min(yfit) 

  if (not (keyword_set(update))) then begin

    widget_control,state.lineplot_xmin_id, $
      set_value=x[0]

    state.lineplot_xmin = x[0]

    widget_control,state.lineplot_xmax_id, $
      set_value=x[n_x-1]

    state.lineplot_xmax = x[n_x-1]

    widget_control,state.lineplot_ymin_id, $
      set_value=min(y)

    state.lineplot_ymin = min(y)

    widget_control,state.lineplot_ymax_id, $
      set_value=(max(y) > max(yfit))

    state.lineplot_ymax = max(y) > max(yfit)

  endif

  title_str = 'Columns ' + $
              strcompress(string(y1),/remove_all) + $
              '-' + strcompress(string(y2),/remove_all) + $
              '   Center=' + strcompress(string(center,format='(f10.2)'),/remove_all) + $
              '   Peak=' + strcompress(string(peak,format='(f10.2)'),/remove_all) + $
              '   FWHM=' + strcompress(string(fwhm,format='(f10.2)'),/remove_all) + $
              '   Bkg=' + strcompress(string(bkg,format='(f10.2)'),/remove_all)

  plot,x,y,psym=1,/ynozero, title = title_str, xtitle='Row (pixels)', $
    ytitle='Pixel Value', $
    color = 7, xst = 3, yst = 3, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

  oplot, x_interp, yfit

endif else begin

  x2=long((state.plot_coord[1]+10.) < (state.image_size[1]-1.))
  x1=long((state.plot_coord[1]-10.) > 0.)
  y2=long((state.plot_coord[0]+2.) < (state.image_size[0]-1))
  y1=long((state.plot_coord[0]-2.) > 0.)
  x=fltarr(x2-x1+1)
  y=fltarr(x2-x1+1)

  n_x = x2-x1+1
  n_y = y2-y1+1

  for i=0, n_x - 1 do begin
    x[i]=x1+i
    y[i]=total(main_image[y1:y2,x[i]])/(n_y)
  endfor

  x_interp=interpol(x,1000)
  y_interp=interpol(y,1000)
  yfit=gaussfit(x_interp,y_interp,a,nterms=4)
  peak = a[0]
  center = a[1]
  fwhm = a[2] * 2.354
  bkg = min(yfit) 

  title_str = 'Cols ' + $
              strcompress(string(y1),/remove_all) + $
              '-' + strcompress(string(y2),/remove_all) + $
              ' Ctr=' + strcompress(string(center,format='(f10.2)'),/remove_all) + $
              ' Pk=' + strcompress(string(peak,format='(f10.2)'),/remove_all) + $
              ' FWHM=' + strcompress(string(fwhm,format='(f10.2)'),/remove_all) + $
              ' Bkg=' + strcompress(string(bkg,format='(f10.2)'),/remove_all)

  plot,x,y,psym=1,/ynozero, title = title_str, xtitle='Row (pixels)', $
    ytitle='Pixel Value', $
    color = 0, xst = 3, yst = 3, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

  oplot, x_interp, yfit

endelse

if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  smtv_resetwindow
endif

end

;--------------------------------------------------------------------

;<<<<<<< smtv_jb.pro
pro smtv_vectorplot, ps=ps, update=update

common smtv_state
common smtv_images

if (state.vector_coord1[0] eq state.vector_coord2[0]) then begin
  smtv_colplot
  return
endif 
if (state.vector_coord1[1] eq state.vector_coord2[1]) then begin
  smtv_rowplot
  return
endif

d = sqrt((state.vector_coord1[0]-state.vector_coord2[0])^2 + $
         (state.vector_coord1[1]-state.vector_coord2[1])^2)

v_d = fix(d + 1)
dx = (state.vector_coord2[0]-state.vector_coord1[0]) / float(v_d - 1)
dy = (state.vector_coord2[1]-state.vector_coord1[1]) / float(v_d - 1)

x = fltarr(v_d)
y = fltarr(v_d)
vectdist = indgen(v_d)
pixval = fltarr(v_d)

x[0] = state.vector_coord1[0]
y[0] = state.vector_coord1[1]

for i = 1, n_elements(x) - 1 do begin
  x[i] = state.vector_coord1[0] + dx * i
  y[i] = state.vector_coord1[1] + dy * i
endfor

for j = 0, n_elements(x) - 1 do begin
  col = x[j]
  row = y[j]
  floor_col = floor(col)
  ceil_col = ceil(col)
  floor_row = floor(row)
  ceil_row = ceil(row)
    
  pixval[j] = (total([main_image[floor_col,floor_row], $
                      main_image[floor_col,ceil_row], $
                      main_image[ceil_col,floor_row], $
                      main_image[ceil_col,ceil_row]])) / 4.

endfor

if (not (keyword_set(ps))) then begin

  if (not (xregistered('smtv_lineplot', /noshow))) then begin
    smtv_lineplot_init
    state.holdrange_value = 0.
    widget_control, state.holdrange_butt_id, set_button=state.holdrange_value
  endif

  widget_control, state.histbutton_base_id, map=0
  widget_control, state.holdrange_butt_id, sensitive=1
  state.plot_type = 'vectorplot'
  smtv_setwindow, state.lineplot_window_id
  erase

; Only initialize plot window and plot ranges to the min/max ranges
; when vectorplot window is not already present or hold range button
; is not set.  Otherwise, use the values currently in the min/max boxes

  if (not (keyword_set(update)) AND $
      state.holdrange_value eq 0) then begin

    widget_control,state.lineplot_xmin_id, $
      set_value=0

    state.lineplot_xmin = 0.0

    widget_control,state.lineplot_xmax_id, $
      set_value=max(vectdist)

    state.lineplot_xmax = max(vectdist)

    widget_control,state.lineplot_ymin_id, $
      set_value=min(pixval)

    state.lineplot_ymin = min(pixval)

    widget_control,state.lineplot_ymax_id, $
      set_value=max(pixval)

    state.lineplot_ymax = max(pixval) 

  endif else begin

    widget_control,state.lineplot_xmin_id, $
      get_value=tmp_xmin

    state.lineplot_xmin = tmp_xmin

    widget_control,state.lineplot_xmax_id, $
      get_value=tmp_xmax

    state.lineplot_xmax = tmp_xmax

    widget_control,state.lineplot_ymin_id, $
      get_value=tmp_ymin

    state.lineplot_ymin = tmp_ymin

    widget_control,state.lineplot_ymax_id, $
      get_value=tmp_ymax
 
    state.lineplot_ymax = tmp_ymax
    
  endelse

  plot, vectdist, pixval, $
    xst = 3, yst = 3, psym = 10, $
    title = strcompress('Plot of vector [' + $
                      strcompress(string(state.vector_coord1[0]) + ',' + $
                      string(state.vector_coord1[1]),/remove_all) + $
                      '] to [' + $
                      strcompress(string(state.vector_coord2[0]) + ',' + $
                      string(state.vector_coord2[1]),/remove_all) + ']'), $
    xtitle = 'Vector Distance', $
    ytitle = 'Pixel Value', $
    color = 7, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

endif else begin 

; Postscript output

  plot, vectdist, pixval, $
    xst = 3, yst = 3, psym = 10, $
    title = strcompress('Plot of vector [' + $
                      strcompress(string(state.vector_coord1[0]) + ',' + $
                      string(state.vector_coord1[1]),/remove_all) + $
                      '] to [' + $
                      strcompress(string(state.vector_coord2[0]) + ',' + $
                      string(state.vector_coord2[1]),/remove_all) + ']'), $
    xtitle = 'Vector Distance', $
    ytitle = 'Pixel Value', $
    color = 0, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

endelse

if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  smtv_resetwindow
endif

end

;--------------------------------------------------------------------

;=======
pro smtv_linesplot_event, event

;event handler for linesplot

common smtv_state
common smtv_images        

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'done': begin
        widget_control, event.top, /destroy
        smtv_refresh
    end

    'imin': begin

        s=state.linesbox
        widget_control, state.imin, get_value=imin
                                ;calculate angle of rotation
        angle=0
        hypotenuse=double(sqrt( (s[0]-s[2])^2 + (s[1]-s[3])^2))
                                ;1st quadrant
        if (s[0] lt s[2] and s[1] lt s[3]) then begin
            opposite=double(abs(s[1]-s[3]))
            angle=asin(opposite/hypotenuse) * 360./(2*!pi) +90.
        endif
        
                                ;2nd quadrant
        if (s[0] lt s[2] and s[1] gt s[3]) then begin
            opposite=double(abs(s[0]-s[2]))
            angle=asin(opposite/hypotenuse) * 360./(2*!pi)
        endif
        
                                ;3rd quadrant
        if (s[0] gt s[2] and s[1] gt s[3]) then begin
            opposite=double(abs(s[0]-s[2]))
            angle=-asin(opposite/hypotenuse) * 360./(2*!pi)
        endif
        
                                ;4th quadrant
        if (s[0] gt s[2] and s[1] lt s[3]) then begin
            opposite=double(abs(s[1]-s[3]))
            angle=-asin(opposite/hypotenuse) * 360./(2*!pi) -90.
        endif
        
                                ;rotate image about point of first click
                                ;im=dblarr(state.image_size[0]*1.5, state.image_size[1]*1.5)
        
        im=rot(main_image, angle, 1.0, s[0], s[1], /interp, /pivot)
        
                                ;check that line rotated isn't bigger than image
        height=hypotenuse
        if (hypotenuse ge s[1]) then height=s[1]
        
        data=dblarr(height)
        
        j=0
        for i=s[1]-height+1, s[1] do begin
            data[j]=im[s[0], i]
            j=j+1
        endfor
        
        data=reverse(data)  
        
                                ;updating controls
        widget_control, state.imin, set_value=imin

        widget_control, state.imin, get_value=imin      
        widget_control, state.imax, get_value=imax  
                                ;plotting
        widget_control, state.lines_plot_screen, get_value=scr
        wset, scr
        plot, data, xtitle='X - axis: Position', ytitle='Y - axis: Intensity', yrange=[imin, imax] 
    end


    'imax': begin
        
        s=state.linesbox
        widget_control, state.imax, get_value=imax
                                ;calculate angle of rotation
        angle=0
        hypotenuse=double(sqrt( (s[0]-s[2])^2 + (s[1]-s[3])^2))
                                ;1st quadrant
        if (s[0] lt s[2] and s[1] lt s[3]) then begin
            opposite=double(abs(s[1]-s[3]))
            angle=asin(opposite/hypotenuse) * 360./(2*!pi) +90.
        endif
        
                                ;2nd quadrant
        if (s[0] lt s[2] and s[1] gt s[3]) then begin
            opposite=double(abs(s[0]-s[2]))
            angle=asin(opposite/hypotenuse) * 360./(2*!pi)
        endif
        
                                ;3rd quadrant
        if (s[0] gt s[2] and s[1] gt s[3]) then begin
            opposite=double(abs(s[0]-s[2]))
            angle=-asin(opposite/hypotenuse) * 360./(2*!pi)
        endif
        
                                ;4th quadrant
        if (s[0] gt s[2] and s[1] lt s[3]) then begin
            opposite=double(abs(s[1]-s[3]))
            angle=-asin(opposite/hypotenuse) * 360./(2*!pi) -90.
        endif
        
                                ;rotate image about point of first click
                                ;im=dblarr(state.image_size[0]*1.5, state.image_size[1]*1.5)
        
        im=rot(main_image, angle, 1.0, s[0], s[1], /interp, /pivot)
        
                                ;check that line rotated isn't bigger than image
        height=hypotenuse
        if (hypotenuse ge s[1]) then height=s[1]
        
        data=dblarr(height)
        
        j=0
        for i=s[1]-height+1, s[1] do begin
            data[j]=im[s[0], i]
            j=j+1
        endfor
        
        data=reverse(data)  
        
                                ;updating controls
        widget_control, state.imax, set_value=imax
        
        widget_control, state.imin, get_value=imin      
        widget_control, state.imax, get_value=imax  
                                ;plotting
        widget_control, state.lines_plot_screen, get_value=scr
        wset, scr
        plot, data, xtitle='X - axis: Position', ytitle='Y - axis: Intensity', yrange=[imin, imax] 
    end

    'lines_gauss': begin
         
        s=state.linesbox
        widget_control, state.imax, get_value=imax
                                ;calculate angle of rotation
        angle=0
        hypotenuse=double(sqrt( (s[0]-s[2])^2 + (s[1]-s[3])^2))
                                ;1st quadrant
        if (s[0] le s[2] and s[1] le s[3]) then begin
            opposite=double(abs(s[1]-s[3]))
            angle=asin(opposite/hypotenuse) * 360./(2*!pi) +90.
        endif
        
                                ;2nd quadrant
        if (s[0] le s[2] and s[1] ge s[3]) then begin
            opposite=double(abs(s[0]-s[2]))
            angle=asin(opposite/hypotenuse) * 360./(2*!pi)
        endif
        
                                ;3rd quadrant
        if (s[0] ge s[2] and s[1] ge s[3]) then begin
            opposite=double(abs(s[0]-s[2]))
            angle=-asin(opposite/hypotenuse) * 360./(2*!pi)
        endif
        
                                ;4th quadrant
        if (s[0] ge s[2] and s[1] le s[3]) then begin
            opposite=double(abs(s[1]-s[3]))
            angle=-asin(opposite/hypotenuse) * 360./(2*!pi) -90.
        endif
        
                                ;rotate image about point of first click
                                ;im=dblarr(state.image_size[0]*1.5, state.image_size[1]*1.5)
        
        im=rot(main_image, angle, 1.0, s[0], s[1], /interp, /pivot)
        
                                ;check that line rotated isn't bigger than image
        height=hypotenuse

        if (hypotenuse ge s[1]) then height=s[1]
        
        data=dblarr(height)
        
        j=0
        for i=s[1]-height+1, s[1] do begin
            data[j]=im[s[0], i]
            j=j+1
        endfor
        
        data=reverse(data)

        ;get info on where the fit is
        widget_control, state.gaussmin, get_value=min
        widget_control, state.gaussmax, get_value=max

        x=data[min:max]

        l=double(fix(min[0]))
        y=dindgen( fix(max)-fix(min)+1)
        y=(y)
        plot, y,x, xtitle='X - axis: Position', ytitle='Y - axis: Intensity', psym=6

        ;not enough data
        if( fix(max)-fix(min)+1 lt 6) then return

        ;res is the fit. To make anything other than a gaussian fit
        ;replace the subroutine smtv_gaussfit with your own routine
        res=smtv_gaussfit(x,y)

        ;display
        widget_control, state.lines_plot_screen, get_value=scr
        wset, scr
        oplot, res, linestyle=2
    end

    else:
endcase




end

;--------------------------------------------------------------------

pro smtv_linesplot

common smtv_state
common smtv_images

s=state.linesbox

;check if a window is already open; if so, don't open a new one
if (not (xregistered('smtv_linesplot', /noshow))) then begin


    ;main base for linesplot 
    res=widget_info(state.base_id, /geometry)
    lines_base = $
      widget_base(/floating, $
                  group_leader = state.base_id, $
                  /row, $
                  /base_align_left, $
                  title = 'smtv arbitrary line plot', $
                  uvalue = 'stats_base', $
                  xoffset=res.xoffset+550)

    ;1st column base, holds the plot area
    plot_base = $
      widget_base(lines_base,$
                  /align_center, $
                  /column, $
                  frame=2)
    
    ;2nd column base, holds the plot controls
    control_base = $
      widget_base(lines_base, $
                  /align_center, $
                  /column, $
                  frame=2)

    ;main screen for plot in 1st column
    state.lines_plot_screen = $
      widget_draw(plot_base, $
                  xsize=600, $
                  ysize=450, $
                  frame=2, $
                  uvalue='plotscreen')

    state.imin = $ 
      cw_field(control_base, $
               value=0, $
               title='Intensity min.. = ', $
               uvalue='imin', $
               xsize=6, $
               /return_events)
    state.imax = $ 
      cw_field(control_base, $
               value=0, $
               title='Intensity max. = ', $
               uvalue='imax', $
               xsize=6, $
               /return_events)    

                                ;oplot buttons
    state.gaussmin = $ 
      cw_field(control_base, $
               value=0, $
               title='Low end of fit = ', $
               uvalue='gaussmin', $
               xsize=6, $
               /return_events)
   

    state.gaussmax = $ 
      cw_field(control_base, $
               value=8, $
               title='High end of fit = ', $
               uvalue='gaussmax', $
               xsize=6, $
               /return_events)

    state.lines_gauss=widget_button(control_base, $
                                    /align_center, $
                                    value='Make Gaussian Fit', $
                                    uvalue='lines_gauss')

    state.lines_done=widget_button(control_base, $
                                    /align_center, $
                                    value='Done', $
                                    uvalue='done')
    
    widget_control, lines_base, /realize


                                ;sdgsdg

    ;calculate angle of rotation
    angle=0
    hypotenuse=double(sqrt( (s[0]-s[2])^2 + (s[1]-s[3])^2))
    ;1st quadrant
    if (s[0] le s[2] and s[1] le s[3]) then begin
        opposite=double(abs(s[1]-s[3]))
        angle=asin(opposite/hypotenuse) * 360./(2*!pi) +90.
    endif

    ;2nd quadrant
    if (s[0] le s[2] and s[1] ge s[3]) then begin
        opposite=double(abs(s[0]-s[2]))
        angle=asin(opposite/hypotenuse) * 360./(2*!pi)
    endif

    ;3rd quadrant
    if (s[0] ge s[2] and s[1] ge s[3]) then begin
        opposite=double(abs(s[0]-s[2]))
        angle=-asin(opposite/hypotenuse) * 360./(2*!pi)
    endif

    ;4th quadrant
    if (s[0] ge s[2] and s[1] le s[3]) then begin
        opposite=double(abs(s[1]-s[3]))
        angle=-asin(opposite/hypotenuse) * 360./(2*!pi) -90.
    endif
    
    ;rotate image about point of first click
    ;im=dblarr(state.image_size[0]*1.5, state.image_size[1]*1.5)
    
    im=rot(main_image, angle, 1.0, s[0], s[1], /interp, /pivot)

    ;check that line rotated isn't bigger than image
    height=hypotenuse
    if (hypotenuse ge s[1]) then height=s[1]

    ;if a bad line, quit
    if (height gt 0) then begin
        
        data=dblarr(height)
        
        j=0
        for i=s[1]-height+1, s[1] do begin
            data[j]=im[s[0], i]
            j=j+1
        endfor
        
        data=reverse(data)
    endif else begin
        data=dindgen(25)
    endelse


    xmanager, 'smtv_linesplot', lines_base, /no_block
    smtv_resetwindow    

    ;updating controls
    widget_control, state.imin, set_value=min(data)
    widget_control, state.imax, set_value=max(data) 
        
    ;plotting
    widget_control, state.lines_plot_screen, get_value=scr
    wset, scr
    plot, data, xtitle='X - axis: Position', ytitle='Y - axis: Intensity'
    
endif
end

;--------------------------------------------------------------------

;>>>>>>> smtv_ks.pro
pro smtv_surfplot, ps=ps, update=update

common smtv_state
common smtv_images

if (not (keyword_set(ps))) then begin

  if (not (xregistered('smtv_lineplot', /noshow))) then begin
    smtv_lineplot_init
  endif

  widget_control, state.histbutton_base_id, map=0
  widget_control, state.holdrange_butt_id, sensitive=0

  if (not (keyword_set(update))) then begin

    plotsize = $
      fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
    center = plotsize > state.coord < (state.image_size[0:1] - plotsize) 

    shade_image = main_image[center[0]-plotsize:center[0]+plotsize-1, $
                             center[1]-plotsize:center[1]+plotsize-1]

    state.lineplot_xmin = center[0]-plotsize
    state.lineplot_xmax = center[0]+plotsize-1
    state.lineplot_ymin = center[1]-plotsize 
    state.lineplot_ymax = center[1]+plotsize-1

; must store the coordinates in state structure if you want to make a
; PS plot because state.coord array will change if you move cursor
; before pressing 'Create PS' button

    state.plot_coord = state.coord

    widget_control, state.lineplot_xmin_id, $
      set_value = state.lineplot_xmin

    widget_control, state.lineplot_xmax_id, $
      set_value = state.lineplot_xmax

    widget_control, state.lineplot_ymin_id, $
      set_value = state.lineplot_ymin

    widget_control, state.lineplot_ymax_id, $
      set_value = state.lineplot_ymax

  endif

  state.plot_type = 'surfplot'
  smtv_setwindow, state.lineplot_window_id
  erase

  state.lineplot_xmin = fix(round(0 > state.lineplot_xmin))
  state.lineplot_xmax = $
        fix(round(state.lineplot_xmax < (state.image_size[0] - 1)))
  state.lineplot_ymin = fix(round(0 > state.lineplot_ymin))
  state.lineplot_ymax = $
        fix(round(state.lineplot_ymax < (state.image_size[1] - 1)))

  if (state.lineplot_xmin ge state.lineplot_xmax OR $
      state.lineplot_ymin ge state.lineplot_ymax) then begin
    smtv_message, 'XMin and YMin must be less than Xmax and YMax', $
      msgtype='error', /window
    return
  endif

  widget_control,state.lineplot_xmin_id, $
    set_value=state.lineplot_xmin

  widget_control,state.lineplot_xmax_id, $
    set_value=state.lineplot_xmax

  widget_control,state.lineplot_ymin_id, $
    set_value=state.lineplot_ymin

  widget_control,state.lineplot_ymax_id, $
    set_value=state.lineplot_ymax  

  shade_image =  main_image[state.lineplot_xmin:state.lineplot_xmax, $
                            state.lineplot_ymin:state.lineplot_ymax]

  tmp_string = $
    strcompress('Surface plot of ' + $
              strcompress('['+string(round(state.lineplot_xmin))+ $
                          ':'+string(round(state.lineplot_xmax))+ $
                          ','+string(round(state.lineplot_ymin))+ $
                          ':'+string(round(state.lineplot_ymax))+ $
                          ']', /remove_all))

  xdim = state.lineplot_xmax - state.lineplot_xmin + 1
  ydim = state.lineplot_ymax - state.lineplot_ymin + 1
  xran = lonarr(xdim)
  yran = lonarr(ydim)
  xran[0] = state.lineplot_xmin
  yran[0] = state.lineplot_ymin

  for i = 1L, xdim - 1, 1 do xran[i] = state.lineplot_xmin + i
  for j = 1L, ydim - 1, 1 do yran[j] = state.lineplot_ymin + j

  shade_surf, shade_image, $
    xran, yran, $
    title = temporary(tmp_string), $
    xtitle = 'X', ytitle = 'Y', ztitle = 'Pixel Value', $
    color = 7, charsize=1.5

endif else begin 

  shade_image =  main_image[state.lineplot_xmin:state.lineplot_xmax, $
                            state.lineplot_ymin:state.lineplot_ymax]

  tmp_string = $
    strcompress('Surface plot of ' + $
              strcompress('['+string(round(state.lineplot_xmin))+ $
                          ':'+string(round(state.lineplot_xmax))+ $
                          ','+string(round(state.lineplot_ymin))+ $
                          ':'+string(round(state.lineplot_ymax))+ $
                          ']', /remove_all))

  xdim = state.lineplot_xmax - state.lineplot_xmin + 1
  ydim = state.lineplot_ymax - state.lineplot_ymin + 1
  xran = lonarr(xdim)
  yran = lonarr(ydim)
  xran[0] = state.lineplot_xmin
  yran[0] = state.lineplot_ymin

  for i = 1L, xdim - 1, 1 do xran[i] = state.lineplot_xmin + i
  for j = 1L, ydim - 1, 1 do yran[j] = state.lineplot_ymin + j

  shade_surf, shade_image, $
    xran, yran, $
    title = temporary(tmp_string), $
    xtitle = 'X', ytitle = 'Y', ztitle = 'Pixel Value', $
    color = 0, charsize=1.5

endelse

if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  smtv_resetwindow
endif

end

;--------------------------------------------------------------------

pro smtv_contourplot, ps=ps, update=update

common smtv_state
common smtv_images

if (not (keyword_set(ps))) then begin

  if (not (xregistered('smtv_lineplot', /noshow))) then begin

; Only initialize plot window and plot ranges to the min/max ranges
; when rowplot window is not already present.  Otherwise, use
; the values currently set in the min/max range boxes

    smtv_lineplot_init

  endif

  widget_control, state.histbutton_base_id, map=0
  widget_control, state.holdrange_butt_id, sensitive=0

  if (not (keyword_set(update))) then begin

    plotsize = $
      fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
    center = plotsize > state.coord < (state.image_size[0:1] - plotsize) 

    contour_image =  main_image[center[0]-plotsize:center[0]+plotsize-1, $
                                center[1]-plotsize:center[1]+plotsize-1]

    state.lineplot_xmin = (center[0]-plotsize)
    state.lineplot_xmax = (center[0]+plotsize-1)
    state.lineplot_ymin = (center[1]-plotsize)
    state.lineplot_ymax = (center[1]+plotsize-1)

; must store the coordinates in state structure if you want to make a
; PS plot because state.coord array will change if you move cursor
; before pressing 'Create PS' button

    state.plot_coord = state.coord

    widget_control,state.lineplot_xmin_id, $
      set_value=state.lineplot_xmin

    widget_control,state.lineplot_xmax_id, $
      set_value=state.lineplot_xmax

    widget_control,state.lineplot_ymin_id, $
      set_value=state.lineplot_ymin

    widget_control,state.lineplot_ymax_id, $
      set_value=state.lineplot_ymax

  endif

  state.plot_type = 'contourplot'
  smtv_setwindow, state.lineplot_window_id
  erase

  state.lineplot_xmin = fix(round(0 > state.lineplot_xmin))
  state.lineplot_xmax = $
        fix(round(state.lineplot_xmax < (state.image_size[0] - 1)))
  state.lineplot_ymin = fix(round(0 > state.lineplot_ymin))
  state.lineplot_ymax = $
        fix(round(state.lineplot_ymax < (state.image_size[1] - 1)))

  if (state.lineplot_xmin ge state.lineplot_xmax OR $
      state.lineplot_ymin ge state.lineplot_ymax) then begin
    smtv_message, 'XMin and YMin must be less than Xmax and YMax', $
      msgtype='error', /window
    return
  endif

  widget_control,state.lineplot_xmin_id, $
    set_value=state.lineplot_xmin

  widget_control,state.lineplot_xmax_id, $
    set_value=state.lineplot_xmax

  widget_control,state.lineplot_ymin_id, $
    set_value=state.lineplot_ymin

  widget_control,state.lineplot_ymax_id, $
    set_value=state.lineplot_ymax  

  contour_image =  main_image[state.lineplot_xmin:state.lineplot_xmax, $
                              state.lineplot_ymin:state.lineplot_ymax]

  if (state.scaling EQ 1) then begin
    contour_image = alog10(contour_image)
    logflag = 'Log'
  endif else begin
    logflag = ''
  endelse

  tmp_string =  $
    strcompress(logflag + $
              ' Contour plot of ' + $
              strcompress('['+string(round(state.lineplot_xmin))+ $
                          ':'+string(round(state.lineplot_xmax))+ $
                          ','+string(round(state.lineplot_ymin))+ $
                          ':'+string(round(state.lineplot_ymax))+ $
                          ']', /remove_all))


  xdim = state.lineplot_xmax - state.lineplot_xmin + 1
  ydim = state.lineplot_ymax - state.lineplot_ymin + 1
  xran = lonarr(xdim)
  yran = lonarr(ydim)
  xran[0] = state.lineplot_xmin
  yran[0] = state.lineplot_ymin

  for i = 1L, xdim - 1, 1 do xran[i] = state.lineplot_xmin + i 
  for j = 1L, ydim - 1, 1 do yran[j] = state.lineplot_ymin + j

  contour, temporary(contour_image), $
    xran, yran, $
    nlevels = 10, $
    /follow, $
    title = temporary(tmp_string), $
    xtitle = 'X', ytitle = 'Y', color = 7

endif else begin

  contour_image =  main_image[state.lineplot_xmin:state.lineplot_xmax, $
                              state.lineplot_ymin:state.lineplot_ymax]

  if (state.scaling EQ 1) then begin
    contour_image = alog10(contour_image)
    logflag = 'Log'
  endif else begin
    logflag = ''
  endelse

  tmp_string =  $
    strcompress(logflag + $
              ' Contour plot of ' + $
              strcompress('['+string(round(state.lineplot_xmin))+ $
                          ':'+string(round(state.lineplot_xmax))+ $
                          ','+string(round(state.lineplot_ymin))+ $
                          ':'+string(round(state.lineplot_ymax))+ $
                          ']', /remove_all))

  xdim = state.lineplot_xmax - state.lineplot_xmin + 1
  ydim = state.lineplot_ymax - state.lineplot_ymin + 1
  xran = lonarr(xdim)
  yran = lonarr(ydim)
  xran[0] = state.lineplot_xmin
  yran[0] = state.lineplot_ymin

  for i = 1L, xdim - 1, 1 do xran[i] = state.lineplot_xmin + i 
  for j = 1L, ydim - 1, 1 do yran[j] = state.lineplot_ymin + j

  contour, temporary(contour_image), $
    xran, yran, $
    nlevels = 10, $
    /follow, $
    title = temporary(tmp_string), $
    xtitle = 'X', ytitle = 'Y', color = 0

endelse

if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  smtv_resetwindow
endif

end

;----------------------------------------------------------------------

pro smtv_histplot, ps=ps, update=update

common smtv_state
common smtv_images

if (not (keyword_set(ps))) then begin

  if (not (xregistered('smtv_lineplot', /noshow))) then begin
    smtv_lineplot_init
  endif

  widget_control, state.histbutton_base_id, map=1
  widget_control, state.holdrange_butt_id, sensitive=0

  if (not (keyword_set(update))) then begin

    state.plot_coord = state.coord

    plotsize_x = $
      fix(min([20, state.image_size[0]/2.]))

    plotsize_y = $
      fix(min([20, state.image_size[1]/2.]))

; Establish pixel boundaries to histogram
    x1 = (state.plot_coord[0]-plotsize_x) > 0.
    x2 = (state.plot_coord[0]+plotsize_x) < (state.image_size[0]-1)
    y1 = (state.plot_coord[1]-plotsize_y) > 0.
    y2 = (state.plot_coord[1]+plotsize_y) < (state.image_size[1]-1)

; Set up histogram pixel array.  User may do rectangular regions.

    hist_image = main_image[x1:x2, y1:y2]

    state.lineplot_xmin = min(hist_image)
    state.lineplot_xmin_orig = state.lineplot_xmin
    state.lineplot_xmax = max(hist_image)
    state.lineplot_xmax_orig = state.lineplot_xmax
    state.lineplot_ymin = 0.

; must store the coordinates in state structure if you want to make a
; PS plot because state.coord array will change if you move cursor
; before pressing 'Create PS' button

    widget_control, state.lineplot_xmin_id, $
      set_value = state.lineplot_xmin

    widget_control, state.lineplot_xmax_id, $
      set_value = state.lineplot_xmax

    widget_control, state.lineplot_ymin_id, $
      set_value = state.lineplot_ymin

    state.binsize = (state.lineplot_xmax - state.lineplot_xmin) * 0.01
    state.binsize = $
      state.binsize > ((state.lineplot_xmax - state.lineplot_xmin) * 1.0e-5)
    state.binsize = fix(state.binsize)

    widget_control, state.x1_pix_id, set_value=x1
    widget_control, state.x2_pix_id, set_value=x2
    widget_control, state.y1_pix_id, set_value=y1
    widget_control, state.y2_pix_id, set_value=y2
    widget_control, state.histplot_binsize_id, set_value=state.binsize

  endif else begin

    widget_control, state.x1_pix_id, get_value=x1
    widget_control, state.x2_pix_id, get_value=x2
    widget_control, state.y1_pix_id, get_value=y1
    widget_control, state.y2_pix_id, get_value=y2

    x1 = (fix(x1)) > 0.
    x2 = (fix(x2)) < (state.image_size[0]-1)
    y1 = (fix(y1)) > 0.
    y2 = (fix(y2)) < (state.image_size[1]-1)

    hist_image = main_image[x1:x2, y1:y2]

  endelse

  state.plot_type = 'histplot'
  smtv_setwindow, state.lineplot_window_id
  erase

; Only initialize plot window and plot ranges to the min/max ranges
; when histplot window is not already present or plot window is present
; but last plot was not a histplot.  Otherwise, use the values
; currently in the min/max boxes

  widget_control, state.histplot_binsize_id, get_value=binsize
  widget_control, state.lineplot_xmin_id, get_value=xmin
  widget_control, state.lineplot_xmax_id, get_value=xmax
  widget_control, state.lineplot_ymin_id, get_value=ymin
  widget_control, state.lineplot_ymax_id, get_value=ymax

  state.binsize = binsize
  state.lineplot_xmin = xmin
  state.lineplot_xmax = xmax
  state.lineplot_ymin = ymin
  state.lineplot_ymax = ymax

  tmp_string = $
    strcompress('Histogram plot of ' + $
              strcompress('['+string(round(x1))+ $
                          ':'+string(round(x2))+ $
                          ','+string(round(y1))+ $
                          ':'+string(round(y2))+ $
                          ']', /remove_all))

;Call plothist to create histogram arrays
  plothist, hist_image, xhist, yhist, bin=state.binsize, /NaN, /nodata

;Create ymax for plot with slight buffer (if initial plot, else take
;ymax in range box)
  if (not (keyword_set(update))) then begin
    state.lineplot_ymax = fix(max(yhist) + 0.05 * max(yhist))
    widget_control, state.lineplot_ymax_id, set_value=state.lineplot_ymax
  endif

;Plot histogram with proper ranges
  plothist, hist_image, xhist, yhist, bin=state.binsize, /NaN, $
    xtitle='Pixel Value', ytitle='Number', title=tmp_string, $
    xran=[state.lineplot_xmin,state.lineplot_xmax], $
    yran=[state.lineplot_ymin,state.lineplot_ymax], $
    xstyle=1, ystyle=1

endif else begin

  widget_control, state.x1_pix_id, get_value=x1
  widget_control, state.x2_pix_id, get_value=x2
  widget_control, state.y1_pix_id, get_value=y1
  widget_control, state.y2_pix_id, get_value=y2

  x1 = (fix(x1)) > 0.
  x2 = (fix(x2)) < (state.image_size[0]-1)
  y1 = (fix(y1)) > 0.
  y2 = (fix(y2)) < (state.image_size[1]-1)

  widget_control, state.x1_pix_id, set_value=x1
  widget_control, state.x2_pix_id, set_value=x2
  widget_control, state.y1_pix_id, set_value=y1
  widget_control, state.y2_pix_id, set_value=y2

  hist_image = main_image[x1:x2, y1:y2]

  tmp_string = $
    strcompress('Histogram plot of ' + $
              strcompress('['+string(round(x1))+ $
                          ':'+string(round(x2))+ $
                          ','+string(round(y1))+ $
                          ':'+string(round(y2))+ $
                          ']', /remove_all))

;Plot histogram with proper ranges
  plothist, hist_image, xhist, yhist, bin=state.binsize, /NaN, $
    xtitle='Pixel Value', ytitle='Number', title=tmp_string, $
    xran=[state.lineplot_xmin,state.lineplot_xmax], $
    yran=[state.lineplot_ymin,state.lineplot_ymax], $
    xstyle=1, ystyle=1

endelse

if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  smtv_resetwindow
endif

END

;----------------------------------------------------------------------

pro smtv_slice3dplot, ps=ps, update=update

common smtv_state
common smtv_images

if (not (keyword_set(ps))) then begin

; Only initialize plot window and plot ranges to the min/max ranges
; when slice3dplot window is not already present, plot window is present
; but last plot was not a slice3dplot, or last plot was a slice3dplot
; but the 'Hold Range' button is not selected.  Otherwise, use the values
; currently in the min/max boxes

  if (not (xregistered('smtv_lineplot', /noshow))) then begin
    smtv_lineplot_init

    widget_control,state.lineplot_xmin_id, $
      set_value=0

    state.lineplot_xmin = 0.0

    widget_control,state.lineplot_xmax_id, $
      set_value=state.image_size[2]

    state.lineplot_xmax = state.image_size[2]

    widget_control,state.lineplot_ymin_id, $
      set_value=min(main_image_stack[state.coord[0], state.coord[1], *])

    state.lineplot_ymin = $
         min(main_image_stack[state.coord[0], state.coord[1], *])

    widget_control,state.lineplot_ymax_id, $
      set_value=max(main_image_stack[state.coord[0], state.coord[1], *])

    state.lineplot_ymax = $
         max(main_image_stack[state.coord[0], state.coord[1], *]) 

  endif

  widget_control, state.histbutton_base_id, map=0

  if (state.plot_type ne 'slice3dplot' OR $
      state.holdrange_value eq 0) then begin

    widget_control,state.lineplot_xmin_id, $
      set_value=0

    state.lineplot_xmin = 0.0

    widget_control,state.lineplot_xmax_id, $
      set_value=state.image_size[2]

    state.lineplot_xmax = state.image_size[2]

    widget_control,state.lineplot_ymin_id, $
      set_value=min(main_image_stack[state.coord[0], state.coord[1], *])

    state.lineplot_ymin = $
         min(main_image_stack[state.coord[0], state.coord[1], *])

    widget_control,state.lineplot_ymax_id, $
      set_value=max(main_image_stack[state.coord[0], state.coord[1], *])

    state.lineplot_ymax = $
         max(main_image_stack[state.coord[0], state.coord[1], *]) 

  endif

  state.plot_type = 'slice3dplot'
  smtv_setwindow, state.lineplot_window_id
  erase

; must store the coordinates in state structure if you want to make a
; PS plot because state.coord array will change if you move cursor
; before pressing 'Create PS' button

  if (not (keyword_set(update))) then state.plot_coord = state.coord

  plot, main_image_stack[state.plot_coord[0], state.plot_coord[1], *], $
    xst = 3, yst = 3, psym = 2, $
    title = 'Plot of pixel [' + $
             strcompress(string(state.plot_coord[0]), /remove_all) + ',' + $
             strcompress(string(state.plot_coord[1]), /remove_all) + ']', $
    xtitle = 'Image Plane', $
    ytitle = 'Pixel Value', $
    color = 7, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

endif else begin 

  plot, main_image_stack[state.plot_coord[0], state.plot_coord[1], *], $
  xst = 3, yst = 3, psym = 2, $
  title = 'Plot of pixel [' + $
             strcompress(string(state.plot_coord[0]), /remove_all) + ',' + $
             strcompress(string(state.plot_coord[1]), /remove_all) + ']', $
  xtitle = 'Image Plane', $
  ytitle = 'Pixel Value', $
  color = 0, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax]

endelse

if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  smtv_resetwindow
endif

end

;--------------------------------------------------------------------

pro smtv_lineplot_event, event

common smtv_state
common smtv_images

widget_control, event.id, get_uvalue = uvalue


case uvalue of
    'lineplot_done': widget_control, event.top, /destroy
    'lineplot_base': begin                       ; Resize event
        smtv_setwindow, state.lineplot_window_id
        state.lineplot_size = [event.x, event.y]- state.lineplot_pad
        widget_control, state.lineplot_widget_id, $
          xsize = (state.lineplot_size[0] > state.lineplot_min_size[0]), $
          ysize = (state.lineplot_size[1] > state.lineplot_min_size[1])
        smtv_resetwindow
    end
    'lineplot_holdrange': begin
;        widget_control, state.holdrange_butt_id
        if (state.holdrange_value eq 1) then state.holdrange_value = 0 $
        else state.holdrange_value = 1
    end
    'lineplot_fullrange': begin
       case state.plot_type of
         'rowplot': begin

            widget_control,state.lineplot_xmin_id, $
              set_value=0

            state.lineplot_xmin = 0.0

            widget_control,state.lineplot_xmax_id, $
              set_value=state.image_size[0]

            state.lineplot_xmax = state.image_size[0]

            widget_control,state.lineplot_ymin_id, $
              set_value=min(main_image[*,state.plot_coord[1]])

            state.lineplot_ymin = min(main_image[*,state.plot_coord[1]])

            widget_control,state.lineplot_ymax_id, $
              set_value=max(main_image[*,state.plot_coord[1]])

            state.lineplot_ymax = max(main_image[*,state.plot_coord[1]]) 

            smtv_rowplot, /update
         end
         'colplot': begin

            widget_control,state.lineplot_xmin_id, $
              set_value=0

            state.lineplot_xmin = 0.0

            widget_control,state.lineplot_xmax_id, $
              set_value=state.image_size[1]

            state.lineplot_xmax = state.image_size[1]

            widget_control,state.lineplot_ymin_id, $
              set_value=min(main_image[state.plot_coord[0], *])

            state.lineplot_ymin = min(main_image[state.plot_coord[0], *])

            widget_control,state.lineplot_ymax_id, $
              set_value=max(main_image[state.plot_coord[0], *])

            state.lineplot_ymax = max(main_image[state.plot_coord[0], *])

            smtv_colplot, /update
         end
         'gaussrowplot': begin

            x2=long((state.plot_coord[0]+10.) < (state.image_size[0]-1.))
            x1=long((state.plot_coord[0]-10.) > 0.)
            y2=long((state.plot_coord[1]+2.) < (state.image_size[1]-1))
            y1=long((state.plot_coord[1]-2.) > 0.)
            x=fltarr(x2-x1+1)
            y=fltarr(x2-x1+1)

            n_x = x2-x1+1
            n_y = y2-y1+1

            for i=0, n_x - 1 do begin
              x[i]=x1+i
              y[i]=total(main_image[x[i],y1:y2])/(n_y)
            endfor

            x_interp=interpol(x,1000)
            y_interp=interpol(y,1000)
            yfit=gaussfit(x_interp,y_interp,a,nterms=4)

            widget_control,state.lineplot_xmin_id, $
              set_value=x[0]

            state.lineplot_xmin = x[0]

            widget_control,state.lineplot_xmax_id, $
              set_value=x[n_x-1]

            state.lineplot_xmax = x[n_x-1]

            widget_control,state.lineplot_ymin_id, $
              set_value=min(y)

            state.lineplot_ymin = min(y)

            widget_control,state.lineplot_ymax_id, $
              set_value=(max(y) > max(yfit))

            state.lineplot_ymax = max(y) > max(yfit)

            smtv_gaussrowplot, /update
         end
         'gausscolplot': begin

            x2=long((state.plot_coord[1]+10.) < (state.image_size[1]-1.))
            x1=long((state.plot_coord[1]-10.) > 0.)
            y2=long((state.plot_coord[0]+2.) < (state.image_size[0]-1))
            y1=long((state.plot_coord[0]-2.) > 0.)
            x=fltarr(x2-x1+1)
            y=fltarr(x2-x1+1)

            n_x = x2-x1+1
            n_y = y2-y1+1

            for i=0, n_x - 1 do begin
              x[i]=x1+i
              y[i]=total(main_image[y1:y2,x[i]])/(n_y)
            endfor

            x_interp=interpol(x,1000)
            y_interp=interpol(y,1000)
            yfit=gaussfit(x_interp,y_interp,a,nterms=4)

            widget_control,state.lineplot_xmin_id, $
              set_value=x[0]

            state.lineplot_xmin = x[0]

            widget_control,state.lineplot_xmax_id, $
              set_value=x[n_x-1]

            state.lineplot_xmax = x[n_x-1]

            widget_control,state.lineplot_ymin_id, $
              set_value=min(y)

            state.lineplot_ymin = min(y)

            widget_control,state.lineplot_ymax_id, $
              set_value=(max(y) > max(yfit))

            state.lineplot_ymax = max(y) > max(yfit)

            smtv_gausscolplot, /update
         end
         'vectorplot': begin

            d = sqrt((state.vector_coord1[0]-state.vector_coord2[0])^2 + $
                    (state.vector_coord1[1]-state.vector_coord2[1])^2)

            v_d = fix(d + 1)
            dx = (state.vector_coord2[0]-state.vector_coord1[0]) / float(v_d - 1)
            dy = (state.vector_coord2[1]-state.vector_coord1[1]) / float(v_d - 1)

            x = fltarr(v_d)
            y = fltarr(v_d)
            vectdist = indgen(v_d)
            pixval = fltarr(v_d)

            x[0] = state.vector_coord1[0]
            y[0] = state.vector_coord1[1]

            for i = 1, n_elements(x) - 1 do begin
              x[i] = state.vector_coord1[0] + dx * i
              y[i] = state.vector_coord1[1] + dy * i
            endfor

            for j = 0, n_elements(x) - 1 do begin
              col = x[j]
              row = y[j]
              floor_col = floor(col)
              ceil_col = ceil(col)
              floor_row = floor(row)
              ceil_row = ceil(row)
    
              pixval[j] = (total([main_image[floor_col,floor_row], $
                                  main_image[floor_col,ceil_row], $
                                  main_image[ceil_col,floor_row], $
                                  main_image[ceil_col,ceil_row]])) / 4.

            endfor

            widget_control,state.lineplot_xmin_id, set_value=0
            state.lineplot_xmin = 0.0

            widget_control,state.lineplot_xmax_id, set_value=max(vectdist)
            state.lineplot_xmax = max(vectdist)

            widget_control,state.lineplot_ymin_id, set_value=min(pixval)
            state.lineplot_ymin = min(pixval)

            widget_control,state.lineplot_ymax_id, set_value=max(pixval)
            state.lineplot_ymax = max(pixval) 

            smtv_vectorplot, /update

         end
         'histplot': begin

            plotsize_x = $
              fix(min([20, state.image_size[0]/2.]))

            plotsize_y = $
              fix(min([20, state.image_size[1]/2.]))

         ; Establish pixel boundaries to histogram
            x1 = (state.plot_coord[0]-plotsize_x) > 0.
            x2 = (state.plot_coord[0]+plotsize_x) < (state.image_size[0]-1)
            y1 = (state.plot_coord[1]-plotsize_y) > 0.
            y2 = (state.plot_coord[1]+plotsize_y) < (state.image_size[1]-1)

         ; Set up histogram pixel array.  User may do rectangular regions.
            hist_image = main_image[x1:x2, y1:y2]

            state.lineplot_xmin = min(hist_image)
            state.lineplot_xmin_orig = state.lineplot_xmin
            state.lineplot_xmax = max(hist_image)
            state.lineplot_xmax_orig = state.lineplot_xmax
            state.lineplot_ymin = 0

            widget_control, state.lineplot_xmin_id, $
              set_value = state.lineplot_xmin

            widget_control, state.lineplot_xmax_id, $
              set_value = state.lineplot_xmax

            widget_control, state.lineplot_ymin_id, $
              set_value = state.lineplot_ymin

            state.binsize = (state.lineplot_xmax - state.lineplot_xmin) * 0.01
            state.binsize = state.binsize > $
              ((state.lineplot_xmax - state.lineplot_xmin) * 1.0e-5)
            state.binsize = fix(state.binsize)

            widget_control, state.x1_pix_id, set_value=x1
            widget_control, state.x2_pix_id, set_value=x2
            widget_control, state.y1_pix_id, set_value=y1
            widget_control, state.y2_pix_id, set_value=y2
            widget_control, state.histplot_binsize_id, set_value=state.binsize

            ;Set lineplot window and erase
            smtv_setwindow, state.lineplot_window_id
            erase

            ;Call plothist to create histogram arrays.  Necessary to get 
            ;default ymax
            plothist, hist_image, xhist, yhist, bin=state.binsize, $
              /NaN, /nodata

            state.lineplot_ymax = fix(max(yhist) + 0.05*max(yhist))

            widget_control, state.lineplot_ymax_id, $
              set_value = state.lineplot_ymax            

            smtv_histplot, /update

         end
         'surfplot': begin

            plotsize = $
              fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
            center = plotsize > state.plot_coord < $
                     (state.image_size[0:1] - plotsize) 

            state.lineplot_xmin = (center[0]-plotsize)
            state.lineplot_xmax = (center[0]+plotsize-1)
            state.lineplot_ymin = (center[1]-plotsize)
            state.lineplot_ymax = (center[1]+plotsize-1)

            widget_control,state.lineplot_xmin_id, $
              set_value=state.lineplot_xmin

            widget_control,state.lineplot_xmax_id, $
              set_value=state.lineplot_xmax

            widget_control,state.lineplot_ymin_id, $
              set_value=state.lineplot_ymin

            widget_control,state.lineplot_ymax_id, $
              set_value=state.lineplot_ymax

            smtv_surfplot, /update
        end
         'contourplot': begin

            plotsize = $
              fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
            center = plotsize > state.plot_coord < $
                     (state.image_size[0:1] - plotsize) 

            state.lineplot_xmin = (center[0]-plotsize)
            state.lineplot_xmax = (center[0]+plotsize-1)
            state.lineplot_ymin = (center[1]-plotsize)
            state.lineplot_ymax = (center[1]+plotsize-1)

            widget_control,state.lineplot_xmin_id, $
              set_value=state.lineplot_xmin

            widget_control,state.lineplot_xmax_id, $
              set_value=state.lineplot_xmax

            widget_control,state.lineplot_ymin_id, $
              set_value=state.lineplot_ymin

            widget_control,state.lineplot_ymax_id, $
              set_value=state.lineplot_ymax

            smtv_contourplot, /update
        end
         'slice3dplot': begin

            widget_control,state.lineplot_xmin_id, $
              set_value=0

            state.lineplot_xmin = 0.0

            widget_control,state.lineplot_xmax_id, $
              set_value=state.image_size[2]

            state.lineplot_xmax = state.image_size[2]

            widget_control,state.lineplot_ymin_id, $
            set_value=min(main_image_stack[state.plot_coord[0], $
                                           state.plot_coord[1], *])

            state.lineplot_ymin = $
              min(main_image_stack[state.plot_coord[0], $
                                   state.plot_coord[1], *])

            widget_control,state.lineplot_ymax_id, $
            set_value=max(main_image_stack[state.plot_coord[0], $
                                           state.plot_coord[1], *])

            state.lineplot_ymax = $
              max(main_image_stack[state.plot_coord[0], $
                                   state.plot_coord[1], *]) 

            smtv_slice3dplot, /update
        end
         else:
       endcase
    end
    'lineplot_ps': begin
        fname = strcompress(state.current_dir + 'smtv_plot.ps', /remove_all)
        forminfo = cmps_form(cancel = canceled, create = create, $
                     parent = state.lineplot_base_id, $
                     /preserve_aspect, $
                     /color, $
                     /nocommon, papersize='Letter', $
                     filename = fname, $
                     button_names = ['Create PS File'])

        if (canceled) then return
        if (forminfo.filename EQ '') then return

        tmp_result = findfile(forminfo.filename, count = nfiles)

        result = ''
        if (nfiles GT 0) then begin
          mesg = strarr(2)
          mesg[0] = 'Overwrite existing file:'
          tmp_string = strmid(forminfo.filename, strpos(forminfo.filename, $
                              '/') + 1)
          mesg[1] = strcompress(tmp_string + '?', /remove_all)
          result =  dialog_message(mesg, $
                             /default_no, $
                             dialog_parent = state.base_id, $
                             /question)                 
        endif

        if (strupcase(result) EQ 'NO') then return
    
        widget_control, /hourglass

        screen_device = !d.name

        set_plot, 'ps'
        device, _extra = forminfo

        case (state.plot_type) of

         'rowplot': begin
            smtv_rowplot, /ps
         end

         'colplot': begin
            smtv_colplot, /ps
         end

         'gaussrowplot': begin
            smtv_gaussrowplot, /ps
         end
         
         'gausscolplot': begin
            smtv_gausscolplot, /ps
         end

         'vectorplot': begin
            smtv_vectorplot, /ps
         end

         'histplot': begin
            smtv_histplot, /ps
         end

         'surfplot': begin
           if (state.lineplot_xmin ge state.lineplot_xmax OR $
               state.lineplot_ymin ge state.lineplot_ymax) then begin
             smtv_message, 'XMin and YMin must be less than Xmax and YMax', $
               msgtype='error', /window
             device, /close
             set_plot, screen_device
             return
           endif

            smtv_surfplot, /ps
         end

         'contourplot': begin
           if (state.lineplot_xmin ge state.lineplot_xmax OR $
               state.lineplot_ymin ge state.lineplot_ymax) then begin
             smtv_message, 'XMin and YMin must be less than Xmax and YMax', $
               msgtype='error', /window
             device, /close
             set_plot, screen_device
             return
           endif

            smtv_contourplot, /ps
         end

         'slice3dplot': begin
            smtv_slice3dplot, /ps
         end

         else:
        endcase

        device, /close
        set_plot, screen_device

    end    

    'lineplot_newrange': begin

       widget_control, state.lineplot_xmin_id, get_value = tmp_value
       state.lineplot_xmin = tmp_value

       widget_control, state.lineplot_xmax_id, get_value = tmp_value
       state.lineplot_xmax = tmp_value

       widget_control, state.lineplot_ymin_id, get_value = tmp_value
       state.lineplot_ymin = tmp_value

       widget_control, state.lineplot_ymax_id, get_value = tmp_value
       state.lineplot_ymax = tmp_value

       case state.plot_type of
         'rowplot': begin
            smtv_rowplot, /update
         end
         'colplot': begin
            smtv_colplot, /update
         end
         'gaussrowplot': begin
            smtv_gaussrowplot, /update
         end
         'gausscolplot': begin
            smtv_gausscolplot, /update
         end
         'vectorplot': begin
            smtv_vectorplot, /update
         end
         'histplot': begin
            widget_control, state.histplot_binsize_id, get_value = tmp_value
            state.binsize = tmp_value
            smtv_histplot, /update
         end
         'surfplot': begin
            smtv_surfplot, /update
         end
         'contourplot': begin
            smtv_contourplot, /update
         end
         'slice3dplot': begin
            smtv_slice3dplot, /update
         end
         else:
       endcase
    end

else:
endcase

end

;----------------------------------------------------------------------
;                         help window
;---------------------------------------------------------------------

pro smtv_help
common smtv_state

;<<<<<<< smtv_jb.pro
;h = strarr(235)         ;DGW 29 August 2005
h = strarr(275)          ;DGW 29 August 2005
;=======
;h = strarr(215)
;>>>>>>> smtv_ks.pro
i = 0
h[i] =  'SMTV HELP'
i = i + 1
h[i] =  ''
i = i + 1
h[i] =  'MENU BAR:'
h[i] =  'File->ReadFits:           Read in a new fits image from disk'
i = i + 1
h[i] =  'File->WriteFits:          Write out a new fits image to disk (single-plane or entire image)'
i = i + 1
h[i] =  'File->WritePS:            Write a PostScript file of the current display'
i = i + 1
h[i] =  'File->WriteImage:         Write a JPEG, TIFF, BMP, PICT, or PNG image of the current display'
i = i + 1
h[i] =  'File->Quit:               Quits smtv'
i = i + 1

h[i] =  ''
i = i + 1

h[i] =  'ColorMap Menu:            Selects color table'
i = i + 1

h[i] =  ''
i = i + 1

h[i] =  'Scaling->Linear:          Selects linear scaling'
i = i + 1
h[i] =  'Scaling->Log:             Selects log scaling'
i = i + 1
h[i] =  'Scaling->HistEq:          Selects histogram-equalized scaling'
i = i + 1

h[i] =  ''
i = i + 1

h[i] =  'Labels->TextLabel:        Brings up a dialog box for text input'
i = i + 1
h[i] =  'Labels->Arrow:            Brings up a dialog box for overplotting arrows'
i = i + 1
h[i] =  'Labels->Contour:          Brings up a dialog box for overplotting contours'
i = i + 1
h[i] =  'Labels->Compass:          Draws a compass (requires WCS info in header)'
i = i + 1
h[i] =  'Labels->Scalebar:         Draws a scale bar (requires WCS info in header)'
;<<<<<<< smtv_jb.pro
i = i + 1
h[i] =  'Labels->Region:           Brings up a dialog box for overplotting regions'
i = i + 1
h[i] =  'Labels->WCS Grid:         Draws a WCS grid on current image'
i = i + 1
;=======
;i = i + 1
h[i] =  'Labels->Draw Extraction:  Draws four-sided polygons based on data supplied by SMART.'
i = i + 1
h[i] =  'Labels->Draw Wavesamp:    Draws four-sided polygons based on data supplied from a'
i = i + 1
h[i] =  '                          wavsamp file. SMTV will attempt to identify the image''s'
i = i + 1
h[i] =  '                          channel number from it''s header.'
i = i + 1
h[i] =  '                          If a channel number is found SMTV will then attempt to   '
i = i + 1
h[i] =  '                          load the appropriate wavsamp file based on system '
i = i + 1
h[i] =  '                          variables supplied by SMART. If these do not exist, then'
i = i + 1
h[i] =  '                          SMTV will attempt to load the wavsamp file from a default  '
i = i + 1
h[i] =  '                          file specified in the code. If that fails too, then the  '
i = i + 1
h[i] =  '                          user will be presented with a dialog to speficy the  '
i = i + 1
h[i] =  '                          wavsamp file. '
i = i + 1
h[i] =  '                          If no channel number is found, then the '
i = i + 1
h[i] =  '                          user will be presented with a dialog to speficy the '
i = i + 1
h[i] =  '                          wavsamp file. '
i = i + 1
h[i] =  '                          The overlay of polygons will zoom with the image and '
i = i + 1
h[i] =  '                          persist until this option is selected again. '
i = i + 1
h[i] =  '                          NOTE: Both Draw Extraction & Wavsamp subtract 0.5 as  '
i = i + 1
h[i] =  '                          as wavesamp assumes 0 is lh corner of pixel and idl assumes'
i = i + 1
h[i] =  '                           0 is lh corner of pixel.'
i = i + 1



;>>>>>>> smtv_ks.pro
h[i] =  'Labels->EraseLast:        Erases the most recent plot label'
i = i + 1
h[i] =  'Labels->EraseAll:         Erases all plot labels'
i = i + 1

h[i] =  ''
i = i + 1

h[i] =  'Blink->SetBlink:          Sets the current display to be the blink image'
i = i + 1
h[i] =  '                            for mouse button 1, 2, or 3'
i = i + 1

h[i] =  ''
i = i + 1

h[i] =  'Zoom->Zoom In:            Zoom in by 2x'
i = i + 1
h[i] =  'Zoom->Zoom Out:           Zoom out by 2x'
i = i + 1
h[i] =  'Zoom->1/16:               Zoom out to 1/16x original image'
i = i + 1
h[i] =  'Zoom->1/8:                Zoom out to 1/8x original image'
i = i + 1
h[i] =  'Zoom->1/4:                Zoom out to 1/4x original image'
i = i + 1
h[i] =  'Zoom->1/2:                Zoom out to 1/2x original image'
i = i + 1
h[i] =  'Zoom->1:                  No Zoom'
i = i + 1
h[i] =  'Zoom->2:                  Zoom in to 2x original image'
i = i + 1
h[i] =  'Zoom->4:                  Zoom in to 4x original image'
i = i + 1
h[i] =  'Zoom->8:                  Zoom in to 8x original image'
i = i + 1
h[i] =  'Zoom->16:                 Zoom in to 16x original image'
i = i + 1
h[i] =  'Zoom->Center:             Recenter image'
i = i + 1
h[i] =  'Zoom->None:               Invert to original image
i = i + 1
h[i] =  'Zoom->Invert X:           Invert the X-axis of the original image'
i = i + 1
h[i] =  'Zoom->Invert Y:           Invert the Y-axis of the original image'
i = i + 1
h[i] =  'Zoom->Invert X&Y:         Invert both the X and Y axes of the original image'
i = i + 1
h[i] =  'Zoom->Rotate:             Rotate image by arbitrary angle'
i = i + 1
h[i] =  'Zoom->0 deg:              Rotate image to original orientation'          
i = i + 1
h[i] =  'Zoom->90 deg:             Rotate original image by 90 degrees'
i = i + 1
h[i] =  'Zoom->180 deg:            Rotate original image by 180 degrees'    
i = i + 1
h[i] =  'Zoom->270 deg:            Rotate original image by 270 degrees'        
i = i + 1

h[i] =  ''
i = i + 1

h[i] =  'ImageInfo->Photometry:    Brings up photometry window'
i = i + 1
h[i] =  'ImageInfo->ImageHeader:   Display the FITS header, if there is one.'
i = i + 1
h[i] =  'ImageInfo->Pixel Table:   Brings up a pixel table that tracks as the cursor moves'
i = i + 1
h[i] =  'ImageInfo->Load Regions:  Load in an SAOImage/DS9 region file and overplot on image'
i = i + 1
h[i] =  '                            Region files must be in the following format:'
i = i + 1
h[i] =  ''
i = i + 1
h[i] =  '                              circle( xcenter, ycenter, radius)'
i = i + 1
h[i] =  '                              box( xcenter, ycenter, xwidth, ywidth)'
i = i + 1
h[i] =  '                              ellipse( xcenter, ycenter, xwidth, ywidth, rotation angle)'
i = i + 1
h[i] =  '                              polygon( x1, y1, x2, y2, x3, y3, ...)'
i = i + 1
h[i] =  '                              line( x1, y1, x2, y2)'
i = i + 1
h[i] = ' '
i = i + 1
h[i] =  '                          Coordinates may be specified in pixels or WCS.  Radii and widths'
i = i + 1
h[i] =  '                          are specified in pixels or arcminutes.  For example,'
i = i + 1
h[i] = ' '
i = i + 1
h[i] =  '                              circle( 100.5, 46.3, 10.0)'
i = i + 1
h[i] = ' '
i = i + 1
h[i] =  '                          draws a circle with a radius of 10 pixels, centered at (100.5, 46.3)'
i = i + 1
h[i] =  ' '
i = i + 1
h[i] =  '                              circle(00:47:55.121, -25:22:11.98, 0.567)'
i = i + 1 
h[i] =  ' '
i = i + 1
h[i] =  '                          draws a circle with a radius of 0.567 arcminutes, centered at (00:47:55.121, -25:22:11.98)'
i = i + 1
h[i] =  ' '
i = i + 1
h[i] =  '                          The coordinate system for the region coordinates may be specified by'
i = i + 1
h[i] = ' '
i = i + 1
h[i] =  '                              circle(00:47:55.121, -25:22:11.98, 0.567, J2000)'
i = i + 1
h[i] =  '                              circle(11.97967, -25.36999, 0.567, J2000)'
i = i + 1
h[i] =  '                              circle(00:45:27.846, -25:38:33.51, 0.567, B1950)'
i = i + 1
h[i] =  '                              circle(11.366, -25.6426, 0.567, B1950)'
i = i + 1
h[i] =  '                              circle(98.566, -88.073, 0.567, galactic)'
i = i + 1
h[i] =  '                              circle(0.10622, -27.88563, 0.567, ecliptic)'
i = i + 1
h[i] =  ' '
i = i + 1
h[i] =  '                          If no coordinate system is given and coordinates are in colon-separated WCS format, the'
i = i + 1
h[i] =  '                          native coordinate system is used.'
i = i + 1
h[i] =  ' '
i = i + 1
h[i] =  '                          Region color may be specified for the following colors in the format below:'
i = i + 1
h[i] =  '                          Red, Black, Green, Blue, Cyan, Magenta, Yellow, White'
i = i + 1
h[i] = ' '
i = i + 1
h[i] = '                               circle(100.5, 46.3, 10.0) # color=red'
i = i + 1
h[i] = ' '
i = i + 1
h[i] =  '                          Region text may be specified in the following format:'
i = i + 1
h[i] = ' '
i = i + 1
h[i] = '                               circle(100.5, 46.3, 10.0) # text={Text written here}'
i = i + 1
h[i] = ' '
i = i + 1
h[i] =  'ImageInfo->RA,dec(J2000): Coordinates displayed are RA,dec (J2000)'
i = i + 1
h[i] =  'ImageInfo->RA,dec(B1950): Coordinates displayed are RA,dec (B1950)'
i = i + 1
h[i] =  'ImageInfo->RA,dec(J2000) deg: Coordinates displayed are RA,dec (J2000) in degrees'
i = i + 1
h[i] =  'ImageInfo->Galactic:      Coordinates displayed are Galactic coordinates'
i = i + 1
h[i] =  'ImageInfo->Ecliptic(J2000): Coordinates displayed are Ecliptic (J2000)'
i = i + 1
h[i] =  'ImageInfo->Native:        Coordinates displayed are those of the image'
i = i + 1
h[i] =  'ImageInfo->Save Regions:  Save currently displayed regions to a SAOImage/DS9 region file'
i = i + 1
h[i] =  'ImageInfo->Archive Image: Dialog to download DSS, 2MASS, or IRAS images into SMTV'
i = i + 1
h[i] =  ''
i = i + 1
h[i] =  'CONTROL PANEL ITEMS:'
i = i + 1
h[i] = 'Min:                      Shows minimum data value displayed; enter new min value here'
i = i + 1
h[i] = 'Max:                      Shows maximum data value displayed; enter new max value here'
i = i + 1
h[i] = 'Pan Window:               Use mouse to drag the image-view box around'
i = i + 1
h[i] = ''
i = i + 1
h[i] = 'MOUSE MODE SELECTOR:'
i = i + 1
h[i] =  'Color:                    Sets color-stretch mode:'
i = i + 1
h[i] = '                            With mouse button 1 down, drag mouse to change the color stretch.  '
i = i + 1
h[i] = '                            Move vertically to change contrast, and'
i = i + 1
h[i] = '                            horizontally to change brightness.'
i = i + 1 
h[i] = '                            button 2 or 3: center on current position'
i = i + 1
h[i] = ' '
i = i + 1
h[i] = 'Zoom:                     Sets zoom mode:' 
i = i + 1 
h[i] = '                            button1: Zoom in & center on current position'
i = i + 1
h[i] = '                            button2: Center on current position'
i = i + 1 
h[i] = '                            button3: Zoom out & center on current position'
i = i + 1
h[i] = ' '
i = i + 1
h[i] = 'Blink:                    Sets blink mode:'
i = i + 1
h[i] = '                            If 2 images have been set to blink:'
i = i + 1 
h[i] = '                              Press the left mouse button in main window to blink'
i = i + 1
h[i] = '                              between the two images.'
i = i + 1
h[i] = ' '
i = i + 1
h[i] = '                            If 3 images have been set to blink:'
i = i + 1
h[i] = '                              Press the left mouse button to blink images 1 and 3.'
i = i + 1
h[i] = '                              Press the middle mouse button to blink imgaes 2 and 3.'
i = i + 1
h[i] = '                              Hold the left mouse button down and then press the middle'
i = i + 1
h[i] = '                              mouse button to blink images 1 and 2.'
i = i + 1
h[i] = ' '
i = i + 1
h[i] = 'ImExam:                   Sets ImageExamine mode:'
i = i + 1
h[i] = '                            button 1: Photometry'
i = i + 1
h[i] = '                            button 2: Center on current position'
i = i + 1
h[i] = '                            button 3: Image statistics'
;<<<<<<< smtv_jb.pro
i = i + 1
h[i] = ' '
i = i + 1
h[i] = 'Region:                   Brings up dialog to overplot regions on displayed image'
i = i + 1
h[i] = '                            button 1: Press the left mouse button to draw region.'
i = i + 1
h[i] = ' '
i = i + 1
h[i] = 'Vector:                   Draws a vector plot between two points'
i = i + 1
h[i] = '                            button 1: Press and hold left mouse while dragging across image.'
i = i + 1
h[i] = '                                      Release left mouse to draw vectorplot between two points.'
i = i + 2
;=======
;i = i + 2
h[i] = 'ImExam3d:                 Sets ImageExamine3d mode:'
i = i + 1
h[i] = '                            button 1: Select arbitrary box with two clicks, defining the corners'
i = i + 1
h[i] = '                            button 2: Run with default 11x11 box'
i = i + 1
h[i] = '                            button 3: Run with default 11x11 box'
i = i + 2
;>>>>>>> smtv_ks.pro
h[i] = 'BUTTONS:'
i = i + 1
h[i] = 'Invert:                   Inverts the current color table'
i = i + 1
h[i] = 'Restretch:                Sets min and max to preserve display colors while linearizing the color table'
i = i + 1
h[i] = 'AutoScale:                Sets min and max to show data values around image median'
i = i + 1
h[i] = 'FullRange:                Sets min and max to show the full data range of the image'
i = i + 1
h[i] = 'Mosaic:                   If the image displayed is a 3D cube of images, this will'
i = i + 1
h[i] = '                          display the cube as a mosaic of images with SMTV treating'
i = i + 1
h[i] = '                          it as a single image. Pressing the button again will'
i = i + 1
h[i] = '                          restore the cube.'
i = i + 1
h[i] = 'ZoomIn:                   Zooms in by 2x'
i = i + 1
h[i] = 'ZoomOut:                  Zooms out by 2x'
i = i + 1
h[i] = 'Zoom1:                    Sets zoom level to original scale'
i = i + 1
h[i] = 'Center:                   Centers image on display window'
i = i + 1
h[i] = 'Done:                     Quits smtv'
i = i + 1
h[i] = ''
i = i + 1

h[i] = 'MULTI-PLANE IMAGE SLIDER:'
i = i + 1
h[i] = 'Image #= :                Type image plane number to display'
i = i + 1
h[i] = '                            Use slidebar to display other image planes'
i = i + 1
h[i] = ''
i = i + 1
h[i] = 'MULTI-PLANE COLOR SCALING DROPLIST:'
i = i + 1
h[i] = 'Constant:                 Keep Min/Max display values the same for each image plane'
i = i + 1
h[i] = 'AutoScale:                SMTV AutoScale Min/Max display values for the displayed plane'
i = i + 1
h[i] = 'Min/Max:                  Set Min/Max display values to Min/Max of the displayed plane'
i = i + 1

h[i] = ''
i = i + 1
h[i] = 'Keyboard commands in display window:'
i = i + 1
h[i] = '  Numeric keypad (with NUM LOCK on) moves cursor'
i = i + 1
h[i] = '    8: Up'
i = i + 1
h[i] = '    2: Down'
i = i + 1
h[i] = '    6: Right'
i = i + 1   
h[i] = '    4: Left'
i = i + 1
h[i] = ' '
i = i + 1
h[i] = '    r: row plot'
i = i + 1
h[i] = '    c: column plot'
i = i + 1
h[i] = '    j: 1D Gaussian fit to image rows'
i = i + 1
h[i] = '    k: 1D Gaussian fit to image columns'
i = i + 1
h[i] = '    h: histogram plot'
i = i + 1
h[i] = '    s: surface plot'
i = i + 1
h[i] = '    t: contour plot'
i = i + 1
h[i] = '    l: pixel slice plot (for 3D images)'
i = i + 1
h[i] = '    p: aperture photometry at current position'
i = i + 1
h[i] = '    i: image statistics at current position'
i = i + 1
h[i] = '    g: shortcut for region plot'
i = i + 1
h[i] = '    z: shortcut for pixel table'
i = i + 1
h[i] = '    q: quits smtv'
i = i + 2
h[i] = 'IDL COMMAND LINE HELP:'
i = i + 1
h[i] =  'To pass an array to smtv:'
i = i + 1
h[i] =  '   smtv, array_name [, options]'
i = i + 1
h[i] =  ''
i = i + 1
h[i] = 'To pass a FITS filename to smtv:'
i = i + 1
h[i] =  '   smtv, fitsfile_name [, options] (enclose filename in single quotes) '
i = i + 1
h[i] =  ''
i = i + 1
h[i] = 'Command-line options are: '
i = i + 1
h[i]  = '   [,min = min_value] [,max=max_value] [,/linear] [,/log] [,/histeq]'
i = i + 1
h[i]  = '   [,/block] [,/align] [,/stretch] [,header=header]'
i = i + 2
h[i] = 'To overplot a contour plot on the draw window:'
i = i + 1
h[i] = '   smtvcontour, array_name [, options...]'
i = i + 1
h[i] =  ''
i = i + 1
h[i] = 'To overplot text on the draw window: '
i = i + 1
h[i] = '   smtvxyouts, x, y, text_string [, options]  (enclose string in single quotes)'
i = i + 1
h[i] =  ''
i = i + 1
h[i] = 'To overplot points or lines on the current plot:'
i = i + 1
h[i] = '   smtvplot, xvector, yvector [, options]'
i = i + 2
h[i] = 'The options for smtvcontour, smtvxyouts, and smtvplot are essentially'
i = i + 1
h[i] = '  the same as those for the idl contour, xyouts, and plot commands,'
i = i + 1
h[i] = '  except that data coordinates are always used.' 
i = i + 1
h[i] = ''
i = i + 1
h[i] = 'The default color for overplots is RED.'
i = i + 2
h[i] = 'The lowest 8 entries in the color table are:'
i = i + 1
h[i] = '    0 = black'
i = i + 1
h[i] = '    1 = red'
i = i + 1
h[i] = '    2 = green'
i = i + 1
h[i] = '    3 = blue'
i = i + 1
h[i] = '    4 = cyan'
i = i + 1
h[i] = '    5 = magenta'
i = i + 1
h[i] = '    6 = yellow'
i = i + 1
h[i] = '    7 = white'
i = i + 1
h[i] = 'The top entry in the color table is also reserved for white. '
i = i + 2
h[i] = 'OTHER COMMANDS:'
i = i + 1
h[i] = '  smtverase [, N]:         Erases all (or last N) plots and text'
i = i + 1
h[i] = '  smtv_shutdown:           Quits smtv'
i = i + 1
h[i] = 'NOTE: If smtv should crash, type smtv_shutdown at the idl prompt.'
i = i + 5
h[i] = strcompress('SMTV.PRO is part of SMART and is only available as part of the SMART package.')
i = i + 2
h[i] = 'SMTV is a modified version of the package ATV written by Aaron Barth.'
i = i + 2
h[i] = 'ATV is available from: http://www.physics.uci.edu/~barth/atv/'


if (not (xregistered('smtv_help', /noshow))) then begin

helptitle = strcompress('smtv v' + state.version + ' help')

    help_base =  widget_base(group_leader = state.base_id, $
                             /column, $
                             /base_align_right, $
                             title = helptitle, $
                             uvalue = 'help_base')

    help_text = widget_text(help_base, $
                            /scroll, $
                            value = h, $
                            xsize = 85, $
                            ysize = 24)
    
    help_done = widget_button(help_base, $
                              value = 'Done', $
                              uvalue = 'help_done')

    widget_control, help_base, /realize
    xmanager, 'smtv_help', help_base, /no_block
    
endif

end

;----------------------------------------------------------------------

pro smtv_help_event, event

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'help_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------
;      Routines for displaying image statistics
;----------------------------------------------------------------------

pro smtv_stats_refresh

; Calculate box statistics and update the results

common smtv_state
common smtv_images

bx = round((state.xstatboxsize - 1) / 2)
by = round((state.ystatboxsize - 1) / 2)

xmin = 0 > (state.cursorpos[0] - bx) < (state.image_size[0] - 1)
xmax = 0 > (state.cursorpos[0] + bx) < (state.image_size[0] - 1)
ymin = 0 > (state.cursorpos[1] - by) < (state.image_size[1] - 1)
ymax = 0 > (state.cursorpos[1] + by) < (state.image_size[1] - 1)

xmin = round(xmin)
xmax = round(xmax)
ymin = round(ymin)
ymax = round(ymax)

cut = float(main_image[xmin:xmax, ymin:ymax])
npix = (xmax - xmin + 1) * (ymax - ymin + 1)

cutmin = min(cut, max=maxx, /nan)
cutmax = maxx
cutmean = mean(cut, /nan, /double)
cutmedian = median(cut)
cutstddev = stddev(cut, /nan, /double)

widget_control, state.xstatbox_id, set_value=state.xstatboxsize
widget_control, state.ystatbox_id, set_value=state.ystatboxsize
widget_control, state.statxcenter_id, set_value = state.cursorpos[0]
widget_control, state.statycenter_id, set_value = state.cursorpos[1]
tmp_string = strcompress('# Pixels in Box:  ' + string(npix))
widget_control, state.stat_npix_id, set_value = tmp_string
tmp_string = strcompress('Min:  ' + string(cutmin))
widget_control, state.statbox_min_id, set_value = tmp_string
tmp_string = strcompress('Max:  ' + string(cutmax))
widget_control, state.statbox_max_id, set_value = tmp_string
tmp_string = strcompress('Mean:  ' + string(cutmean))
widget_control, state.statbox_mean_id, set_value = tmp_string
tmp_string = strcompress('Median:  ' + string(cutmedian))
widget_control, state.statbox_median_id, set_value = tmp_string
tmp_string = strcompress('StdDev:  ' + string(cutstddev))
widget_control, state.statbox_stdev_id, set_value = tmp_string

smtv_tvstats

end

;----------------------------------------------------------------------

pro smtv_stats_event, event

common smtv_state
common smtv_images

widget_control, event.id, get_uvalue = uvalue

case uvalue of

    'xstatbox': begin
        state.xstatboxsize = long(event.value) > 3
        if ( (state.xstatboxsize / 2 ) EQ $
             round(state.xstatboxsize / 2.)) then $
          state.xstatboxsize = state.xstatboxsize + 1
        if (state.stat_xyresize eq 1) then $
            state.ystatboxsize = state.xstatboxsize
        smtv_stats_refresh
    end

    'ystatbox': begin
        state.ystatboxsize = long(event.value) > 3
        if ( (state.ystatboxsize / 2 ) EQ $
             round(state.ystatboxsize / 2.)) then $
          state.ystatboxsize = state.ystatboxsize + 1
        if (state.stat_xyresize eq 1) then $
            state.xstatboxsize = state.ystatboxsize
        smtv_stats_refresh
    end

    'statxcenter': begin
        state.cursorpos[0] = 0 > long(event.value) < (state.image_size[0] - 1)
        smtv_stats_refresh
    end

    'statycenter': begin
        state.cursorpos[1] = 0 > long(event.value) < (state.image_size[1] - 1)
        smtv_stats_refresh
    end

    'statxyresize': begin
      widget_control, state.stat_xyresize_button_id
      if (state.stat_xyresize eq 1) then state.stat_xyresize = 0 $
      else state.stat_xyresize = 1
    end

    'showstatzoom': begin
        widget_control, state.showstatzoom_id, get_value=val
        case val of
            'Show Region': begin
                widget_control, state.statzoom_widget_id, $
                  xsize=state.statzoom_size, ysize=state.statzoom_size
                widget_control, state.showstatzoom_id, $
                  set_value='Hide Region'
            end
            'Hide Region': begin
                widget_control, state.statzoom_widget_id, $
                  xsize=1, ysize=1
                widget_control, state.showstatzoom_id, $
                  set_value='Show Region'
             end
         endcase
         smtv_stats_refresh
    end
  
    'stats_hist': begin

       x1 = state.cursorpos[0] - (state.xstatboxsize/2)
       x2 = state.cursorpos[0] + (state.xstatboxsize/2)
       y1 = state.cursorpos[1] - (state.ystatboxsize/2)
       y2 = state.cursorpos[1] + (state.ystatboxsize/2)

       if (not (xregistered('smtv_lineplot', /noshow))) then begin
         smtv_lineplot_init
       endif

       state.plot_coord = state.cursorpos
       widget_control, state.x1_pix_id, set_value=x1
       widget_control, state.x2_pix_id, set_value=x2
       widget_control, state.y1_pix_id, set_value=y1
       widget_control, state.y2_pix_id, set_value=y2
       hist_image = main_image[x1:x2,y1:y2]

       state.lineplot_xmin = min(hist_image)
       state.lineplot_xmax = max(hist_image)
       state.lineplot_ymin = 0.
       state.binsize = (state.lineplot_xmax - state.lineplot_xmin) * 0.01
       state.binsize = state.binsize > $
         ((state.lineplot_xmax - state.lineplot_xmin) * 1.0e-5)
       state.binsize = fix(state.binsize)

       ;Set plot window before calling plothist to get histogram ranges
       smtv_setwindow, state.lineplot_window_id
       erase

       plothist, hist_image, xhist, yhist, bin=state.binsize, /NaN, /nodata

       state.lineplot_ymax = max(yhist) + (0.05*max(yhist))

       widget_control, state.lineplot_xmin_id, $
         set_value = state.lineplot_xmin

       widget_control, state.lineplot_xmax_id, $
         set_value = state.lineplot_xmax

       widget_control, state.lineplot_ymin_id, $
         set_value = state.lineplot_ymin

       widget_control, state.lineplot_ymax_id, $
         set_value = state.lineplot_ymax

       widget_control, state.histplot_binsize_id, set_value=state.binsize

       smtv_histplot, /update

    end

    'stats_save': begin
       stats_outfile = dialog_pickfile(filter='*.txt', $
                        file='smtv_stats.txt', get_path = tmp_dir, $
                        title='Please Select File to Append Stats')

       IF (strcompress(stats_outfile, /remove_all) EQ '') then RETURN

       IF (stats_outfile EQ tmp_dir) then BEGIN
         smtv_message, 'Must indicate filename to save.', $
                       msgtype = 'error', /window
         return
       ENDIF

       openw, lun, stats_outfile, /get_lun, /append

       widget_control, state.stat_npix_id, get_value = npix_str
       widget_control, state.statbox_min_id, get_value = minstat_str
       widget_control, state.statbox_max_id, get_value = maxstat_str
       widget_control, state.statbox_mean_id, get_value = meanstat_str
       widget_control, state.statbox_median_id, get_value = medianstat_str
       widget_control, state.statbox_stdev_id, get_value = stdevstat_str

       printf, lun, 'SMTV IMAGE BOX STATISTICS--NOTE: IDL Arrays Begin With Index 0'
       printf, lun, '============================================================='
       printf, lun, ''
       printf, lun, 'Image Name: ' + strcompress(state.imagename,/remove_all)
       printf, lun, 'Image Size: ' + strcompress(string(state.image_size[0]) $
                           + ' x ' + string(state.image_size[1]))
 
       printf, lun, 'Image Min: ' + $
                    strcompress(string(state.image_min),/remove_all)
       printf, lun, 'Image Max: ' + $
                    strcompress(string(state.image_max),/remove_all)

       if (state.image_size[2] gt 1) then printf, lun, 'Image Plane: ' + $
                    strcompress(string(state.cur_image_num),/remove_all)

       printf, lun, ''
       printf, lun, 'Selected Box Statistics:'
       printf, lun, '------------------------'
     
       printf, lun, 'X-Center: ' + strcompress(string(state.cursorpos[0]), $
                /remove_all)
       printf, lun, 'Y-Center: ' + strcompress(string(state.cursorpos[1]), $
                /remove_all)
       printf, lun, 'Xmin: ' + $
              strcompress(string(state.cursorpos[0] - state.xstatboxsize/2), $
                /remove_all)
       printf, lun, 'Xmax: ' + $
              strcompress(string(state.cursorpos[0] + state.xstatboxsize/2), $
                /remove_all)
       printf, lun, 'Ymin: ' + $
              strcompress(string(state.cursorpos[1] - state.ystatboxsize/2), $
                /remove_all)
       printf, lun, 'Ymax: ' + $
              strcompress(string(state.cursorpos[1] + state.ystatboxsize/2), $
                /remove_all)

       printf, lun, npix_str
       printf, lun, minstat_str
       printf, lun, maxstat_str
       printf, lun, meanstat_str
       printf, lun, medianstat_str
       printf, lun, stdevstat_str
       printf, lun, ''

       close, lun
       free_lun, lun

    end

    'stats_done': widget_control, event.top, /destroy
    else:
endcase


end

;----------------------------------------------------------------------

pro smtv_showstats

; Brings up a widget window for displaying image statistics

common smtv_state
common smtv_images

common smtv_state

state.cursorpos = state.coord

if (not (xregistered('smtv_stats', /noshow))) then begin

    stats_base = $
      widget_base(group_leader = state.base_id, $
                  /column, $
                  /base_align_center, $
                  title = 'smtv image statistics', $
                  uvalue = 'stats_base')
    state.stats_base_id = stats_base
    
    stats_nbase = widget_base(stats_base, /row, /base_align_center)
    stats_base1 = widget_base(stats_nbase, /column, frame=1)
    stats_base2 = widget_base(stats_nbase, /column)
    stats_base2a = widget_base(stats_base2, /column, frame=1)
    stats_zoombase = widget_base(stats_base, /column)

    tmp_string = strcompress('Image size:  ' + $
                             string(state.image_size[0]) + $
                             ' x ' + $
                             string(state.image_size[1]))

    size_label = widget_label(stats_base1, value = tmp_string, /align_left)

    tmp_string = strcompress('Image Min:  ' + string(state.image_min))
    min_label= widget_label(stats_base1, value = tmp_string, /align_left)
    tmp_string = strcompress('Image Max:  ' + string(state.image_max))
    max_label= widget_label(stats_base1, value = tmp_string, /align_left)

    state.xstatbox_id = $
      cw_field(stats_base1, $
               /long, $
               /return_events, $
               title = 'Box Size (X) for Stats:', $
               uvalue = 'xstatbox', $
               value = state.xstatboxsize, $
               xsize = 5)

    state.ystatbox_id = $
      cw_field(stats_base1, $
               /long, $
               /return_events, $
               title = 'Box Size (Y) for Stats:', $
               uvalue = 'ystatbox', $
               value = state.ystatboxsize, $
               xsize = 5)    

    state.statxcenter_id = $
      cw_field(stats_base1, $
               /long, $
               /return_events, $
               title = 'Box X Center:', $
               uvalue = 'statxcenter', $
               value = state.cursorpos[0], $ 
               xsize = 5)

    state.statycenter_id = $
      cw_field(stats_base1, $
               /long, $
               /return_events, $
               title = 'Box Y Center:', $
               uvalue = 'statycenter', $
               value = state.cursorpos[1], $ 
               xsize = 5)

    statxyresize_id = $
      widget_base(stats_base1, $
                  row = 1, $
                  /nonexclusive)

    state.stat_xyresize_button_id = $
      widget_button(statxyresize_id, $
                    value = 'Square Box Statistics', $
                    uvalue = 'statxyresize')

    tmp_string = strcompress('# Pixels in Box:  ' + string(100000))
    state.stat_npix_id = widget_label(stats_base2a, value = tmp_string,$
      /align_left)
    tmp_string = strcompress('Min:  ' + '0.00000000')
    state.statbox_min_id = widget_label(stats_base2a, value = tmp_string,$
      /align_left)
    tmp_string = strcompress('Max:  ' + '0.00000000')
    state.statbox_max_id = widget_label(stats_base2a, value = tmp_string, $
      /align_left)
    tmp_string = strcompress('Mean:  ' + '0.00000000')
    state.statbox_mean_id = widget_label(stats_base2a, value = tmp_string, $
      /align_left)
    tmp_string = strcompress('Median:  ' + '0.00000000')
    state.statbox_median_id = widget_label(stats_base2a, value = tmp_string, $
      /align_left)
    tmp_string = strcompress('StdDev:  ' + '0.00000000')
    state.statbox_stdev_id = widget_label(stats_base2a, value = tmp_string, $
      /align_left)
    
    state.showstatzoom_id = widget_button(stats_base2, $
          value = 'Hide Region', uvalue = 'showstatzoom')

    stat_hist = widget_button(stats_base2, value = 'Histogram Pixels', $
          uvalue = 'stats_hist')

    stat_save = widget_button(stats_base2, value = 'Save Stats', $
          uvalue = 'stats_save')

    stat_done = $
      widget_button(stats_base2, $
                    value = 'Done', $
                    uvalue = 'stats_done')
    
    state.statzoom_widget_id = widget_draw(stats_zoombase, $
       xsize = state.statzoom_size, ysize = state.statzoom_size)

    widget_control, statxyresize_id, set_button = state.stat_xyresize

    widget_control, stats_base, /realize
    
    xmanager, 'smtv_stats', stats_base, /no_block
    
    widget_control, state.statzoom_widget_id, get_value = tmp_val
    state.statzoom_window_id = tmp_val

    smtv_resetwindow

endif

smtv_stats_refresh

end

;---------------------------------------------------------------------

pro smtv_showstats3d_event, event

;event handler for showstats3d

common smtv_state
common smtv_images        

xmin=state.stat3dminmax(0)
xmax=state.stat3dminmax(1)
ymin=state.stat3dminmax(2)
ymax=state.stat3dminmax(3)

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'im_slider1': begin
        smtv_stats3d_refresh
        end
    'im_slider2': begin
        smtv_stats3d_refresh
    end
    'done':  begin
        widget_control, event.top, /destroy
        smtv_refresh
    end

    'refresh': begin
        ;refresh rectangle
        
        smtv_refresh
        ;calculate box size
        xsize=abs(state.s3sel[2]-state.s3sel[0])
        ysize=abs(state.s3sel[3]-state.s3sel[1])
        
        if (state.s3sel[1] lt state.s3sel[3]) then begin
            tmp=state.s3sel[1]
            state.s3sel[1]=state.s3sel[3]
            state.s3sel[3]=tmp
        endif
        
        if (state.s3sel[0] gt state.s3sel[2]) then begin
            tmp=state.s3sel[0]
            state.s3sel[0]=state.s3sel[2]
            state.s3sel[2]=tmp
        endif

        s=state.s3sel
        r=[0, 0, s[0], s[1], s[0]+xsize, s[1], s[2], s[3], s[0], s[1]-ysize]

       ;get draw widget id, draw box 
        smtv_setwindow, state.draw_window_id
        smtv_display_box, r
    end

    ;update box size
    'xsize': begin
        widget_control, event.id, get_value=xsize
        
        ;check if entered boxsize is even
        if (xsize mod 2) eq 0 then xsize=xsize+1

        ;check if entered boxsize is smaller than image
        if (xsize gt state.image_size[0]) then xsize=state.image_size[0] 
          
        ;update widget
        widget_control, event.id, set_value=xsize
        state.stat3dbox[0]=xsize
        smtv_stats3d_refresh         
    end
    
    'ysize': begin
        widget_control, event.id, get_value=ysize
        
        ;check if entered boxsize is even
        if (ysize mod 2) eq 0 then ysize=ysize+1     

        ;check if entered boxsize is smaller than image
        if (ysize gt state.image_size[1]) then ysize=state.image_size[1] 
     
        ;update widget
        widget_control, event.id, set_value=ysize
         state.stat3dbox[1]=ysize 
         smtv_stats3d_refresh    
    end     

    ;update box center
    'xcenter': begin
         widget_control, event.id, get_value=xcenter
         
         ;check that new center is in image
         if (xcenter gt state.image_size[0]) then xcenter=state.image_size[0]
         state.stat3dcenter[0]=xcenter

         ;update widget
         widget_control, event.id, set_value=xcenter        
         smtv_stats3d_refresh
     end

    'ycenter': begin
         widget_control, event.id, get_value=ycenter
         
         ;check that new center is in image
         if (ycenter gt state.image_size[1]) then ycenter=state.image_size[1]
         state.stat3dcenter[1]=ycenter         
         
         ;update widget
         widget_control, event.id, set_value=ycenter
         smtv_stats3d_refresh         
     end

     'save': begin
         widget_control, state.data_table, get_value=data
         
         ;let user choose filename
         res=dialog_pickfile(dialog_parent=state.base_id, $
                             file='stats3d.dat', $
                             get_path = tmp_dir, $
                             title='Please Select File to save 3dStats')

         ;check that selected file is ok
         if (strcompress(res, /remove_all) eq '') then return

         if (res eq tmp_dir) then begin
             res1=dialog_message('ERROR: Must select a filename!', $
                                 dialog_parent=state.base_id, $
                                 title='Saving Stats3d')
             return
         endif

         ;open output
         get_lun, u
         openw, u, res

         ;begin writing
         
         printf, u, '#SMTV IMAGE CUBE STATISTICS--NOTE: IDL Arrays Begin With Index 0'
         printf, u, '#============================================================='
         printf, u, '#'
         printf, u, '#Image Size:  '+strtrim(state.image_size[0],1)+' x '+strtrim(state.image_size[1],1)+  ' x '+strtrim(state.image_size[2],1)
         printf, u, '#File Name,  Minimum, Maximum, Mean, Median, Std. dev.'


         data1=strarr(6, state.image_size[2])
         for i=0, state.image_size[2]-1 do begin
             data1(0,i)=strtrim(names_stack[i],2)
             data1(1,i)=data(0,i)
             data1(2,i)=data(1,i)
             data1(3,i)=data(2,i)
             data1(4,i)=data(3,i)
             data1(5,i)=data(4,i)        
         endfor

         printf, u, format='(A35, T40, F12.4, T57, F12.4, T74, F12.4, T91, F12.4, T108, F12.4)', data1

         ;close up
         close, u
         free_lun, u
     end

    else: begin
        print, 'ERROR: Problem with showstat3d.'
    end
endcase

end

;---------------------------------------------------------------------

pro smtv_stats3d_refresh

;refreshes stat3d

common smtv_state
common smtv_images

;preparing the center & size of window
state.cursorpos=state.coord

bx = round((state.stat3dbox(0) - 1) / 2)
by = round((state.stat3dbox(1) - 1) / 2)

xmin = 0 > (state.stat3dcenter[0] - bx) < (state.image_size[0] - 1)
xmax = 0 > (state.stat3dcenter[0] + bx) < (state.image_size[0] - 1)
ymin = 0 > (state.stat3dcenter[1] - by) < (state.image_size[1] - 1)
ymax = 0 > (state.stat3dcenter[1] + by) < (state.image_size[1] - 1)


xmin = round(xmin)
xmax = round(xmax)
ymin = round(ymin)
ymax = round(ymax)

state.stat3dminmax(0)=xmin
state.stat3dminmax(1)=xmax
state.stat3dminmax(2)=ymin
state.stat3dminmax(3)=ymax
                    
;refreshing screens
;1st screen
widget_control, state.screen1, get_value=scr1
widget_control, state.im_slider1, get_value=im1_num
wset, scr1
tvscl, congrid(main_image_stack(xmin:xmax, ymin:ymax, im1_num), 256, 256)    

;2nd screen
widget_control, state.screen2, get_value=scr2
widget_control, state.im_slider2, get_value=im2_num
wset, scr2
tvscl, congrid(main_image_stack(xmin:xmax, ymin:ymax, im2_num), 256, 256)

;refreshing data
data=dblarr(5, state.image_size[2])

for i=0, state.image_size[2]-1 do begin
    data(0,i)=min(main_image_stack(xmin:xmax, ymin:ymax, i), /nan)
    data(1,i)=max(main_image_stack(xmin:xmax, ymin:ymax, i), /nan)
    data(2,i)=mean(main_image_stack(xmin:xmax, ymin:ymax, i), /nan)
    data(3,i)=median(main_image_stack(xmin:xmax, ymin:ymax, i))
    data(4,i)=stddev(main_image_stack(xmin:xmax, ymin:ymax, i), /nan)
endfor

widget_control, state.data_table, set_value=data
end

;---------------------------------------------------------------------

pro smtv_showstats3d

; Brings up a widget window for displaying image statistics

common smtv_state
common smtv_images

;preparing the center & size of window
state.cursorpos=state.coord
;state.stat3dbox=[11, 11]
;state.stat3dcenter=state.coord

bx = round((state.stat3dbox[0] - 1) / 2)
by = round((state.stat3dbox[1] - 1) / 2)

xmin = 0 > (state.stat3dcenter[0] - bx) < (state.image_size[0] - 1)
xmax = 0 > (state.stat3dcenter[0] + bx) < (state.image_size[0] - 1)
ymin = 0 > (state.stat3dcenter[1] - by) < (state.image_size[1] - 1)
ymax = 0 > (state.stat3dcenter[1] + by) < (state.image_size[1] - 1)

xmin = round(xmin)
xmax = round(xmax)
ymin = round(ymin)
ymax = round(ymax)

if (state.mosaic eq 1) then return

;store box info
state.stat3dminmax=[xmin, xmax, ymin, ymax]

;main base for stat3d    
res=widget_info(state.base_id, /geometry)
stats_base = $
  widget_base(/floating, $
              group_leader = state.base_id, $
              /column, $
              /base_align_left, $
              title = 'smtv 3d image statistics', $
              uvalue = 'stats_base', $
              xoffset=res.xoffset+650)

n_images=state.image_size[2]
n_stats=5

                                ;quit if there is no image
if (n_images eq 0) then return

row1=widget_base(stats_base, column=2)
row2=widget_base(stats_base, column=3, /align_left)
column1=widget_base(row1, frame=2, /align_left, /column)
column2=widget_base(row1, frame=2, /align_left, /column)
column3=widget_base(row2, frame=2, /align_left, /column) 
column4=widget_base(row2, frame=2, /align_left, /column)
column5=widget_base(row2, frame=2, /align_left, /column)

tmp_string='Image Cube Size: '+strtrim(state.image_size[0],1)+ $
  ' x '+strtrim(state.image_size[1],1)+ $
  ' x '+strtrim(state.image_size[2],1)
title_field=widget_label(column1, value=tmp_string)

                                ;box size forms
xsize=cw_field(column1, $
               value=state.stat3dbox(0), $
               title='Box size (x) = ', $
               uvalue='xsize', $
               xsize=6, $
               /return_events)

ysize=cw_field(column1, $
               value=state.stat3dbox(1), $
               title='Box size (y) = ', $
               uvalue='ysize', $
               xsize=6, $
               /return_events)

xcenter=cw_field(column1, $
                 value=state.stat3dcenter(0), $
                 title='Box center (x) = ', $
                 uvalue='xcenter', $
                 xsize=6, $
                 /return_events)

ycenter=cw_field(column1, $
                 value=state.stat3dcenter(1), $
                 title='Box center (y) = ', $
                 uvalue='ycenter', $
                 xsize=6, $
                 /return_events)

state.stat3d_done=widget_button(column1, $
                                /align_center, $
                                value='Done', $
                                uvalue='done')
state.stat3d_refresh=widget_button(column1, $
                                /align_center, $
                                value='Refresh Screen', $
                                uvalue='refresh')
save_stats=widget_button(column1, $
                                /align_center, $
                                value='Save Cube Statistics', $
                                uvalue='save')

title_field1=widget_label(column2, value='Image Cube Statistics')

                                ;gathering data, preparing table
rows=strarr(n_images)
cols=['Minimum','Maximum', 'Mean', 'Median','Std. dev.']

data=dblarr(n_stats, n_images)

for i=0, n_images-1 do begin
    rows(i)='Image #'+strtrim(i+1,1)
    data(0,i)=min(main_image_stack(xmin:xmax, ymin:ymax, i), /nan)
    data(1,i)=max(main_image_stack(xmin:xmax, ymin:ymax, i), /nan)
    data(2,i)=mean(main_image_stack(xmin:xmax, ymin:ymax, i), /nan)
    data(3,i)=median(main_image_stack(xmin:xmax, ymin:ymax, i))
    data(4,i)=stddev(main_image_stack(xmin:xmax, ymin:ymax, i), /nan)
endfor

                                ;making table
state.data_table=widget_table(column2, $
                        xsize=5, $
                        column_labels=cols, $
                        row_labels=rows, $
                        ;ysize=8,$
                        y_scroll_size=10, $
                        value=data, $
                        /scroll)

                                ;display
state.screen1=widget_draw(column3, $
                          xsize=256, $
                          ysize=256, $
                          frame=1)

state.im_slider1=widget_slider(column3, $
                               minimum=0, $
                               maximum=n_images-1, $
                               value=0, $
                               uvalue='im_slider1', $
                               title='Image #')

state.screen2=widget_draw(column4, $
                          xsize=256, $
                          ysize=256, $
                          frame=1)

state.im_slider2=widget_slider(column4, $
                               minimum=0, $
                               maximum=n_images-1, $
                               value=0, $
                               uvalue='im_slider2', $
                               title='Image #')  

state.screen3=widget_draw(column5, $
                          xsize=256, $
                          ysize=256, $
                          frame=1, $
                          uvalue=scr2)

widget_control, stats_base, /realize

xmanager, 'smtv_showstats3d', stats_base, /no_block
smtv_resetwindow    

;showing initial screens
widget_control, state.screen3, get_value=scr3
wset, scr3

; tvscl, congrid(sm_mosaic(main_image_stack), 256, 256)  ; DGW 29 August 2005
tvscl, congrid(sm_mosaic(main_image_stack, bmask_image_stack, bmask_mosaic=bmask_mosaic), 256, 256) ; DGW 29 August 2005

widget_control, state.screen1, get_value=scr1
wset, scr1
tvscl, congrid(main_image_stack(xmin:xmax, ymin:ymax, 0), 256, 256)    

widget_control, state.screen2, get_value=scr2
wset, scr2
tvscl, congrid(main_image_stack(xmin:xmax, ymin:ymax, 0), 256, 256)

end
;---------------------------------------------------------------------

pro smtv_tvstats

; Routine to display the zoomed region around a stats point

common smtv_state
common smtv_images

smtv_setwindow, state.statzoom_window_id
erase

x = round(state.cursorpos[0])
y = round(state.cursorpos[1])

xboxsize = (state.xstatboxsize - 1) / 2
yboxsize = (state.ystatboxsize - 1) / 2

xsize = state.xstatboxsize
ysize = state.ystatboxsize

image = bytarr(xsize,ysize)

xmin = (0 > (x - xboxsize))
xmax = ((x + xboxsize) < (state.image_size[0] - 1) )
ymin = (0 > (y - yboxsize) )
ymax = ((y + yboxsize) < (state.image_size[1] - 1))

startx = abs( (x - xboxsize) < 0 )
starty = abs( (y - yboxsize) < 0 ) 

image[startx, starty] = scaled_image[xmin:xmax, ymin:ymax]

xs = indgen(xsize) + xmin - startx
ys = indgen(ysize) + ymin - starty

xs_delta = (xs[xsize-1] - xs[0]) / float(xsize - 1.0)
ys_delta = (ys[ysize-1] - ys[0]) / float(ysize - 1.0)
x_ran = [xs[0]-xs_delta/2.0,xs[xsize-1]+xs_delta/2.0]
y_ran = [ys[0]-ys_delta/2.0,ys[ysize-1]+ys_delta/2.0]

dev_width = 0.8 * state.statzoom_size
dev_pos = [0.15 * state.statzoom_size, $
           0.15 * state.statzoom_size, $
           0.95 * state.statzoom_size, $
           0.95 * state.statzoom_size]

x_factor = dev_width / xsize
y_factor = dev_width / ysize
x_offset = (x_factor - 1.0) / x_factor / 2.0
y_offset = (y_factor - 1.0) / y_factor / 2.0
xi = findgen(dev_width) / x_factor - x_offset ;x interp index
yi = findgen(dev_width) / y_factor - y_offset ;y interp index

image = Poly_2D(image, [[0,0],[1.0/x_factor,0]], $
             [[0,1.0/y_factor],[0,0]], $
             0, dev_width, dev_width)

xsize = (size(image))[1]
ysize = (size(image))[2]
out_xs = xi * xs_delta + xs[0]
out_ys = yi * ys_delta + ys[0]

sz = size(image)
xsize = Float(sz[1])       ;image width
ysize = Float(sz[2])       ;image height
dev_width = dev_pos[2] - dev_pos[0] + 1
dev_width = dev_pos[3] - dev_pos[1] + 1

tv, image, /device, dev_pos[0], dev_pos[1], $
  xsize=dev_pos[2]-dev_pos[0], $
  ysize=dev_pos[3]-dev_pos[1]

plot, [0, 1], /noerase, /nodata, xstyle = 1, ystyle = 1, $
  /device, position = dev_pos, color=7, $
  xrange = x_ran, yrange = y_ran, xtitle='X', ytitle='Y'

smtv_resetwindow
end

;----------------------------------------------------------------------
;        aperture photometry and radial profile routines
;---------------------------------------------------------------------

pro smtv_imcenterf, xcen, ycen

; program to calculate the center of mass of an image around
; the point (x,y), return the answer in (xcen,ycen).
;
; by M. Liu, adapted for inclusion in SMTV by AJB
;
; ALGORITHM:
;   1. first finds max pixel value in
;	   a 'bigbox' box around the cursor
;   2. then calculates centroid around the object 
;   3. iterates, recalculating the center of mass 
;      around centroid until the shifts become smaller 
;      than MINSHIFT (0.3 pixels) 

common smtv_images
common smtv_state

; iteration controls
MINSHIFT = 0.3

; max possible x or y direction shift
MAXSHIFT = 3

; Bug fix 4/16/2000: added call to round to make sure bigbox is an integer
bigbox=round(1.5*state.centerboxsize)

sz = size(main_image)

; box size must be odd
dc = (state.centerboxsize-1)/2
if ( (bigbox / 2 ) EQ round(bigbox / 2.)) then bigbox = bigbox + 1
db = (bigbox-1)/2

; need to start with integers
xx = state.cursorpos[0]
yy = state.cursorpos[1]

; first find max pixel in box around the cursor
x0 = (xx-db) > 0
x1 = (xx+db) < (sz(1)-1)
y0 = (yy-db) > 0
y1 = (yy+db) < (sz(2)-1)
cut = main_image[x0:x1,y0:y1]
cutmax = max(cut)
w=where(cut EQ cutmax)
cutsize = size(cut)
my = (floor(w/cutsize[1]))[0]
mx = (w - my*cutsize[1])[0]

xx = mx + x0
yy = my + y0 
xcen = xx
ycen = yy

; then find centroid 
if  (n_elements(xcen) gt 1) then begin
    xx = round(total(xcen)/n_elements(xcen)) 
    yy = round(total(ycen)/n_elements(ycen)) 
endif

done = 0
niter = 1
    
;	cut out relevant portion
sz = size(main_image)
x0 = round((xx-dc) > 0)		; need the ()'s
x1 = round((xx+dc) < (sz[1]-1))
y0 = round((yy-dc) > 0)
y1 = round((yy+dc) < (sz[2]-1))
xs = x1 - x0 + 1
ys = y1 - y0 + 1
cut = float(main_image[x0:x1, y0:y1])

                                ; find x position of center of mass
cenxx = fltarr(xs, ys, /nozero)
for i = 0L, (xs-1) do $         ; column loop
  cenxx[i, *] = cut[i, *] * i
xcen = total(cenxx) / total(cut) + x0

                                ; find y position of center of mass
cenyy = fltarr(xs, ys, /nozero)
for i = 0L, (ys-1) do $         ; row loop
  cenyy[*, i] = cut[*, i] * i
ycen = total(cenyy) / total(cut) + y0

if (abs(xcen-state.cursorpos[0]) gt MAXSHIFT) or $
  (abs(ycen-state.cursorpos[1]) gt MAXSHIFT) then begin
    state.photwarning = 'Warning: Possible mis-centering?'
endif

end

;----------------------------------------------------------------------

function smtv_splinefwhm, rad, prof, splrad, splprof

; given a radial profile (counts vs radius) will use
; a spline to extract the FWHM
;
; ALGORITHM
;   finds peak in radial profile, then marches along until finds
;   where radial profile has dropped to half of that,
;   assumes peak value of radial profile is at minimum radius
;
; original version by M. Liu, adapted for SMTV by AJB

common smtv_state

nrad = n_elements(rad)

; check the peak
w = where(prof eq max(prof))
if float(rad(w[0])) ne min(rad) then begin
state.photwarning = 'Warning: Profile peak is off-center!'
  return,-1
endif

; interpolate radial profile at 50 times as many points
splrad = min(rad) + findgen(nrad*50+1) * (max(rad)-min(rad)) / (nrad*50)
nspl = n_elements(splrad)

; spline the profile
splprof = spline(rad,prof,splrad)

; march along splined profile until cross 0.5*peak value
found = 0
i = 0
repeat begin
  if splprof(i) lt 0.5*max(splprof) then $
	found = 1 $
  else $
	i = i+1
endrep until ((found) or (i eq nspl))

if (i lt 2) or (i eq nspl) then begin
state.photwarning = 'Warning: Unable to measure FWHM!'
  return,-1
endif

; now interpolate across the 2 points straddling the 0.5*peak
fwhm = splrad(i)+splrad(i-1)

return,fwhm
end

;-----------------------------------------------------------------------

pro smtv_radplotf, x, y, fwhm, ps=ps

; Program to calculate radial profile of an image
; given aperture location, range of sizes, and inner and 
; outer radius for sky subtraction annulus.  Calculates sky by
; median.
; 
; original version by M. Liu, adapted for inclusion in SMTV by AJB

common smtv_state
common smtv_images

; set defaults
inrad = 0.5*sqrt(2)
outrad = round(state.outersky * 1.2)
drad=1.
insky = outrad+drad
outsky = insky+drad+20.

; initialize arrays
inrad = float(inrad)
outrad = float(outrad)
drad = float(drad)
nrad = ceil((outrad-inrad)/drad) + 1
out = fltarr(nrad,12)

;-------------------------------------------------------PH 29 Aug. 2005

; Added check that "x" and "y" values are finite (IE. not "NaN")

if not finite(x) then x = 0.0
if not finite(y) then y = 0.0

;-------------------------------------------------------PH 29 Aug. 2005

; extract relevant image subset (may be rectangular), translate coord origin,
;   bounded by edges of image
;   (there must be a cute IDL way to do this neater)
sz = size(main_image)
x0 = floor(x-outsky) 
x1 = ceil(x+outsky)   ; one pixel too many?
y0 = floor(y-outsky) 
y1 = ceil(y+outsky)
x0 = x0 > 0.0
x1 = x1 < (sz[1]-1)
y0 = y0 > 0.0
y1 = y1 < (sz[2]-1)
nx = x1 - x0 + 1
ny = y1 - y0 + 1


; trim the image, translate coords
img = main_image[x0:x1,y0:y1]
xcen = x - x0
ycen = y - y0

; for debugging, can make some masks showing different regions
skyimg = fltarr(nx,ny)			; don't use /nozero!!
photimg = fltarr(nx,ny)			; don't use /nozero!!

; makes an array of (distance)^2 from center of aperture
;   where distance is the radial or the semi-major axis distance.
;   based on DIST_CIRCLE and DIST_ELLIPSE in Goddard IDL package,
;   but deals with rectangular image sections
distsq = fltarr(nx,ny,/nozero)

xx = findgen(nx)
yy = findgen(ny)
x2 = (xx - xcen)^(2.0)
y2 = (yy - ycen)^(2.0)
for i = 0L,(ny-1) do $          ; row loop
  distsq[*,i] = x2 + y2(i)

; get sky level by masking and then medianing remaining pixels
; note use of "gt" to avoid picking same pixels as flux aperture
ns = 0
msky = 0.0
errsky = 0.0

in2 = insky^(2.0)
out2 = outsky^(2.0)
if (in2 LT max(distsq)) then begin
    w = where((distsq gt in2) and (distsq le out2),ns)
    skyann = img[w] 
endif else begin
    w = where(distsq EQ distsq)
    skyann = img[w]
    state.photwarning = 'Not enough pixels in sky!'
endelse

msky = median(skyann)
errsky = stddev(skyann)
skyimg[w] = -5.0
photimg = skyimg

errsky2 = errsky * errsky

out[*,8] = msky
out[*,9] = ns
out[*,10]= errsky

; now loop through photometry radii, finding the total flux, differential
;	flux, and differential average pixel value along with 1 sigma scatter
; 	relies on the fact the output array is full of zeroes
for i = 0,nrad-1 do begin
    
    dr = drad
    if i eq 0 then begin
        rin =  0.0
        rout = inrad
        rin2 = -0.01
    endif else begin
        rin = inrad + drad *(i-1)	
        rout = (rin + drad) < outrad
        rin2 = rin*rin
    endelse
    rout2 = rout*rout
    
; 	get flux and pixel stats in annulus, wary of counting pixels twice
;	checking if necessary if there are pixels in the sector
    w = where(distsq gt rin2 and distsq le rout2,np)
    
    pfrac = 1.0                 ; fraction of pixels in each annulus used
    
    if np gt 0 then begin
        ann = img[w]
        dflux = total(ann) * 1./pfrac
        dnpix = np
        dnet = dflux - (dnpix * msky) * 1./pfrac
        davg = dnet / (dnpix * 1./pfrac)
        if np gt 1 then dsig = stddev(ann) else dsig = 0.00
        
;		std dev in each annulus including sky sub error
        derr = sqrt(dsig*dsig + errsky2)
        
        photimg[w] = rout2

;-------------------------------------------------------PH 29 Aug. 2005
; Added check that "out" values are finite (IE. not "NaN")

;        out[i,0] = (rout+rin)/2.0
;        out[i,1] = out[i-1>0,1] + dflux
;        out[i,2] = out[i-1>0,2] + dnet
;        out[i,3] = out[i-1>0,3] + dnpix
;        out[i,4] = dflux
;        out[i,5] = dnpix
;        out[i,6] = davg
;        out[i,7] = dsig
;        out[i,11] = derr
;    endif else if (i ne 0) then begin
;        out[i,0]= rout
;        out[i,1:3] = out[i-1,1:3]
;        out[i, 4:7] = 0.0
;        out[i,11] = 0.0
;    endif else begin
;        out[i, 0] = rout
;    endelse
        
        if finite((rout+rin)/2.0)       then out[i,0]  = (rout+rin)/2.0
        if finite(out[i-1>0,1] + dflux) then out[i,1]  = out[i-1>0,1] + dflux
        if finite(out[i-1>0,2] + dnet)  then out[i,2]  = out[i-1>0,2] + dnet
        if finite(out[i-1>0,3] + dnpix) then out[i,3]  = out[i-1>0,3] + dnpix
        if finite(dflux)                then out[i,4]  = dflux
        if finite(dnpix)                then out[i,5]  = dnpix
        if finite(davg)                 then out[i,6]  = davg
        if finite(dsig)                 then out[i,7]  = dsig
        if finite(derr)                 then out[i,11] = derr
    endif else if (i ne 0) then begin
        if finite(rout)         then out[i,0]   = rout
        if finite(out[i-1,1:3]) then out[i,1:3] = out[i-1,1:3]
        out[i, 4:7] = 0.0
        out[i,11]   = 0.0
    endif else begin
        if finite(rout) then out[i, 0] = rout
    endelse

;-------------------------------------------------------PH 29 Aug. 2005
  
endfor

; fill radpts array after done with differential photometry
w = where(distsq ge 0.0 and distsq le outrad*outrad)
radpts = dblarr(2,n_elements(w))
radpts[0,*] = sqrt(distsq[w])
radpts[1,*] = img[w]

; compute FWHM via spline interpolation of radial profile
fwhm = smtv_splinefwhm(out[*,0],out[*,6])

; plot the results

if n_elements(radpts(1, *)) gt 100 then pp = 3 else pp = 1

if (not (keyword_set(ps))) then begin

  plot, radpts(0, *), radpts(1, *), /nodata, xtitle = 'Radius (pixels)', $
    ytitle = 'Counts', color=7, charsize=1.2, /ynozero
  oplot, radpts(0, *), radpts(1, *), psym = pp, color=6
  oploterror, out(*, 0), out(*, 6)+out(*, 8), $
    out(*, 11)/sqrt(out(*, 5)), psym=-4, color=7, errcolor=7

endif else begin

  plot, radpts(0, *), radpts(1, *), /nodata, xtitle = 'Radius (pixels)', $
    ytitle = 'Counts', color=0, charsize=1.2, /ynozero
;  oplot, radpts(0, *), radpts(1, *), psym = pp, color=0
  oploterror, out(*, 0), out(*, 6)+out(*, 8), $
    out(*, 11)/sqrt(out(*, 5)), psym=-4, color=0, errcolor=0

endelse

end

;-----------------------------------------------------------------------

pro smtv_apphot_refresh, ps=ps

; Do aperture photometry using idlastro daophot routines.

common smtv_state
common smtv_images

state.photwarning = 'Warnings: None.'

; Center on the object position nearest to the cursor
if (state.centerboxsize GT 0) then begin
    smtv_imcenterf, x, y
endif else begin   ; no centering
    x = state.cursorpos[0]
    y = state.cursorpos[1]
endelse

; Make sure that object position is on the image
x = 0 > x < (state.image_size[0] - 1)
y = 0 > y < (state.image_size[1] - 1)

if ((x - state.outersky) LT 0) OR $
  ((x + state.outersky) GT (state.image_size[0] - 1)) OR $
  ((y - state.outersky) LT 0) OR $
  ((y + state.outersky) GT (state.image_size[1] - 1)) then $
  state.photwarning = 'Warning: Sky apertures fall outside image!'

; Condition to test whether phot aperture is off the image
if (x LT state.r) OR $
  ((state.image_size[0] - x) LT state.r) OR $
  (y LT state.r) OR $
  ((state.image_size[1] - y) LT state.r) then begin
    flux = -1.
    state.photwarning = 'Warning: Aperture Outside Image Border!'
endif
    
phpadu = 1.0                    ; don't convert counts to electrons
apr = [state.r]
skyrad = [state.innersky, state.outersky]
; Assume that all pixel values are good data
badpix = [state.image_min-1, state.image_max+1]  

if (state.skytype EQ 1) then begin    ; calculate median sky value

    xmin = (x - state.outersky) > 0
    xmax = (xmin + (2 * state.outersky + 1)) < (state.image_size[0] - 1)
    ymin = (y - state.outersky) > 0
    ymax = (ymin + (2 * state.outersky + 1)) < (state.image_size[1] - 1)
    
    small_image = main_image[xmin:xmax, ymin:ymax]
    nx = (size(small_image))[1]
    ny = (size(small_image))[2]
    i = lindgen(nx)#(lonarr(ny)+1)
    j = (lonarr(nx)+1)#lindgen(ny)
    xc = x - xmin
    yc = y - ymin
    
    w = where( (((i - xc)^2 + (j - yc)^2) GE state.innersky^2) AND $
               (((i - xc)^2 + (j - yc)^2) LE state.outersky^2),  nw)
    
    if ((x - state.outersky) LT 0) OR $
      ((x + state.outersky) GT (state.image_size[0] - 1)) OR $
      ((y - state.outersky) LT 0) OR $
      ((y + state.outersky) GT (state.image_size[1] - 1)) then $
      state.photwarning = 'Warning: Sky apertures fall outside image!'
    
    if (nw GT 0) then  begin
        skyval = median(small_image(w)) 
    endif else begin
        skyval = -1
        state.photwarning = 'Warning: No pixels in sky!'
    endelse
endif

; Do the photometry now
case state.skytype of
    0: aper, main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
      skyrad, badpix, flux=abs(state.magunits-1), /silent
    1: aper, main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
      skyrad, badpix, flux=abs(state.magunits-1), /silent, $
      setskyval = skyval
    2: aper, main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
      skyrad, badpix, flux=abs(state.magunits-1), /silent, $
      setskyval = 0
endcase

flux = flux[0]
sky = sky[0]

if (flux EQ 99.999) then begin
    state.photwarning = 'Warning: Error in computing flux!'
    flux = -1.0
endif

if (state.magunits EQ 1) then begin    ; apply zeropoint
    flux = flux + state.photzpt - 25.0
endif

; Run smtv_radplotf and plot the results

if (not (keyword_set(ps))) then begin
  smtv_setwindow, state.radplot_window_id
  smtv_radplotf, x, y, fwhm
endif else begin
  smtv_radplotf, x, y, fwhm, /ps
endelse

; overplot the phot apertures on radial plot
if (not (keyword_set(ps))) then begin

plots, [state.r, state.r], !y.crange, line = 1, color=2, thick=2, psym=0
xyouts, /data, state.r, !y.crange(1)*0.92, ' aprad', $
  color=2, charsize=1.5
if (state.skytype NE 2) then begin
    plots, [state.innersky,state.innersky], !y.crange, $
      line = 1, color=4, thick=2, psym=0
    xyouts, /data, state.innersky, !y.crange(1)*0.85, ' insky', $
      color=4, charsize=1.5
    plots, [state.outersky,state.outersky], !y.crange, $
      line = 1, color=5, thick=2, psym=0
    xyouts, /data, state.outersky * 0.82, !y.crange(1)*0.75, ' outsky', $
      color=5, charsize=1.5
endif
plots, !x.crange, [sky, sky], color=1, thick=2, psym=0, line = 2
xyouts, /data, state.innersky + (0.1*(state.outersky-state.innersky)), $
  sky+0.06*(!y.crange[1] - sky), 'sky level', color=1, charsize=1.5

smtv_resetwindow

endif else begin

plots, [state.r, state.r], !y.crange, line = 1, color=0, thick=2, psym=0
xyouts, /data, state.r, !y.crange(1)*0.92, ' aprad', $
  color=0, charsize=1.5
if (state.skytype NE 2) then begin
    plots, [state.innersky,state.innersky], !y.crange, $
      line = 1, color=0, thick=2, psym=0
    xyouts, /data, state.innersky, !y.crange(1)*0.85, ' insky', $
      color=0, charsize=1.5
    plots, [state.outersky,state.outersky], !y.crange, $
      line = 1, color=0, thick=2, psym=0
    xyouts, /data, state.outersky * 0.82, !y.crange(1)*0.75, ' outsky', $
      color=0, charsize=1.5
endif
plots, !x.crange, [sky, sky], color=1, thick=2, psym=0, line = 2
xyouts, /data, state.innersky + (0.1*(state.outersky-state.innersky)), $
  sky+0.06*(!y.crange[1] - sky), 'sky level', color=1, charsize=1.5

endelse

; output the results

case state.magunits of
    0: fluxstr = 'Object counts: '
    1: fluxstr = 'Magnitude: '
endcase
  
state.centerpos = [x, y]

tmp_string = string(state.cursorpos[0], state.cursorpos[1], $
                    format = '("Cursor position:  x=",i4,"  y=",i4)' )
tmp_string1 = string(state.centerpos[0], state.centerpos[1], $
                    format = '("Object centroid:  x=",f6.1,"  y=",f6.1)' )
tmp_string2 = strcompress(fluxstr+string(flux, format = '(g12.6)' ))
tmp_string3 = string(sky, format = '("Sky level: ",g12.6)' )
tmp_string4 = string(fwhm, format='("FWHM (pix): ",g7.3)' )

widget_control, state.centerbox_id, set_value = state.centerboxsize
widget_control, state.cursorpos_id, set_value = tmp_string
widget_control, state.centerpos_id, set_value = tmp_string1
widget_control, state.radius_id, set_value = state.r 
widget_control, state.outersky_id, set_value = state.outersky
widget_control, state.innersky_id, set_value = state.innersky
widget_control, state.skyresult_id, set_value = tmp_string3
widget_control, state.photresult_id, set_value = tmp_string2
widget_control, state.fwhm_id, set_value = tmp_string4
widget_control, state.photwarning_id, set_value=state.photwarning

; Uncomment next lines if you want smtv to output the WCS coords of 
; the centroid for the photometry object:
;if (state.wcstype EQ 'angle') then begin
;    xy2ad, state.centerpos[0], state.centerpos[1], *(state.astr_ptr), $
;      clon, clat
;    wcsstring = smtv_wcsstring(clon, clat, (*state.astr_ptr).ctype,  $
;                state.equinox, state.display_coord_sys, state.display_equinox)
;    print, 'Centroid WCS coords: ', wcsstring
;endif

if (not (keyword_set(ps))) then $
  smtv_tvphot

smtv_resetwindow
end

;----------------------------------------------------------------------

pro smtv_tvphot

; Routine to display the zoomed region around a photometry point,
; with circles showing the photometric apterture and sky radii.

common smtv_state
common smtv_images

smtv_setwindow, state.photzoom_window_id
erase

x = round(state.centerpos[0])
y = round(state.centerpos[1])

boxsize = round(state.outersky * 1.2)
xsize = (2 * boxsize) + 1
ysize = (2 * boxsize) + 1
image = bytarr(xsize,ysize)

xmin = (0 > (x - boxsize))
xmax = ((x + boxsize) < (state.image_size[0] - 1) )
ymin = (0 > (y - boxsize) )
ymax = ((y + boxsize) < (state.image_size[1] - 1))

startx = abs( (x - boxsize) < 0 )
starty = abs( (y - boxsize) < 0 ) 

image[startx, starty] = scaled_image[xmin:xmax, ymin:ymax]

xs = indgen(xsize) + xmin - startx
ys = indgen(ysize) + ymin - starty

xs_delta = (xs[xsize-1] - xs[0]) / float(xsize - 1.0)
ys_delta = (ys[ysize-1] - ys[0]) / float(ysize - 1.0)
x_ran = [xs[0]-xs_delta/2.0,xs[xsize-1]+xs_delta/2.0]
y_ran = [ys[0]-ys_delta/2.0,ys[ysize-1]+ys_delta/2.0]

dev_width = 0.8 * state.photzoom_size
dev_pos = [0.15 * state.photzoom_size, $
           0.15 * state.photzoom_size, $
           0.95 * state.photzoom_size, $
           0.95 * state.photzoom_size]

x_factor = dev_width / xsize
y_factor = dev_width / ysize
x_offset = (x_factor - 1.0) / x_factor / 2.0
y_offset = (y_factor - 1.0) / y_factor / 2.0
xi = findgen(dev_width) / x_factor - x_offset ;x interp index
yi = findgen(dev_width) / y_factor - y_offset ;y interp index

image = Poly_2D(image, [[0,0],[1.0/x_factor,0]], $
             [[0,1.0/y_factor],[0,0]], $
             0, dev_width, dev_width)

xsize = (size(image))[1]
ysize = (size(image))[2]
out_xs = xi * xs_delta + xs[0]
out_ys = yi * ys_delta + ys[0]

sz = size(image)
xsize = Float(sz[1])       ;image width
ysize = Float(sz[2])       ;image height
dev_width = dev_pos[2] - dev_pos[0] + 1
dev_width = dev_pos[3] - dev_pos[1] + 1

tv, image, /device, dev_pos[0], dev_pos[1], $
  xsize=dev_pos[2]-dev_pos[0], $
  ysize=dev_pos[3]-dev_pos[1]

plot, [0, 1], /noerase, /nodata, xstyle = 1, ystyle = 1, $
  /device, position = dev_pos, color=7, $
  xrange = x_ran, yrange = y_ran

tvcircle, /data, state.r, state.centerpos[0], state.centerpos[1], $
  color=2, thick=2, psym=0
if (state.skytype NE 2) then begin
    tvcircle, /data, state.innersky, state.centerpos[0], state.centerpos[1], $
      color=4, thick=2, psym=0
    tvcircle, /data, state.outersky, state.centerpos[0], state.centerpos[1], $
      color=5, thick=2, psym=0
endif

smtv_resetwindow
end

;----------------------------------------------------------------------

pro smtv_apphot_event, event

common smtv_state
common smtv_images

widget_control, event.id, get_uvalue = uvalue

case uvalue of

    'centerbox': begin
        if (event.value EQ 0) then begin
            state.centerboxsize = 0
        endif else begin
            state.centerboxsize = long(event.value) > 3
            if ( (state.centerboxsize / 2 ) EQ $
                 round(state.centerboxsize / 2.)) then $
              state.centerboxsize = state.centerboxsize + 1
        endelse
        smtv_apphot_refresh
    end
        
    'radius': begin
        state.r = 1 > long(event.value) < state.innersky
        smtv_apphot_refresh
    end

    'innersky': begin
        state.innersky = state.r > long(event.value) < (state.outersky - 1)
        state.innersky = 2 > state.innersky
        if (state.outersky EQ state.innersky + 1) then $
          state.outersky = state.outersky + 1
        smtv_apphot_refresh
    end

    'outersky': begin
        state.outersky = long(event.value) > (state.innersky + 2)
        smtv_apphot_refresh
    end

    'showradplot': begin
        widget_control, state.showradplot_id, get_value=val
        case val of
            'Show Radial Profile': begin
                ysize = 350 < (state.screen_ysize - 350)
                widget_control, state.radplot_widget_id, $
                  xsize=500, ysize=ysize
                widget_control, state.showradplot_id, $
                  set_value='Hide Radial Profile'
            end
            'Hide Radial Profile': begin
                widget_control, state.radplot_widget_id, $
                  xsize=1, ysize=1
                widget_control, state.showradplot_id, $
                  set_value='Show Radial Profile'
             end
         endcase
         smtv_apphot_refresh
    end

    'magunits': begin
        state.magunits = event.value
        smtv_apphot_refresh
    end

    'photsettings': smtv_apphot_settings

    'radplot_stats_save': begin
        radplot_stats_outfile = dialog_pickfile(filter='*.txt', $
                        file='smtv_phot.txt', get_path = tmp_dir, $
                        title='Please Select File to Append Photometry Stats')

        IF (strcompress(radplot_stats_outfile, /remove_all) EQ '') then RETURN

        IF (radplot_stats_outfile EQ tmp_dir) then BEGIN
          smtv_message, 'Must indicate filename to save.', $
                       msgtype = 'error', /window
          return
        ENDIF

        openw, lun, radplot_stats_outfile, /get_lun, /append

        widget_control, state.cursorpos_id, get_value = cursorpos_str
        widget_control, state.centerbox_id, get_value = centerbox_str
        widget_control, state.centerpos_id, get_value = centerpos_str
        widget_control, state.radius_id, get_value = radius_str
        widget_control, state.innersky_id, get_value = innersky_str
        widget_control, state.outersky_id, get_value = outersky_str
        widget_control, state.fwhm_id ,get_value = fwhm_str
        widget_control, state.skyresult_id, get_value = skyresult_str
        widget_control, state.photresult_id, get_value = objectcounts_str

        printf, lun, 'SMTV PHOTOMETRY RESULTS--NOTE: IDL Arrays Begin With Index 0'
        printf, lun, '============================================================='
        if (state.image_size[2] gt 1) then printf, lun, 'Image Plane: ' + $
                     strcompress(string(state.cur_image_num),/remove_all)
        printf, lun, strcompress(cursorpos_str)
        printf, lun, 'Centering box size (pix): ' + $
                      strcompress(string(centerbox_str),/remove_all)
        printf, lun, strcompress(centerpos_str)
        printf, lun, 'Aperture radius: ' + $
                     strcompress(string(radius_str), /remove_all)
        printf, lun, 'Inner sky radius: ' + $
                     strcompress(string(innersky_str), /remove_all)
        printf, lun, 'Outer sky radius: ' + $
                     strcompress(string(outersky_str), /remove_all)
        printf, lun, strcompress(fwhm_str)
        printf, lun, strcompress(skyresult_str)
        printf, lun, objectcounts_str
        printf, lun, ''

        close, lun
        free_lun, lun
    end

    'apphot_ps': begin

        fname = strcompress(state.current_dir + 'smtv_phot.ps', /remove_all)
        forminfo = cmps_form(cancel = canceled, create = create, $
                     /preserve_aspect, $
                     /color, $
                     /nocommon, papersize='Letter', $
                     filename = fname, $
                     button_names = ['Create PS File'])

        if (canceled) then return
        if (forminfo.filename EQ '') then return

        tmp_result = findfile(forminfo.filename, count = nfiles)

        result = ''
        if (nfiles GT 0) then begin
          mesg = strarr(2)
          mesg[0] = 'Overwrite existing file:'
          tmp_string = strmid(forminfo.filename, strpos(forminfo.filename, $
                              '/') + 1)
          mesg[1] = strcompress(tmp_string + '?', /remove_all)
          result =  dialog_message(mesg, $
                             /default_no, $
                             dialog_parent = state.base_id, $
                             /question)                 
        endif

        if (strupcase(result) EQ 'NO') then return
    
        widget_control, /hourglass

        screen_device = !d.name

        set_plot, 'ps'
        device, _extra = forminfo

        smtv_apphot_refresh, /ps

        device, /close
        set_plot, screen_device

    end

    'apphot_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------

pro smtv_apphot_settings

; Routine to get user input on various photometry settings

common smtv_state

skyline = strcompress('0, button, IDLPhot Sky|Median Sky|No Sky Subtraction,'+$
                      'exclusive,' + $
                      'label_left=Select Sky Algorithm: , set_value = ' + $
                      string(state.skytype))

magline = strcompress('0, button, Counts|Magnitudes, exclusive,' + $
                      'label_left = Select Output Units: , set_value =' + $
                      string(state.magunits))

zptline = strcompress('0, float,'+string(state.photzpt) + $
                      ',label_left = Magnitude Zeropoint:,' + $
                      'width = 12')

formdesc = [skyline, $
            magline, $
            zptline, $
            '0, label, [Magnitude = zeropoint - 2.5 log (counts)]', $
            '0, button, Apply Settings, quit', $
            '0, button, Cancel, quit']

textform = cw_form(formdesc, /column, $
                   title = 'smtv photometry settings')

if (textform.tag5 EQ 1) then return ; cancelled

state.skytype = textform.tag0
state.magunits = textform.tag1
state.photzpt = textform.tag2

smtv_apphot_refresh

end

;----------------------------------------------------------------------

pro smtv_apphot

; aperture photometry front end

common smtv_state

state.cursorpos = state.coord

if (not (xregistered('smtv_apphot', /noshow))) then begin

    apphot_base = $
      widget_base(/base_align_center, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'smtv aperture photometry', $
                  uvalue = 'apphot_base')
    
    apphot_top_base = widget_base(apphot_base, /row, /base_align_center)

    apphot_data_base1 = widget_base( $
            apphot_top_base, /column, frame=0)

    apphot_data_base2 = widget_base( $
            apphot_top_base, /column, frame=0)

    apphot_draw_base = widget_base( $
            apphot_base, /row, /base_align_center, frame=0)

    apphot_data_base1a = widget_base(apphot_data_base1, /column, frame=1)
    tmp_string = $
      string(1000, 1000, $
             format = '("Cursor position:  x=",i4,"  y=",i4)' )

    state.cursorpos_id = $
      widget_label(apphot_data_base1a, $
                   value = tmp_string, $
                   uvalue = 'cursorpos', /align_left)

    state.centerbox_id = $
      cw_field(apphot_data_base1a, $
               /long, $
               /return_events, $
               title = 'Centering box size (pix):', $
               uvalue = 'centerbox', $
               value = state.centerboxsize, $
               xsize = 5)
    
    tmp_string1 = $
      string(99999.0, 99999.0, $
             format = '("Object centroid:  x=",f7.1,"  y=",f7.1)' )
    
    state.centerpos_id = $
      widget_label(apphot_data_base1a, $
                   value = tmp_string1, $
                   uvalue = 'centerpos', /align_left)

    state.radius_id = $
      cw_field(apphot_data_base1a, $
               /long, $
               /return_events, $
               title = 'Aperture radius:', $
               uvalue = 'radius', $
               value = state.r, $
               xsize = 5)
    
    state.innersky_id = $
      cw_field(apphot_data_base1a, $
               /long, $
               /return_events, $
               title = 'Inner sky radius:', $
               uvalue = 'innersky', $
               value = state.innersky, $
               xsize = 5)
    
    state.outersky_id = $
      cw_field(apphot_data_base1a, $
               /long, $
               /return_events, $
               title = 'Outer sky radius:', $
               uvalue = 'outersky', $
               value = state.outersky, $
               xsize = 5)
    
    photzoom_widget_id = widget_draw( $
         apphot_data_base2, $
         scr_xsize=state.photzoom_size, scr_ysize=state.photzoom_size)

    tmp_string4 = string(0.0, format='("FWHM (pix): ",g7.3)' )
    state.fwhm_id = widget_label(apphot_data_base2, $
                                 value=tmp_string4, $
                                 uvalue='fwhm')

    tmp_string3 = string(10000000.00, $
                         format = '("Sky level: ",g12.6)' )
    
    state.skyresult_id = $
      widget_label(apphot_data_base2, $
                   value = tmp_string3, $
                   uvalue = 'skyresult')
    
    tmp_string2 = string(1000000000.00, $
                         format = '("Object counts: ",g12.6)' )
    
    state.photresult_id = $
      widget_label(apphot_data_base2, $
                   value = tmp_string2, $
                   uvalue = 'photresult', $
                   /frame)

    state.photwarning_id = $
      widget_label(apphot_data_base1, $
                   value='-------------------------', $
                   /dynamic_resize, $
                   frame=1)

    photsettings_id = $
      widget_button(apphot_data_base1, $
                    value = 'Photometry Settings...', $
                    uvalue = 'photsettings')

    radplot_log_save = $
      widget_button(apphot_data_base1, $
                    value = 'Save Photometry Stats', $
                    uvalue = 'radplot_stats_save')

    state.showradplot_id = $
      widget_button(apphot_data_base1, $
                    value = 'Hide Radial Profile', $
                    uvalue = 'showradplot')
    
    state.radplot_widget_id = widget_draw( $
         apphot_draw_base, scr_xsize=500, $
           scr_ysize=(350 < (state.screen_ysize - 350)))

    apphot_ps = $
      widget_button(apphot_data_base2, $
                    value = 'Create Profile PS', $
                    uvalue = 'apphot_ps')

    apphot_done = $
      widget_button(apphot_data_base2, $
                    value = 'Done', $
                    uvalue = 'apphot_done')

    widget_control, apphot_base, /realize

    widget_control, photzoom_widget_id, get_value=tmp_value
    state.photzoom_window_id = tmp_value
    widget_control, state.radplot_widget_id, get_value=tmp_value
    state.radplot_window_id = tmp_value

    xmanager, 'smtv_apphot', apphot_base, /no_block
    
    smtv_resetwindow
endif

smtv_apphot_refresh

end

;--------------------------------------------------------------------
;    smtv main program.  needs to be last in order to compile.
;---------------------------------------------------------------------

; Main program routine for SMTV.  If there is no current SMTV session,
; then run smtv_startup to create the widgets.  If SMTV already exists,
; then display the new image to the current SMTV window.

pro smtv, image, $
         min = minimum, $
         max = maximum, $
         autoscale = autoscale,  $
         linear = linear, $
         log = log, $
         histeq = histeq, $
         block = block, $
         align = align, $
         stretch = stretch, $
         header = header, $
         imname = imname, $
         smart = smart, $
         bmask = bmask

common smtv_state
common smtv_images

if (not(keyword_set(block))) then block = 0 else block = 1

newimage = 0

if ( (n_params() EQ 0) AND (xregistered('smtv', /noshow))) then begin
    print, 'USAGE: smtv, array_name OR fitsfile'
    print, '         [,min = min_value] [,max=max_value] '
    print, '         [,/linear] [,/log] [,/histeq] [,/block]'
    print, '         [,/align] [,/stretch] [,header=header]'
    return
endif

if (!d.name NE 'X' AND !d.name NE 'WIN' AND !d.name NE 'MAC') then begin
    print, 'Graphics device must be set to X, WIN, or MAC for SMTV to work.'
    retall
endif

; Before starting up smtv, get the user's external window id.  We can't
; use the smtv_getwindow routine yet because we haven't run smtv
; startup.  A subtle issue: smtv_resetwindow won't work the first time
; through because xmanager doesn't get called until the end of this
; routine.  So we have to deal with the external window explicitly in
; this routine.
if (not (xregistered('smtv', /noshow))) then begin
   userwindow = !d.window
   smtv_startup
   align = 0B     ; align, stretch keywords make no sense if we are
   stretch = 0B   ; just starting up. 
endif

;change
IF KEYWORD_SET(smart) THEN state.smart=1
if keyword_set(bmask) then begin
   state.bmask=1
   if ((size(bmask))[0]) lt 2 then bmask = fltarr((size(image))[1],(size(image))[2])
endif else begin
   if ((size(image))[0]) eq 2 then bmask = fltarr((size(image))[1],(size(image))[2])
   if ((size(image))[0]) eq 3 then bmask = fltarr((size(image))[1],(size(image))[2],(size(image))[2])
endelse
; If image is a filename, read in the file
if ( (n_params() NE 0) AND (size(image, /tname) EQ 'STRING')) then begin
    ifexists = findfile(image, count=count)
    if (count EQ 0) then begin
        print, 'ERROR: File not found!'
    endif else begin
        smtv_readfits, fitsfilename=image, newimage=newimage
    endelse
endif

; Check for existence of array
if ( (n_params() NE 0) AND (size(image, /tname) NE 'STRING') AND $
   (size(image, /tname) EQ 'UNDEFINED')) then begin
    print, 'ERROR: Data array does not exist!'
endif

; If user has passed smtv a data array, read it into main_image.
if ( (n_params() NE 0) AND (size(image, /tname) NE 'STRING') AND $
   (size(image, /tname) NE 'UNDEFINED')) then begin
; Make sure it's a 2-d or 3-d array
    if ( (size(image))[0] NE 2 AND (size(image))[0] NE 3) then begin
        print, 'ERROR: Input data must be a 2-d or 3-d array!'    
    endif else begin
        if (size(image))[0] EQ 2 THEN begin
            main_image = image
            bmask_image = bmask
            newimage = 1
            state.image_size = [(size(main_image_stack))[1:2], 1]
            if keyword_set(imname) then state.imagename = imname $
              else state.imagename=''
            state.title_extras = ''
;<<<<<<< smtv_jb.pro
            if keyword_set(header) then begin
               if size(header[0],/type) ne 10 then smtv_setheader, header else $
                 smtv_setheader, *header[0]
            endif else begin
               mkhdr,header,image
               smtv_setheader,header
            endelse
;            
;            widget_control, state.curimnum_base_id,map=0,xsize=1,ysize=1
;=======
;            smtv_setheader, *header[0]

            widget_control, state.curimnum_base_id,map=0,xsize=1,ysize=1
;>>>>>>> smtv_ks.pro

;            widget_control, state.curimnum_text_id, sensitive = 0, $
;                     set_value = 0
;            widget_control, state.curimnum_slidebar_id, sensitive = 0, $
;                     set_value = 0, set_slider_min = 0, set_slider_max = 0



        endif else begin ; case of 3-d stack of images [x,y,n]
            main_image_stack = image
            bmask_image_stack = bmask
            main_image = main_image_stack[*, *, 0]
            bmask_image = bmask_image_stack[*,*,0]
            state.image_size = (size(main_image_stack))[1:3]
            state.cur_image_num = 0
            newimage = 1
;<<<<<<< smtv_jb.pro
;            state.imagename = ''
;            state.title_extras = $
;              strcompress('Plane ' + string(state.cur_image_num))
;=======
            if keyword_set(imname) then begin
               names_stack = imname
               state.imagename = imname[0]
            endif else begin
               state.imagename=''
               names_stack=strarr(n_elements(image[0,0,*]))
            endelse
            if (keyword_set(header)) then begin
               header_stack = header
               header=(*header[0])
            endif else begin
               for i = 0, (size(image))[3] - 1 do begin
                  mkhdr,hdr,image[*,*,i]
                  if i eq 0 then outhead=ptr_new(hdr) else $
                    outhead = [outhead,ptr_new(hdr)]
                  header_stack = outhead
                  header = (*outhead[0])
               endfor
            endelse

            state.title_extras = ''
;>>>>>>> smtv_ks.pro
            smtv_setheader, header

            widget_control,state.curimnum_base_id,map=1, $
              xsize=state.draw_window_size[0],ysize=45

            widget_control, state.curimnum_text_id, sensitive = 1, $
                     set_value = 0
            widget_control, state.curimnum_slidebar_id, sensitive = 1, $
                     set_value = 0, set_slider_min = 0, $
                     set_slider_max = state.image_size[2]-1
        endelse
          ;Reset image rotation angle to 0 and inversion to none
           state.rot_angle = 0.
           state.invert_image = 'none'
    endelse
endif

; improvements as of v1.4:
widget_control, state.base_id, tlb_get_size=tmp_event
state.base_pad = tmp_event - state.draw_window_size


;   Define default startup image 
if (n_elements(main_image) LE 1) then begin
    main_image = cos(((findgen(500)- 250)*2) # ((findgen(500)-250)))
    imagename = ''
    newimage = 1
    mkhdr,hdr,main_image
    smtv_setheader, hdr
endif


if (newimage EQ 1) then begin  
; skip this part if new image is invalid or if user selected 'cancel'
; in dialog box
    smtv_settitle
    smtv_getstats, align=align
    
    delvarx, display_image

    if n_elements(minimum) GT 0 then begin
        state.min_value = minimum
    endif
    
    if n_elements(maximum) GT 0 then begin 
        state.max_value = maximum
    endif
    
    if state.min_value GE state.max_value then begin
        state.min_value = state.max_value - 1.
    endif
    
    if (keyword_set(linear)) then state.scaling = 0
    if (keyword_set(log))    then state.scaling = 1
    if (keyword_set(histeq)) then state.scaling = 2
    
; Only perform autoscale if current stretch invalid or stretch keyword
; not set
    IF (state.min_value EQ state.max_value) OR $
      (keyword_set(stretch) EQ 0) THEN BEGIN 

       if (keyword_set(autoscale) OR $
           ((state.default_autoscale EQ 1) AND (n_elements(minimum) EQ 0) $
            AND (n_elements(maximum) EQ 0)) ) $
         then smtv_autoscale
    ENDIF 
    smtv_set_minmax
    
    IF NOT keyword_set(align) THEN BEGIN 
       state.zoom_level = 2
       state.zoom_factor = 2.^state.zoom_level
    ENDIF 

    smtv_displayall
    
    smtv_resetwindow
;    if (state.image_size[0]*2 le state.draw_window_size[0]) AND $
;           (state.image_size[1]*2 le state.draw_window_size[1]) then $
;           for tempvar = 1, $
;           floor(sqrt(min(state.draw_window_size/state.image_size[0:1]))) do $
;           smtv_zoom, 'in'
;    if (state.image_size[0] le state.draw_window_size[0]*2) AND $
;           (state.image_size[1] le state.draw_window_size[1]*2) then $
;           for tempvar = 1, $
;           floor(sqrt(min(state.image_size[0:1]/state.draw_window_size))) do $
;           smtv_zoom, 'out'
endif

; Register the widget with xmanager if it's not already registered
if (not(xregistered('smtv', /noshow))) then begin
    nb = abs(block - 1)
    xmanager, 'smtv', state.base_id, no_block = nb, cleanup = 'smtv_shutdown'
    wset, userwindow
    ; if blocking mode is set, then when the procedure reaches this
    ; line smtv has already been terminated.  If non-blocking, then
    ; the procedure continues below.  If blocking, then the state
    ; structure doesn't exist any more so don't set active window.
    if (block EQ 0) then state.active_window_id = userwindow
endif

end
