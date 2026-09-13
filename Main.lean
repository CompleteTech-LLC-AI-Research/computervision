import Computervision

-- 1. Pixel round-trip test (pure red):
#eval FloatConv.rgb8ToYCbCr8 ⟨255, 0, 0⟩
-- Output: { y := 76, cb := 85, cr := 255 }

#eval FloatConv.yCbCr8ToRGB8 ⟨76, 85, 255⟩
-- Output: { r := 254, g := 0, b := 0 } (1-bit round-trip quantization)

-- 2. Create a 2x2 test image and convert it:
def testImg : Image (RGB UInt8) :=
  Image.ofFn 2 2 fun x y =>
    if x == y then ⟨255, 0, 0⟩ else ⟨0, 255, 0⟩

#eval testImg.toYCbCr8

-- 3. EMVA 1288 Characterization example:
def demoSensor : EMVA1288.SensorParams := {
  gainK := 0.25,               -- 0.25 DN / e⁻ (4.0 e⁻ / DN)
  readNoise_e := 4.2,          -- 4.2 e⁻ readout noise
  saturationCap_e := 10000.0,  -- 10,000 e⁻ full-well capacity
  darkOffset_DN := 12.5,       -- 12.5 DN dark offset
  darkVariance_DN2 := 1.187    -- dark temporal variance
}

def demoReport : EMVA1288.Report := {
  params := demoSensor,
  spatial := some {
    dsnu_DN := 0.95,
    dsnu_e := 3.8,
    prnu_percent := 0.72
  }
}

#eval IO.print (EMVA1288.formatReport demoReport)

def main : IO Unit := do
  IO.println "=== Computer Vision & EMVA 1288 in Lean 4 ==="
  IO.println s!"Pure red in YCbCr: {repr (FloatConv.rgb8ToYCbCr8 ⟨255, 0, 0⟩)}"
  IO.print (EMVA1288.formatReport demoReport)
