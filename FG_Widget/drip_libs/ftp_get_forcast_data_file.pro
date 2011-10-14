;-----------------------------------------------------------------
FUNCTION Url_Callback, status, progress, data

   ; print the info msgs from the url object
   PRINT, status

   ; return 1 to continue, return 0 to cancel
   RETURN, 1
END

;-----------------------------------------------------------------
PRO ftp_get_forcast_data_file

   ; If the url object throws an error it will be caught here
   CATCH, errorStatus 
   IF (errorStatus NE 0) THEN BEGIN
      CATCH, /CANCEL

      ; Display the error msg in a dialog and in the IDL output log
      r = DIALOG_MESSAGE(!ERROR_STATE.msg, TITLE='URL Error', $
         /ERROR)
      PRINT, !ERROR_STATE.msg

      ; Get the properties that will tell us more about the error.
      oUrl->GetProperty, RESPONSE_CODE=rspCode, $
         RESPONSE_HEADER=rspHdr, RESPONSE_FILENAME=rspFn
      PRINT, 'rspCode = ', rspCode
      PRINT, 'rspHdr= ', rspHdr
      PRINT, 'rspFn= ', rspFn

      ; Destroy the url object
      OBJ_DESTROY, oUrl
      RETURN
   ENDIF

   ; create a new IDLnetURL object 
   oUrl = OBJ_NEW('IDLnetUrl')

   ; Specify the callback function
   oUrl->SetProperty, CALLBACK_FUNCTION ='Url_Callback'

   ; Set verbose to 1 to see more info on the transacton
   oUrl->SetProperty, VERBOSE = 1

   ; Set the transfer protocol as ftp
   oUrl->SetProperty, url_scheme = 'ftp'

   ; The ITT VIS FTP server
   oUrl->SetProperty, URL_HOST = '130.134.188.27'
   
   oUrl->SetProperty, URL_USERNAME = 'forcast'
   oUrl->SetProperty, URL_PASSWORD = 'sofia02!'

   ; The FTP server path of the file to download
   oUrl->SetProperty, URL_PATH = '/Lab/CD039/B/b039_2831.fits'

   ; Make a request to the ITT VIS FTP server.
   ; Retrieve a binary image file and write it 
   ; to the local disk's IDL main directory.

   fn = oUrl->Get(FILENAME = '/Users/keller/Desktop/b039_2831.fits' )  

   ; Print the path to the file retrieved from the remote server
   PRINT, 'filename returned = ', fn

   ; The FTP server path of the next file to download
   ;oUrl->SetProperty, URL_PATH = 'doc/examples/ascii.txt'

   ; Retrieve an ascii text file as an array of strings
   ;strings = oUrl->Get( /STRING_ARRAY )

   ; Print the returned array of strings
   ;PRINT, 'array of strings returned:'
   ;for i=0, n_elements(strings)-1 do print, strings[i]

   ; Destroy the url object
   OBJ_DESTROY, oUrl

END
