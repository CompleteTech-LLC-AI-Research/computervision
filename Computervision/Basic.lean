structure RGB (α : Type) where
  r : α
  g : α
  b : α
  deriving Repr, DecidableEq

structure YCbCr (α : Type) where
  y  : α
  cb : α
  cr : α
  deriving Repr, DecidableEq

instance [Inhabited α] : Inhabited (RGB α) where
  default := ⟨default, default, default⟩

instance [Inhabited α] : Inhabited (YCbCr α) where
  default := ⟨default, default, default⟩

-- Example: Full-range BT.601 / JFIF with Float
namespace FloatConv

def rgbToYCbCr (c : RGB Float) : YCbCr Float :=
  let y  :=  0.299    * c.r + 0.587    * c.g + 0.114    * c.b
  let cb := -0.168736 * c.r - 0.331264 * c.g + 0.5      * c.b + 128.0
  let cr :=  0.5      * c.r - 0.418688 * c.g - 0.081312 * c.b + 128.0
  ⟨y, cb, cr⟩

def yCbCrToRGB (c : YCbCr Float) : RGB Float :=
  let cbShift := c.cb - 128.0
  let crShift := c.cr - 128.0
  let r := c.y + 1.402    * crShift
  let g := c.y - 0.344136 * cbShift - 0.714136 * crShift
  let b := c.y + 1.772    * cbShift
  ⟨r, g, b⟩

def clampToUInt8 (x : Float) : UInt8 :=
  if x < 0.0 then 0
  else if x > 255.0 then 255
  else x.toUInt64.toUInt8

def rgbUInt8ToFloat (c : RGB UInt8) : RGB Float :=
  ⟨c.r.toNat.toFloat, c.g.toNat.toFloat, c.b.toNat.toFloat⟩

def rgbFloatToUInt8 (c : RGB Float) : RGB UInt8 :=
  ⟨clampToUInt8 c.r, clampToUInt8 c.g, clampToUInt8 c.b⟩

def yCbCrUInt8ToFloat (c : YCbCr UInt8) : YCbCr Float :=
  ⟨c.y.toNat.toFloat, c.cb.toNat.toFloat, c.cr.toNat.toFloat⟩

def yCbCrFloatToUInt8 (c : YCbCr Float) : YCbCr UInt8 :=
  ⟨clampToUInt8 c.y, clampToUInt8 c.cb, clampToUInt8 c.cr⟩

/-- Convert RGB UInt8 directly to YCbCr UInt8 via BT.601 -/
def rgb8ToYCbCr8 (c : RGB UInt8) : YCbCr UInt8 :=
  yCbCrFloatToUInt8 (rgbToYCbCr (rgbUInt8ToFloat c))

/-- Convert YCbCr UInt8 directly to RGB UInt8 via BT.601 -/
def yCbCr8ToRGB8 (c : YCbCr UInt8) : RGB UInt8 :=
  rgbFloatToUInt8 (yCbCrToRGB (yCbCrUInt8ToFloat c))

end FloatConv
