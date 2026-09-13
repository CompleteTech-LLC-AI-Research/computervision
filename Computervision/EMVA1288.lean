import Computervision.Image

/-!
# EMVA Standard 1288 for Machine Vision Sensors and Cameras

This module implements the mathematical and measurement model specified by
the European Machine Vision Association (EMVA) Standard 1288.

### Key Equations:
1. **System Gain (K)**: `K = (σ²_y - σ²_y.dark) / (μ_y - μ_y.dark)` [DN / e⁻]
2. **Readout Noise (σ_read,e)**: `σ_read,e = √(max(0, σ²_y.dark - σ²_quant)) / K` [e⁻]
   where `σ²_quant = 1 / 12 ≈ 0.08333 DN²`
3. **Saturation Capacity (μ_e.sat)**: `μ_e.sat = (μ_y.sat - μ_y.dark) / K` [e⁻]
4. **Absolute Sensitivity Threshold (μ_e.min)**: `μ_e.min = σ_read,e + 0.5` [e⁻]
5. **Maximum SNR**: `SNR_max = √(μ_e.sat)` (or `20 · log10(SNR_max)` in dB)
6. **Dynamic Range (DR)**: `DR = μ_e.sat / μ_e.min` (or `20 · log10(DR)` in dB)
-/

namespace EMVA1288

/-- Quantization noise variance for 1-LSB quantization: σ²_quant = 1 / 12 -/
def quantVariance : Float :=
  1.0 / 12.0

/-- Characterized EMVA 1288 sensor parameters -/
structure SensorParams where
  /-- Overall system gain K in DN / e⁻ -/
  gainK : Float
  /-- Readout noise in electrons (e⁻) -/
  readNoise_e : Float
  /-- Saturation capacity / Full well capacity in electrons (e⁻) -/
  saturationCap_e : Float
  /-- Dark offset μ_y.dark in DN -/
  darkOffset_DN : Float
  /-- Dark temporal variance σ²_y.dark in DN² -/
  darkVariance_DN2 : Float
  deriving Repr

namespace SensorParams

/-- Conversion factor / Responsiveness in e⁻ / DN (inverse of system gain K) -/
def conversionFactor (p : SensorParams) : Float :=
  1.0 / p.gainK

/-- Temporal readout noise in Digital Numbers (DN) -/
def readNoise_DN (p : SensorParams) : Float :=
  Float.sqrt (max 0.0 p.darkVariance_DN2)

/-- Absolute sensitivity threshold (signal at SNR = 1) in electrons (e⁻) -/
def sensitivityThreshold_e (p : SensorParams) : Float :=
  p.readNoise_e + 0.5

/-- Maximum Signal-to-Noise Ratio (linear) -/
def snrMax (p : SensorParams) : Float :=
  Float.sqrt (max 0.0 p.saturationCap_e)

/-- Maximum Signal-to-Noise Ratio in dB -/
def snrMaxDb (p : SensorParams) : Float :=
  20.0 * Float.log10 (snrMax p)

/-- Dynamic Range (linear): saturation capacity / absolute sensitivity threshold -/
def dynamicRange (p : SensorParams) : Float :=
  p.saturationCap_e / (sensitivityThreshold_e p)

/-- Dynamic Range in dB -/
def dynamicRangeDb (p : SensorParams) : Float :=
  20.0 * Float.log10 (dynamicRange p)

end SensorParams

/-- Spatial non-uniformity metrics according to EMVA 1288 -/
structure NonUniformity where
  /-- Dark Signal Non-Uniformity (DSNU) in Digital Numbers (DN) -/
  dsnu_DN : Float
  /-- Dark Signal Non-Uniformity (DSNU) in electrons (e⁻) -/
  dsnu_e : Float
  /-- Photo Response Non-Uniformity (PRNU) in percentage (%) -/
  prnu_percent : Float
  deriving Repr

/-- Complete EMVA 1288 Characterization Report -/
structure Report where
  params : SensorParams
  spatial : Option NonUniformity := none
  deriving Repr

/-- Format an EMVA 1288 Report into a clean summary table -/
def formatReport (r : Report) : String :=
  let p := r.params
  let base :=
    s!"================== EMVA 1288 SENSOR REPORT ==================\n" ++
    s!"System Gain (K):                 {p.gainK} DN/e⁻ ({p.conversionFactor} e⁻/DN)\n" ++
    s!"Readout Noise (σ_read):         {p.readNoise_e} e⁻ ({p.readNoise_DN} DN)\n" ++
    s!"Saturation Capacity (μ_e.sat):   {p.saturationCap_e} e⁻\n" ++
    s!"Sensitivity Threshold (μ_e.min): {p.sensitivityThreshold_e} e⁻\n" ++
    s!"Maximum SNR (SNR_max):           {p.snrMax} ({p.snrMaxDb} dB)\n" ++
    s!"Dynamic Range (DR):              {p.dynamicRange} ({p.dynamicRangeDb} dB)\n" ++
    s!"Dark Offset (μ_y.dark):          {p.darkOffset_DN} DN\n"
  match r.spatial with
  | none =>
    base ++ s!"============================================================\n"
  | some s =>
    base ++
    s!"----------------- Spatial Non-Uniformity -------------------\n" ++
    s!"DSNU:                            {s.dsnu_DN} DN ({s.dsnu_e} e⁻)\n" ++
    s!"PRNU:                            {s.prnu_percent} %\n" ++
    s!"============================================================\n"

/-!
### EMVA 1288 Measurement Algorithms (Two-Image Method)
-/

/-- Compute the temporal mean and variance from two flat-field captures under identical conditions.
    Using (imgA - imgB) eliminates fixed spatial patterns (PRNU/DSNU), isolating temporal noise:
    Var(A - B) = Var(A) + Var(B) = 2 · σ²_temporal
-/
def emvaTemporalStats (imgA imgB : Image Float) : Float × Float :=
  let n := imgA.pixels.size
  if n == 0 || n != imgB.pixels.size then
    (0.0, 0.0)
  else Id.run do
    -- 1. Temporal mean signal: average of (imgA + imgB) / 2
    let mut sumMean := 0.0
    for i in [:n] do
      let avgPix := (imgA.pixels[i]! + imgB.pixels[i]!) / 2.0
      sumMean := sumMean + avgPix
    let meanY := sumMean / n.toFloat

    -- 2. Temporal variance: variance of (imgA - imgB) / 2
    let mut sumDiff := 0.0
    let mut sumDiffSq := 0.0
    for i in [:n] do
      let diff := imgA.pixels[i]! - imgB.pixels[i]!
      sumDiff := sumDiff + diff
      sumDiffSq := sumDiffSq + diff * diff

    let meanDiff := sumDiff / n.toFloat
    let varDiff := if n > 1 then
      (sumDiffSq - n.toFloat * meanDiff * meanDiff) / (n.toFloat - 1.0)
    else
      0.0

    return (meanY, varDiff / 2.0)

/-- Compute the spatial mean and sample variance across an image's pixels -/
def spatialStats (img : Image Float) : Float × Float :=
  let n := img.pixels.size
  if n == 0 then
    (0.0, 0.0)
  else Id.run do
    let mut sum := 0.0
    let mut sumSq := 0.0
    for i in [:n] do
      let val := img.pixels[i]!
      sum := sum + val
      sumSq := sumSq + val * val

    let mean := sum / n.toFloat
    let variance := if n > 1 then
      (sumSq - n.toFloat * mean * mean) / (n.toFloat - 1.0)
    else
      0.0
    return (mean, variance)

/-- Characterize sensor parameters from:
    - `(darkA, darkB)`: two dark images (lens capped / exposure without light)
    - `(illumA, illumB)`: two flat-field illuminated images
    - `satDN`: the saturation digital level (e.g., 255.0 for 8-bit, 4095.0 for 12-bit)
-/
def characterizeFromPairs
    (darkA darkB : Image Float)
    (illumA illumB : Image Float)
    (satDN : Float) : Option SensorParams :=
  let (meanDark, varDark) := emvaTemporalStats darkA darkB
  let (meanIllum, varIllum) := emvaTemporalStats illumA illumB

  let deltaMean := meanIllum - meanDark
  let deltaVar  := varIllum - varDark

  if deltaMean <= 0.0 || deltaVar <= 0.0 then
    none
  else
    -- Overall system gain K = Δσ²_y / Δμ_y
    let k := deltaVar / deltaMean

    -- Readout noise in electrons: σ_read,e = √(max(0, σ²_dark - σ²_quant)) / K
    let netDarkVar := max 0.0 (varDark - quantVariance)
    let readNoiseE := Float.sqrt netDarkVar / k

    -- Saturation capacity in electrons: μ_e.sat = (μ_y.sat - μ_y.dark) / K
    let satCapE := max 0.0 (satDN - meanDark) / k

    some {
      gainK            := k
      readNoise_e      := readNoiseE
      saturationCap_e  := satCapE
      darkOffset_DN    := meanDark
      darkVariance_DN2 := varDark
    }

/-- Compute spatial non-uniformities (DSNU and PRNU) using averaged pairs -/
def measureSpatialNonUniformity
    (darkA darkB : Image Float)
    (illumA illumB : Image Float)
    (params : SensorParams) : Option NonUniformity :=
  let n := darkA.pixels.size
  if n == 0 || n != darkB.pixels.size || n != illumA.pixels.size || n != illumB.pixels.size then
    none
  else
    -- Averaged dark image
    let avgDarkArr : Array Float := Id.run do
      let mut arr := Array.mkEmpty n
      for i in [:n] do
        arr := arr.push ((darkA.pixels[i]! + darkB.pixels[i]!) / 2.0)
      return arr
    let avgDark : Image Float := ⟨darkA.width, darkA.height, avgDarkArr⟩

    -- Averaged illuminated image minus dark offset
    let correctedArr : Array Float := Id.run do
      let mut arr := Array.mkEmpty n
      for i in [:n] do
        let avgIllum := (illumA.pixels[i]! + illumB.pixels[i]!) / 2.0
        let darkVal  := avgDarkArr[i]!
        arr := arr.push (avgIllum - darkVal)
      return arr
    let correctedIllum : Image Float := ⟨illumA.width, illumA.height, correctedArr⟩

    -- DSNU is spatial standard deviation of averaged dark image
    let (_, varDarkSpatial) := spatialStats avgDark
    let dsnuDN := Float.sqrt (max 0.0 varDarkSpatial)
    let dsnuE  := dsnuDN / params.gainK

    -- PRNU is spatial standard deviation of corrected illuminated image divided by mean signal
    let (meanSignal, varSignalSpatial) := spatialStats correctedIllum
    if meanSignal <= 0.0 then
      none
    else
      let stdSignalSpatial := Float.sqrt (max 0.0 varSignalSpatial)
      let prnuPercent := (stdSignalSpatial / meanSignal) * 100.0
      some {
        dsnu_DN      := dsnuDN
        dsnu_e       := dsnuE
        prnu_percent := prnuPercent
      }

/-- Run full EMVA 1288 analysis producing a complete Report -/
def runEMVA1288Analysis
    (darkA darkB : Image Float)
    (illumA illumB : Image Float)
    (satDN : Float) : Option Report :=
  match characterizeFromPairs darkA darkB illumA illumB satDN with
  | none => none
  | some p =>
    let spatial := measureSpatialNonUniformity darkA darkB illumA illumB p
    some { params := p, spatial := spatial }

end EMVA1288
