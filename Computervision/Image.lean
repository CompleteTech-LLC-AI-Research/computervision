import Computervision.Basic

structure Image (α : Type) where
  width  : Nat
  height : Nat
  pixels : Array α
  deriving Repr

namespace Image

/-- Create an image with a generator function (x, y) ↦ pixel -/
def ofFn (width height : Nat) (f : Nat → Nat → α) : Image α := Id.run do
  let mut arr := Array.mkEmpty (width * height)
  for y in [:height] do
    for x in [:width] do
      arr := arr.push (f x y)
  return ⟨width, height, arr⟩

/-- Safe coordinate access -/
def get? (img : Image α) (x y : Nat) : Option α :=
  if x < img.width && y < img.height then
    img.pixels[y * img.width + x]?
  else
    none

/-- Default fallback coordinate access -/
def getD [Inhabited α] (img : Image α) (x y : Nat) : α :=
  if x < img.width && y < img.height then
    img.pixels.getD (y * img.width + x) default
  else
    default

/-- Functional point-wise map -/
def map (f : α → β) (img : Image α) : Image β :=
  ⟨img.width, img.height, img.pixels.map f⟩

/-- Convert an RGB Float image to YCbCr Float -/
def toYCbCr (img : Image (RGB Float)) : Image (YCbCr Float) :=
  img.map FloatConv.rgbToYCbCr

/-- Convert a YCbCr Float image to RGB Float -/
def toRGB (img : Image (YCbCr Float)) : Image (RGB Float) :=
  img.map FloatConv.yCbCrToRGB

/-- Convert an RGB UInt8 image to YCbCr UInt8 -/
def toYCbCr8 (img : Image (RGB UInt8)) : Image (YCbCr UInt8) :=
  img.map FloatConv.rgb8ToYCbCr8

/-- Convert a YCbCr UInt8 image to RGB UInt8 -/
def toRGB8 (img : Image (YCbCr UInt8)) : Image (RGB UInt8) :=
  img.map FloatConv.yCbCr8ToRGB8

end Image
