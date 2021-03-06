cimport lib

from .util cimport error_check, query_interface, register_object, aaf_integral, fraction_to_aafRational, AUID
from .base cimport AAFObject, AAFBase
from .define cimport DataDef, DataDefMap, ContainerDef, CompressionDefMap, ContainerDefMap, CodecDefMap
from .mob cimport SourceMob 

from libcpp.map cimport map
from libcpp.string cimport string
from libcpp.pair cimport pair
from libcpp.vector cimport vector

from wstring cimport wstring, wideToString, toWideString

cpdef dict EssenceFormatDefMap = {}

cpdef dict ColorSpace = {}

ColorSpace['yuv'] = lib.kAAFColorSpaceYUV
ColorSpace['yiq'] = lib.kAAFColorSpaceYIQ
ColorSpace['hsi'] = lib.kAAFColorSpaceHSI
ColorSpace['hsv'] = lib.kAAFColorSpaceHSV
ColorSpace['ycrcb'] = lib.kAAFColorSpaceYCrCb
ColorSpace['ydrdb'] = lib.kAAFColorSpaceYDrDb
ColorSpace['cmyk'] = lib.kAAFColorSpaceCMYK

cpdef dict FrameLayout = {}

FrameLayout['fullframe'] = lib.kAAFFullFrame
FrameLayout['separatefields'] = lib.kAAFSeparateFields
FrameLayout['onefield'] = lib.kAAFOneField
FrameLayout['mixedfields'] = lib.kAAFMixedFields
FrameLayout['segmentedframe'] = lib.kAAFSegmentedFrame

cpdef dict ColorSiting = {}


ColorSiting['cositing'] = lib.kAAFCoSiting
ColorSiting['averaging'] = lib.kAAFAveraging
ColorSiting['threetap'] = lib.kAAFThreeTap
ColorSiting['quincunx'] = lib.kAAFQuincunx
ColorSiting['rec601'] = lib.kAAFRec601
ColorSiting['unknownsiting'] = lib.kAAFUnknownSiting

cdef register_formatdefs(map[string, pair[ lib.aafUID_t, string] ] def_map, dict d, replace=[]):
    cdef pair[string, pair[lib.aafUID_t, string] ] def_pair
    cdef AUID auid_obj 
    for pair in def_map:
        auid_obj = AUID()
        auid_obj.from_auid(pair.second.first)
        name = pair.first
        for n in replace:
            name = name.replace(n, '')
        d[name.lower()] = (auid_obj, pair.second.second)
        
register_formatdefs(lib.get_essenceformats_def_map(), EssenceFormatDefMap, ['kAAF'])


cdef fused format_specifier:
    lib.aafInt8
    lib.aafInt16
    lib.aafInt32
    lib.aafUInt32
    lib.aafColorSpace_t
    lib.aafRect_t 
    lib.aafFrameLayout_t
    lib.aafColorSiting_t
    lib.aafUID_t
    lib.aafBoolean_t
    
cdef class EssenceData(AAFObject):
    def __cinit__(self):
        self.iid = lib.IID_IAAFEssenceData
        self.auid = lib.AUID_AAFEssenceData
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFEssenceData)

        AAFObject.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
    def initialize(self, SourceMob source_mob):
        error_check(self.ptr.Initialize(source_mob.src_ptr))
    
    def read(self, lib.aafUInt32  bytes):
        
        cdef lib.aafUInt32 readsize = min(bytes, self.size - self.position)
        
        if readsize <= 0:
            return None
        
        cdef vector[lib.UChar] buf = vector[lib.UChar](readsize)
        cdef lib.aafUInt32 bytes_read = 0
        
        error_check(self.ptr.Read(readsize,
                                  <lib.aafUInt8 *> &buf[0],
                                  &bytes_read))
        
        cdef string s = string(<char *> &buf[0], bytes_read )
        return s
    
    def write(self, bytes data):
        cdef string s_data = string(data)
        cdef lib.aafUInt32 bytes_written
        
        error_check(self.ptr.Write(len(data),
                                   <lib.aafUInt8 *> s_data.c_str(),
                                   &bytes_written
                                   ))
    
    property position:
        def __get__(self):
            cdef lib.aafPosition_t value
            error_check(self.ptr.GetPosition(&value))
            return value
        def __set__(self, lib.aafPosition_t  value):
            error_check(self.ptr.SetPosition(value))
        
    property size:
        def __get__(self):
            cdef lib.aafLength_t value
            error_check(self.ptr.GetSize(&value))
            return value
    property source_mob:
        def __get__(self):
            cdef SourceMob mob = SourceMob.__new__(SourceMob)
            error_check(self.ptr.GetFileMob(&mob.src_ptr))
            mob.query_interface()
            mob.root = self.root
            return mob
        def __set__(self, SourceMob mob):
            error_check(self.ptr.SetFileMob(mob.src_ptr))
            
    
cdef class EssenceFormat(AAFBase):
    def __cinit__(self):
        self.iid = lib.IID_IAAFEssenceFormat
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFEssenceFormat)

        AAFBase.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
    def __setitem__(self, bytes x, y):
        self.set_format_specifier(x,y)

    def set_format_specifier(self, bytes specifier, object value ):

        specifier = specifier.lower()
        cdef AUID auid_obj = EssenceFormatDefMap[specifier][0]
        cdef AUID audi_operand_obj
        cdef lib.aafUID_t auid = auid_obj.get_auid()
        
        specifier_type = EssenceFormatDefMap[specifier][1]

        cdef lib.aafRect_t rect
        cdef lib.aafInt32 line_map[5]
        
        #print auid_obj.auid,specifier_type
        
        if specifier_type == 'operand.expInt32':
            set_format_specifier[lib.aafInt32](self,auid, value)
        elif specifier_type in ('operand.expUInt32', '?operand.expUInt32'):
            set_format_specifier[lib.aafUInt32](self,auid, value)
        elif specifier_type == 'operand.expBoolean':
            set_format_specifier[lib.aafBoolean_t](self,auid, value)
        elif specifier_type == 'operand.expPixelFormat':
            set_format_specifier[lib.aafColorSpace_t](self, auid, ColorSpace[value.lower()])
        elif specifier_type == 'operand.expRect':
            rect.xSize = value[0]
            rect.ySize = value[1]
            rect.xOffset = value[2]
            rect.yOffset = value[3]
            set_format_specifier[lib.aafRect_t](self,auid, rect)
        elif specifier_type == 'operand.expFrameLayout':
            set_format_specifier[lib.aafFrameLayout_t](self,auid, FrameLayout[value.lower()])
        elif specifier_type == 'operand.expColorSiting':
            set_format_specifier[lib.aafColorSiting_t](self,auid, ColorSiting[value.lower()])
        elif specifier_type == "operand.expAuid":
            audi_operand_obj = CompressionDefMap[value.lower()]
            set_format_specifier[lib.aafUID_t](self, auid, audi_operand_obj.get_auid())
        elif specifier_type == "operand.expLineMap":
            length = len(value)
            for i,value in enumerate(value):
                line_map[i] = value
            error_check(self.ptr.AddFormatSpecifier(auid, sizeof(lib.aafInt32)*length, <lib.aafUInt8*> &line_map))
        else:
            raise NotImplementedError(specifier_type)

cdef object set_format_specifier(EssenceFormat format,lib.aafUID_t &auid, format_specifier value):
    error_check(format.ptr.AddFormatSpecifier(auid, sizeof(format_specifier), <lib.aafUInt8*> &value))


cdef class EssenceMultiAccess(AAFBase):
    def __cinit__(self):
        self.iid = lib.IID_IAAFEssenceMultiAccess
        self.essence_ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.essence_ptr

    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.essence_ptr, lib.IID_IAAFEssenceMultiAccess)

        AAFBase.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.essence_ptr:
            self.essence_ptr.Release()
            
cdef class EssenceAccess(EssenceMultiAccess):
    def __cinit__(self):
        self.iid = lib.IID_IAAFEssenceAccess
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFEssenceAccess)

        EssenceMultiAccess.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
    def get_emptyfileformat(self):
        cdef EssenceFormat format =  EssenceFormat.__new__(EssenceFormat)
        error_check(self.ptr.GetEmptyFileFormat(&format.ptr))
        format.query_interface()
        format.root = self.root
        return format
    
    def set_fileformat(self, EssenceFormat format):
        
        error_check(self.ptr.PutFileFormat(format.ptr))
        
    def index_sample_size(self,lib.aafPosition_t index):
        """
        The size in bytes of the given sample
        """
        cdef lib.aafLength_t sample_size
        error_check(self.ptr.GetIndexedSampleSize(self.datadef.ptr, index, &sample_size))
        return sample_size
    
    def seek(self, lib.aafPosition_t index):
        """
        Seek to Given frame index in essence, Useful only on reading, you can't seek aound while writing
        essence.
        """
        error_check(self.ptr.Seek(index))
        
    def read(self, lib.aafUInt32 nb_samples=1):
        """
        Read a given number of samples from an opened essence stream.
        This call will only return a single channel of essence from an
        interleaved stream.
        A video sample is a frame.
        """
        
        cdef lib.aafUInt32 samples_read
        cdef lib.aafUInt32 bytes_read
        cdef lib.aafUInt32 sample_size = self.max_sample_size
        cdef vector[lib.UChar] buf = vector[lib.UChar](sample_size*nb_samples)
        
        cdef string s
        
        hr = self.ptr.ReadSamples(nb_samples,
                                 sample_size*nb_samples,
                                 &buf[0],
                                 &samples_read,
                                 &bytes_read)
        
        if hr == lib.AAFRESULT_EOF:
            return None
        else:
            error_check(hr)
                    
        s = string(<char * > &buf[0], bytes_read)
        return s
        
    def complete_write(self):
        """
        Handle any format related writing at the end and adjust mob
        lengths.  Must be called before releasing a write essence
        access.
        """
        error_check(self.ptr.CompleteWrite())
        
    def write(self, data, lib.aafUInt32 samples=1, bytes data_type = b'uint8'):
        """
        Writes data to the given essence stream.
        A single video frame is ONE sample.
        Data Length must be large enough to hold the total sample size.
        """
        data_type = data_type.lower()
        cdef lib.aafUInt32 samples2
        
        if isinstance(data, bytes):
            return essence_write_bytes(self, data, samples)
        
        
        if data_type == 'uint16':
            return essence_write_samples[lib.aafUInt16](self, data, samples, 0)
        elif data_type == 'uint8':
            return essence_write_samples[lib.aafUInt8](self, data, samples, 0)
        else:
            raise ValueError("data_type: %s not supported" % str(data_type))
        
    property samples:
        """
        The number of samples in the essence
        """
        def __get__(self):
            cdef lib.aafLength_t result
            error_check(self.ptr.CountSamples(self.datadef.ptr, &result))
            return result
    
    property max_sample_size:
        """
        The size in bytes of the largest sample in the essence.
        """
        def __get__(self):
            cdef lib.aafLength_t max_size
            error_check(self.ptr.GetLargestSampleSize(self.datadef.ptr, &max_size))
            return max_size
    
    property codec_flavour:
        def __set__(self, bytes value):
            cdef AUID auid = CodecDefMap[value.lower()]
            error_check(self.ptr.SetEssenceCodecFlavour(auid.get_auid()))
            
    property codec_name:
        def __get__(self):
            cdef lib.aafCharacter name[1024]
            error_check(self.ptr.GetCodecName(1024, name))
            cdef wstring w_name = wstring(name)
            return wideToString(w_name)
            
    property codecID:
        def __get__(self):
            cdef AUID auid = AUID()
            error_check(self.ptr.GetCodecID(&auid.auid))
            return auid
            

        
        
cdef object essence_write_bytes(EssenceAccess essence, bytes data, lib.aafUInt32 samples):
    cdef lib.aafUInt32 size = len(data)
    cdef lib.aafUInt32 byte_size = sizeof(lib.UChar) * size
    cdef lib.aafUInt32 samples_written =0
    cdef lib.aafUInt32 bytes_written =0
    
    cdef vector[lib.aafUInt8] buf = vector[lib.aafUInt8](size)
    
    cdef char *c
    for i,v in enumerate(data):
        c = v
        buf[i] = <lib.aafUInt8> c[0]
        
    #print len(buf), byte_size, buf.size(),samples

    error_check(essence.ptr.WriteSamples(samples,
                                         byte_size,
                                         <lib.aafUInt8 *> &buf[0],
                                         &samples_written,
                                         &bytes_written
                                         ))
    #print 'wrote', samples_written,bytes_written,samples
    return samples_written,bytes_written

cdef object essence_write_samples(EssenceAccess essence, data, lib.aafUInt32 samples, aaf_integral data_type):
    
    cdef lib.aafUInt32 size = len(data)
    cdef lib.aafUInt32 byte_size = sizeof(aaf_integral) * size
    cdef vector[aaf_integral] buf = vector[aaf_integral](size)
    
    for i,v in enumerate(data):
        buf[i] = v
    
    cdef lib.aafUInt32 samples_written =0
    cdef lib.aafUInt32 bytes_written =0
    error_check(essence.ptr.WriteSamples(samples,
                                         byte_size,
                                         <lib.aafUInt8 *> &buf[0],
                                         &samples_written,
                                         &bytes_written
                                         ))
    return samples_written,bytes_written
    #print 'wrote samples', samples_written, size
    #print 'wrote bytes', bytes_written, byte_size

cdef class Locator(AAFObject):
    def __cinit__(self):
        self.iid = lib.IID_IAAFLocator
        self.auid = lib.AUID_AAFLocator
        self.loc_ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.loc_ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.loc_ptr, lib.IID_IAAFLocator)

        AAFObject.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.loc_ptr:
            self.loc_ptr.Release()
            
    property path:
        """
        Absolute Uniform Resource Locator (URL) complying with RFC 1738 or 
        relative Uniform Resource Identifier (URI) complying with RFC 2396 
        for file containing the essence. If it is a relative URI, 
        the base URI is determined from the URI of the AAF file itself.
        """
        def __get__(self):
            
            cdef lib.aafUInt32  size_in_bytes
            error_check(self.loc_ptr.GetPathBufLen(&size_in_bytes))
            cdef int size_in_chars = (size_in_bytes / sizeof(lib.aafCharacter)) + 1
            cdef vector[lib.aafCharacter] buf = vector[lib.aafCharacter]( size_in_chars )
            
            error_check(self.loc_ptr.GetPath(&buf[0], size_in_bytes))            
            cdef wstring w_name = wstring(&buf[0])
            return wideToString(w_name)

        def __set__(self, bytes value):
            
            cdef wstring w_value = toWideString(value)
            error_check(self.loc_ptr.SetPath(w_value.c_str()))
            
            
cdef class NetworkLocator(Locator):
    def __cinit__(self):
        self.iid = lib.IID_IAAFNetworkLocator
        self.auid = lib.AUID_AAFNetworkLocator
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.loc_ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFNetworkLocator)

        Locator.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.loc_ptr:
            self.loc_ptr.Release()
            
    def initialize(self):
        error_check(self.ptr.Initialize())
            
cdef class EssenceDescriptor(AAFObject):
    def __cinit__(self):
        self.iid = lib.IID_IAAFEssenceDescriptor
        self.auid = lib.AUID_AAFEssenceDescriptor
        self.essence_ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.essence_ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.essence_ptr, lib.IID_IAAFEssenceDescriptor)

        AAFObject.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.essence_ptr:
            self.essence_ptr.Release()
    
    def append_locator(self, Locator loc):
        error_check(self.essence_ptr.AppendLocator(loc.loc_ptr))
            
cdef class FileDescriptor(EssenceDescriptor):
    def __cinit__(self):
        self.iid = lib.IID_IAAFFileDescriptor
        self.auid = lib.AUID_AAFFileDescriptor
        self.file_ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.file_ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.file_ptr, lib.IID_IAAFFileDescriptor)

        EssenceDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.file_ptr:
            self.file_ptr.Release()
    
    property sample_rate:
        def __set__(self, value):
            cdef lib.aafRational_t rate
            fraction_to_aafRational(value, rate)
            error_check(self.file_ptr.SetSampleRate(rate))
        def __get__(self):
            return self['SampleRate']
            
    property container_format:
        def __set__(self, bytes value):
            cdef ContainerDef cont_def = self.dictionary().lookup_containerdef(value)
            error_check(self.file_ptr.SetContainerFormat(cont_def.ptr))
        def __get__(self):
            cdef ContainerDef cont_def = ContainerDef.__new__(ContainerDef)
            error_check(self.file_ptr.GetContainerFormat(&cont_def.ptr))
            cont_def.query_interface()
            cont_def.root = self.root
            auid = cont_def['Identification']
            
            for key,value in ContainerDefMap.items():
                if value == auid:
                    return key
            return cont_def.name
            
cdef class WAVEDescriptor(FileDescriptor):
    """
    The WAVEDescriptor class specifies that a File SourceMob is associated with audio essence
    formatted according to the RIFF Waveform Audio File Format (WAVE).
    The WAVEDescriptor class is a sub-class of the FileDescriptor class. 
    A WAVEDescriptor object shall be owned by a file SourceMob.
    """
    
    def __cinit__(self):
        self.iid = lib.IID_IAAFWAVEDescriptor
        self.auid = lib.AUID_AAFWAVEDescriptor
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFWAVEDescriptor)

        FileDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
    def initialize(self):
        error_check(self.ptr.Initialize())
            
cdef class AIFCDescriptor(FileDescriptor):
    """
    The AIFCDescriptor class specifies that a File SourceMob is associated with 
    audio essence formatted according to the 
    Audio Interchange File Format with Compression (AIFC)
    """
    
    def __cinit__(self):
        self.iid = lib.IID_IAAFAIFCDescriptor
        self.auid = lib.AUID_AAFAIFCDescriptor
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFAIFCDescriptor)

        FileDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()

    def initialize(self):
        error_check(self.ptr.Initialize())
        
    property summary:
        def __get__(self):
            cdef lib.aafUInt32 bufer_size
            error_check(self.ptr.GetSummaryBufferSize(&bufer_size))
            cdef vector[lib.aafUInt8] buf = vector[lib.aafUInt8]( bufer_size )
            
            error_check(self.ptr.GetSummary(bufer_size, <lib.aafUInt8 *> &buf[0]))
            cdef lib.aafUInt8 *data = <lib.aafUInt8 *>  &buf[0]
            return data[:bufer_size]
            #HRESULT GetSummaryBufferSize(aafUInt32 *pSize)

        def __set__(self, bytes value):
            cdef lib.aafUInt32 bufer_size =  len(value) * sizeof(lib.aafUInt8)
            error_check(self.ptr.SetSummary(bufer_size, <lib.aafUInt8 *> value ))
            
cdef class TIFFDescriptor(FileDescriptor):
    """
    The TIFFDescriptor class specifies that a File SourceMob 
    is associated with video essence formatted according to 
    the TIFF specification.
    """
    
    def __cinit__(self):
        self.iid = lib.IID_IAAFTIFFDescriptor
        self.auid = lib.AUID_AAFTIFFDescriptor
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFTIFFDescriptor)

        FileDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
    def initialize(self):
        pass
            
cdef class DigitalImageDescriptor(FileDescriptor):
    """
    The DigitalImageDescriptor class specifies that a File SourceMob is associated with 
    video essence that is formatted either using RGBA or luminance/chrominance formatting.
    The DigitalImageDescriptor class is a sub-class of the FileDescriptor class. 
    The DigitalImageDescriptor class is an abstract class.
    """
    
    def __cinit__(self):
        self.iid = lib.IID_IAAFDigitalImageDescriptor
        self.auid = lib.AUID_AAFDigitalImageDescriptor
        self.im_ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.im_ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.im_ptr, lib.IID_IAAFDigitalImageDescriptor)

        FileDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.im_ptr:
            self.im_ptr.Release()
    
    property compression:
        def __set__(self, bytes value):
            cdef AUID auid = CompressionDefMap[value.lower()]
            error_check(self.im_ptr.SetCompression(auid.get_auid()))
        
        def __get__(self):
            cdef AUID auid = AUID()
            error_check(self.im_ptr.GetCompression(&auid.auid))
            
            for key,value in CompressionDefMap.items():
                if value == auid:
                    return key
            
            raise ValueError("Unknown Compression")
    
    property stored_view:
        """
        The dimension of the stored view.  Typically this includes
        leading blank video lines, any VITC lines, as well as the active
        picture area. Set takes a tuple (width, height)
        """
        def __set__(self, size):
            cdef lib.aafUInt32 width = size[0]
            cdef lib.aafUInt32 height = size[1]
            #Note AAF has these backwords!
            error_check(self.im_ptr.SetStoredView(height,width))
        def __get__(self):
            cdef lib.aafUInt32 width
            cdef lib.aafUInt32 height
            
            error_check(self.im_ptr.GetStoredView(&height,&width))
            return (width, height)
    
    property sampled_view:
        """
        The dimensions of sampled view.  Typically this includes
        any VITC lines as well as the active picture area, but excludes
        leading blank video lines. Set takes a tuple (width, height x_offset, y_offset)
        """
        def __set__(self, rect):
            cdef lib.aafUInt32 width = rect[0]
            cdef lib.aafUInt32 height = rect[1]
            cdef lib.aafInt32 x_offset = rect[2]
            cdef lib.aafInt32 y_offset = rect[3]
            
            error_check(self.im_ptr.SetSampledView(height, width, x_offset, y_offset))
        
        def __get__(self):
            cdef lib.aafUInt32 width
            cdef lib.aafUInt32 height
            cdef lib.aafInt32 x_offset
            cdef lib.aafInt32 y_offset
            error_check(self.im_ptr.GetSampledView(&height, &width, &x_offset, &y_offset))
            return (width, height, x_offset, y_offset)
        
    property display_view:
        """
        the dimension of display view.  Typically this includes
        the active picture area, but excludes leading blank video lines
        and any VITC lines. Set takes a tuple (width, height x_offset, y_offset)
        """
        def __set__(self, rect):
            cdef lib.aafUInt32 width = rect[0]
            cdef lib.aafUInt32 height = rect[1]
            cdef lib.aafInt32 x_offset = rect[2]
            cdef lib.aafInt32 y_offset = rect[3]
            
            error_check(self.im_ptr.SetDisplayView(height, width, x_offset, y_offset))
        
        def __get__(self):
            cdef lib.aafUInt32 width
            cdef lib.aafUInt32 height
            cdef lib.aafInt32 x_offset
            cdef lib.aafInt32 y_offset
            error_check(self.im_ptr.GetDisplayView(&height, &width, &x_offset, &y_offset))
            return (width, height, x_offset, y_offset)
    property aspect_ratio:
        """
        Image Aspect Ratio.  This ratio describes the
        ratio between the horizontal size and the vertical size in the
        intended final image.
        """
        def __set__(self, value):
            cdef lib.aafRational_t ratio
            fraction_to_aafRational(value, ratio)
            error_check(self.im_ptr.SetImageAspectRatio(ratio))
        def __get__(self):
            return self['ImageAspectRatio']
        
    property layout:
        """
        The frame layout.  The frame layout describes whether all
        data for a complete sample is in one frame or is split into more
        than/ one field. Set Takes a str.
        
        Values are:
            "fullframe"      - Each frame contains a full sample in progressive 
                               scan lines.
            "separatefields" - Each sample consists of two fields, 
                               which when interlaced produce a full sample.
            "onefield"       - Each sample consists of two interlaced
                               fields, but only one field is stored in the
                               data stream.
            "mixxedfields"   - Similar to FullFrame, except the two fields
        
        Note: value is always converted to lowercase
        """
        
        def __set__(self, bytes value):
            value = value.lower()
            if value == "none":
                value = None
            if value is None:
                pass
            
            cdef lib.aafFrameLayout_t layout = FrameLayout[value]
            
            error_check(self.im_ptr.SetFrameLayout(layout))
            
        def __get__(self):
            cdef lib.aafFrameLayout_t layout
            
            error_check(self.im_ptr.GetFrameLayout(&layout))
            print layout
            
            for key, value in FrameLayout.items():
                if value == layout:
                    return key
                
    property line_map:
        """
        The VideoLineMap property.  The video line map specifies the
        scan line in the analog source that corresponds to the beginning 
        of each digitized field.  For single-field video, there is 1
        value in the array.  For interleaved video, there are 2 values
        in the array. Set Takes a Tuple, example: (0) or (0,1).
        """
        def __set__(self, value):
            if len(value) == 0 or len(value ) > 2:
                raise ValueError("line_map len must be 1 or 2")
            cdef lib.aafUInt32 numberElements = len(value)
            
            cdef lib.aafInt32 line_map[2]
            
            for i,value in enumerate(value):
                line_map[i] = value
            
            error_check(self.im_ptr.SetVideoLineMap(numberElements, line_map))
        def __get__(self):
            cdef lib.aafUInt32 numberElements
            error_check(self.im_ptr.GetVideoLineMapSize(&numberElements))
            
            cdef vector[lib.aafInt32] buf
            # I don't Know if its possible to have a line_map bigger then 2
            cdef lib.aafInt32 line_map[5]
            
            error_check(self.im_ptr.GetVideoLineMap(numberElements, line_map))

            l = []
            for i in xrange(numberElements):
                l.append(line_map[i])
                
            return tuple(l)
        
    property image_alignment:
        """
        Specifies the alignment when storing the digital essence.  For example, a value of 16
        means that the image is stored on 16-byte boundaries.  The
        starting point for a field will always be a multiple of 16 bytes.
        If the field does not end on a 16-byte boundary, it is padded
        out to the next 16-byte boundary.
        """
        def __get__(self):
            cdef lib.aafUInt32 value
            error_check(self.im_ptr.GetImageAlignmentFactor(&value))
            return value
        def __set__(self, lib.aafUInt32 value):
            error_check(self.im_ptr.SetImageAlignmentFactor(value))
        
        

cdef class CDCIDescriptor(DigitalImageDescriptor):
    """
    The CDCIDescriptor class specifies that a file SourceMob is associated with video
    essence formatted with one luminance component and two color-difference components 
    as specified in this document.
    Informative note: This format is commonly known as YCbCr.
    The CDCIDescriptor class is a sub-class of the DigitalImageDescriptor class.
    A CDCIDescriptor object shall be owned by a file SourceMob.
    """
    def __cinit__(self):
        self.iid = lib.IID_IAAFCDCIDescriptor
        self.auid = lib.AUID_AAFCDCIDescriptor
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFCDCIDescriptor)

        DigitalImageDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
    def initialize(self):
        error_check(self.ptr.Initialize())
            
    property component_width:
        """
        The ComponentWidth property.  Specifies the number of bits
        used to store each component.  Typical values can be 8, 10,
        12, 14, or 16, but others are permitted by the reference
        implementation.  Each component in a sample is packed
        contiguously; the sample is filled with the number of bits
        specified by the optional PaddingBits property.  If the
        PaddingBits property is omitted, samples are packed
        contiguously.
        """
        def __set__(self, lib.aafInt32 value):
            error_check(self.ptr.SetComponentWidth(value))
        def __get__(self):
            cdef lib.aafInt32 value
            error_check(self.ptr.GetComponentWidth(&value))
            return value
        
    property horizontal_subsampling:
        """
        The HorizontalSubsampling property.  Specifies the ratio of
        luminance sampling to chrominance sampling in the horizontal direction.
        For 4:2:2 video, the value is 2, which means that there are twice as
        many luminance values as there are color-difference values.
        Another typical value is 1; however other values are permitted by
        the reference implementation.
        """
        def __set__(self, lib.aafUInt32 value):
            error_check(self.ptr.SetHorizontalSubsampling(value))
        def __get__(self):
            cdef lib.aafUInt32 value
            error_check(self.ptr.GetHorizontalSubsampling(&value))
            return value
        
    property vertical_subsampling:
        """
        The VerticalSubsampling property.  Specifies the ratio of
        luminance sampling to chrominance sampling in the vertical direction.
        For 4:2:2 video, the value is 2, which means that there are twice as
        many luminance values as there are color-difference values.
        Another typical value is 1; however other values are permitted by
        the reference implementation.
        """
        def __set__(self, lib.aafUInt32 value):
            error_check(self.ptr.SetVerticalSubsampling(value))
        def __get__(self):
            cdef lib.aafUInt32 value
            error_check(self.ptr.GetVerticalSubsampling(&value))
            return value
        
    property color_range:
        """
        The ColorRange property.  Specifies the range of allowable
        digital chrominance component values.  Chrominance values are
        unsigned and the range is centered on 128 for 8-bit video and 512
        for 10-bit video.  This value is used for both chrominance
        components.
        """
        def __set__(self, lib.aafUInt32 value):
            error_check(self.ptr.SetColorRange(value))
        def __get__(self):
            cdef lib.aafUInt32 value
            error_check(self.ptr.GetColorRange(&value))
            return value
        
cdef class RGBADescriptor(DigitalImageDescriptor):
    def __cinit__(self):
        self.iid = lib.IID_IAAFRGBADescriptor
        self.auid = lib.AUID_AAFRGBADescriptor
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFRGBADescriptor)

        DigitalImageDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
cdef class SoundDescriptor(FileDescriptor):
    def __cinit__(self):
        self.iid = lib.IID_IAAFSoundDescriptor
        self.auid = lib.AUID_AAFSoundDescriptor
        self.snd_ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.snd_ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.snd_ptr, lib.IID_IAAFSoundDescriptor)

        FileDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.snd_ptr:
            self.snd_ptr.Release()
            
cdef class PCMDescriptor(SoundDescriptor):
    def __cinit__(self):
        self.iid = lib.IID_IAAFPCMDescriptor
        self.auid = lib.AUID_AAFPCMDescriptor
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFPCMDescriptor)

        SoundDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
cdef class TapeDescriptor(EssenceDescriptor):
    def __cinit__(self):
        self.iid = lib.IID_IAAFTapeDescriptor
        self.auid = lib.AUID_AAFTapeDescriptor
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFTapeDescriptor)

        EssenceDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
    
    def initialize(self):
        error_check(self.ptr.Initialize())
        
cdef class PhysicalDescriptor(EssenceDescriptor):
    def __cinit__(self):
        self.iid = lib.IID_IAAFPhysicalDescriptor
        self.auid = lib.AUID_AAFPhysicalDescriptor
        self.phys_ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.phys_ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.phys_ptr, lib.IID_IAAFPhysicalDescriptor)

        EssenceDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.phys_ptr:
            self.phys_ptr.Release()
            
cdef class ImportDescriptor(PhysicalDescriptor):
    def __cinit__(self):
        self.iid = lib.IID_IAAFImportDescriptor
        self.auid = lib.AUID_AAFImportDescriptor
        self.ptr = NULL
    
    cdef lib.IUnknown **get_ptr(self):
        return <lib.IUnknown **> &self.ptr
    
    cdef query_interface(self, AAFBase obj = None):
        if obj is None:
            obj = self
        else:
            query_interface(obj.get_ptr(), <lib.IUnknown **> &self.ptr, lib.IID_IAAFImportDescriptor)

        PhysicalDescriptor.query_interface(self, obj)
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
    
    def initialize(self):
        error_check(self.ptr.Initialize())
        
register_object(EssenceData)
register_object(Locator)
register_object(NetworkLocator)
register_object(EssenceDescriptor)
register_object(FileDescriptor)
register_object(WAVEDescriptor)
register_object(AIFCDescriptor)
register_object(TIFFDescriptor)
register_object(DigitalImageDescriptor)
register_object(CDCIDescriptor)
register_object(RGBADescriptor)
register_object(SoundDescriptor)
register_object(PCMDescriptor)
register_object(TapeDescriptor)
register_object(PhysicalDescriptor)
register_object(ImportDescriptor)