;=============================================================================
;
;	This source code file is copyright (c) Vadim Drubetsky AKA the 
; Black Phantom. All rights reserved.
;
;	This source code file is a part of the Tripple-DOS project. Your use 
; of this source code must fully comply with the accompanying license file, 
; LICENSE.TXT. You must have this file enclosed with your Tripple-DOS copy in
; order for it to be legal.
;
;	In no event, except for when it is explicitly stated by the applicable 
; law, shall Vadim Drubetsky aka the Black Phantom be liable for any special,
; incidental, indirect, or consequential damages (including but not limited to
; profit loss, business interruption, loss of business information, or any 
; other pecuniary loss) arising out of the use of or inability to use 
; Tripple-DOS, even if he has been advised of the possibility of such damages.
;
;=============================================================================

;=============================================================================
;
;				MEMMAN.ASM
;				----------
;
;	Simple protmode linear memory management services.
;
; In order to access page tables, they are supplied with page tables
; control array. This array has the structure of page directory but
; contain linear addresses of page tables instead of physical. Of course,
; linear addresses must be page-aligned (address of page); value of -1 will
; indicate the entry is not mapped (needed?)
;
;	(!)	DS = INIT_DS for most functions in this file.
;	(!)	Allocated page dirs are never freed (framework IsPageTblEmpty
; is ready).
;
;	Changes:
;	--------
;
;=============================================================================

		PAGES_MAP_SIZE	EQU	20000h

	INCLUDE	X86.INC
	INCLUDE	DEF.INC
	INCLUDE	TASKMAN.INC
	INCLUDE	PHLIB32.MCR

	EXTRN	MemSize: dword
	EXTRN	SysPagesCtl: dword
	EXTRN	SysPdbLin: dword
	EXTRN	SysPdb: dword
	EXTRN	Pdb: dword
	EXTRN	PdbSeg: word
	EXTRN	GdtBase: dword
	EXTRN	CurrLdtBase: dword
	EXTRN	Field: byte
	EXTRN	NumOfTasks: dword
	EXTRN	FirstTask: dword

	EXTRN	InitErrHandler: near

DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'
	PUBVAR		PagesMapSeg, DW, ?	; Segment address of pages map
	PUBVAR		PagesMap, DD, ?	; linear address of pages map.
	PUBVAR		PagesCtlSeg, DW, ?	; Segment address of pages control 
						; array
	PUBVAR		PagesCtl, DD, ?		; Linear address of pages 
						; control array
	PUBVAR		PdbLin, DD, ?		; PDB linear address.
	PUBVAR		OsHeapEnd, DD, 	OS_HEAP	; Points to the tail of OS heap
						; linear address.
	PUBVAR		OsHeapBitmap, DD, ?	; Linear address of OS heap 
						; bitmap.
	PUBVAR		OsHeapBitmapSeg, DW, ?	; Segment address of OS heap
						; bitmap.
	PUBVAR		OsStartPage, DD, ?	; System start physical
						; address.
	PUBVAR		OsEndPage, DD, ?	; System end physical
						; address.
	PUBVAR		DynPagesTbl2, DD, ?	; A global page table for
						; dynamic page table tables
	PUBVAR		DynPagesTbl2Seg, DW, ?	; Segment address -"-
DATA	ENDS


CODE	SEGMENT	PARA	PUBLIC	USE16	'CODE'
ASSUME	CS:CODE, DS:DATA
.486p

;-----------------------------------------------------------------------------
;
;	Initializes pages availability bit string in real mode. Mask pages
; belonging to OS.
;
;	I: 
;	O: CF=0 - success, 1 - memory allocation error.
;
;-----------------------------------------------------------------------------
PUBLIC	InitPagesMap
InitPagesMap	PROC	USES es

	;
	; Zero pages map.
	;
	mov	es, PagesMapSeg
	sub	di, di
	mov	ecx, MemSize
	shr	ecx, 3
	inc	ecx
	sub	al, al
	cld
		rep	stosb

	;
	; Mark pages belonging to OS busy.
	;
	mov	es, PagesMapSeg
	sub	di, di
	mov	al, 0FFh
	mov	ecx, OsEndPage
	shr	ecx, 12			; ECX = pages count.
	mov	dx, cx			; Keep pages count.
	shr	ecx, 3
	cld
		rep	stosb
	mov	cx, dx
	and	cx, 7
	mov	al, 1
set_mask:
	test	cx, cx
	jz	end_set_mask
	shl	al, 1
	dec	cx
	jmp	set_mask
end_set_mask:
	dec	ax			; Set necessary bits.
	stosb

	;
	; Mark memory A0000 - FFFFF busy.
	;
	mov	ecx, 0Ch		; Mark busy 60h pages.
	mov	di, 0A0000h SHR 15	; At address A0000
	mov	al, -1			; Set all bits (pages) busy.
	cld
		rep	stosb

	;
	; If providing XMS, mark HMA (100000-110000) busy.
	;
IFDEF	PROVIDE_HIMEM
	mov	word ptr es:[8000h SHR 10], -1
ENDIF	; PROVIDE_HIMEM

	;
	; Initialize page table control array. There are 
	; 2 page tables - one maps 1st Mb, the other - OS kernel at 2nd Gb.
	; And one more for dynamic pages table.
	;
	mov	es, PdbSeg
	mov	eax, es:[0]		; 1st Mb page table
	sub	eax, OsStartPage
	or	eax, OS_BASE
	and	eax, 0FFFFF000h		; Linear address is page-aligned (!)

	mov	ecx, es:[OS_BASE SHR 20]	; OS kernel page table
	sub	ecx, OsStartPage
	or	ecx, OS_BASE
	and	ecx, 0FFFFF000h		; Linear address is page-aligned (!)

	mov	di, OS_HEAP SHR 20
	mov	edx, es:[di]		; OS heap page
	mov	ebx, edx
	sub	edx, OsStartPage
	or	edx, OS_BASE
	and	edx, 0FFFFF000h		; Linear address is page-aligned (!)

	mov	esi, es:[OS_DYN_PAGETBLS SHR 20]	; OS kernel page table
	sub	esi, OsStartPage
	or	esi, OS_BASE
	and	esi, 0FFFFF000h		; Linear address is page-aligned (!)

	mov	es, PagesCtlSeg
	mov	es:[0], eax
	mov	es:[OS_BASE SHR 20], ecx
	mov	es:[di], edx
	mov	es:[OS_DYN_PAGETBLS SHR 20], esi

	;
	; Record PDB linear address.
	;
	mov	eax, SysPdb
	sub	eax, OsStartPage
	or	eax, OS_BASE
	mov	SysPdbLin, eax

	;
	; Zero OS heap bitmap.
	;
	mov	es, OsHeapBitmapSeg
	sub	di, di
	mov	cx, 2000h		; Zero 32k
	sub	eax, eax
	cld
		rep	stosd

	;
	; Zero dynamic page tables page table.
	;
	mov	es, DynPagesTbl2Seg
	sub	di, di
	mov	cx, 400h
	sub	eax, eax
	cld
		rep	stosd

	ret
InitPagesMap	ENDP

CODE	ENDS


CODE32	SEGMENT	PARA	PUBLIC	USE32	'CODE'
ASSUME	CS:CODE32, DS:FLAT

;-----------------------------------------------------------------------------
;
;	I: SI:EDI -> Seg:Offs
;	   EBX = Eflags
;	O: EAX = linear address
;
;	Converts pointer to linear address.
;
;-----------------------------------------------------------------------------
PUBLIC PointerToLinear
PointerToLinear	PROC	near	USES edx
	test	ebx, FL_VM
	jz	prot_mode

	mov	eax, esi
	and	eax, 0FFFFh
	shl	eax, 4
	add	eax, edi
	ret
prot_mode:

	mov	edx, esi
	and	edx, 0FFF8h
	test	si, 4		; LDT selector?
	jnz	ldt_sel

	add	edx, GdtBase
	jmp	get_base_address

ldt_sel:
	add	edx, CurrLdtBase
get_base_address:
	mov	eax, dword ptr (Descriptor386 PTR fs:[edx]).BaseHigh32
	mov	edx, dword ptr (Descriptor386 PTR fs:[edx]).BaseLow
	shl	eax, 24
	and	edx, 0FFFFFFh
	add	eax, edx

	add	eax, edi
	ret
PointerToLinear	ENDP


;-----------------------------------------------------------------------------
;
;	Returns physical address for a given linear.
;
;	I: EAX = linear
;	O: CF = 0 - OK, EAX = physical.
;	      = 1 - error, page not present.
;
;-----------------------------------------------------------------------------
PUBLIC	LinearToPhysical
LinearToPhysical	PROC	USES ebx ecx edx
; Check if page table present.
	mov	ebx, PdbLin		; FS:EBX -> current PDB linear address.
	mov	ecx, eax
	shr	ecx, 22			; ECX = page dir. entry
	test	dword ptr fs:[ebx+ecx*4], PAGE_PRESENT
	jnz	page_tbl_present
; Page table not present, linear address invalid.
	stc
	ret

page_tbl_present:
	mov	ecx, eax
	shr	ecx, 22
	mov	ebx, PagesCtl		; fs:[ebx] -> pages array ctl.
	mov	ecx, fs:[ebx+ecx*4]	; ECX = page table linear address.

	mov	edx, eax
	shr	edx, 12
	and	edx, 3FFh		; EDX = page table entry
	mov	ecx, fs:[ecx+edx*4]	; ECX = page physical address.

	test	ecx, PAGE_PRESENT
	jnz	page_exists

; Page not present, linear address invalid.
	stc
	ret

page_exists:
	and	eax, 0FFFh
	and	ecx, NOT 0FFFh		; Clear page attributes.
	or	eax, ecx		; Change page linear address to phys.

	clc
	ret
LinearToPhysical	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = linear address that is mapped by the page table
;
;	O: EAX != 0 - not empty
;	   EAX = 0 - empty
;
;	R:
;	Should be called only for dynamically allocated page tables (heap).
;
;-----------------------------------------------------------------------------
IsPageTblEmpty	PROC	USES fs ecx
	mov	ecx, eax
IF	0
	and	ecx, 0FFFFFFF8h
	or	ecx, 003FFFF8h		; Offset FF8h in last page table
					; entry.
ELSE
	and	ecx, 0FFFFFFFCh
	or	ecx, 003FFFFCh		; Offset FFCh in last page table
					; entry.
ENDIF
	mov	eax, PAGE_PRESENT
test_empty:
	test	fs:[ecx], eax
	jz	test_next
; Return not empty.
	mov	eax, 1
	ret

test_next:
	sub	ecx, 4
	jnl	test_empty
; Return empty.
	sub    eax, eax
	ret

IsPageTblEmpty	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = linear address to be mapped in the directory.
;	(!) the address must be within OS heap linear range.
;
;	O: CF = 0 - success
;		1 - fail
;
;	Creates a new page table directory entry (page table) that will map
; the given linear address (but doesn't map the address itself)
;
;	R:
;	* Page table is always given U = 1, W = 1, P = 1
; (restrictions are applied at page table entry level).
;	* Last entry of page table allocated this way contains itself.
;
;-----------------------------------------------------------------------------
CreatePageTable	PROC	USES eax ebx ecx edx esi edi
	cmp	eax, OS_HEAP
	jb	@F
	cmp	eax, OS_HEAP + OS_HEAP_SIZE
	jna	create
@@:
	stc
	ret

create:
; Check if the page table already exists.
	mov	ecx, eax
	shr	ecx, 22
	mov	edx, SysPdbLin
	test	dword ptr fs:[edx][ecx*4], PAGE_PRESENT
	jz	@F
	stc
	ret

@@:
	mov	ecx, eax
	mov	esi, eax

	;
	; Allocate page for page table entry.
	;
	call	AllocPage
	cmp	eax, -1
	jne	map_page_table
	stc
	ret

map_page_table:
; Set page table's physical address in page dir.
	shr	esi, 22
	or	eax, PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER

; Map new page table in all address spaces.
	mov	edx, SysPdbLin
	mov	fs:[edx][esi*4], eax

	sub	ebx, ebx
	mov	edi, FirstTask
set_pt_in_pdb:
	cmp	ebx, NumOfTasks
	jnb	set_pt_lin

	mov	edx, (DosTask PTR fs:[edi]).TaskPdbLin
	mov	fs:[edx][esi*4], eax
	inc	ebx
	add	edi, SIZEOF DosTask
	jmp	set_pt_in_pdb

; Set page table's page's linear address to its own last element.
set_pt_lin:
	and	eax, NOT PAGE_USER 			; U = 0
IF 0
	and	ecx, NOT 00000FFFh
	or	ecx, 003FF000h

; At this point linear address of the page table (mapped into itself) is
; still not valid, so MapPage _cannot_ be called to map the page directory
; to ifself. Instead _this_ page table physical address will be mapped to
; _temporary_ linear - 003FF000h which is always present.

	push	ecx
	mov	ecx, 3FF000h
	call	MapPage
	pop	ecx

	mov	ebx, PagesCtl
	mov	dword ptr fs:[ebx][esi], 3FF000h
	call	MapPage
ELSE
; Map PT to its element in a DynPagesTbl2.
	sub	ecx, OS_HEAP
	shr	ecx, 10
	and	ecx, NOT 0FFFh
	lea	ecx, [ecx+OS_DYN_PAGETBLS]
	call	MapPage
ENDIF

; Set page table's linear address in page table control array. Must be set
; prior to calling MapPage.
	mov	ebx, SysPagesCtl
	mov	fs:[ebx][esi*4], ecx

; Set the new PT in PagesCtls in all tasks
	mov	eax, FirstTask
	sub	edx, edx
set_pages_ctl:
	cmp	edx, NumOfTasks
	jnb	clear_page_tbl

	mov	ebx, (DosTask PTR fs:[eax]).TaskPageCtl
	mov	fs:[ebx][esi*4], ecx
	inc	edx
	add	eax, SIZEOF DosTask
	jmp	set_pages_ctl

clear_page_tbl:
; Set page table to all 0s.
	mov	esi, 0FFCh
	sub	eax, eax

zero_page_tbl:
	mov	fs:[ecx][esi], eax
	sub	esi, 4
	jnl	zero_page_tbl

IF 0
; Set linear address that maps page table as busy.
	mov	esi, OsHeapBitmap
	mov	eax, ecx
	and	eax, NOT OS_HEAP
	shr	eax, 12
	bts	dword ptr fs:[esi], eax
ENDIF

	clc
	ret

CreatePageTable	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = physical address and attributes to set.
;	   ECX = linear address
;
;	O: CF = 0 - success
;		1 - fail
;
;	Maps given physical page to linear address.
;
;	R:
;	* The physical address must be allocated with AllocPage or otherwise
; set present. 
;	* If page directory is not present the function returns fail.
;	* The attributes in EAX apply to page only and will not be applied
; to appropriate page table directory.
;
;-----------------------------------------------------------------------------
MapPage		PROC	USES eax ebx ecx edx esi

	mov	edx, PdbLin
	mov	ebx, PagesCtl
	;
	; Check if appropriate page table is present.
	;
	mov	esi, ecx
	shr	esi, 20
	and	esi, 00000FFCh
	test	dword ptr fs:[edx][esi], PAGE_PRESENT
	jnz	map_page

cmp	ecx, OS_DYN_PAGETBLS
jb	@F
int 2
@@:
; If not present, return fail.
	stc
	ret

map_page:
	mov	esi, fs:[ebx][esi]		; Page table linear address.
	shr	ecx, 10
	and	ecx, 00000FFCh
	mov	fs:[esi][ecx], eax

	mov	eax, cr3
	mov	cr3, eax			; Invalidate TLB.

	clc
	ret
MapPage		ENDP


;-----------------------------------------------------------------------------
;
;	I:
;	O: CF = 0, EAX = Page physical address.
;		1, EAX = -1 if no free pages.
;
;	Allocates physical page
;
;-----------------------------------------------------------------------------
PUBLIC	AllocPage
AllocPage	PROC	USES ecx edx
	call	FirstFreePage
	cmp	eax, -1
	jne	page_found

	stc
	ret
page_found:
	mov	ecx, PagesMap
	mov	edx, eax
	shr	edx, 12			; EDX = bit offset.
	bts	dword ptr fs:[ecx], edx	; Set bit specified by EDX.

	clc
	ret
AllocPage	ENDP


;-----------------------------------------------------------------------------
;
;	I:
;	O: EAX = physical address.
;		 -1 if no free pages.
;
;	Searches in pages map and returns first free physical page found.
;
;-----------------------------------------------------------------------------
FirstFreePage	PROC	USES ecx edx

	mov	ecx, PagesMap	; FS:ECX -> pages map.
	sub	eax, eax	; EAX = page number (address >> 12)
find_free:
	mov	edx, fs:[ecx]
	cmp	edx, -1
	jne	specify_free

	add	ecx, 4
	add	eax, 32
	cmp	eax, MemSize
	jna	find_free

	mov	eax, -1
	jmp	end_find_free

specify_free:
	shr	edx, 1
	jnc	free_found

	inc	eax
	jmp	specify_free

free_found:
	shl	eax, 12
end_find_free:

	ret
FirstFreePage	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = page to free.
;	O:
;
;	Frees previously allocated page. Doesn't check if the page was
; previously allocated.
;
;-----------------------------------------------------------------------------
PUBLIC	FreePage
FreePage	PROC	USES ecx edx
	mov	ecx, PagesMap
	mov	edx, eax
	shr	edx, 12

	btr	dword ptr fs:[ecx], edx	; Clear bit specified by EDX.
	ret
FreePage	ENDP


;-----------------------------------------------------------------------------
;
;	Returns number of free physical pages left.
;
;	I:
;	O:	EAX = number of pages.
;
; (!) Assumed that linear memory space is always enough.
;
;-----------------------------------------------------------------------------
PUBLIC	LeftFreePages
LeftFreePages	PROC	USES ebx ecx edx esi
	mov	ecx, PagesMap		; FS:ECX -> pages in loop.
	sub	eax, eax		; EAX = count of free pages.
	mov	ebx, MemSize		; EBX = memory count

count_pages:
	mov	edx, fs:[ecx]
	add	ecx, 4
	test	edx, edx
	jz	adjust_ptr

; Count busy pages.
add_count:
	inc	eax
	lea	esi, [edx-1]
	and	edx, esi
	jnz	add_count

adjust_ptr:
	sub	ebx, 32
	jg	count_pages

	neg	eax
	add	eax, MemSize

; Subtract number of pages that would need to page page directories.
	mov	edx, eax
	shr	edx, 10
	inc	edx
	sub	eax, edx

	ret
LeftFreePages	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = attributes
;	O: CF = 0 - OK, EAX = linear address of a page.
;	   CF = 1 - error,
;		EAX = -1 if not enough free pages for page of for page dir.
;		    = -2 if all heap is already used.
;
;	Allocates page from OS heap.
;
;-----------------------------------------------------------------------------
PUBLIC	HeapAllocPage
HeapAllocPage	PROC	USES ecx edx ebx esi edi
	and	eax, 0FFFh
	mov	esi, eax
	call	AllocPage
	cmp	eax, -1
	jne	map_page
	stc
	ret

map_page:
	or	esi, eax
	;
	; Search in OS heap bitmap for first available entry.
	;
	mov	edi, OsHeapBitmap
	mov	ecx, OS_HEAP
find_free:
	mov	edx, fs:[edi]
	cmp	edx, -1
	jne	specify_free

	add	edi, 4
	add	ecx, 20000h
	cmp	ecx, OS_HEAP + OS_HEAP_SIZE - 1
	jna	find_free

	mov	eax, -2
	stc
	ret

specify_free:
	shr	edx, 1
	jnc	free_found

	add	ecx, 1000h
	jmp	specify_free
free_found:
	mov	eax, esi		; Apply given attributes.
	call	MapPage
	mov	eax, ecx
	jnc	set_busy

	call	CreatePageTable
	jnc	free_found

	mov	eax, -1
	ret
set_busy:

	mov	ecx, OsHeapBitmap
	mov	edx, eax
	and	edx, NOT OS_HEAP
	shr	edx, 12			; EDX = bit offset.
	bts	dword ptr fs:[ecx], edx	; Set bit specified by EDX.
end_find_free:

	cmp	eax, OsHeapEnd
	jb	finish
	mov	OsHeapEnd, eax
	add	OsHeapEnd, 1000h	; Update heap end.
finish:
	clc
	ret
HeapAllocPage	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = attributes
;	O: CF = 0 - OK, EAX = linear address of a page.
;	   CF = 1 - error,
;		EAX = -1 if not enough free pages for page of for page dir.
;		    = -2 if all heap is already used.
;
;	Allocates page from OS heap and fill with 0s.
;
;-----------------------------------------------------------------------------
PUBLIC	HeapAllocZPage
HeapAllocZPage	PROC	USES es ecx edi
	call	HeapAllocPage
	jnc	@F
	ret
@@:
	cld
	mov	edi, eax
	push	fs
	pop	es
	mov	ecx, 400h
	sub	eax, eax
		rep	stosd

	lea	eax, [edi - 1000h]	; Restore EAX.

	clc
	ret
HeapAllocZPage	ENDP


;-----------------------------------------------------------------------------
;
;	Frees previously allocated page from OS heap.
;
;	I: EAX = linear address of a page.
;	O: CF = 0 OK
;	        1 wrong page.
;
;-----------------------------------------------------------------------------
PUBLIC	HeapFreePage
HeapFreePage	PROC	USES eax ecx edx

; If page is not within OS_HEAP, return error.
	cmp	eax, OS_HEAP
	jnb	@F
	stc
	ret

@@:
	cmp	eax, OS_HEAP + OS_HEAP_SIZE
	jna	@F
	stc
	ret

@@:
	mov	ecx, OsHeapBitmap
	mov	edx, eax
	and	edx, NOT OS_HEAP
	shr	edx, 12

	btr	dword ptr fs:[ecx], edx	; Clear bit specified by EDX.
	jc	@F			; If page was allocated, go on.
	stc
	ret

@@:
	call	LinearToPhysical	; If page was mappped correctly, go on.
	jnc	@F
	ret

@@:
	call	FreePage
	clc
	ret
HeapFreePage	ENDP


;-----------------------------------------------------------------------------
;
;	Allocates contiguous linear memory from OS heap.
;
;	I: EAX = attributes
;	   ECX = size
;	O: CF = 0 - OK, EAX = linear address of a first page.
;	   CF = 1 - error,
;		EAX = -1 if not enough free pages for page of for page dir.
;		    = -2 if all heap is already used.
;
;	(!) Allocated memory is always page-aligned.
;
;-----------------------------------------------------------------------------
PUBLIC	HeapAllocMem
HeapAllocMem	PROC	USES ebx ecx edx esi edi
LOCAL	HeapCount: DWORD
LOCAL	HeapStart: DWORD

	and	eax, 0FFFh
	mov	esi, eax		; ESI holds attributes.


	mov	eax, ecx
	call	HeapGetRegion
	jnc	@F
	ret				; Error code is already in EAX.

; Heap region is OK. Allocate physical memory.
@@:
	mov	HeapStart, eax
	mov	HeapCount, ecx
	add	HeapCount, eax		; HeapCount = last lin. page to map.

	mov	edi, eax		; Keep start linear address.
	mov	ecx, eax

	mov	edx, NOT OS_HEAP
	and	edx, ecx
	shr	edx, 12			; EDX = pointer in heap bitmap
	mov	ebx, OsHeapBitmap	; FS:EBX -> heap bitmap.

alloc_next:
	call	AllocPage		; Allocate physical page.
	jc	not_enough_physical

map_page:
	or	eax, esi		; Apply atributes.
	call	MapPage
	jnc	set_busy

; MapPage failed: need to create a new page table.
	xchg	eax, ecx
	call	CreatePageTable
	xchg	eax, ecx
	jc	not_enough_physical
	jmp	map_page

set_busy:
	bts	dword ptr fs:[ebx], edx

	add	ecx, 1000h
	inc	edx
	cmp	ecx, HeapCount
	jb	alloc_next

	mov	eax, edi
	clc
	ret

not_enough_physical:
	;
	; Free pages back from ECX to EDI.
	;
	mov	eax, ecx
	call	HeapFreePage
	sub	ecx, 1000h
	cmp	ecx, edi
	jnb	not_enough_physical

	mov	eax, -1
	stc
	ret
HeapAllocMem	ENDP


;-----------------------------------------------------------------------------
;
;	Gets a required amount of linear memory without allocating physical.
;
;	I: EAX = size in bytes.
;	O: CF = 0 - OK, EAX = start address.
;	      = 1 - error, all heap exhausted.
;
;-----------------------------------------------------------------------------
PUBLIC	HeapGetRegion
HeapGetRegion	PROC	USES ebx ecx edx esi edi
LOCAL	HeapCount: dword, BitCount: dword

; Don't do that.
IF 0
; If requested more than 4M - 4K, return error.
	cmp	eax, 3FF000h
	jna	@F
	mov	eax, -2
	stc
	ret
ENDIF

@@:
	;
	; Search in OS heap bitmap for first available entry.
	;
	mov	edi, OsHeapBitmap
	mov	HeapCount, OS_HEAP

	sub	ebx, ebx		; Reset EBX - pages count.
find_free:

	mov	edx, fs:[edi]
	cmp	edx, -1
	jne	check_free

go_on_look:
	add	edi, 4
	add	HeapCount, 20000h
	cmp	HeapCount, OS_HEAP + OS_HEAP_SIZE - 1
	jna	find_free

	mov	eax, -2
	stc
	ret

check_free:
	test	edx, edx
	jnz	reset_bit_count

	mov	esi, ecx
	sub	esi, ebx
	add	esi, HeapCount
	cmp	esi, OS_HEAP + OS_HEAP_SIZE
	jb	@F

	mov	eax, -2
	stc
	ret

@@:
	add	ebx, 20000h
	add	HeapCount, 20000h

	cmp	ebx, ecx
	jnb	mem_found
	add	edi, 4
	jmp	find_free

reset_bit_count:
	mov	BitCount, 32
count_0s:
	shr	edx, 1
	jnc	@F
	sub	ebx, ebx
	jmp	enough_pages?
@@:
	add	ebx, 1000h
enough_pages?:
	add	HeapCount, 1000h
	cmp	ebx, ecx
	jnb	mem_found

	cmp	HeapCount, OS_HEAP + OS_HEAP_SIZE - 1
	jna	count_next_bit

	mov	eax, -2
	stc
	ret

count_next_bit:
	dec	BitCount
	jnz	count_0s

	add	edi, 4
	jmp	find_free

mem_found:
; If region crosses 4M boundary, start looking again from the 4M boundary.
	mov	eax, HeapCount
	and	eax, 3FFFFFh
	cmp	eax, ebx
	jnb	@F

	sub	ebx, ebx			; Reset page count
	and	HeapCount, NOT 3FFFFFh		; Patch heap count
	mov	edi, HeapCount			; Set bitmap pointer
	sub	edi, OS_HEAP
	shr	edi, 12 + 3
	add	edi, OsHeapBitmap
	jmp	find_free

@@:
	;
	; Return start linear address.
	;
	mov	ecx, HeapCount
	sub	ecx, ebx		
	mov	eax, ecx

	clc
	ret
HeapGetRegion	ENDP


;-----------------------------------------------------------------------------
;
;	Frees linear region of memory.
;
;	I: EAX = linear address.
;	   ECX = size (bytes).
;
;-----------------------------------------------------------------------------
PUBLIC	HeapFreeMem
HeapFreeMem	PROC	USES eax ecx
@@:
	call	HeapFreePage
	add	eax, 1000h
	sub	ecx, 1000h
	jg	@B

	ret
HeapFreeMem	ENDP


CODE32	ENDS

END
