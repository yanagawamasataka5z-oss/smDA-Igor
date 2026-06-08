#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma version=4.01

// =============================================================================
// SMI_Main.ipf - smDA: single-molecule Dynamics Analyzer
// =============================================================================
// 
// Version 4.0.1
// =============================================================================
//
// ★★★  ★★★
// Igor ProFile > Open File > Procedure:
//   1. SMI_Core.ipf        - 
//   2. SMI_FitFunctions.ipf - 
//   3. SMI_DataLoader.ipf   - 
//   4. SMI_Panel.ipf        - GUI
//   5. SMI_Diffusion.ipf    - 
//   6. SMI_Intensity.ipf    - 
//   7. SMI_Statistics.ipf   - 
//   8. SMI_Kinetics.ipf     - 
//   9. SMI_Timelapse.ipf    - On-rate
//  10. SMI_Comparison.ipf   - 
//  11. SMI_Layout.ipf       - 
//  12. SMI_Colocalization.ipf - 
//  13. SMI_Segmentation.ipf - 
//  14. (removed from public release)
//  15. SMI_Main.ipf         - 
//
// SMI_Initialize() 
// =============================================================================

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Menu "smDA"
	"Initialize smDA/1", SMI_Initialize()
	"Open Panel/2", SMI_CreatePanel()
	"-"
	Submenu "Window Control"
		"Clear All Graphs/9", ClearAllGraphs()
		"Clear All Tables/8", ClearAllTables()
		"Clear All Layouts/7", ClearAllLayouts()
		"Kill All Waves/0", SMI_KillAllWaves()
	End
	"-"
	Submenu "Data Management"
		"Rename Folders", SMI_RenameFoldersFromList()
		"Initialize Parameters", InitializeGlobalParameters()
	End
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function SMI_Initialize()
	Print "=== smDA - single-molecule Dynamics Analyzer v4.0.1 ==="
	Print "Initializing..."
	
	// 
	InitializeGlobalParameters()
	
	Print "Initialization complete."
	Print ""
	Print "Run SMI_CreatePanel() to open the GUI panel."
	Print ""
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function SMI_CreatePanel()
	CreateMainPanel()
End

// =============================================================================
// Panel, DataLoader
// =============================================================================

// -----------------------------------------------------------------------------
// MSD
// -----------------------------------------------------------------------------
Function SMI_AnalyzeMSD(SampleName, fitType)
	String SampleName
	Variable fitType  // 0: free, 1: confined, 2: confined+error
	
	Print "=== MSD Analysis ==="
	
	// MSD
	CalculateMSD(SampleName)
	
	// 
	FitMSD_Safe(SampleName, fitType)
	
	// 
	DisplayMSDGraph(SampleName)
	DisplayDiffusionResultsGraph(SampleName)
	
	Print "MSD analysis complete."
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function SMI_AnalyzeIntensity(SampleName, maxOligomers)
	String SampleName
	Variable maxOligomers
	
	Print "=== Intensity Analysis ==="
	
	// LogNorm
	NVAR/Z cSumLogNorm = root:cSumLogNorm
	Variable useLogScale = 0
	if(NVAR_Exists(cSumLogNorm) && cSumLogNorm == 1)
		useLogScale = 1
	endif
	
	// Step 1: 
	Print "  Creating intensity histogram..."
	if(useLogScale)
		CreateIntensityHistogramLog(SampleName)
	else
		CreateIntensityHistogram(SampleName)
	endif
	
	// Step 2: 
	NVAR/Z cFixMean = root:cFixMean
	NVAR/Z cFixSD = root:cFixSD
	
	Variable fixMean = 0, fixSD = 0
	if(NVAR_Exists(cFixMean))
		fixMean = cFixMean
	endif
	if(NVAR_Exists(cFixSD))
		fixSD = cFixSD
	endif
	
	Print "  Running global fitting..."
	GlobalFitIntensity(SampleName, maxOligomers, fixMean, fixSD)
	
	// Step 3: 
	DisplayIntensityHistGraph(SampleName)
	DisplayPopulationGraph(SampleName)
	
	Print "Intensity analysis complete."
End

// -----------------------------------------------------------------------------
// Step Size
// -----------------------------------------------------------------------------
Function SMI_AnalyzeStepSize(SampleName)
	String SampleName
	
	Print "=== Step Size Analysis ==="
	
	// 
	NVAR/Z deltaTMin = root:StepDeltaTMin
	NVAR/Z deltaTMax = root:StepDeltaTMax
	NVAR/Z minStates = root:StepFitMinStates
	NVAR/Z maxStates = root:StepFitMaxStates
	
	Variable dtMin = NVAR_Exists(deltaTMin) ? deltaTMin : 1
	Variable dtMax = NVAR_Exists(deltaTMax) ? deltaTMax : 5
	Variable sMin = NVAR_Exists(minStates) ? minStates : 1
	Variable sMax = NVAR_Exists(maxStates) ? maxStates : 3
	
	// HMM
	NVAR/Z cHMM = root:cHMM
	Variable isHMM = NVAR_Exists(cHMM) ? cHMM : 0
	
	if(isHMM)
		// HMM Step Size 
		Print "  Calculating Step Size Histogram (HMM mode)..."
		CalculateStepSizeHistogramHMM(SampleName)
		// 
		Print "  Fitting Step Size distribution..."
		FitStepSizeDistributionHMM(SampleName, sMax)
		// 
		DisplayStepSizeHistogramHMM(SampleName)
	else
		// Non-HMM: AIC
		Print "  Running AIC-based Step Size fitting..."
		FitStepSizeWithAIC_NonHMM(SampleName, sMin, sMax)
	endif
	
	// HeatmapΔt max >= 2 
	NVAR/Z StepDeltaTMax = root:StepDeltaTMax
	if(NVAR_Exists(StepDeltaTMax) && StepDeltaTMax >= 2)
		Print "  Creating MSD Heatmap..."
		CreateMSDHeatmap(SampleName)
	else
		Print "  Skipping Heatmap (Δt max < 2)"
	endif
	
	Print "Step Size analysis complete."
End

// -----------------------------------------------------------------------------
// Localization Precision
// -----------------------------------------------------------------------------
Function SMI_AnalyzeLP(SampleName)
	String SampleName
	
	Print "=== Localization Precision Analysis ==="
	
	// LP 
	CalculateLPHistogram(SampleName)
	
	// 
	DisplayLPHistogram(SampleName)
	
	Print "LP analysis complete."
End

// -----------------------------------------------------------------------------
// Density
// -----------------------------------------------------------------------------
Function SMI_AnalyzeDensity(SampleName)
	String SampleName
	
	Print "=== Density Analysis (Ripley K-function) ==="
	
	// Density
	Density_Gcount(SampleName)
	
	// 
	DisplayDensityGcount(SampleName)
	
	Print "Density analysis complete."
End

// -----------------------------------------------------------------------------
// Molecular Density
// -----------------------------------------------------------------------------
Function SMI_AnalyzeMolDensity(SampleName)
	String SampleName
	
	Print "=== Molecular Density Analysis ==="
	
	// CalculateMolecularDensityHMM
	Variable result
	result = CalculateMolecularDensity(SampleName)
	
	// 
	if(result == 1)
		DisplayMolecularDensity(SampleName)
		Print "Molecular Density analysis complete."
	else
		Print "Molecular Density analysis skipped (prerequisites not met)"
	endif
	
	return result
End
