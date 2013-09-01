cimport lib

from .util cimport error_check, query_interface, register_object

from base cimport AAFObject, AAFBase, AUID
from mob cimport Mob 
from datadef cimport DataDef
from iterator cimport ComponentIter, SegmentIter

cdef class Component(AAFObject):
    def __init__(self, AAFBase obj = None):
        super(Component, self).__init__(obj)
        self.iid = lib.IID_IAAFComponent
        self.auid = lib.AUID_AAFComponent
        self.comp_ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.comp_ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.comp_ptr
    
    def __dealloc__(self):
        if self.comp_ptr:
            self.comp_ptr.Release()
            
    property length:
        def __get__(self):
            if self.has_key("Length"):
                return self['Length']
            return None
            
cdef class Segment(Component):
    def __init__(self, AAFBase obj = None):
        super(Segment, self).__init__(obj)
        self.iid = lib.IID_IAAFSegment
        self.auid = lib.AUID_AAFSegment
        self.seg_ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.seg_ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.seg_ptr
    
    def __dealloc__(self):
        if self.seg_ptr:
            self.seg_ptr.Release()
            
cdef class Transition(Component):
    def __init__(self, AAFBase obj = None):
        super(Transition, self).__init__(obj)
        self.iid = lib.IID_IAAFTransition
        self.auid = lib.AUID_AAFTransition
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
cdef class Sequence(Segment):
    def __init__(self, AAFBase obj = None):
        super(Sequence, self).__init__(obj)
        self.iid = lib.IID_IAAFSequence
        self.auid = lib.AUID_AAFSequence
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
    def initialize(self, bytes media_kind):
        cdef DataDef media_datadef        
        media_datadef = self.dictionary().lookup_datadef(media_kind)
        error_check(self.ptr.Initialize(media_datadef.ptr))
        
    def components(self):
        cdef ComponentIter comp_inter = ComponentIter()
        error_check(self.ptr.GetComponents(&comp_inter.ptr))
        return comp_inter
    
cdef class Timecode(Segment):
    def __init__(self, AAFBase obj = None):
        super(Timecode, self).__init__(obj)
        self.iid = lib.IID_IAAFTimecode
        self.auid = lib.AUID_AAFTimecode
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()

cdef class Filler(Segment):
    def __init__(self, AAFBase obj = None):
        super(Filler, self).__init__(obj)
        self.iid = lib.IID_IAAFFiller
        self.auid = lib.AUID_AAFFiller
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
cdef class Pulldown(Segment):
    def __init__(self, AAFBase obj = None):
        super(Pulldown, self).__init__(obj)
        self.iid = lib.IID_IAAFPulldown
        self.auid = lib.AUID_AAFPulldown
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()

cdef class SourceReference(Segment):
    def __init__(self, AAFBase obj = None):
        super(SourceReference, self).__init__(obj)
        self.iid = lib.IID_IAAFSourceReference
        self.auid = lib.AUID_AAFSourceReference
        self.ref_ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ref_ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ref_ptr
    
    def __dealloc__(self):
        if self.ref_ptr:
            self.ref_ptr.Release()
            
cdef class SourceClip(SourceReference):
    def __init__(self, AAFBase obj = None):
        super(SourceReference, self).__init__(obj)
        self.iid = lib.IID_IAAFSourceClip
        self.auid = lib.AUID_AAFSourceClip
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
    def resolve_ref(self):
        cdef Mob mob = Mob()
        error_check(self.ptr.ResolveRef(&mob.ptr))
        return Mob(mob).resolve()
    
cdef class OperationGroup(Segment):
    def __init__(self, AAFBase obj = None):
        super(OperationGroup, self).__init__(obj)
        self.iid = lib.IID_IAAFOperationGroup
        self.auid = lib.AUID_AAFOperationGroup
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
    def input_segments(self):
        cdef Segment seg
        for i in xrange(self.nb_input_segments):
            seg = Segment()
            error_check(self.ptr.GetInputSegmentAt(i, &seg.seg_ptr))
            yield Segment(seg).resolve()
    
    property nb_input_segments:
        def __get__(self):
            cdef lib.aafUInt32 value
            error_check(self.ptr.CountSourceSegments(&value))
            return value
        
    
cdef class NestedScope(Segment):
    def __init__(self, AAFBase obj = None):
        super(NestedScope, self).__init__(obj)
        self.iid = lib.IID_IAAFNestedScope
        self.auid = lib.AUID_AAFNestedScope
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
    def segments(self):
        cdef SegmentIter seg_iter = SegmentIter()
        error_check(self.ptr.GetSegments(&seg_iter.ptr))
        return seg_iter
    
cdef class ScopeReference(Segment):
    def __init__(self, AAFBase obj = None):
        super(ScopeReference, self).__init__(obj)
        self.iid = lib.IID_IAAFScopeReference
        self.auid = lib.AUID_AAFScopeReference
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()

cdef class EssenceGroup(Segment):
    """
    Describes multiple digital representations of the same original content source.
    """
    def __init__(self, AAFBase obj = None):
        super(EssenceGroup, self).__init__(obj)
        self.iid = lib.IID_IAAFEssenceGroup
        self.auid = lib.AUID_AAFEssenceGroup
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
cdef class Selector(Segment):
    """
    Provides the value of a single Segment while preserving references to unused alternatives.
    """
    def __init__(self, AAFBase obj = None):
        super(Selector, self).__init__(obj)
        self.iid = lib.IID_IAAFSelector
        self.auid = lib.AUID_AAFSelector
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
            
cdef class Event(Segment):
    def __init__(self, AAFBase obj = None):
        super(Event, self).__init__(obj)
        self.iid = lib.IID_IAAFEvent
        self.auid = lib.AUID_AAFEvent
        self.event_ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.event_ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.event_ptr
    
    def __dealloc__(self):
        if self.event_ptr:
            self.event_ptr.Release()
            
cdef class CommentMarker(Event):
    def __init__(self, AAFBase obj = None):
        super(CommentMarker, self).__init__(obj)
        self.iid = lib.IID_IAAFCommentMarker
        self.auid = lib.AUID_AAFCommentMarker
        self.comment_ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.comment_ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.comment_ptr
    
    def __dealloc__(self):
        if self.comment_ptr:
            self.comment_ptr.Release()
            
cdef class DescriptiveMarker(CommentMarker):
    def __init__(self, AAFBase obj = None):
        super(DescriptiveMarker, self).__init__(obj)
        self.iid = lib.IID_IAAFDescriptiveMarker
        self.auid = lib.AUID_AAFDescriptiveMarker
        self.ptr = NULL
        if not obj:
            return
        
        query_interface(obj.get(), <lib.IUnknown **> &self.ptr, self.iid)
    
    cdef lib.IUnknown **get(self):
        return <lib.IUnknown **> &self.ptr
    
    def __dealloc__(self):
        if self.ptr:
            self.ptr.Release()
    
register_object(Component)
register_object(Segment)
register_object(Transition)
register_object(Sequence)
register_object(Timecode)
register_object(Filler)
register_object(Pulldown)
register_object(SourceReference)
register_object(SourceClip)
register_object(OperationGroup)
register_object(NestedScope)
register_object(ScopeReference)
register_object(EssenceGroup)
register_object(Selector)
register_object(Event)
register_object(CommentMarker)
register_object(DescriptiveMarker)