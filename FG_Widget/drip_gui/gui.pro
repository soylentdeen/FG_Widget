; NAME:
;     GUI - Version 1.7.0
;
; PURPOSE:
;     Starts the GUI for running the FORCAST DRiP.
;
; CALLING SEQUENCE:
;     GUI, [XSIZE=XS, YSIZE=YS, DATAMAN=DATAMAN_RETURN]
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
;     DATAMAN - Returns the dataman variable to access reduced data
;               from the IDL command line.
;
; CALLED ROUTINES AND OBJECTS:
;     DRIP_CONFIG_LOAD: To load the drip configuration
;     CW_DRIP_DISP: To create display compound widgets
;     CW_DRIP_MW: To create a message window compound widget
;     DRIP_DATAMAN: The datamanager for all stored data
;     DRIP_MENU: The Menu Manager that creates general menu items
;     DRIP_PIPEMAN: The pipeline manager that reduced data and sends
;                   reduced data to the data manager
;     DRIP_AUTOMAN: The auto manager, a tool to automatically reduce data
;     DRIP_DISPMAN: The display manager to manage the displays and
;                   analysis objects
;     DRIP_ANALMAN: The manger for all label analysis objects
;     DRIP_ANALMAN_SELECT: The manager for selection analysis objects
;     DRIP_ANALMAN_STATS: The manager for statistics analysis objects
;     DRIP_ANALMAN_POINT: The manager for point analysis objects
;
; PROCEDURE:
;     load configuration files, lay out the widgets, create manager
;     objects, start manager objects, set the gui in motion.
;
; RESTRICTIONS:
;     Some objects may have memory leaks.
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
;     Modified: Marc Berthoud, Palomar, July 2006
;               - Added buttons for pipeline
;               - Expanded data information interface
;               - Added option to return dataman
;     Modified: Marc Berthoud, Cornell University, September 2007
;               - Added dripconf loading and saving
;               - Made various managers responsible for their widgets

;******************************************************************************
;     DRIP_EVENTHAND - Event Handler
;******************************************************************************
pro drip_eventhand, event
Widget_Control, event.id, Get_UValue=cmd
Call_Method, cmd.method, cmd.object, event
end


;******************************************************************************
;     DRIP_CLEANUP - To clean up when done
;******************************************************************************
pro drip_cleanup, top
; get menu, dataman, dropman, dispman, automan and pipeman objects
widget_control, top, get_uvalue=obj
; destroy these objects
; (display objects are destroyed by dispman::cleanup)
; (mw object is destroyed by pipeman::cleanup)
obj_destroy, obj
; save drip configuration variables
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


;******************************************************************************
;     GUI - Main function
;******************************************************************************
pro gui, xsize=xs, ysize=ys, dataman=dataman_return, _extra=e

; check size keywords
if not keyword_set(xs) then xs=256
if not keyword_set(ys) then ys=xs

; create gui common block (fonts, pathcut)
COMMON gui_os_dependent_values, largefont, smallfont,mediumfont

CASE !VERSION.OS_FAMILY OF
    'unix'      : begin
        largefont='-*-helvetica-medium-r-*-*-18-*-*'
        smallfont='-*-helvetica-medium-r-*-*-10-*-*'
        mediumfont='-*-helvetica-bold-r-*-*-12-*-*'
        device, retain=2        ; to make sure displays get redrawn
    end
    'Windows'   : begin
        largefont='helvetica*24'
        smallfont='helvetica*14'
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
common gui_config_info, guiconf
guiconf=[conffilename]
; read configuration file -> config (array of strings)
if strlen(conffilename) gt 0 then begin
    openr,fileunit,conffilename,/get_lun
    s=''
    while not eof(fileunit) do begin
        readf,fileunit,s
        guiconf=[guiconf,s]
    endwhile
    close,fileunit
    free_lun,fileunit
endif

;** create widgets and objects
; base widget
top=widget_base(column=2, title='FORCAST Quick Look Data Reduction', $
;      mbar=mbar, /scroll, x_scroll_size=1024, y_scroll_size=768) ; scroling
mbar=mbar,event_pro='top_event') ; non scroling
; control base / item
cbase=widget_base(top, column=1, /base_align_left, /frame, space=5, $
                  xsize=2*xs+29) ;, ysize=185)
ctrlbase=widget_base(cbase, /row )
; Pipeline Control Base
ctrlbase1=widget_base(ctrlbase, /column )
; draw base
dbase=widget_base(top, row=2, /base_align_left, space=5)
; info base (had xsize=450 ysize=ys*2+200+153
ibase=widget_base(top, /column, /base_align_left)

; display windows + display manager (will be widget id's of objects)
disp=cw_drip_disp(dbase, quad_id='A', xsize=xs, ysize=ys, _extra=e)
disp=[disp,cw_drip_disp(dbase, quad_id='B', xsize=xs, ysize=ys, _extra=e)]
disp=[disp,cw_drip_disp(dbase, quad_id='C', xsize=xs, ysize=ys, _extra=e)]
disp=[disp,cw_drip_disp(dbase, quad_id='D', xsize=xs, ysize=ys, _extra=e)]
; get objects
dispn=4
disp_objs=objarr(dispn)
for i=0, dispn-1 do begin ;get object ref from 1st child widget uvalue
    id=widget_info(disp[i], /child)
    widget_control, id, get_uvalue=obj
    disp_objs[i]=obj
endfor

; message window item (get mw as message window object)
mw_widget=cw_drip_mw(ibase, xsize=82, ysize=10)
mw_list_id=widget_info(mw_widget, /child)
widget_control, mw_list_id, get_uvalue=mw
drip_errproc={object:mw, funct:'print'}

; create objects
dataman=obj_new('drip_dataman', mw)
midbase=widget_base(ibase, /row, /frame)
dispman=obj_new('drip_dispman', disp_objs, dataman, 1, midbase)
dropman=obj_new('drip_dropman', dataman, mw)
pipeman=obj_new('drip_pipeman', dataman, mw)
automan=obj_new('drip_automan', mw,pipeman)
menu=obj_new('drip_menu', dataman, pipeman, mw, $
             [dataman, pipeman, dropman, dispman, automan] )
; analysis object managers
midhalfbase=widget_base(midbase,/column)
analman_label=obj_new('drip_analman',midhalfbase)
analman_select=obj_new('drip_analman_select',ibase)
analman_scale=obj_new('drip_analman_scale',ibase)
analman_stats=obj_new('drip_analman_stats',ibase)
analman_point=obj_new('drip_analman_point',ibase)
analmans=[analman_label, analman_select, analman_scale, analman_stats, $
          analman_point]
; return dataman if requested
if keyword_set(dataman_return) then begin
    dataman_return=dataman
    print,"To list data manager functions type dataman->printhelp"
endif

;** realize, start objects, register
widget_control, top, set_uvalue=[menu,dataman,dropman,dispman,automan,pipeman], /realize
; start all objects (the order is important)
dataman->start, ctrlbase
dispman->start, analmans
analman_label->start, disp_objs
analman_select->start, disp_objs, dataman
analsels=analman_select->getdata(/anals)
analman_scale->start, disp_objs
analman_stats->start, dispman
analman_point->start, dispman
dropman->start
menu->start, mbar, disp_sels=analsels
pipeman->start, mbar, ctrlbase1, disp_sels=analsels
automan->start, mbar, ctrlbase1

; preserve color table
COMMON color_table, set_color
set_color=[0,0,0]
tvlct,set_color(0), set_color(1), set_color(2), /get
print,'colors: ',set_color

xmanager, 'gui', top, cleanup='drip_cleanup', /no_block
greeting=getpar(guiconf,'greeting')
if (size(greeting))[1] eq 7 then mw->print,greeting
end

