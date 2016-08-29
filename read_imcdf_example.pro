; docformat = 'rst'
;+
; :file_comments:
;   methods that begin with __ are considered private methods
;   and should not be callled directly
;
; :requires:
;   IDL 8.1
;
; :author:
;   Charles Blais, 2016, Natural Resources Canada
;-

;+
; :description:
;   Constructor.
;-
function intermagnetcdf::init
  compile_opt idl2
  ;-- allocate memory to pointer when initializing object
  self.cdfid = ptr_new(/allocate)
  return,1
end

;+
; :description:
;   Read the content fo the INTERMAGNET CDF file and store in the object
;
; :params:
;   filename: in, required, type=string
;     CDF filename to read
;-
pro intermagnetcdf::read, filename
  compile_opt idl2
  *(self.cdfid) = cdf_open(filename, /readonly)   ; Open a file.
end

;+
; :description:
;   Get attributes in global scope of CDF file
;   Note that the attribute may or may not be set and can have more then one values
;   maxgentry indicates the amount of values found in the global scope attribute
;
; :params:
;   attname_or_number: in, required, type=string or number
;     attribute name or name as used by cdf_control procedure
;
; :return:
;   attribute value or list of attribute values
;-
function intermagnetcdf::__getGlobalAttr, attname_or_number
  compile_opt idl2
  if cdf_attexists(*(self.cdfid), attname_or_number) then begin
    cdf_control, *(self.cdfid), attribute=attname_or_number, get_attr_info=info
    values = list()
    for i=0,info.maxgentry do begin
      cdf_attget, *(self.cdfid), attname_or_number, i, x
      values.add, x
    endfor
    if values.count() eq 1 then return, values[0] $
    else return, values
  endif else return, !null
end
function intermagnetcdf::getFormatDescription
  return, self.__getGlobalAttr('FormatDescription')
end
function intermagnetcdf::getFormatVersion
  return, self.__getGlobalAttr('FormatVersion')
end
function intermagnetcdf::getIagaCode
  return, self.__getGlobalAttr('IagaCode')
end
function intermagnetcdf::getElementsRecorded
  return, self.__getGlobalAttr('ElementsRecorded')
end
function intermagnetcdf::getPublicationLevel
  return, self.__getGlobalAttr('PublicationLevel')
end
function intermagnetcdf::getPublicationDate
  return, self.__getGlobalAttr('PublicationDate')
end
function intermagnetcdf::getObservatoryName
  return, self.__getGlobalAttr('ObservatoryName')
end
function intermagnetcdf::getLatitude
  return, self.__getGlobalAttr('Latitude')
end
function intermagnetcdf::getLongitude
  return, self.__getGlobalAttr('Longitude')
end
function intermagnetcdf::getElevation
  return, self.__getGlobalAttr('Elevation')
end
function intermagnetcdf::getInstitution
  return, self.__getGlobalAttr('Institution')
end
function intermagnetcdf::getVectorSensOrient
  return, self.__getGlobalAttr('VectorSensOrient')
end
function intermagnetcdf::getStandardLevel
  return, self.__getGlobalAttr('StandardLevel')
end
function intermagnetcdf::getStandardName
  return, self.__getGlobalAttr('StandardName')
end
function intermagnetcdf::getStandardVersion
  return, self.__getGlobalAttr('StandardVersion')
end
function intermagnetcdf::getPartialStandDesc
  return, self.__getGlobalAttr('PartialStandDesc')
end
function intermagnetcdf::getSource
  return, self.__getGlobalAttr('Source')
end
function intermagnetcdf::getTermsOfUse
  return, self.__getGlobalAttr('TermsOfUse')
end
function intermagnetcdf::getUniqueIdentifier
  return, self.__getGlobalAttr('UniqueIdentifier')
end
function intermagnetcdf::getParentIdentifiers
  return, self.__getGlobalAttr('ParentIdentifiers')
end
function intermagnetcdf::getReferenceLinks
  return, self.__getGlobalAttr('ReferenceLinks')
end


;+
; :description:
;   Get the data found under one of the zvariables
;
; :params:
;   element: in, required, type=string
;     element to be returned, as labeled under the attribute LABLAXIS of the CDF
;
; :return:
;   value found in zvariables and meta is a hash with all the attributes defined
;-
function intermagnetcdf::getData, element, metadata = metadata, datetime=datetime
  compile_opt idl2
  
  ; clear metadata and datetimes
  metadata = hash()
  datetime = []
  
  inq = cdf_inquire(*(self.cdfid))
  ; Read all the variable attribute entries.
  ; Walk through all of the zVariables
  for varNum = 0, inq.nzvars-1 do begin
    ; only read if the LABLAXIS is set
    if ~cdf_attexists(*(self.cdfid), 'LABLAXIS', varNum, /zvariable) then continue
    
    cdf_attget_entry, *(self.cdfid), 'LABLAXIS', varNum, attType, cdf_label, status, /zvariable
    if status ne 1 then continue
    if strcmp(cdf_label, element, /fold_case) then begin
      cdf_control, *(self.cdfid), variable=varNum, /zvariable, get_var_info=var_inq
      cdf_varget, *(self.cdfid), varNum, values, /zvariable, rec_count = var_inq.maxrecs
      
      ; get associated times if there are any
      if cdf_attexists(*(self.cdfid), 'DEPEND_0', varNum, /zvariable) then begin
        cdf_attget_entry, *(self.cdfid), 'DEPEND_0', varNum, attType, cdf_depend, status, /zvariable
        cdf_varget, *(self.cdfid), cdf_depend, datetime, /zvariable, rec_count = var_inq.maxrecs
      endif
      
      ; get all the attributes and add them to the metadata
      for attrNum = 0, inq.natts-1 do begin
        ; Read the variable attribute
        cdf_attget_entry, *(self.cdfid), attrNum, varNum, attType, value, $
          status, /zvariable, attribute_name=attName
        if status ne 1 then continue
        metadata[attName] = value
      endfor  
      return, values
    endif
  endfor
  return, !null
end


;+
; :description:
;   Read the content fo the INTERMAGNET CDF file and store in the object
;-
pro intermagnetcdf::close
  compile_opt idl2
  cdf_close, *(self.cdfid) ;Close the cdf file.
end

;+
; :description:
;   Destructor.
;-
pro gicSimulator::cleanup
  compile_opt IDL2
  self.close
  ptr_free, self.cdfid
end


pro intermagnetcdf__define
  void={intermagnetcdf, $
      cdfid : ptr_new()}
  return
end


;------- main --------
; Example
cdf = obj_new('intermagnetcdf')
cdf.read, 'tst_20140101_000000_pt1s_4.cdf'
print, 'IAGA Code: ', cdf.getIagaCode()
print, 'Publication Date: ', cdf_encode_epoch(cdf.getPublicationDate())
print, 'Parent Identifiers: ', cdf.getParentIdentifiers()
print, 'Reference Links: ', cdf.getReferenceLinks()

data =  cdf.getData('h', metadata=metadata, datetime=datetime)
print, 'First 10 H data', data[0:10]
print, 'First 10 timestamps as epoch', datetime[0:10]
print, metadata

cdf.close
end