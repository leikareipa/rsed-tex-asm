;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Parses the manifesto (.$FT) file.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Parses the project's manifesto file to locate any directives to modify the game's palette, and
;;; applies those modifications to the program's internal palette.
;;;
;;; Note that you should only run this routine once you've parsed the command line to find the project's name, etc.
;;;
;;; EXPECTS:
;;;     - gs to point to the pixel buffer's segment.
;;;	- es to point to the video memory buffer's segment.
;;; DESTROYS:
;;;     - al, ecx, di, si
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Apply_Palette_Modifications_From_Manifesto
    ret
