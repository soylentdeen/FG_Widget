; NAME:
;     FG_WIDGET - Version .6
;
; PURPOSE:
;     GUI for running the DRiP.
;
; CALLING SEQUENCE:
;     FG_WIDGET, [XSIZE=XS, YSIZE=YS]
;
; INPUTS:
;     XSIZE - X dimension of the display windows
;     YSIZE - Y dimension of the display windows
;
; OUTPUTS: (save capabilities)
;     IDL output: final reduced image, averaged sum of final reduced images, or
;                 full data structure(s).  IDL save file with full data
;                 structure(s)
;     FITS output: averaged sum of final reduced images.
;
; CALLED ROUTINES AND OBJECTS:
;     DRIP__DEFINE
;     CW_DRIP_DISP
;     DRIP_DISPMAN
;     DRIP_DATAMAN
;     DRIP_MENU
;     DRIP_AUTOMAN
;     CW_DRIP_MW
;
; SIDE EFFECTS:
;     None identified.
;
; RESTRICTIONS:
;     save routines need to be updated
;
; PROCEDURE:
;     lay out the widgets, create manager objects, set the gui in motion.
;
; MODIFICATION HISTORY:
;     Written by:  Alfred Lee, Cornell University, 2002
;     Modified: Alfred Lee, Cornell University, January 2003
;               Decided to give this version a number
;     Modified: Alfred Lee, CU, March 9, 2003
;               Added the AUTO object to code.  Also lumped all created
;               objects into the top base's UValue, so that all may be
;               destroyed together.
;     Modified: Marc Berthoud, CU, July, 2003
;               - added use of common block gui_os_dependent_values
;                 and largefont to handle system dependent font declarations
;                 and filename delimeters
;               - added widget fileinfo
;               - moved pipeline step selection into CW_DRIP_QL's
;     Modified: Marc Berthoud CU, October, 2003
;               - added use of configuration file for gui settings
;                 (saved as common block gui_config_info)
;                 standart file if guiconf.txt in current directory
;                 program asks about loading and saving config file
;     Modified: Marc Berthoud CU, December, 2004
;               - added image manager to manage user analysis of
;                 the displayed data
;     Modified: Marc Berthoud CU, March, 2004
;               - moved widget creation for image manager to
;                 imgman::init
;     Modified: Marc Berthoud CU, April, 2006
;               - renamed dispman -> dataman
;               - renamed imgman -> dispman
;     Modified: Luke Keller, Ithaca College, May 2010
;               - Update to v1.4 in title bar
;               - Include save of dripconfig on exit

;**************************************************************************
;   EVENTHANDLER
;**************************************************************************

pro drip_eventhand, event
Widget_Control, event.id, Get_UValue=cmd
Call_Method, cmd.method, cmd.object, event
end

;**************************************************************************
;    DRIP_CLEANUP
;**************************************************************************


pro drip_cleanup, top
; get menu, dropman, dispman, imgman, automan objects
widget_control, top, get_uvalue=obj
; destroy these objects
; (ql and mw objects are destroyed by imgman::cleanup)
obj_destroy, obj
; save drip config information
common drip_config_info, dripconf, drip_errproc
conffilename=dripconf[0]
print,'dripconffilename=',conffilename
err=0
if strlen(conffilename) gt 0 then begin
    openw,fileunit,conffilename,/get_lun, error=err
    ; check for error opening file
    if err ne 0 then begin
        print, "ERROR: drip cleanup could NOT open drip config"
        print, "       ",!ERROR__STATE.MSG
    endif else begin
        s=size(dripconf)
        ; save variables (except dripconf[0] which is filename)
        for i=1,s[1]-1 do printf,fileunit,dripconf[i]
        close,fileunit
    endelse
    free_lun,fileunit
endif
; save gui configuration variables
common gui_config_info, guiconf
conffilename=guiconf[0]
print,'guiconffilename=',conffilename
if strlen(conffilename) gt 0 then begin
    openw,fileunit,conffilename,/get_lun, error=err
    ; check for error opening file
    if err ne 0 then begin
        print, "ERROR: drip cleanup could NOT open drip config"
        print, "       ",!ERROR__STATE.MSG
    endif else begin
        s=size(guiconf)
        ; save variables (except guiconf[0] which is filename)
        for i=1,s[1]-1 do printf,fileunit,guiconf[i]
        close,fileunit
    endelse
    free_lun,fileunit
endif

end

;**************************************************************************
;    FG_WIDGET MAIN FUNCTION
;**************************************************************************


pro fg_widget, xsize=xs, ysize=ys, dataman=dataman_return, _extra=e

; check keywords
if not keyword_set(xs) then xs=256
if not keyword_set(ys) then ys=xs

cd,current=currentpath
!path=expand_path('+'+currentpath)+':'+expand_path('+'+!dir)

; create gui common block (fonts, pathcut)
COMMON gui_os_dependent_values, largefont, smallfont, mediumfont
CASE !VERSION.OS_FAMILY OF
   'unix'      : begin
       largefont='-*-helvetica-medium-r-*-*-18-*-*'
       smallfont=''
       mediumfont='-*-helvetica-bold-r-*-*-12-*-*' 
       device, retain=2 ; to make sure displays get redrawn
   end
   'Windows'   : begin
       largefont='helvetica*24'
       smallfont='courier*12'
       mediumfont='helvetica*18'
   end
ENDCASE


;** load drip configuration file
common drip_config_info, dripconf, drip_errproc
drip_config_load,/prompt

;** load gui configuration file
; search for gui configuration file -> conffilename
cd,'.',current=currentdir
if (size(findfile(currentdir+path_sep()+'guiconf.txt')))[0] eq 1 then begin
    conffilename=currentdir+path_sep()+'guiconf.txt'
endif else begin
    conffilename=dialog_pickfile(/must_exist,/read,title='Load GUI Conf File:')
endelse

; initialize config_info (save filename in config[0])
common gui_config_info, config
config=[conffilename]
; read configuration file -> config (array of strings)
if strlen(conffilename) gt 0 then begin
    openr,fileunit,conffilename,/get_lun
    s=''
    while not eof(fileunit) do begin
        readf,fileunit,s
        config=[config,s]
    endwhile
    close,fileunit
    free_lun,fileunit
endif

;** widgets and objects
; base widget
top=widget_base(column=2, title='FORCAST Spectral Extraction Widget v1.4', $
;      mbar=mbar, /scroll, x_scroll_size=800, y_scroll_size=600) ; scroling
       mbar=mbar) ; non scroling
;control base
cbase=widget_base(top, column=1, /base_align_left, /frame, space=5, $
      xsize=2*xs+29, ysize=170)
ctrlbase=widget_base(cbase, /row )
;Pipeline Control Base
ctrlbase1=widget_base(ctrlbase, /column )

;image draw base
dbase=widget_base(top, column=2, /base_align_left, space=5)

;info base (had xsize=450 ysize=ys*2+200+153
ibase=widget_base(top, /column, /base_align_left)

;message window base
mwbase = widget_base(top,/column,/base_align_left)

;extract draw base
edbase = widget_base(top,/column,/base_align_left)

;extract analysis base
eabase = widget_base(top,/column,/base_align_left)


;display windows + display manager (will be widget id's of objects)
disp=cw_drip_disp(dbase, quad_id='A', xsize=xs, ysize=ys, _extra=e)
disp=[disp,cw_drip_disp(dbase, quad_id='B', xsize=xs, ysize=ys, _extra=e)]

;get objects
dispn=2
disp_objs=objarr(dispn)
for i=0,dispn-1 do begin  ;get object ref from 1st child widget uvalue
    id=widget_info(disp[i], /child)
    widget_control, id, get_uvalue=obj
    disp_objs[i]=obj
endfor

;message window item (get mw as message window object)
mw_widget=cw_drip_mw(mwbase, xsize=82, ysize=5)
mw_list_id=widget_info(mw_widget, /child)
widget_control, mw_list_id, get_uvalue=mw
drip_errproc={object:mw, funct:'print'}

;extract draw widget
;extDisp=cw_drip_ext(edbase, ext_id='ext1',xsize=512,ysize=400) 
extDisp=cw_drip_xplot(edbase,ext_id='ext1',xsize=512, ysize=400, mw=mw)
id =  widget_info(extDisp,/child)
widget_control,id,get_uvalue=obj
xplot=obj


dataman=obj_new('drip_dataman', mw)
extman=obj_new('drip_extman',mw,dataman)
;dispman=obj_new('drip_dispman', disp_objs, mw, dataman,0,ibase)
dispman=obj_new('drip_dispman', disp_objs, dataman, 0, ibase)  ;midbase
dropman=obj_new('drip_dropman', dataman, mw)
pipeman=obj_new('drip_pipeman', dataman, mw)
automan=obj_new('drip_automan', mw,pipeman)
;menu=obj_new('drip_menu', dataman, mw,$
;             [dataman, pipeman, dispman, automan, extman])
menu=obj_new('drip_menu', dataman, pipeman, mw, $
           [dataman, pipeman, dispman, automan, extman])
; analysis object managers
analman_label=obj_new('drip_analman',ibase)
analman_select=obj_new('drip_analman_select',ibase)
analman_scale=obj_new('drip_analman_scale',ibase)
analman_stats=obj_new('drip_analman_stats',ibase)
analman_extract=obj_new('drip_analman_extract', eabase)
analmans=[analman_label, analman_select,analman_scale, analman_stats, $
          analman_extract]
; return dataman if requested
if keyword_defined(dataman_return) then dataman_return=dataman


;** realize, start, register
widget_control, top, set_uvalue=[menu,dataman,dropman,dispman,automan,pipeman],$
                /realize
;start all objects
dataman->start, ctrlbase
dispman->start, analmans
analman_label->start, disp_objs
analman_select->start, disp_objs, dataman
analsels=analman_select->getdata(/anals)
analman_scale->start, disp_objs
analman_stats->start, dispman
xplot->start,dispman
analman_extract->start, dispman, xplot, extman
dropman->start
menu->start, mbar, disp_sels=analsels
pipeman->start, mbar, ctrlbase1, disp_sels=analsels
automan->start, mbar, ctrlbase1
greeting=getpar(config,'greeting')
if (size(greeting))[0] eq 7 then mw->print,greeting
xmanager, 'gui', top, cleanup='drip_cleanup', /no_block


end


; Added the following dummy functions to allow resolve_all to finish..
PRO TRNLOG
END

PRO SETLOG
END
