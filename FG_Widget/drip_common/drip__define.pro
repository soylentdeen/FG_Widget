; NAME:
;     DRIP - Version .8.0
;
; PURPOSE:
;     Data Reduction Interactive Pipeline
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP', FILELIST)
;     Structure=Obj->RUN(FILELIST)
;
; INPUTS:
;     FILELIST - Filename(s) of the fits file(s) containing data to be reduced.
;                May be a string array
;
; STRUCTURE:
;     {mode, n, readme, set                                              - settings
;      path, filename, header, basehead                                  - file info
;      data, cleaned, badflags, linearized, flatted, merged, undistorted - pipe steps
;      coadded, lastcoadd                                                - final products
;      badmap, linear_coeffs, flats, cleanedflats, masterflat}           - calibration
;
; OUTPUTS:
;     IDL output: full data structure(s).
;
;     FITS output: final coadded result or individual step results
;
; CALLED ROUTINES AND OBJECTS:
;     SXPAR
;     SXADDPAR
;     FITS_READ
;     READFITS
;     FITS_WRITE
;
; SIDE EFFECTS:
;     None identified
;
; RESTRICTIONS:
;     Data (FITS) file or dripconfig.txt file must specify locations
;     of bad pixel map, dark frames, and flat fields.
;
; PROCEDURE:
;     Upon initialization get mode. For each file check if the mode is
;     correct and reduce the file. All files are coadded. Run returns
;     the data structure.
;     Save saves _reduced.fits files with additional data reduction keywords
;
; MODIFICATION HISTORY:
;     Written by:  Alfred Lee, Cornell University, June, 2002
;     Modified:   Alfred Lee, CU, June 18, 2002
;                 added two keywords for TPCON and TPCOFF.  Made both routines
;                 functional
;     Modified:   Alfred Lee, CU, June 21, 2002
;                 adjusted code for new TPC class.
;     Modified:   Alfred Lee, CU, June 24, 2002
;                 adjusted code for changes in TPC.  Allowed for multiple file
;                 input.
;     Modified:   Alfred Lee, CU, June 25, 2002
;                 DRIP now saves a fits file containing the averaged
;                 sum of the final images from every inputted file.
;                 added PRINT statements.
;     Modified:   Alfred Lee, CU, June 27, 2002
;                 Added a NO_SAVE keyword to skip saving, which takes
;                 much time.
;     Modified:   Alfred Lee, CU, July 11, 2002
;                 Converted into an Object to be used with DRIP_GUI.
;     Modified:   Alfred Lee, CU, September 27, 2002
;                 Refined for use with GUI.  Uses fewer assumed parameters,
;                 and checks for more.
;     Modified:   Alfred Lee, CU, October 8, 2002
;                 Fixed GETDATA to be more functional.
;     Modified:   Alfred Lee, CU, January 30, 2003
;                 updated save routine
;     Rewritten:  Marc Berthoud, CU, June 2004
;                 Merged former drip(4.2), tpc(5.1) and dataman(3)
;                 objects to get single drip object
;     Modified:   Marc Berthoud, CU, August 2004
;                 Have run be a procedure and getdata (no params)
;                 return all the data (no pointers)
;     Modified:   Marc Berthoud, CU, May 2005
;                 Added use of pathload, pathsave instead of path
;                 Added use of badfile and flatfile
;                 * if badfile and flatfile are changed after first
;                   run() then getcal() has to be called to load them
;     Modified:   Marc Berthoud, CU, August 2007
;                 Added catch if flatfile or badmask doesn't open
;                 Added use of darkfile: flat=flatfile-darkfile
;                 Added loading of drip configuration file
;    
;     Modified:   Luke Keller, IC, August 2009
;                 Changed flatfield prep to use standardized flat file format
;
;     Modified:   Luke Keller, IC, January 2010
;                 Added final non-linearity correction
;
;     Modified    Luke Keller, IC, March 2010
;                 Added use of MASKFILE to mask flatfield files 
;                 for use in grism mode (getcal)
;                 Added 'darksum' step to drip structure
;     Modified    Luke Keller, IC, May 2 2010
;                 Added drip::findcal to search for calibration data in the
;                 current data directory


;****************************************************************************
;     SETDATA - set data values
;****************************************************************************

pro drip::setdata, mode=mo, n=n, readme=rm, $
        pathload=pl, pathsave=ps, filename=fn, header=hd, basehead=bh, $
        badfile=bf, linfile=lnf, flatfile=ff, data=da, $  ;LIN
        cleaned=cl, badflags=bl, linearized=lnr, flatted=fl, stacked=st, undistorted=ud, $  ;LIN
        
        extracted=exd, allwave=alw, allflux=alf,$ ;7/7/11
        merged=md, coadded=coa, coadded_rot=cor, lastcoadd=lc, $ ;EXT  , extspec=exs
        badmap=bm, darks=ds, cleanddarks=cd, darksum=dks, flats=fs, cleanedflats=cf, $
        masterflat=mf, lincor=lnc ;LIN

if keyword_set(mo) then self.mode=mo
if keyword_set(n) then  self.n=n
if keyword_set(rm) then self.readme=rm
if keyword_set(pl) then self.pathload=pl
if keyword_set(ps) then self.pathsave=ps
if keyword_set(fn) then self.filename=fn
if keyword_set(hd) then *self.header=hd
if keyword_set(bh) then *self.basehead=bh
if keyword_set(bf) then *self.badfile=bf
if keyword_set(lnf) then *self.linfile=lnf  ;LIN
if keyword_set(ff) then *self.flatfile=ff
if keyword_set(da) then *self.data=da
if keyword_set(cl) then *self.cleaned=cl
if keyword_set(bl) then *self.badflags=bl
if keyword_set(lnr) then *self.linearized=lnr  ;LIN
if keyword_set(fl) then *self.flatted=fl
if keyword_set(st) then *self.stacked=st
if keyword_set(ud) then *self.undistorted=ud

if keyword_set(exd) then *self.extracted=exd ;7/7/11
if keyword_set(alw) then *self.allwave=alw   ;7/7/11
if keyword_set(alf) then *self.allflux=alf   ;7/7/11

if keyword_set(md) then *self.merged=md
if keyword_set(coa) then *self.coadded=coa
if keyword_set(cor) then *self.coadded_rot=cor
;if keyword_set(exs) then *self.extspec=exs ;EXT
if keyword_set(lc) then *self.lastcoadd=lc
if keyword_set(bm) then *self.badmap=bm
if keyword_set(fs) then *self.darks=ds
if keyword_set(cd) then *self.cleaneddarks=cd
if keyword_set(dks) then *self.darksum=dks
if keyword_set(fs) then *self.flats=fs
if keyword_set(lnc) then *self.lincor=lnc     ;LIN
if keyword_set(cf) then *self.cleanedflats=cf
if keyword_set(mf) then *self.masterflat=mf

end

;****************************************************************************
;     GETDATA - Returns SELF structure as a non-object or specified variables
;****************************************************************************

function drip::getdata, mode=mo, n=n, readme=rm, $
             pathload=pl, pathsave=ps, filename=fn, header=hd, basehead=bh, $
             badfile=bf, linfile=lnf, flatfile=ff, data=da, $  ;LIN
             cleaned=cl, badflags=bl, linearized=lnr, flatted=fl, stacked=st, undistorted=ud, $ ;LIN
            
 extracted=exd, allwave=alw, allflux=alf,$ ;7/7/11
 merged=md, coadded=coa, coadded_rot=cor, lastcoadd=lc, $ ;EXT  extspec=exs,
             badmap=bm, darks=ds, cleaneddarks=cd, darksum=dks, flats=fs, cleanedflats=cf, $
             masterflat=mf, lincor=lnc ;LIN

if keyword_set(mo) then return, self.mode
if keyword_set(n)  then return, self.n
if keyword_set(rm) then return, self.readme
if keyword_set(pl) then return, self.pathload
if keyword_set(ps) then return, self.pathsave
if keyword_set(fn) then return, self.filename
if keyword_set(hd) then return, *self.header
if keyword_set(bh) then return, *self.basehead
if keyword_set(bf) then return, *self.badfile
if keyword_set(lnf) then return, *self.linfile  ;LIN
if keyword_set(ff) then return, *self.flatfile
if keyword_set(da) then return, *self.data
if keyword_set(cl) then return, *self.cleaned
if keyword_set(bl) then return, *self.badflags
if keyword_set(lnr) then return, *self.linearized  ;LIN
if keyword_set(fl) then return, *self.flatted
if keyword_set(st) then return, *self.stacked
if keyword_set(ud) then return, *self.undistorted

if keyword_set(exd) then return, *self.extracted ;7/7/11
if keyword_set(alw) then return, *self.allwave   ;7/7/11
if keyword_set(alf) then return, *self.allflux   ;7/7/11

if keyword_set(md) then return, *self.merged
if keyword_set(coa) then return, *self.coadded
if keyword_set(cor) then return, *self.coadded_rot
;if keyword_set(exs) then return, *self.extspec        ;EXT
if keyword_set(lc) then return, *self.lastcoadd
if keyword_set(bm) then return, *self.badmap
if keyword_set(ds) then return, *self.darks
if keyword_set(cd) then return, *self.cleaneddarks
if keyword_set(dks) then return, *self.darksum
if keyword_set(fs) then return, *self.flats
if keyword_set(lnc) then return, *self.lincor   ;LIN
if keyword_set(cf) then return, *self.cleanedflats
if keyword_set(mf) then return, *self.masterflat

structure={mode:self.mode, n:self.n, readme:self.readme, header:*self.header, $
           basehead:*self.basehead, filename:self.filename, $
           pathload:self.pathload, pathsave:self.pathsave, $
           badfile:self.badfile, linfile:self.linfile, flatfile:self.flatfile, $ ;LIN
           data:*self.data, cleaned:*self.cleaned, badflags:*self.badflags, $
           linearized:*self.linearized, flatted:*self.flatted, stacked:*self.stacked, $ ;LIN
           undistorted:*self.undistorted,$

           extracted:*self.extracted, allwave:*self.allwave, allflux:*self.allflux,$ ;7/7/11
           merged:*self.merged, $
           coadded:*self.coadded, coadded_rot:rot(*self.coadded, 90), $ ;extspec:*self.extspec, $;  EXT
           lastcoadd:*self.lastcoadd, badmap:*self.badmap, darks:*self.darks, $
           cleaneddarks:*self.cleaneddarks, darksum:*self.darksum, flats:*self.flats, $
           lincor:*self.lincor, $ ;LIN
           cleanedflats:*self.cleanedflats, masterflat:*self.masterflat, $
           posdata:*self.posdata, chopsub:*self.chopsub, $
           nodsub:*self.nodsub}
return, structure

end

;******************************************************************************
;     LOAD - load intermediate steps from FITS image.
;******************************************************************************

pro drip::load, filename, masterflat=mf, cleaned=cl, linearized=lnr, flatted=fl, stacked=st, $ ;LIN
                undistort=ud, merged=md, coadded=coa, coadded_rot=cor  ;, extspec=exs   ;EXT

; error check
s=size(filename)
if (s[0] ne 0) and (s[1] ne 7) then begin
    drip_message, 'drip::load - Must provide filename'
    return
endif
; make output filename and set data
self.filename=filename
namepos=strpos(self.filename,'.fit',/reverse_search)
if keyword_set(mf) then begin
    fname=self.pathload+strmid(self.filename,0,namepos)+'_masterflat.fits'
    data=self.masterflat
    head=self.header
endif else if keyword_set(cl) then begin
    fname=self.pathload+strmid(self.filename,0,namepos)+'_cleaned.fits'
    data=self.cleaned
    head=self.header
endif else if keyword_set(lnr) then begin   ;LIN
    fname=self.pathload+strmid(self.filename,0,namepos)+'_linearized.fits'
    data=self.linearized
    head=self.header    
endif else if keyword_set(fl) then begin
    fname=self.pathload+strmid(self.filename,0,namepos)+'_flatted.fits'
    data=self.flatted
    head=self.header
endif else if keyword_set(st) then begin
    fname=self.pathload+strmid(self.filename,0,namepos)+'_stacked.fits'
    data=self.stacked
    head=self.header
endif else if keyword_set(ud) then begin
    fname=self.pathload+strmid(self.filename,0,namepos)+'_undistorted.fits'
    data=self.undistorted
    head=self.header
endif else if keyword_set(md) then begin
    fname=self.pathload+strmid(self.filename,0,namepos)+'_merged.fits'
    data=self.merged
    head=self.header
endif else if keyword_set(coa) then begin
    fname=self.pathload+strmid(self.filename,0,namepos)+'_coadded.fits'
    data=self.coadded
    head=self.basehead
endif else if keyword_set(cor) then begin
    fname=self.pathload+strmid(self.filename,0,namepos)+'_coadded_rot.fits'
    data=self.coadded_rot
    head=self.basehead
;endif else if keyword_set(exs) then begin
;    fname=self.pathload+strmid(self.filename,0,namepos)+'_extspec.fits'  ; EXT
;    data=self.extspec
;    head=self.basehead    
endif else begin
    fname=self.pathload+strmid(self.filename,0,namepos)+'_reduced.fits'
    data=self.coadded
    head=self.basehead
endelse
; read file
*data=readfits(fname,*head,/noscale)
end

;******************************************************************************
;     SAVE - save final output or intermediate steps as FITS image.
;******************************************************************************

pro drip::save, masterflat=mf, cleaned=cl, linearized=lnr, flatted=fl, stacked=st, $ ;LIN
                undistort=ud, merged=md, coadded=co, coadded_rot=cor, $ ;  EXT    extspec=exs, 
                filename=filename

; check if reduced data available
if self.n lt 1 then begin
    drip_message, 'drip::save - no reduced data to save'
    return
endif
; make output filename and set data
namepos=strpos(self.filename,'.fit',/reverse_search)
if keyword_set(mf) then begin
    fname=strmid(self.filename,0,namepos)+'_masterflat.fits'
    data=self.masterflat
endif else if keyword_set(cl) then begin
    fname=strmid(self.filename,0,namepos)+'_cleaned.fits'
    data=self.cleaned
endif else if keyword_set(lnr) then begin ; LIN
    fname=strmid(self.filename,0,namepos)+'_linearized.fits'
    data=self.linearized    
endif else if keyword_set(fl) then begin
    fname=strmid(self.filename,0,namepos)+'_flatted.fits'
    data=self.flatted
endif else if keyword_set(st) then begin
    fname=strmid(self.filename,0,namepos)+'_stacked.fits'
    data=self.stacked
endif else if keyword_set(ud) then begin
    fname=strmid(self.filename,0,namepos)+'_undistorted.fits'
    data=self.undistorted
endif else if keyword_set(md) then begin
    fname=strmid(self.filename,0,namepos)+'_merged.fits'
    data=self.merged
endif else if keyword_set(co) then begin
    fname=strmid(self.filename,0,namepos)+'_coadded.fits'
    data=self.coadded
endif else if keyword_set(cor) then begin
    fname=strmid(self.filename,0,namepos)+'_coadded_rot.fits'
    data=self.coadded_rot
;endif else if keyword_set(exs) then begin
;    fname=strmid(self.filename,0,namepos)+'_extspec.fits'
;    data=self.extspec
endif else begin
    fname=strmid(self.filename,0,namepos)+'_reduced.fits'
    data=self.coadded
endelse
; add pathsave to fname if there is no full path in fname
if strpos(self.filename,path_sep()) lt 0 then fname = self.pathsave + fname
; check for overriding filename selection
if keyword_set(filename) then fname=filename
; save file
fits_write,fname,*data,*self.basehead
drip_message,'saved reduced data file: '+fname


;SAVE EXTRACTED SPECTRA AS FITS TABLE

if keyword_set(fname) then begin
fname=strmid(self.filename,0,namepos)+'_reduced_ext.fits'
  ; if not(strmatch(file,'*.fits')) then file=file+'.fits'
  ; self.prevPath=prevPath
;print, 'allwave',((*self.extracted)[*,0])
;print, 'allflux',((*self.extracted)[*,1])
  len=n_elements((*self.extracted)[*,1])
  orders=((*self.extracted)[*,2]);(intarr(len))+1
   error=dblarr(len)
   data=[transpose((*self.extracted)[*,0]),$ ;allwave
         transpose((*self.extracted)[*,1]),$ ;allflux
         transpose(error),$
         transpose(orders)]
   collabels=['wavelength', 'flux', 'flux_error','order']
   ;self.mw->print,'Written file '+fname  
   drip_message, 'Wrote File'+fname
   wr_spfits,fname,data, len, collabels=collabels
endif
end


;******************************************************************************
;     FINDCAL - find support files (flat, dark)
;******************************************************************************

pro drip::findcal
; Searches current data directory for flatfield data file and chooses the
; most recent flat that has the same instrument configuration as the data
; to be reduced.

fitsdir,file_names, keyvalue, self.pathload, t=self.pathload+'fitsdir.txt', $
  /nosize, keywords='INSTMODE, INSTCFGN, DATE-OBS, TIME-OBS, OBJNAME'
icfg=drip_getpar(*self.basehead,'INSTCFGN')

; find most recent FLAT files with INSTCFGN matching current data file
; first check if any flat file are present in the data directory
if (n_elements(file_names) gt 0) then begin
    flat_list=file_names(where(keyvalue[*,0] eq 'FLAT' and keyvalue[*,1] eq icfg))
    key_list1=keyvalue[where(keyvalue[*,0] eq 'FLAT' and keyvalue[*,1] eq icfg),*]
    ; Sort by date
    date_sort=sort(key_list1[*,2])
    ;print,date_sort
    key_list2=key_list1[date_sort,*]
    flat_list2=flat_list[date_sort,*]
    latest_date=key_list2[n_elements(key_list2[*,2])-1,2]
    ;drip_message,'latest date is '+latest_date
    ; Sort by time stamp
    time_sort=sort(key_list2[*,3])
    key_list3=key_list2[time_sort,*]
    flat_list3=flat_list2[time_sort,*]
    latest_time=key_list3[n_elements(key_list3[*,3])-1,3]
    latest_flat=flat_list3[n_elements(flat_list)-1]
    ;drip_message,'latest time is '+latest_time
    ;drip_message,'latest flat is '+latest_flat

    self.flatfile=latest_flat+'.fits'
    drip_message,'drip::findcal - using flatfield file: '+latest_flat+'.fits'
endif else begin
    drip_message, 'drip::findcal - no flatfield data found'
endelse

end

;******************************************************************************
;     GETCAL - get support files (nonlin, flat, dark and bad)
;******************************************************************************

pro drip::getcal
;** read files and enter obs_id's
; read bad pixel map

;Find mode of grism
print, drip_getpar(*self.basehead,'FILT1_S')
print, drip_getpar(*self.basehead,'FILT2_S')
if(drip_getpar(*self.basehead,'FILT1_S') eq 'G1+blk')then mode =2
if(drip_getpar(*self.basehead,'FILT1_S') eq 'G3+blk')then mode =3
if((drip_getpar(*self.basehead,'FILT4_S') eq 'grism5+blk')) then mode = 4
if((drip_getpar(*self.basehead,'FILT4_S') eq 'grism6+blk')) then mode = 5
if((drip_getpar(*self.basehead,'FILT1_S') eq 'G1+blk') and $
   (drip_getpar(*self.basehead,'FILT2_S') eq 'grism 2')) then mode = 0
if((drip_getpar(*self.basehead,'FILT1_S') eq 'G3+blk') and $
   (drip_getpar(*self.basehead,'FILT2_S') eq 'grism 4')) then mode =1

if (mode le 3) then begin
   badpix = '../Cal/swc_badpix.fits' 
   dark = '../Cal/swc_dark.fits'
endif
if (mode gt 3) then begin
   badpix = '../Cal/lwc_badpix.fits'
   dark = '../Cal/swc_dark.fits'
endif
;              ||||                                     ||||
;***********   VVVV NEEDS REVISION FOR NEWLY MADE FLATS VVVV **********
; flat files x3 (m, d, b3) NEEDS TO FIND INFO IN HEADER (DNE
; CURRENTLY)
; b3 setting will be removed?
case mode of
   0: flat = '../Cal/G1xG2_m_flat.fits'
   1: flat = '../Cal/G3xG4_m_flat.fits'
   2: flat = '../Cal/G1_m_Coldflat.fits'
   3: flat = '../Cal/G3_m_flat.fits'
   4: flat = '../Cal/G5_m_flat.fits'
   5: flat = '../Cal/G6_IRS_m_flat.fits'
endcase
;***********   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  ***********


self.badfile=badpix
if self.badfile eq 'x' then begin
    ; no file found - set badmap to 0.0
    drip_message, 'drip::getcal - No Bad Pixel Map'
    *self.badmap=fltarr(256,256)
    (*self.badmap)[*,*]=0.0
endif else begin
    self.badfile=self.pathload+self.badfile
    *self.badmap=readfits(self.badfile,badhead,/noscale)
    if size(*self.badmap,/N_dimensions) gt 0 then begin
        ; get bad map obs_id and add to basehead
        bad_obs_id=sxpar(badhead,'obs_id')
        sxaddpar,*self.basehead,'BAD_OID',bad_obs_id
        self.parentn=self.parentn+1
        parstring='PARENT'+strtrim(string(self.parentn),2)
        sxaddpar,*self.basehead,parstring,bad_obs_id
    endif  else begin
        ; no valid data loaded - set badmap to 0.0
        drip_message, 'drip::getcal - Error Loading Bad Pixel Map = ' + $
          self.badfile
        *self.badmap=fltarr(256,256)
        (*self.badmap)[*,*]=0.0
    endelse
endelse
*self.badflags=*self.badmap
; read dark frames
self.darkfile=dark
if self.darkfile eq 'x' then begin
    ; no file found - set dark to 0.0
    drip_message, 'drip::getcal - No Dark Frames'
    *self.darks=fltarr(256,256)
    (*self.darks)[*,*]=0.0
endif else begin
    self.darkfile=self.pathload+self.darkfile
    *self.darks=readfits(self.darkfile,darkhead,/noscale)
    if size(*self.darks,/N_dimensions) gt 0 then begin
        ; get darks obs_id and add to basehead
        dark_obs_id=sxpar(darkhead,'obs_id')
        sxaddpar,*self.basehead,'DARK_OID',dark_obs_id
        self.parentn=self.parentn+1
        parstring='PARENT'+strtrim(string(self.parentn),2)
        sxaddpar,*self.basehead,parstring,dark_obs_id
    endif  else begin
        ; no valid data loaded - set dark to 0.0
        drip_message, 'drip::getcal - Error Loading Dark Frames = ' + $
          self.darkfile
        *self.darks=fltarr(256,256)
        (*self.darks)[*,*,*]=0.0
    endelse
endelse

; read linearity correction coefficient files, DETCHAN = (0 for SWC, 1 for LWC)  ;LIN
det_chan=fix(drip_getpar(*self.basehead,'DETCHAN'),type=2)
no_linearity_data = 0 ; 1 = 'No linearity data found', 0 = 'linearity data found'
;det_chan=fix(sxpar(*self.basehead,'DETCHAN'))
if det_chan eq 0 then begin
    self.linfile=self.pathload+'../Cal/SWC_linearity_coeff.fits'
    *self.lincor=readfits(self.linfile,/noscale)
endif else begin
    if det_chan eq 1 then begin
    self.linfile=self.pathload+'../Cal/LWC_linearity_coeff.fits'
    *self.lincor=readfits(self.linfile,/noscale)
endif else begin
    ; no valid data loaded - set linearity correction to 1.0 (no correction)
    drip_message, 'drip::getcal - Error Loading linearity coeff file = ' + self.linfile
    no_linearity_data = 1
    ; Need a graceful way to abort non-lin correction
endelse
endelse
s=size(*self.lincor)
if s[0] lt 3 then begin
    drip_message, 'drip::getcal - Error Loading linearity coeff file = ' + self.linfile
    no_linearity_data = 1
    *self.lincor=fltarr(256,256)+1.0    
endif

; read flat fields
no_flat_data=0 ; 1 = 'No flat data found', 0 = 'flat data found'
if self.flatfile eq '' then self.flatfile=flat
;print, 'self.flatfile = ', self.flatfile
if self.flatfile eq 'x' then begin
    ; no file found - set flat to 1.0
    drip_message, 'drip::getcal - No Flat Frames'
    *self.flats=fltarr(256,256)
    (*self.flats)[*,*]=1.0
    no_flat_data=1
endif else begin
    self.flatfile=self.pathload+self.flatfile
    *self.flats=readfits(self.flatfile,flathead,/noscale)
    if size(*self.flats,/N_dimensions) gt 0 then begin
        ; get flat obs_id and add to basehead
        flat_obs_id=sxpar(flathead,'obs_id')
        sxaddpar,*self.basehead,'FLAT_OID',flat_obs_id
        self.parentn=self.parentn+1
        parstring='PARENT'+strtrim(string(self.parentn),2)
        sxaddpar,*self.basehead,parstring,flat_obs_id
    endif else begin
        ; no valid data loaded - set flat pixels values to 1.0
        drip_message, 'drip::getcal - Error Loading Flat Frames = ' + $
          self.flatfile
        drip_message, 'drip::getcal - Skipping flatfield correction'
        *self.flats=fltarr(256,256)
        (*self.flats)[*,*]=1.0
        no_flat_data=1
    endelse
endelse
;** make master flat
; make darksum
*self.cleaneddarks=drip_clean(*self.darks,*self.badmap,*self.basehead)
drip_message,'drip::getcal - done cleaning darks'
s=size(*self.cleaneddarks)
if s[0] gt 2 then darksum=total(*self.cleaneddarks,3)/s[3] else darksum=*self.cleaneddarks
*self.darksum=darksum/s[3]  ; mean of darks
; make flatsum
*self.cleanedflats=drip_clean(*self.flats,*self.badmap,*self.basehead)

drip_message,'drip::getcal - done cleaning flats'
;Apply ordermask to flatfield: used for grism mode (if grism mode
;detected) to ignore inter-order pixels when calculating median values
;for the master flatfield image. If imaging mode, then used the entire
;array.

;filter=drip_getpar(*self.basehead,'FILT2_S')
;filter=sxpar(*self.basehead,'FILT2_S')


if mode eq  0 then begin  ;get the order mask
    fname='../Cal/G1xG2_order_mask.fits'
    ordermask=readfits(self.pathload+fname)
endif
if mode eq   1 then begin ;get the order mask
    fname='../Cal/G3xG4_order_mask.fits'
    ordermask=readfits(self.pathload+fname)
endif
if mode gt  1 then ordermask=dblarr(256,256)+1

;Build master flatfield image. Flat files are 4-plane fits data cubes
; MASTERFLAT IS DARK-SUBTRACTED
;Planes are: HOT (0), HOT (1), COLD (2), COLD (3)
s=size(*self.cleanedflats)
if s[0] eq 2 then begin
    flatdiff=*self.cleanedflats;    -*self.darksum
    master=flatdiff/median(flatdiff[where(ordermask eq 1)])
    if (mode eq 0 or mode eq 1) then master[where(ordermask eq 0)]=1.
    ;(no_flat_data eq 0) replaced by mode eq 0/1 to work with single disperse
endif
if s[0] eq 3 then begin
    CASE 1 of 
        (s[3] eq 4): begin  
          ; First frame is the sum integrations on a warmer/brighter source
          hflat=((*self.cleanedflats)[*,*,0]+(*self.cleanedflats)[*,*,1])/2
          ; Second frame is the sum integrations on a cooler/fainter source 
          lflat=((*self.cleanedflats)[*,*,2]+(*self.cleanedflats)[*,*,3])/2
          flatdiff=hflat-lflat
          master=flatdiff/median(flatdiff[where(ordermask eq 1)]) ; normalize
          if ((mode eq 0) OR (mode eq 1)) then master[where(ordermask eq 0)]=1.
          end
       (s[3] eq 2): begin
          ; First frame is integration on a warmer/brighter source
          hflat=((*self.cleanedflats)[*,*,0])
          ; Second frame is integration on a cooler/fainter source 
          lflat=((*self.cleanedflats)[*,*,1])
          flatdiff=hflat-lflat
          master=flatdiff/median(flatdiff[where(ordermask eq 1)]) ; normalize
          if ((mode eq 0) OR (mode eq 1)) then master[where(ordermask eq 0)]=1.
          end
       (s[3] eq 3) OR (s[3] gt 4): begin  ; Assume planes are images of same source
          flatsum=total(*self.cleanedflats,3)
          ; make masterflat: darksub and normalize
          flatdiff=flatsum    ;flatsum-*self.darksum
          master=flatdiff/median(flatdiff[where(ordermask eq 1)])
          if ((mode eq 0) OR (mode eq 1)) then master[where(ordermask eq 0)]=1.
          end
    ENDCASE
endif
*self.masterflat=drip_jbclean(master,header)

;apply non-linearity correction...                        LIN
if no_flat_data eq 0 then *self.masterflat=(drip_nonlin(master, *self.lincor))
;else *self.masterflat=master   ; ...unless no flat data found

; set output file obs_id and pipe version
obs_id=drip_getpar(*self.basehead,'OBS_ID')
new_obs_id='P_'+obs_id
sxaddpar,*self.basehead,'OBS_ID',new_obs_id
sxaddpar,*self.basehead,'PIPEVERS','Forcast_Drip_1.0'

end

;****************************************************************************
;     STEPBACK - ignore last reduced image
;****************************************************************************

pro drip::stepback

if (size(*self.lastcoadd))[0] gt 0 then begin
    *self.coadded=*self.lastcoadd
    parstring='PARENT'+strtrim(string(self.n+2),2)
    sxdelpar,*self.basehead,parstring
    self.n=self.n-1
endif
end

;****************************************************************************
;     REDUCE - reduce image in current data
;****************************************************************************

pro drip::reduce
; This procedure is only used if there is no INSTMODE specified
; that has its own pipeline definition (e.g. c2n__define.pro for INSTMODE='C2N')

; clean
*self.cleaned=drip_clean(*self.data,*self.badmap,*self.basehead)
; nonlin
*self.linearized=drip_nonlin(*self.cleaned,*self.lincor)     ;LIN
; flat
*self.flatted=drip_flat(*self.linearized,*self.masterflat,*self.darksum)    ;LIN
; stack
*self.stacked=drip_stack(*self.flatted,*self.header)
; undistort
*self.undistorted=drip_undistort(*self.stacked,*self.header,*self.basehead)
; merge
*self.merged=drip_merge(*self.undistorted,*self.flatted,*self.header,*self.basehead)
; coadd
if self.n gt 0 then begin
    *self.lastcoadd=*self.coadded
    *self.coadded=*self.coadded+*self.merged 
endif else begin
    *self.coadded=*self.merged     
    *self.lastcoadd=*self.merged
    (*self.lastcoadd)[*,*]=0.0
endelse
; create readme
;print,'REDUCE FINISHED'
end

;****************************************************************************
;     RUN - reduces filelist
;****************************************************************************

pro drip::run, filelist

; check validity of filelist
lists=size(filelist)
if lists[1+lists[0]] ne 7 then begin
    drip_message, 'drip::run - must specify file name(s)'
    return
endif
; make file list if only 1 file given
if lists[0] eq 0 then begin
    filelist=[filelist]
    lists=size(filelist)
endif
; getcal if necessary
; Use findcal if keyword 'find_cal' is set to 'y' in dripconfig
if drip_getpar(*self.basehead,'FIND_CAL') eq 'Y' then begin
    drip_message, 'drip::run - Using findcal to find flat data'
    self->findcal
endif

if self.n eq 0 then self->getcal
; loop over files
for filei=0,lists[1]-1 do begin
    reduce_this_file=1
    self.filename=filelist[filei]
    ; load file
    data=readfits(self.filename,*self.header,/noscale)
    ; check data reliability
    if size(data, /n_dimen) lt 2 then begin
        drip_message, 'drip::run - nonvalid input file: '+ self.filename
        reduce_this_file=0
    endif
    ; check file mode
    if reduce_this_file gt 0 then begin
        mode=drip_getpar(*self.header,'INSTMODE')
        if mode eq 'x' then begin
            drip_message, $
              'drip::run - '+self.filename+' must have instmode keyword'
            reduce_this_file=0
        endif else begin
            if self.mode ne mode then begin
                drip_message, ['drip::run - file=' + self.filename , $
                  '   does not have current mode=' + self.mode, $
                  '   file ignored'], /fatal
                reduce_this_file=0
            endif
        endelse
    endif
    ; reduce data
    if reduce_this_file gt 0 then begin
        *self.data=data
        ; reduce but if its first file copy basehead->head then ->basehead
        ;      to insure that keywords configured are replaced in
        ;      basehead (which is saved)
        if self.n gt 0 then begin
            *self.lastcoadd=*self.coadded
            self->reduce
        endif else begin
            *self.header=*self.basehead
            self->reduce
            *self.basehead=*self.header
            *self.lastcoadd=*self.coadded
            (*self.lastcoadd)[*,*]=0.0
        endelse
        ; update settings
        self.n++
        self.parentn++
        parstring='PARENT'+strtrim(string(self.parentn),2)
        sxaddpar,*self.basehead,parstring,sxpar(*self.header,'OBS_ID')
    endif
endfor
end

;****************************************************************************
;     CLEANUP - Destroy pointer heap variables.
;****************************************************************************

pro drip::cleanup

; cleanup data
ptr_free, self.header
ptr_free, self.basehead
ptr_free, self.data
ptr_free, self.cleaned
ptr_free, self.badflags
ptr_free, self.linearized   ;LIN
ptr_free, self.flatted
ptr_free, self.posdata
ptr_free, self.chopsub
ptr_free, self.nodsub
ptr_free, self.stacked
ptr_free, self.undistorted
ptr_free, self.allwave
ptr_free, self.allflux
ptr_free, self.extracted
ptr_free, self.merged
ptr_free, self.coadded
ptr_free, self.coadded_rot
;ptr_free, self.extspec  ;EXT
ptr_free, self.lastcoadd
ptr_free, self.badmap
ptr_free, self.darks
ptr_free, self.flats
ptr_free, self.lincor   ;LIN
ptr_free, self.cleaneddarks
ptr_free, self.darksum
ptr_free, self.cleanedflats
ptr_free, self.masterflat

end

;****************************************************************************
;     INIT - Initialize structure fields.
;****************************************************************************

function drip::init, filelist

; initialize data
self.header=ptr_new(/allocate_heap)
self.basehead=ptr_new(/allocate_heap)
self.data=ptr_new(/allocate_heap)
self.cleaned=ptr_new(/allocate_heap)
self.badflags=ptr_new(/allocate_heap)
self.linearized=ptr_new(/allocate_heap)  ;LIN
self.flatted=ptr_new(/allocate_heap)
self.posdata=ptr_new(/allocate_heap)
*self.posdata=-1
self.chopsub=ptr_new(/allocate_heap)
*self.chopsub=-1
self.nodsub=ptr_new(/allocate_heap)
*self.nodsub=-1
self.stacked=ptr_new(/allocate_heap)
self.undistorted=ptr_new(/allocate_heap)

;below 7/7/11
self.extracted=ptr_new(/allocate_heap)
*self.extracted=-1
self.allwave=ptr_new(/allocate_heap)
*self.allwave=-1
self.allflux=ptr_new(/allocate_heap)
*self.allflux=-1

self.merged=ptr_new(/allocate_heap)
self.coadded=ptr_new(/allocate_heap)
self.coadded_rot=ptr_new(/allocate_heap)
;self.extspec=ptr_new(/allocate_heap) ;EXT
self.lastcoadd=ptr_new(/allocate_heap)
self.badmap=ptr_new(/allocate_heap)
self.darks=ptr_new(/allocate_heap)
self.flats=ptr_new(/allocate_heap)
self.lincor=ptr_new(/allocate_heap)     ;LIN
self.cleaneddarks=ptr_new(/allocate_heap)
self.darksum=ptr_new(/allocate_heap)
self.cleanedflats=ptr_new(/allocate_heap)
self.masterflat=ptr_new(/allocate_heap)
; check validity of filelist
lists=size(filelist)
if lists[1+lists[0]] ne 7 then begin
    drip_message, 'drip::init - must specify valid file name(s)'
    return, 0
endif
; get filename
if lists[0] gt 0 then file=filelist[0] else file=filelist
; set path and filename
pathend=strpos(file,'/',/reverse_search)
if pathend eq -1 then pathend=strpos(file,'\',/reverse_search)
pathend=pathend+1
self.pathload=strmid(file,0,pathend)
self.pathsave=self.pathload
self.filename=strmid(file,pathend)
; load drip configuration file necessary
common drip_config_info, dripconf
if total(size(dripconf)) eq 0 then drip_config_load
; get base header
fits_read, file, null, *self.basehead, /header
; get mode
self.mode=drip_getpar(*self.basehead,'INSTMODE',/vital)
; if no mode found exit
;    (this will never happen if drip_new is used as that procedure
;     always checks for INSTMODE first)
if self.mode eq 'x' then begin
    drip_message,'drip::init - No INSTMODE found - exiting',/fatal
    return, 0
endif
;success
return, 1
end

;****************************************************************************
;     DRIP__DEFINE - Define the DRIP class structure.
;****************************************************************************

pro drip__define

struct={drip, $
        ; admin variables
        mode:'', $                  ; FORCAST instrument mode
        n:0, $                      ; number of reduced files
        readme:strarr(5), $         ; readme string
        parentn:0, $                ; counter for number of parent files
        ; file variables
        pathload:'', $              ; path for input files (from first file)
        pathsave:'', $              ; path to save files
        filename:'', $              ; name of current file (w/o path)
        badfile:'', $               ; name of bad pix file
        darkfile:'', $              ; name of dark file
        linfile:'', $               ; name of linearity correction coeffs file   ;LIN
        flatfile:'', $              ; name of flats file
        header:ptr_new(), $         ; current file header
        basehead:ptr_new(), $       ; output file header (=header of init file)
        ; data variables
        data:ptr_new(), $           ; raw data
        cleaned:ptr_new(), $        ; cleaned data
        badflags:ptr_new(), $       ; flags where data is bad
        linearized:ptr_new(), $     ; linearized data              ;LIN
        flatted:ptr_new(), $        ; flatfielded data
        posdata:ptr_new(), $        ; position data
        chopsub:ptr_new(), $        ; chop subtracted frames
        nodsub:ptr_new(), $         ; nod subtraced frames
        stacked:ptr_new(), $        ; stacked data
        undistorted:ptr_new(), $    ; undistored data

        extracted:ptr_new(), $      ; extracted data    ;7/7/11
        allwave:ptr_new(), $        ; wavelength data   ;7/7/11
        allflux:ptr_new(), $        ; flux data         ;7/7/11

        merged:ptr_new(), $         ; merged data
        coadded:ptr_new(), $        ; coadded data
        coadded_rot:ptr_new(), $    ; coadded rotated
 ;       extspec:ptr_new(), $        ; extracted grism spectrum  ;EXT
        lastcoadd:ptr_new(), $      ; previous coadded data
        ; support data varaiables
        badmap:ptr_new(), $         ; map of bad pixels
        darks:ptr_new(), $          ; dark frames
        lincor:ptr_new(), $         ; linarity correction coefficients     ;LIN
        flats:ptr_new(), $          ; flat frames
        cleaneddarks:ptr_new(), $   ; cleaned dark frames
        cleanedflats:ptr_new(), $   ; cleaned flat frames
        masterflat:ptr_new(), $     ; master flat
        darksum:ptr_new() $         ; sum of dark frames
       }

end
