#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma version=2.0
// ModuleName - 

// =============================================================================
// SMI_Panel.ipf - GUI Panel for Single Molecule Imaging Analysis
// =============================================================================
// 
// Version 2.0 - Refactored with improved layout and functionality
// =============================================================================

// 
Static Constant kPanelWidth = 820
Static Constant kPanelHeight = 620
Static Constant kTabHeight = 570
Static Constant kMargin = 10
Static Constant kControlHeight = 20
Static Constant kControlSpacing = 25

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function CreateMainPanel()
	// 
	DoWindow/K SMI_MainPanel
	
	// 
	NVAR/Z framerate = root:framerate
	if(!NVAR_Exists(framerate))
		InitializeGlobalParameters()
	endif
	
	// 
	NewPanel/K=1/W=(50, 30, 50+kPanelWidth, 30+kPanelHeight) as "smDA - single-molecule Dynamics Analyzer v5.4.6"
	DoWindow/C SMI_MainPanel
	
	// 
	TabControl mainTab, pos={5, 5}, size={kPanelWidth-10, kTabHeight}
	TabControl mainTab, proc=TabProc, tabLabel(0)="Auto Analysis"
	TabControl mainTab, tabLabel(1)="Data Loading"
	TabControl mainTab, tabLabel(2)="Diffusion"
	TabControl mainTab, tabLabel(3)="Intensity"
	TabControl mainTab, tabLabel(4)="Kinetics"
	TabControl mainTab, tabLabel(5)="Colocalization"
	TabControl mainTab, tabLabel(6)="Statistics"
	TabControl mainTab, tabLabel(7)="Timelapse"
	TabControl mainTab, tabLabel(8)="Layout Single"
	TabControl mainTab, tabLabel(9)="Layout Col"

	//
	CreateCommonTab()
	CreateDataLoadingTab()
	CreateDiffusionTab()
	CreateIntensityTab()
	CreateKineticsTab()
	CreateColocalizationTab()
	CreateStatisticsTab()
	CreateTimelapseTab()
	CreateLayoutTab()
	CreateLayoutColTab()

	//
	TitleBox statusBar, pos={kMargin, kPanelHeight-25}, size={kPanelWidth-2*kMargin, 20}
	TitleBox statusBar, title="Ready", frame=0, fStyle=2
	
	// Common
	ShowTab(0)
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function TabProc(ctrlName, tabNum) : TabControl
	String ctrlName
	Variable tabNum
	
	ShowTab(tabNum)
	return 0
End

static Function ShowTab(tabNum)
	Variable tabNum
	
	Variable i, j
	String ctrlList, ctrlName
	
	// tab0_tab9_
	for(i = 0; i < 10; i += 1)
		ctrlList = ControlNameList("SMI_MainPanel", ";", "tab" + num2str(i) + "_*")
		for(j = 0; j < ItemsInList(ctrlList); j += 1)
			ctrlName = StringFromList(j, ctrlList)
			ControlInfo/W=SMI_MainPanel $ctrlName
			if(V_Flag != 0)
				ModifyControl $ctrlName, disable=1
			endif
		endfor
	endfor
	
	// 
	ctrlList = ControlNameList("SMI_MainPanel", ";", "tab" + num2str(tabNum) + "_*")
	for(j = 0; j < ItemsInList(ctrlList); j += 1)
		ctrlName = StringFromList(j, ctrlList)
		ModifyControl $ctrlName, disable=0
	endfor
End

// -----------------------------------------------------------------------------
// Tab 0: Common Parameters
// -----------------------------------------------------------------------------
static Function CreateCommonTab()
	Variable yPos = 40
	Variable xPos = kMargin + 10
	Variable groupWidth = 380
	
	// ===  ===
	GroupBox tab0_grp1, pos={xPos, yPos}, size={groupWidth, 130}, title="Measurement Parameters"
	
	yPos += 25
	SetVariable tab0_framerate, pos={xPos+10, yPos}, size={150, kControlHeight}
	SetVariable tab0_framerate, title="Rate [s/f]:", value=root:framerate
	SetVariable tab0_framerate, limits={0.001, 10, 0.0005}
	
	SetVariable tab0_framenum, pos={xPos+170, yPos}, size={90, kControlHeight}
	SetVariable tab0_framenum, title="Frames:", value=root:FrameNum
	SetVariable tab0_framenum, limits={1, 100000, 100}
	
	SetVariable tab0_scale, pos={xPos+270, yPos}, size={100, kControlHeight}
	SetVariable tab0_scale, title="Scale:", value=root:scale
	SetVariable tab0_scale, limits={0.01, 1, 0.001}, proc=UpdateDerivedParamsProc
	
	yPos += kControlSpacing
	SetVariable tab0_roiSize, pos={xPos+10, yPos}, size={110, kControlHeight}
	SetVariable tab0_roiSize, title="ROI [pix]:", value=root:ROIsize
	SetVariable tab0_roiSize, limits={1, 50, 1}
	
	SetVariable tab0_minframe, pos={xPos+130, yPos}, size={100, kControlHeight}
	SetVariable tab0_minframe, title="Min:", value=root:MinFrame
	SetVariable tab0_minframe, limits={1, 1000, 1}
	
	SetVariable tab0_pixnum, pos={xPos+240, yPos}, size={130, kControlHeight}
	SetVariable tab0_pixnum, title="Pix Num:", value=root:PixNum
	SetVariable tab0_pixnum, limits={64, 2048, 64}, proc=UpdateDerivedParamsProc
	
	yPos += kControlSpacing
	SetVariable tab0_excoef, pos={xPos+10, yPos}, size={110, kControlHeight}
	SetVariable tab0_excoef, title="ExCoef:", value=root:ExCoef
	SetVariable tab0_excoef, limits={0.0001, 1000, 0.01}
	
	SetVariable tab0_qe, pos={xPos+130, yPos}, size={100, kControlHeight}
	SetVariable tab0_qe, title="QE:", value=root:QE
	SetVariable tab0_qe, limits={0.1, 1, 0.01}
	
	// Intensity
	NVAR/Z IntensityMode = root:IntensityMode
	Variable intModePopNum = NVAR_Exists(IntensityMode) ? (IntensityMode + 1) : 2  // Photon number (mode=2)
	PopupMenu tab0_intensitymode, pos={xPos+240, yPos}, size={140, kControlHeight}
	PopupMenu tab0_intensitymode, title="Intensity:", mode=intModePopNum, value="Raw Intensity;Photon number"
	PopupMenu tab0_intensitymode, proc=IntensityModePopProc
	
	// ===  ===
	xPos = kMargin + 10 + groupWidth + 20
	yPos = 40
	GroupBox tab0_grp2, pos={xPos, yPos}, size={groupWidth, 130}, title="Data Format (AAS)"
	
	yPos += 25
	CheckBox tab0_chk_aas2, pos={xPos+10, yPos}, size={50, kControlHeight}
	CheckBox tab0_chk_aas2, title="v2", variable=root:cAAS2, proc=AAS2CheckProc
	
	CheckBox tab0_chk_aas4, pos={xPos+60, yPos}, size={50, kControlHeight}
	CheckBox tab0_chk_aas4, title="v4", variable=root:cAAS4, proc=AAS4CheckProc
	
	CheckBox tab0_chk_hmm, pos={xPos+115, yPos}, size={60, kControlHeight}
	CheckBox tab0_chk_hmm, title="HMM", variable=root:cHMM
	
	SetVariable tab0_dstate, pos={xPos+180, yPos}, size={70, kControlHeight}
	SetVariable tab0_dstate, title="n:", value=root:Dstate
	SetVariable tab0_dstate, limits={1, 5, 1}
	
	SetVariable tab0_segment, pos={xPos+260, yPos}, size={110, kControlHeight}
	SetVariable tab0_segment, title="Seg:", value=root:MaxSegment
	SetVariable tab0_segment, limits={0, 100, 1}
	
	yPos += kControlSpacing + 5
	// Row 2: Additional input format checkboxes
	CheckBox tab0_chk_trackmate, pos={xPos+10, yPos}, size={80, kControlHeight}
	CheckBox tab0_chk_trackmate, title="TrackMate", variable=root:cTrackMate
	
	CheckBox tab0_chk_vbspt, pos={xPos+115, yPos}, size={60, kControlHeight}
	CheckBox tab0_chk_vbspt, title="vbSPT", variable=root:cVBSPT
	
	CheckBox tab0_chk_image, pos={xPos+200, yPos}, size={60, kControlHeight}
	CheckBox tab0_chk_image, title="Image", variable=root:cImage
	
	PopupMenu tab0_importmode, pos={xPos+270, yPos}, size={105, 22}
	PopupMenu tab0_importmode, value="Multi TIF;Averaged TIF", mode=1
	
	yPos += kControlSpacing
	Button tab0_btn_init, pos={xPos+10, yPos}, size={115, 28}
	Button tab0_btn_init, title="Initialize", proc=InitParamsButtonProc
	
	Button tab0_btn_save, pos={xPos+130, yPos}, size={115, 28}
	Button tab0_btn_save, title="Save Settings", proc=SaveSettingsButtonProc
	Button tab0_btn_load, pos={xPos+250, yPos}, size={115, 28}
	Button tab0_btn_load, title="Load Settings", proc=LoadSettingsButtonProc
	
	// Annotation below Data Format GroupBox
	TitleBox tab0_format_info, pos={xPos+10, 173}, size={370, kControlHeight}
	TitleBox tab0_format_info, title="v2/v4: AAS version / HMM: load *_hmm.csv / n: HMM states / Image: load matching TIF"
	TitleBox tab0_format_info, frame=0, fStyle=2, fSize=10
	
	// === Single Sample Analysis1 ===
	xPos = kMargin + 10
	yPos = 190
	GroupBox tab0_grp3, pos={xPos, yPos}, size={780, 120}, title="Single Sample Analysis"
	
	// : Single Analysis
	yPos += 25
	Button tab0_btn_fullall, pos={xPos+10, yPos}, size={150, 40}
	Button tab0_btn_fullall, title="▶ Single Analysis", proc=FullAllAnalysisProc, fStyle=1, fColor=(0,0,65535)
	
	// : Sample Name
	CheckBox tab0_chk_userdefined, pos={xPos+210, yPos}, size={200, kControlHeight}
	CheckBox tab0_chk_userdefined, title="Use user-defined name", variable=root:cUseUserDefinedName
	CheckBox tab0_chk_userdefined, proc=UserDefinedNameCheckProc
	
	SetVariable tab0_samplename, pos={xPos+420, yPos}, size={350, kControlHeight}
	SetVariable tab0_samplename, title="Sample:", value=root:gSampleNameInput, disable=2
	
	yPos += 28
	TitleBox tab0_single_info, pos={xPos+210, yPos}, size={200, 35}
	TitleBox tab0_single_info, title="OFF: Use folder name / ON: Use user-defined", frame=0, fStyle=2, fSize=10
	
	// Target Sample SampleName
	TitleBox tab0_label_sample, pos={xPos+420, yPos+2}, size={80, 20}
	TitleBox tab0_label_sample, title="or Select:", frame=0, fStyle=1
	
	PopupMenu tab0_pop_sample, pos={xPos+500, yPos}, size={180, 20}
	PopupMenu tab0_pop_sample, mode=1, value=#"GetAnalyzedSampleList()"
	PopupMenu tab0_pop_sample, proc=CommonSamplePopupProc
	
	Button tab0_btn_refresh, pos={xPos+695, yPos-2}, size={70, 24}
	Button tab0_btn_refresh, title="Refresh", proc=RefreshSampleListProc
	
	// : Diffusion, Intensity, Kinetics- 
	yPos += 25
	Button tab0_btn_fulldiff, pos={xPos+15, yPos}, size={240, 28}
	Button tab0_btn_fulldiff, title="Diffusion", proc=FullDiffusionTabProc, fStyle=0
	
	Button tab0_btn_fullint, pos={xPos+270, yPos}, size={240, 28}
	Button tab0_btn_fullint, title="Intensity", proc=FullIntensityTabProc, fStyle=0
	
	Button tab0_btn_fullkin, pos={xPos+525, yPos}, size={240, 28}
	Button tab0_btn_fullkin, title="Kinetics", proc=FullKineticsTabProc, fStyle=0
	
	// === Batch Analysis ===
	xPos = kMargin + 10
	yPos = 325
	GroupBox tab0_grp5, pos={xPos, yPos}, size={780, 80}, title="Batch Analysis (Multiple Samples)"
	
	// : Auto Analysis
	yPos += 25
	Button tab0_btn_autoall, pos={xPos+10, yPos}, size={150, 40}
	Button tab0_btn_autoall, title="▶▶ Auto Analysis", proc=AutoAnalysisAllProc, fStyle=1, fColor=(36873,14755,58982)
	Button tab0_btn_autoall, help={"Run: Batch → Clear Graph → Clear Table → Average → Compare"}
	
	// : Inner GroupBox
	GroupBox tab0_grp5a, pos={xPos+175, yPos-5}, size={405, 50}, title="Individual Steps"
	
	Button tab0_btn_batch, pos={xPos+185, yPos+8}, size={110, 32}
	Button tab0_btn_batch, title="Batch", proc=BatchAnalysisProc, fStyle=1, fColor=(0,0,65535)
	
	TitleBox tab0_arrow1, pos={xPos+300, yPos+12}, size={20, 20}
	TitleBox tab0_arrow1, title="→", frame=0, fSize=14, fStyle=1
	
	Button tab0_btn_averageall, pos={xPos+325, yPos+8}, size={110, 32}
	Button tab0_btn_averageall, title="Average All", proc=AverageAllButtonProc, fStyle=1, fColor=(65535,43520,0)
	
	TitleBox tab0_arrow2, pos={xPos+440, yPos+12}, size={20, 20}
	TitleBox tab0_arrow2, title="→", frame=0, fSize=14, fStyle=1
	
	Button tab0_btn_compareall, pos={xPos+465, yPos+8}, size={110, 32}
	Button tab0_btn_compareall, title="Compare All", proc=CompareAllButtonProc, fStyle=1, fColor=(0,52428,0)

	Button tab0_btn_reanalyze, pos={xPos+595, yPos}, size={170, 40}
	Button tab0_btn_reanalyze, title="Reanalyze All", proc=ReanalyzeAllProc, fStyle=1, fColor=(51664,44236,58982)
	Button tab0_btn_reanalyze, help={"Reanalyze all existing sample folders (skip Load). For _rand, pre-loaded data."}
	
	// ===  ===
	yPos = 420
	GroupBox tab0_grp4, pos={xPos, yPos}, size={780, 55}, title="Results Summary"
	
	// 
	CheckBox tab0_chk_suppress, pos={xPos+600, yPos-2}, size={180, kControlHeight}
	CheckBox tab0_chk_suppress, title="Suppress Console Output", variable=root:cSuppressOutput
	CheckBox tab0_chk_suppress, help={"Suppress detailed output to command line for faster analysis"}
	
	yPos += 22
	TitleBox tab0_results, pos={xPos+10, yPos}, size={760, 25}
	TitleBox tab0_results, title="No analysis results", frame=1
End

// -----------------------------------------------------------------------------
// Tab 1: Data Loading
// -----------------------------------------------------------------------------
static Function CreateDataLoadingTab()
	Variable yPos = 40
	Variable xPos = kMargin + 10
	Variable groupWidth = 780
	
	// ===  ===
	GroupBox tab1_grp1, pos={xPos, yPos}, size={groupWidth, 100}, title="Sample Information"
	
	yPos += 25
	SetVariable tab1_samplename, pos={xPos+10, yPos}, size={300, kControlHeight}
	SetVariable tab1_samplename, title="Sample Name:"
	SetVariable tab1_samplename, value=root:gSampleNameInput
	
	TitleBox tab1_status, pos={xPos+330, yPos}, size={400, kControlHeight}
	TitleBox tab1_status, title="Status: Ready", frame=0, fStyle=2
	
	yPos += 30
	CheckBox tab1_chk_userdefined, pos={xPos+10, yPos}, size={200, kControlHeight}
	CheckBox tab1_chk_userdefined, title="Use user-defined name", variable=root:cUseUserDefinedName
	
	TitleBox tab1_single_info, pos={xPos+220, yPos}, size={550, kControlHeight}
	TitleBox tab1_single_info, title="OFF: Use folder name as SampleName / ON: Use user-defined SampleName", frame=0, fStyle=2, fSize=10
	
	// ===  ===
	yPos = 160
	GroupBox tab1_grp2, pos={xPos, yPos}, size={groupWidth, 150}, title="Load Data (Format settings in Common tab)"
	
	// Row 1: Load Data
	yPos += 25
	Button tab1_btn_load, pos={xPos+10, yPos}, size={140, 40}
	Button tab1_btn_load, title="Load Data", proc=LoadDataButtonProc, fStyle=1, fColor=(0,0,65535)
	
	// Row 2: Compare Lower Bound
	yPos += 48
	Button tab1_btn_compare_lb, pos={xPos+10, yPos}, size={140, 40}
	Button tab1_btn_compare_lb, title="Compare LB", proc=CompareLowerBoundProc, fStyle=1, fColor=(0,52428,0)
	Button tab1_btn_compare_lb, help={"Compare normalized Lower Bound across states within sample"}
	
	// === Trajectory ===
	yPos = 325
	GroupBox tab1_grp3, pos={xPos, yPos}, size={groupWidth, 110}, title="Trajectory"
	
	// - 
	CheckBox tab1_chk_trajectory, pos={xPos+600, yPos-2}, size={180, kControlHeight}
	CheckBox tab1_chk_trajectory, title="Run in Auto Analysis", variable=root:cRunTrajectory
	
	yPos += 30
	Button tab1_btn_trace, pos={xPos+10, yPos}, size={180, 35}
	Button tab1_btn_trace, title="Trajectory", proc=TraceButtonProc, fStyle=1, fColor=(0,0,65535)
	
	Button tab1_btn_aligned, pos={xPos+200, yPos}, size={200, 35}
	Button tab1_btn_aligned, title="Origin-Aligned Trajectory", proc=AlignedTrajectoryButtonProc, fStyle=1, fColor=(0,0,65535)
	Button tab1_btn_aligned, help={"Create trajectories with origin alignment for each state"}
	
	Button tab1_btn_avgaligned, pos={xPos+410, yPos}, size={200, 35}
	Button tab1_btn_avgaligned, title="Average Aligned Trajectory", proc=AvgAlignedTrajectoryButtonProc, fStyle=1, fColor=(65535,43520,0)
	Button tab1_btn_avgaligned, help={"Create averaged aligned trajectory from all cells"}
	
	// Aligned Trajectory 1
	yPos += 40
	TitleBox tab1_label_minsteps, pos={xPos+10, yPos+2}, size={60, 20}
	TitleBox tab1_label_minsteps, title="MinSteps:", frame=0
	SetVariable tab1_sv_minsteps, pos={xPos+80, yPos}, size={60, kControlHeight}
	SetVariable tab1_sv_minsteps, limits={1,1000,1}, value=_NUM:10
	
	TitleBox tab1_label_totalsteps, pos={xPos+155, yPos+2}, size={70, 20}
	TitleBox tab1_label_totalsteps, title="TotalSteps:", frame=0
	SetVariable tab1_sv_totalsteps, pos={xPos+230, yPos}, size={70, kControlHeight}
	SetVariable tab1_sv_totalsteps, limits={10,100000,100}, value=_NUM:2000
	
	TitleBox tab1_label_axisrange, pos={xPos+320, yPos+2}, size={50, 20}
	TitleBox tab1_label_axisrange, title="±Axis:", frame=0
	SetVariable tab1_sv_axisrange, pos={xPos+370, yPos}, size={60, kControlHeight}
	SetVariable tab1_sv_axisrange, limits={0.1,100,0.5}, value=_NUM:1.0
	TitleBox tab1_label_axisunit, pos={xPos+435, yPos+2}, size={30, 20}
	TitleBox tab1_label_axisunit, title="µm", frame=0
	
	TitleBox tab1_label_lthresh, pos={xPos+480, yPos+2}, size={20, 20}
	TitleBox tab1_label_lthresh, title="L:", frame=0
	SetVariable tab1_sv_lthresh, pos={xPos+498, yPos}, size={50, kControlHeight}
	SetVariable tab1_sv_lthresh, limits={0.1,10,0.1}, value=_NUM:1.0, proc=LThreshSyncProc
	TitleBox tab1_label_lthresh2, pos={xPos+550, yPos+2}, size={30, 20}
	TitleBox tab1_label_lthresh2, title="µm", frame=0
	
	// ===  ===
	yPos = 455
	GroupBox tab1_grp4, pos={xPos, yPos}, size={groupWidth, 100}, title="Data Information"
	
	yPos += 25
	TitleBox tab1_info, pos={xPos+10, yPos}, size={groupWidth-20, 80}
	TitleBox tab1_info, title="No data loaded", frame=1
End

// -----------------------------------------------------------------------------
// Tab 2: Intensity Analysis
// -----------------------------------------------------------------------------
static Function CreateIntensityTab()
	Variable yPos = 40
	Variable xPos = kMargin + 10
	Variable groupWidth = 380
	
	// ===  ===
	GroupBox tab3_grp1, pos={xPos, yPos}, size={groupWidth, 290}, title="Intensity Histogram"
	
	// - 
	CheckBox tab3_chk_intensity, pos={xPos+200, yPos-2}, size={180, kControlHeight}
	CheckBox tab3_chk_intensity, title="Run in Auto Analysis", variable=root:cRunIntensity
	
	yPos += 25
	SetVariable tab3_minolig, pos={xPos+10, yPos}, size={170, kControlHeight}
	SetVariable tab3_minolig, title="Min Oligomers:", value=root:MinOligomerSize
	SetVariable tab3_minolig, limits={1, 16, 1}
	
	SetVariable tab3_maxolig, pos={xPos+190, yPos}, size={170, kControlHeight}
	SetVariable tab3_maxolig, title="Max Oligomers:", value=root:MaxOligomerSize
	SetVariable tab3_maxolig, limits={1, 16, 1}
	
	yPos += kControlSpacing
	SetVariable tab3_ihistbin, pos={xPos+10, yPos}, size={170, kControlHeight}
	SetVariable tab3_ihistbin, title="Hist Bin:", value=root:IhistBin
	SetVariable tab3_ihistbin, limits={1, 10000, 10}
	
	SetVariable tab3_ihistdim, pos={xPos+190, yPos}, size={170, kControlHeight}
	SetVariable tab3_ihistdim, title="Hist Dim:", value=root:IhistDim
	SetVariable tab3_ihistdim, limits={100, 10000, 100}
	
	yPos += kControlSpacing
	SetVariable tab3_imeaninit, pos={xPos+10, yPos}, size={170, kControlHeight}
	SetVariable tab3_imeaninit, title="Mean Int:", value=root:MeanIntGauss
	SetVariable tab3_imeaninit, limits={100, 50000, 100}
	
	SetVariable tab3_isdinit, pos={xPos+190, yPos}, size={170, kControlHeight}
	SetVariable tab3_isdinit, title="SD Int:", value=root:SDIntGauss
	SetVariable tab3_isdinit, limits={10, 5000, 10}
	
	yPos += kControlSpacing
	SetVariable tab3_lognormsd, pos={xPos+10, yPos}, size={170, kControlHeight}
	SetVariable tab3_lognormsd, title="LogNorm SD:", value=root:SDIntLognorm
	SetVariable tab3_lognormsd, limits={0.01, 1.0, 0.01}
	
	NVAR/Z gSumLogNorm = root:cSumLogNorm
	Variable intFitMode = (NVAR_Exists(gSumLogNorm) && gSumLogNorm == 1) ? 2 : 1
	PopupMenu tab3_intfittype, pos={xPos+190, yPos}, size={170, kControlHeight}
	PopupMenu tab3_intfittype, title="Fit Func:", value="Gauss;LogNorm"
	PopupMenu tab3_intfittype, mode=intFitMode, proc=IntFitTypePopupProc
	
	yPos += kControlSpacing
	CheckBox tab3_fixmean, pos={xPos+10, yPos}, size={80, kControlHeight}
	CheckBox tab3_fixmean, title="Fix Mean", variable=root:cFixMean
	
	CheckBox tab3_fixsd, pos={xPos+100, yPos}, size={80, kControlHeight}
	CheckBox tab3_fixsd, title="Fix SD", variable=root:cFixSD
	
	CheckBox tab3_normbyS0, pos={xPos+190, yPos}, size={170, kControlHeight}
	CheckBox tab3_normbyS0, title="Norm by total number", variable=root:IntNormByS0
	
	// Run / Average / Compare buttons
	yPos += kControlSpacing + 10
	Button tab3_btn_runint, pos={xPos+10, yPos}, size={240, 28}
	Button tab3_btn_runint, title="Run Intensity Histogram", proc=RunIntHistButtonProc, fStyle=1, fColor=(0,0,65535)
	
	Button tab3_btn_intaic, pos={xPos+260, yPos}, size={100, 28}
	Button tab3_btn_intaic, title="AIC Select", proc=IntAICButtonProc
	
	yPos += 32
	Button tab3_btn_avgint, pos={xPos+10, yPos}, size={175, 28}
	Button tab3_btn_avgint, title="Average Intensity Histogram", proc=AverageIntHistButtonProc, fStyle=1, fColor=(65535,43520,0)
	
	Button tab3_btn_compareint, pos={xPos+195, yPos}, size={175, 28}
	Button tab3_btn_compareint, title="Compare Intensity", proc=CompareIntensityButtonProc, fStyle=1, fColor=(0,52428,0)
	
	// ===  ===
	xPos = kMargin + 10 + groupWidth + 20
	yPos = 40
	GroupBox tab3_grp2, pos={xPos, yPos}, size={groupWidth, 170}, title="Localization Precision"
	
	// 
	CheckBox tab3_chk_lp, pos={xPos+200, yPos-2}, size={180, kControlHeight}
	CheckBox tab3_chk_lp, title="Run in Auto Analysis", variable=root:cRunLP
	
	yPos += 25
	SetVariable tab3_lphistbin, pos={xPos+10, yPos}, size={170, kControlHeight}
	SetVariable tab3_lphistbin, title="LP Bin [nm]:", value=root:LPhistBin
	SetVariable tab3_lphistbin, limits={1, 50, 1}
	
	SetVariable tab3_lphistdim, pos={xPos+190, yPos}, size={170, kControlHeight}
	SetVariable tab3_lphistdim, title="LP Dim:", value=root:LPhistDim
	SetVariable tab3_lphistdim, limits={10, 500, 10}
	
	// Run / Average / Compare buttons
	yPos += kControlSpacing + 10
	Button tab3_btn_lphist, pos={xPos+10, yPos}, size={360, 28}
	Button tab3_btn_lphist, title="Run Localization Precision Histogram", proc=LPHistButtonProc, fStyle=1, fColor=(0,0,65535)
	
	yPos += 32
	Button tab3_btn_avglp, pos={xPos+10, yPos}, size={175, 28}
	Button tab3_btn_avglp, title="Average LP Histogram", proc=AverageLPHistButtonProc, fStyle=1, fColor=(65535,43520,0)
	
	Button tab3_btn_comparelp, pos={xPos+195, yPos}, size={175, 28}
	Button tab3_btn_comparelp, title="Compare LP", proc=CompareLPButtonProc, fStyle=1, fColor=(0,52428,0)
	
	// === Density ===
	xPos = kMargin + 10 + groupWidth + 20
	yPos = 220
	GroupBox tab3_grp3, pos={xPos, yPos}, size={groupWidth, 115}, title="Particle Density"
	
	// 
	CheckBox tab3_chk_density, pos={xPos+200, yPos-2}, size={180, kControlHeight}
	CheckBox tab3_chk_density, title="Run in Auto Analysis", variable=root:cRunDensity
	
	yPos += 25
	SetVariable tab3_rhistbin, pos={xPos+10, yPos}, size={115, kControlHeight}
	SetVariable tab3_rhistbin, title="R Bin [um]:", value=root:RHistBin
	SetVariable tab3_rhistbin, limits={0.01, 1, 0.01}
	
	SetVariable tab3_rhistdim, pos={xPos+135, yPos}, size={110, kControlHeight}
	SetVariable tab3_rhistdim, title="R Dim:", value=root:RHistDim
	SetVariable tab3_rhistdim, limits={10, 2000, 100}
	
	SetVariable tab3_dsmooth, pos={xPos+255, yPos}, size={115, kControlHeight}
	SetVariable tab3_dsmooth, title="Smooth:", value=root:DSmoothing
	SetVariable tab3_dsmooth, limits={0, 10, 1}
	
	yPos += kControlSpacing
	SetVariable tab3_densitystart, pos={xPos+10, yPos}, size={175, kControlHeight}
	SetVariable tab3_densitystart, title="Analysis range:", value=root:DensityStartFrame
	SetVariable tab3_densitystart, limits={1, 10000, 1}
	
	SetVariable tab3_densityend, pos={xPos+195, yPos}, size={85, kControlHeight}
	SetVariable tab3_densityend, title="-", value=root:DensityEndFrame
	SetVariable tab3_densityend, limits={1, 10000, 1}
	
	TitleBox tab3_densitylbl, pos={xPos+285, yPos}, size={80, kControlHeight}
	TitleBox tab3_densitylbl, title="frames"
	
	yPos += kControlSpacing + 5
	Button tab3_btn_density, pos={xPos+10, yPos}, size={175, 28}
	Button tab3_btn_density, title="Run Particle Density", proc=DensityGcountButtonProc, fStyle=1, fColor=(0,0,65535)
	
	Button tab3_btn_comparedensity, pos={xPos+195, yPos}, size={175, 28}
	Button tab3_btn_comparedensity, title="Compare Density", proc=CompareDensityButtonProc, fStyle=1, fColor=(0,52428,0)
	
	// === Molecular Density===
	xPos = kMargin + 10 + groupWidth + 20
	yPos = 345
	GroupBox tab3_grp4, pos={xPos, yPos}, size={groupWidth, 130}, title="Molecular Density"
	
	// 
	CheckBox tab3_chk_moldens, pos={xPos+200, yPos-2}, size={180, kControlHeight}
	CheckBox tab3_chk_moldens, title="Run in Auto Analysis", variable=root:cRunMolDensity
	CheckBox tab3_chk_moldens, proc=MolDensityCheckProc
	
	yPos += 25
	TitleBox tab3_moldenstitle, pos={xPos+10, yPos}, size={360, kControlHeight}
	TitleBox tab3_moldenstitle, title="Combine: Intensity(oligomer) × Dstate × Density"
	TitleBox tab3_moldenstitle, frame=0
	
	// Run / Average / Compare buttons
	yPos += kControlSpacing + 5
	Button tab3_btn_moldens, pos={xPos+10, yPos}, size={360, 28}
	Button tab3_btn_moldens, title="Run Molecular Density", proc=MolDensityButtonProc, fStyle=1, fColor=(0,0,65535)
	
	yPos += 32
	Button tab3_btn_avgmoldens, pos={xPos+10, yPos}, size={175, 28}
	Button tab3_btn_avgmoldens, title="Average Molecular Density", proc=AverageMolDensButtonProc, fStyle=1, fColor=(65535,43520,0)
	
	Button tab3_btn_comparemoldens, pos={xPos+195, yPos}, size={175, 28}
	Button tab3_btn_comparemoldens, title="Compare Mol Density", proc=CompareMolDensButtonProc, fStyle=1, fColor=(0,52428,0)
End

// -----------------------------------------------------------------------------
// Tab 3: Diffusion Analysis
// -----------------------------------------------------------------------------
static Function CreateDiffusionTab()
	Variable yPos = 40
	Variable xPos = kMargin + 10
	Variable groupWidth = 380
	
	// === MSD ===
	GroupBox tab2_grp1, pos={xPos, yPos}, size={groupWidth, 300}, title="MSD Analysis"
	
	// 
	CheckBox tab2_chk_msd, pos={xPos+200, yPos-2}, size={180, kControlHeight}
	CheckBox tab2_chk_msd, title="Run in Auto Analysis", variable=root:cRunMSD
	
	yPos += 25
	SetVariable tab2_msdrange, pos={xPos+10, yPos}, size={115, kControlHeight}
	SetVariable tab2_msdrange, title="MSD Range:", value=root:AreaRangeMSD
	SetVariable tab2_msdrange, limits={2, 50, 1}
	
	SetVariable tab2_msdthreshold, pos={xPos+130, yPos}, size={100, kControlHeight}
	SetVariable tab2_msdthreshold, title="Thresh[%]:", value=root:ThresholdMSD
	SetVariable tab2_msdthreshold, limits={0.1, 50, 1}
	
	CheckBox tab2_moveave, pos={xPos+240, yPos}, size={120, kControlHeight}
	CheckBox tab2_moveave, title="Moving Average", variable=root:cMoveAve
	
	yPos += kControlSpacing
	NVAR/Z gFitType = root:FitType
	Variable fitTypeMode = NVAR_Exists(gFitType) ? gFitType + 1 : 3
	PopupMenu tab2_fittype, pos={xPos+10, yPos}, size={170, kControlHeight}
	PopupMenu tab2_fittype, title="Fit Type:", value="Free;Confined;Confined+Err;Anomalous;Anomalous+Err"
	PopupMenu tab2_fittype, mode=fitTypeMode, proc=FitTypePopupProc
	
	yPos += kControlSpacing
	SetVariable tab2_initd, pos={xPos+10, yPos}, size={170, kControlHeight}
	SetVariable tab2_initd, title="Init D [um2/s]:", value=root:InitialD0
	SetVariable tab2_initd, limits={0.001, 10, 0.01}
	
	SetVariable tab2_initl, pos={xPos+190, yPos}, size={170, kControlHeight}
	SetVariable tab2_initl, title="Init L [um]:", value=root:InitialL
	SetVariable tab2_initl, limits={0.01, 10, 0.1}
	
	yPos += kControlSpacing
	CheckBox tab2_fixeps, pos={xPos+10, yPos}, size={70, kControlHeight}
	CheckBox tab2_fixeps, title="Fix ε", variable=root:Efix
	
	SetVariable tab2_initeps, pos={xPos+85, yPos}, size={120, kControlHeight}
	SetVariable tab2_initeps, title="[um]:", value=root:InitialEpsilon
	SetVariable tab2_initeps, limits={0, 0.1, 0.001}
	
	// Run / Average / Compare buttons
	yPos += kControlSpacing + 10
	Button tab2_btn_runmsd, pos={xPos+10, yPos}, size={360, 28}
	Button tab2_btn_runmsd, title="Run MSD Analysis", proc=RunMSDButtonProc, fStyle=1, fColor=(0,0,65535)
	
	yPos += 32
	Button tab2_btn_statsmsd, pos={xPos+10, yPos}, size={175, 28}
	Button tab2_btn_statsmsd, title="Average MSD", proc=StatsMSDButtonProc, fStyle=1, fColor=(65535,43520,0)
	
	Button tab2_btn_comparemsd, pos={xPos+195, yPos}, size={175, 28}
	Button tab2_btn_comparemsd, title="Compare MSD Parameters", proc=CompareMSDParamsButtonProc, fStyle=1, fColor=(0,52428,0)
	
	// === Step Size Histogram ===
	xPos = kMargin + 10 + groupWidth + 20
	yPos = 40
	GroupBox tab2_grp2, pos={xPos, yPos}, size={groupWidth, 360}, title="Stepsize Histogram"
	
	// 
	CheckBox tab2_chk_stepsize, pos={xPos+200, yPos-2}, size={180, kControlHeight}
	CheckBox tab2_chk_stepsize, title="Run in Auto Analysis", variable=root:cRunStepSize
	
	yPos += 25
	SetVariable tab2_stepdeltatmax, pos={xPos+10, yPos}, size={110, kControlHeight}
	SetVariable tab2_stepdeltatmax, title="Δt max:", value=root:StepDeltaTMax
	SetVariable tab2_stepdeltatmax, limits={1, 50, 1}
	
	TitleBox tab2_lbl_heatmapnote, pos={xPos+125, yPos+2}, size={200, kControlHeight}
	TitleBox tab2_lbl_heatmapnote, title="(Heatmap requires Δt max ≥ 2)", frame=0, fSize=10
	
	yPos += kControlSpacing
	SetVariable tab2_stepbin, pos={xPos+10, yPos}, size={115, kControlHeight}
	SetVariable tab2_stepbin, title="Bin [um]:", value=root:StepHistBin
	SetVariable tab2_stepbin, limits={0.001, 0.5, 0.005}
	
	SetVariable tab2_stepdim, pos={xPos+130, yPos}, size={105, kControlHeight}
	SetVariable tab2_stepdim, title="Dim:", value=root:StepHistDim
	SetVariable tab2_stepdim, limits={10, 500, 10}
	
	// D-state model selection (AIC)
	SetVariable tab2_stepminstates, pos={xPos+245, yPos}, size={80, kControlHeight}
	SetVariable tab2_stepminstates, title="D-state:", value=root:StepFitMinStates
	SetVariable tab2_stepminstates, limits={1, 5, 1}
	
	SetVariable tab2_stepmaxstates, pos={xPos+330, yPos}, size={35, kControlHeight}
	SetVariable tab2_stepmaxstates, title="-", value=root:StepFitMaxStates
	SetVariable tab2_stepmaxstates, limits={1, 5, 1}
	
	yPos += kControlSpacing
	SetVariable tab2_stepfitd1, pos={xPos+10, yPos}, size={175, kControlHeight}
	SetVariable tab2_stepfitd1, title="D1 (slowest) [um2/s]:", value=root:StepFitD1
	SetVariable tab2_stepfitd1, limits={0.001, 10, 0.001}
	
	SetVariable tab2_stepfitscale, pos={xPos+195, yPos}, size={165, kControlHeight}
	SetVariable tab2_stepfitscale, title="Scale (D2=D1*S):", value=root:StepFitScale
	SetVariable tab2_stepfitscale, limits={1, 100, 1}
	
	// Run Stepsize / Heatmap
	yPos += kControlSpacing + 10
	Button tab2_btn_runstep, pos={xPos+10, yPos}, size={200, 28}
	Button tab2_btn_runstep, title="Run Stepsize Histogram", proc=RunStepHistButtonProc, fStyle=1, fColor=(0,0,65535)
	
	Button tab2_btn_msdheat, pos={xPos+220, yPos}, size={140, 28}
	Button tab2_btn_msdheat, title="Run Heatmap", proc=MSDHeatmapButtonProc, fStyle=1, fColor=(0,0,65535)
	
	// Heatmap contrast settings
	yPos += 32
	SetVariable tab2_heatmin, pos={xPos+10, yPos}, size={115, kControlHeight}
	SetVariable tab2_heatmin, title="Contrast:", value=root:HeatmapMin
	SetVariable tab2_heatmin, limits={0, 100, 0.01}
	
	SetVariable tab2_heatmax, pos={xPos+130, yPos}, size={50, kControlHeight}
	SetVariable tab2_heatmax, title="-", value=root:HeatmapMax
	SetVariable tab2_heatmax, limits={0, 100, 0.01}
	
	// 
	yPos += kControlSpacing
	SetVariable tab2_color0, pos={xPos+10, yPos}, size={85, kControlHeight}
	SetVariable tab2_color0, title="S0:", value=root:Color0
	
	SetVariable tab2_color1, pos={xPos+100, yPos}, size={85, kControlHeight}
	SetVariable tab2_color1, title="S1:", value=root:Color1
	
	SetVariable tab2_color2, pos={xPos+190, yPos}, size={85, kControlHeight}
	SetVariable tab2_color2, title="S2:", value=root:Color2
	
	SetVariable tab2_color3, pos={xPos+280, yPos}, size={85, kControlHeight}
	SetVariable tab2_color3, title="S3:", value=root:Color3
	
	// === Average/Compare  ===
	yPos += 32
	Button tab2_btn_statsstep, pos={xPos+10, yPos}, size={175, 28}
	Button tab2_btn_statsstep, title="Average Stepsize Histogram", proc=AverageStepHistButtonProc, fStyle=1, fColor=(65535,43520,0)
	
	Button tab2_btn_avgheat, pos={xPos+195, yPos}, size={175, 28}
	Button tab2_btn_avgheat, title="Average Heatmap", proc=AverageHeatmapButtonProc, fStyle=1, fColor=(65535,43520,0)
	
	yPos += 32
	Button tab2_btn_comparedstate, pos={xPos+10, yPos}, size={175, 28}
	Button tab2_btn_comparedstate, title="Compare D-state Population", proc=CompareDstateButtonProc, fStyle=1, fColor=(0,52428,0)
End

// -----------------------------------------------------------------------------
// Tab 4: Kinetics AnalysisOff-rate, On-rate
// -----------------------------------------------------------------------------
static Function CreateKineticsTab()
	Variable yPos = 40
	Variable xPos = kMargin + 10
	Variable groupWidth = 380
	
	// === On-time (off-rate)  ===
	GroupBox tab4_grp1, pos={xPos, yPos}, size={groupWidth, 230}, title="On-time (off-rate) Analysis"
	
	// 
	CheckBox tab4_chk_offrate, pos={xPos+200, yPos-2}, size={180, kControlHeight}
	CheckBox tab4_chk_offrate, title="Run in Auto Analysis", variable=root:cRunOffrate
	
	yPos += 25
	TitleBox tab4_modellabel, pos={xPos+10, yPos+2}, title="Model:", frame=0
	
	SetVariable tab4_expmin, pos={xPos+60, yPos}, size={70, kControlHeight}
	SetVariable tab4_expmin, title="Min:", value=root:ExpMin_off
	SetVariable tab4_expmin, limits={1, 5, 1}
	
	TitleBox tab4_exptitle, pos={xPos+135, yPos+2}, title="-", frame=0
	
	SetVariable tab4_expmax, pos={xPos+150, yPos}, size={70, kControlHeight}
	SetVariable tab4_expmax, title="Max:", value=root:ExpMax_off
	SetVariable tab4_expmax, limits={1, 5, 1}
	
	SetVariable tab4_minframe, pos={xPos+230, yPos}, size={140, kControlHeight}
	SetVariable tab4_minframe, title="Min Frames:", value=root:MinFrame
	SetVariable tab4_minframe, limits={1, 100, 1}
	
	yPos += kControlSpacing
	SetVariable tab4_tau1, pos={xPos+10, yPos}, size={170, kControlHeight}
	SetVariable tab4_tau1, title="Tau1 [s]:", value=root:InitialTau1_off
	SetVariable tab4_tau1, limits={0.001, 100, 0.1}
	
	SetVariable tab4_tauscale, pos={xPos+190, yPos}, size={170, kControlHeight}
	SetVariable tab4_tauscale, title="Scale_tau:", value=root:TauScale_off
	SetVariable tab4_tauscale, limits={1, 100, 1}
	
	yPos += kControlSpacing
	SetVariable tab4_a1, pos={xPos+10, yPos}, size={170, kControlHeight}
	SetVariable tab4_a1, title="A1 [%]:", value=root:InitialA1_off
	SetVariable tab4_a1, limits={0.1, 100, 10}
	
	SetVariable tab4_ascale, pos={xPos+190, yPos}, size={170, kControlHeight}
	SetVariable tab4_ascale, title="Scale_A:", value=root:AScale_off
	SetVariable tab4_ascale, limits={0.01, 10, 0.1}
	
	yPos += kControlSpacing
	CheckBox tab4_orc, pos={xPos+10, yPos}, size={200, kControlHeight}
	CheckBox tab4_orc, title="Edge correction", value=1, variable=root:cORC
	
	// Run / Average / Compare buttons
	yPos += kControlSpacing + 5
	Button tab4_btn_duration, pos={xPos+10, yPos}, size={360, 28}
	Button tab4_btn_duration, title="Run On-time Analysis", proc=DurationButtonProc, fStyle=1, fColor=(0,0,65535)
	
	yPos += 32
	Button tab4_btn_statsoff, pos={xPos+10, yPos}, size={175, 28}
	Button tab4_btn_statsoff, title="Average On-time", proc=AverageOntimeButtonProc, fStyle=1, fColor=(65535,43520,0)
	
	Button tab4_btn_compareoff, pos={xPos+195, yPos}, size={175, 28}
	Button tab4_btn_compareoff, title="Compare On-time", proc=CompareOntimeButtonProc, fStyle=1, fColor=(0,52428,0)
	
	// === On-rate ===
	xPos = kMargin + 10 + groupWidth + 20
	yPos = 40
	GroupBox tab4_grp2, pos={xPos, yPos}, size={groupWidth, 230}, title="On-rate Analysis"
	
	// 
	CheckBox tab4_chk_onrate, pos={xPos+200, yPos-2}, size={180, kControlHeight}
	CheckBox tab4_chk_onrate, title="Run in Auto Analysis", variable=root:cRunOnrate
	
	yPos += 25
	CheckBox tab4_usedensity, pos={xPos+10, yPos}, size={250, kControlHeight}
	CheckBox tab4_usedensity, title="Use Density result (cell-based)", value=1, variable=root:cUseDensityForOnrate
	CheckBox tab4_usedensity, proc=UseDensityCheckProc
	
	yPos += kControlSpacing
	SetVariable tab4_tauvon, pos={xPos+10, yPos}, size={170, kControlHeight}
	SetVariable tab4_tauvon, title="Initial Tau [s]:", value=root:InitialTauon
	SetVariable tab4_tauvon, limits={0.001, 1000, 1}
	
	SetVariable tab4_v0von, pos={xPos+190, yPos}, size={170, kControlHeight}
	SetVariable tab4_v0von, title="Initial V0:", value=root:InitialVon
	SetVariable tab4_v0von, limits={0.001, 1000, 0.1}
	
	yPos += kControlSpacing + 5
	Button tab4_btn_onrate, pos={xPos+10, yPos}, size={360, 28}
	Button tab4_btn_onrate, title="Run On-rate Analysis", proc=OnrateButtonProc2, fStyle=1, fColor=(0,0,65535)
	
	// Average / Compare buttons for On-rate
	yPos += 32
	Button tab4_btn_statson, pos={xPos+10, yPos}, size={175, 28}
	Button tab4_btn_statson, title="Average On-rate", proc=AverageOnrateButtonProc, fStyle=1, fColor=(65535,43520,0)
	
	Button tab4_btn_compareon, pos={xPos+195, yPos}, size={175, 28}
	Button tab4_btn_compareon, title="Compare On-rate", proc=CompareOnrateButtonProc, fStyle=1, fColor=(0,52428,0)
	
	// === State Transition  ===
	xPos = kMargin + 10
	yPos = 280
	GroupBox tab4_grp3, pos={xPos, yPos}, size={groupWidth, 220}, title="HMM State Transition Analysis"
	
	// 
	CheckBox tab4_chk_statetrans, pos={xPos+200, yPos-2}, size={130, kControlHeight}
	CheckBox tab4_chk_statetrans, title="Run in Auto Analysis", variable=root:cRunStateTransition
	
	yPos += 25
	TitleBox tab4_translabel, pos={xPos+10, yPos}, frame=0
	TitleBox tab4_translabel, title="Calculate transition time constants (τij) from HMM TransA matrix"
	
	// k/τ 
	CheckBox tab4_chk_outtau, pos={xPos+335, yPos-2}, size={20, kControlHeight}
	CheckBox tab4_chk_outtau, title="τ", value=1, mode=1, proc=KinOutputModeCheckProc, variable=root:cKinOutputTau
	
	CheckBox tab4_chk_outk, pos={xPos+358, yPos-2}, size={20, kControlHeight}
	CheckBox tab4_chk_outk, title="k", value=0, mode=1, proc=KinOutputModeCheckProc
	
	yPos += kControlSpacing + 5
	Button tab4_btn_statetrans, pos={xPos+10, yPos}, size={360, 28}
	Button tab4_btn_statetrans, title="Run State Transition Analysis", proc=StateTransitionButtonProc, fStyle=1, fColor=(0,0,65535)
	
	// Average / Compare buttonsOn-time
	yPos += 32
	Button tab4_btn_avgstatetrans, pos={xPos+10, yPos}, size={175, 28}
	Button tab4_btn_avgstatetrans, title="Average State Transition", proc=AverageStateTransButtonProc, fStyle=1, fColor=(65535,43520,0)
	
	Button tab4_btn_comparestatetrans, pos={xPos+195, yPos}, size={175, 28}
	Button tab4_btn_comparestatetrans, title="Compare State Transition", proc=CompareStateTransButtonProc, fStyle=1, fColor=(0,52428,0)
	
	// State Transition Diagram 
	yPos += 35
	TitleBox tab4_title_diagparam, pos={xPos+10, yPos}, size={200, 20}
	TitleBox tab4_title_diagparam, title="Diagram parameters:", frame=0
	
	// 1: Label, Arrow, τ
	yPos += 20
	TitleBox tab4_label_statelabel, pos={xPos+10, yPos+2}, size={55, 20}
	TitleBox tab4_label_statelabel, title="Label:", frame=0
	SetVariable tab4_sv_statelabel, pos={xPos+50, yPos}, size={60, kControlHeight}
	SetVariable tab4_sv_statelabel, limits={100,500,10}, value=_NUM:200
	TitleBox tab4_label_statelabel2, pos={xPos+112, yPos+2}, size={10, 20}
	TitleBox tab4_label_statelabel2, title="%", frame=0
	
	TitleBox tab4_label_arrowoffset, pos={xPos+135, yPos+2}, size={50, 20}
	TitleBox tab4_label_arrowoffset, title="Arrow:", frame=0
	SetVariable tab4_sv_arrowoffset, pos={xPos+178, yPos}, size={50, kControlHeight}
	SetVariable tab4_sv_arrowoffset, limits={-20,20,1}, value=_NUM:4
	TitleBox tab4_label_arrowoffset2, pos={xPos+230, yPos+2}, size={10, 20}
	TitleBox tab4_label_arrowoffset2, title="%", frame=0
	
	TitleBox tab4_label_tauoffset, pos={xPos+260, yPos+2}, size={30, 20}
	TitleBox tab4_label_tauoffset, title="τ:", frame=0
	SetVariable tab4_sv_tauoffset, pos={xPos+280, yPos}, size={50, kControlHeight}
	SetVariable tab4_sv_tauoffset, limits={1,30,1}, value=_NUM:1
	TitleBox tab4_label_tauoffset2, pos={xPos+332, yPos+2}, size={10, 20}
	TitleBox tab4_label_tauoffset2, title="%", frame=0
	
	// 2: Line Space, Font Size, Graph Size
	yPos += 22
	TitleBox tab4_label_linespace, pos={xPos+10, yPos+2}, size={35, 20}
	TitleBox tab4_label_linespace, title="LS:", frame=0
	SetVariable tab4_sv_linespace, pos={xPos+35, yPos}, size={45, kControlHeight}
	SetVariable tab4_sv_linespace, limits={-20,10,1}, value=_NUM:0
	
	TitleBox tab4_label_fontsize, pos={xPos+95, yPos+2}, size={35, 20}
	TitleBox tab4_label_fontsize, title="Font:", frame=0
	SetVariable tab4_sv_fontsize, pos={xPos+130, yPos}, size={40, kControlHeight}
	SetVariable tab4_sv_fontsize, limits={6,20,1}, value=_NUM:12
	
	TitleBox tab4_label_graphsize, pos={xPos+185, yPos+2}, size={50, 20}
	TitleBox tab4_label_graphsize, title="Size:", frame=0
	SetVariable tab4_sv_graphsize, pos={xPos+218, yPos}, size={50, kControlHeight}
	SetVariable tab4_sv_graphsize, limits={200,800,50}, value=_NUM:300
	
	TitleBox tab4_label_lthresh, pos={xPos+280, yPos+2}, size={50, 20}
	TitleBox tab4_label_lthresh, title="L:", frame=0
	SetVariable tab4_sv_lthresh, pos={xPos+298, yPos}, size={50, kControlHeight}
	SetVariable tab4_sv_lthresh, limits={0.1,10,0.1}, value=_NUM:1.0, proc=LThreshKinSyncProc
	TitleBox tab4_label_lthresh2, pos={xPos+350, yPos+2}, size={20, 20}
	TitleBox tab4_label_lthresh2, title="µm", frame=0
	
	// 3: Use Aligned Trajectory 
	yPos += 22
	CheckBox tab4_chk_usealigned, pos={xPos+10, yPos}, size={170, kControlHeight}
	CheckBox tab4_chk_usealigned, title="Use Aligned Trajectory", variable=root:cUseAlignedTraj
	
	TitleBox tab4_label_trajscale, pos={xPos+185, yPos+2}, size={45, 20}
	TitleBox tab4_label_trajscale, title="Scale:", frame=0
	SetVariable tab4_sv_trajscale, pos={xPos+225, yPos}, size={50, kControlHeight}
	SetVariable tab4_sv_trajscale, limits={0.5,10,0.5}, value=_NUM:2.5
End

// -----------------------------------------------------------------------------
// Tab 5: Colocalization Analysis
// -----------------------------------------------------------------------------
static Function CreateColocalizationTab()
	// 
	// =====  =====
	Variable/G root:cSameHMMD = 1			// Same HMM D-state ON
	Variable/G root:MaxDistance = 100		//  [nm]
	Variable/G root:MaxDratio = 10			// D
	Variable/G root:ColMinFrame = 1			// 
	Variable/G root:ColRoom = 1				// Room
	Variable/G root:ColIntHistBin = 100		// 
	Variable/G root:ColIntHistDim = 100		// 
	Variable/G root:ColIndex = 1			// Col1/EC1, Col2/EC2, ...
	// Compare Parameters (preserve existing values if already set)
	NVAR/Z gColWeightingMode = root:ColWeightingMode
	NVAR/Z gColAffinityParam = root:ColAffinityParam
	NVAR/Z gColIntensityMode = root:ColIntensityMode
	NVAR/Z gColDiffusionMode = root:ColDiffusionMode
	NVAR/Z gColOntimeMode = root:ColOntimeMode
	NVAR/Z gColOnrateMode = root:ColOnrateMode
	NVAR/Z gColOutputChannel = root:ColOutputChannel
	if(!NVAR_Exists(gColWeightingMode))
		Variable/G root:ColWeightingMode = 1	// 0=Particle, 1=Molecule
	endif
	if(!NVAR_Exists(gColAffinityParam))
		Variable/G root:ColAffinityParam = 0	// 0=Kb, 1=Density, 2=Distance
	endif
	if(!NVAR_Exists(gColIntensityMode))
		Variable/G root:ColIntensityMode = 0	// 0=Simple, 1=Fitting
	endif
	if(!NVAR_Exists(gColDiffusionMode))
		Variable/G root:ColDiffusionMode = 0	// 0=per Total, 1=per Col
	endif
	if(!NVAR_Exists(gColOntimeMode))
		Variable/G root:ColOntimeMode = 0		// 0=Simple, 1=Fitting
	endif
	if(!NVAR_Exists(gColOnrateMode))
		Variable/G root:ColOnrateMode = 0		// 0=On-event rate, 1=k_on
	endif
	if(!NVAR_Exists(gColOutputChannel))
		Variable/G root:ColOutputChannel = 0	// 0=Both, 1=C1, 2=C2
	endif
	// ColocalizationOn-timeAutoAnalysis
	Variable/G root:ColTau1 = 0.05			// Colocalization Tau1 [s]
	Variable/G root:ColTauScale = 5			// Colocalization Scale_tau
	Variable/G root:ColA1 = 80				// Colocalization A1 [%]
	Variable/G root:ColAScale = 0.5			// Colocalization Scale_A
	// AutoAnalysisOn-time
	Variable/G root:InitialTau1_off = 0.5	//  [s]
	Variable/G root:TauScale_off = 5		// Tau (Tau_n = Tau1 * Scale^(n-1))
	Variable/G root:InitialA1_off = 80		// A1 [%]
	Variable/G root:AScale_off = 0.5		// A (A_n = A1 * Scale^(n-1))
	
	Variable yPos = 40
	Variable xPos = kMargin + 10
	Variable groupWidth = 380
	
	// === Colocalization Settings===
	GroupBox tab5_grp1, pos={xPos, yPos}, size={groupWidth, 210}, title="Colocalization Settings"

	yPos += 25
	// Same HMM D-state + Density Area (Min/Max)
	CheckBox tab5_chk_samedstate, pos={xPos+10, yPos}, size={170, kControlHeight}
	CheckBox tab5_chk_samedstate, title="Same HMM D-state", variable=root:cSameHMMD

	NVAR/Z gColAreaMode = root:ColAreaMode
	Variable colAreaModeVal = NVAR_Exists(gColAreaMode) ? gColAreaMode : 1  // default=1 (max)
	TitleBox tab5_info_areamode, pos={xPos+190, yPos+3}, size={80, 18}
	TitleBox tab5_info_areamode, title="Area:", frame=0, fSize=12
	PopupMenu tab5_pop_areamode, pos={xPos+230, yPos}, size={120, 20}
	PopupMenu tab5_pop_areamode, mode=(colAreaModeVal + 1), value="Min;Max", proc=ColAreaModeProc

	yPos += kControlSpacing
	SetVariable tab5_sv_maxdist, pos={xPos+10, yPos}, size={170, kControlHeight}
	SetVariable tab5_sv_maxdist, title="Max Distance [nm]:", value=root:MaxDistance
	SetVariable tab5_sv_maxdist, limits={10, 1000, 10}

	SetVariable tab5_sv_maxdratio, pos={xPos+190, yPos}, size={170, kControlHeight}
	SetVariable tab5_sv_maxdratio, title="Max D Ratio:", value=root:MaxDratio
	SetVariable tab5_sv_maxdratio, limits={1, 100, 1}

	yPos += kControlSpacing
	SetVariable tab5_sv_minframe, pos={xPos+10, yPos}, size={170, kControlHeight}
	SetVariable tab5_sv_minframe, title="Min Frames:", value=root:ColMinFrame
	SetVariable tab5_sv_minframe, limits={1, 100, 1}

	SetVariable tab5_sv_room, pos={xPos+190, yPos}, size={170, kControlHeight}
	SetVariable tab5_sv_room, title="Room (frames):", value=root:ColRoom
	SetVariable tab5_sv_room, limits={0, 10, 1}

	// Int hist:  + Bin/Dim
	yPos += kControlSpacing
	TitleBox tab5_info_inthist, pos={xPos+10, yPos+3}, size={50, 18}
	TitleBox tab5_info_inthist, title="Int hist:", frame=0, fSize=12
	
	SetVariable tab5_sv_intbin, pos={xPos+70, yPos}, size={120, kControlHeight}
	SetVariable tab5_sv_intbin, title="Bin:", value=root:ColIntHistBin
	SetVariable tab5_sv_intbin, limits={1, 10000, 100}
	
	SetVariable tab5_sv_intdim, pos={xPos+200, yPos}, size={120, kControlHeight}
	SetVariable tab5_sv_intdim, title="Dim:", value=root:ColIntHistDim
	SetVariable tab5_sv_intdim, limits={10, 1000, 10}
	
	// On-time: Tau1, Scale_tauColocalization
	yPos += kControlSpacing
	TitleBox tab5_info_ontime, pos={xPos+10, yPos+3}, size={60, 18}
	TitleBox tab5_info_ontime, title="On-time:", frame=0, fSize=12
	
	SetVariable tab5_sv_tau1, pos={xPos+70, yPos}, size={130, kControlHeight}
	SetVariable tab5_sv_tau1, title="Tau1 [s]:", value=root:ColTau1
	SetVariable tab5_sv_tau1, limits={0.001, 1000, 0.1}
	
	SetVariable tab5_sv_tauscale, pos={xPos+210, yPos}, size={110, kControlHeight}
	SetVariable tab5_sv_tauscale, title="Scale_tau:", value=root:ColTauScale
	SetVariable tab5_sv_tauscale, limits={1, 100, 1}
	
	// On-time: A1, Scale_AColocalization
	yPos += kControlSpacing
	SetVariable tab5_sv_a1, pos={xPos+70, yPos}, size={130, kControlHeight}
	SetVariable tab5_sv_a1, title="A1 [%]:", value=root:ColA1
	SetVariable tab5_sv_a1, limits={0.1, 100, 10}
	
	SetVariable tab5_sv_ascale, pos={xPos+210, yPos}, size={110, kControlHeight}
	SetVariable tab5_sv_ascale, title="Scale_A:", value=root:ColAScale
	SetVariable tab5_sv_ascale, limits={0.01, 10, 0.1}
	
	// Make Target List Settings
	Button tab5_btn_makelist, pos={xPos+10, yPos+22}, size={170, 35}
	Button tab5_btn_makelist, title="Make Target Lists", proc=ColMakeListProc, fStyle=1, fColor=(0,0,65535)
	
	TitleBox tab5_info_list, pos={xPos+190, yPos+27}, size={180, 25}
	TitleBox tab5_info_list, title="Create List_C1 & C2\rfor 2-color analysis", frame=0, fStyle=2, fSize=10
	
	// === Colocalization Analysis===
	xPos = kMargin + 10 + groupWidth + 20
	yPos = 40
	GroupBox tab5_grp3, pos={xPos, yPos}, size={groupWidth, 210}, title="Colocalization Analysis"
	
	yPos += 25
	Button tab5_btn_analyze, pos={xPos+10, yPos}, size={200, 40}
	Button tab5_btn_analyze, title="▶ Analyze Colocalization", proc=ColAnalyzeProc, fStyle=1, fColor=(0,0,65535)
	Button tab5_btn_analyze, help={"Run all Batch Analysis for each sample pair"}
	
	TitleBox tab5_info_analyze, pos={xPos+220, yPos+5}, size={150, 35}
	TitleBox tab5_info_analyze, title="Run all Batch\rAnalysis functions", frame=0, fStyle=2, fSize=10
	
	yPos += 55
	Button tab5_btn_avghist, pos={xPos+10, yPos}, size={200, 35}
	Button tab5_btn_avghist, title="Average Histograms", proc=ColAvgHistProc, fStyle=1, fColor=(65535,43520,0)
	
	TitleBox tab5_info_avghist, pos={xPos+220, yPos+5}, size={150, 25}
	TitleBox tab5_info_avghist, title="Average histograms\racross cells", frame=0, fStyle=2, fSize=10
	
	yPos += 50
	Button tab5_btn_compare, pos={xPos+10, yPos}, size={200, 35}
	Button tab5_btn_compare, title="Compare Parameters", proc=ColCompareProc, fStyle=1, fColor=(0,52428,0)
	
	TitleBox tab5_info_compare, pos={xPos+220, yPos+5}, size={150, 25}
	TitleBox tab5_info_compare, title="Compare D-state, Off-rate,\rOn-rate across conditions", frame=0, fStyle=2, fSize=10
	
	yPos += 45
	TitleBox tab5_lbl_channel, pos={xPos+10, yPos+2}, size={50, 20}
	TitleBox tab5_lbl_channel, title="Output:", frame=0
	NVAR colChMode = root:ColOutputChannel
	PopupMenu tab5_pop_channel, pos={xPos+60, yPos}, size={100, 20}
	PopupMenu tab5_pop_channel, mode=(colChMode + 1), value="Both;C1;C2", proc=ColChannelModeProc
	
	TitleBox tab5_lbl_weighting, pos={xPos+180, yPos+2}, size={60, 20}
	TitleBox tab5_lbl_weighting, title="Weighting:", frame=0
	NVAR colWtMode = root:ColWeightingMode
	PopupMenu tab5_pop_weighting, pos={xPos+250, yPos}, size={100, 20}
	PopupMenu tab5_pop_weighting, mode=(colWtMode + 1), value="Particle;Molecule", proc=ColWeightingModeProc
	
	// === Batch Analysis- 6 ===
	// : Find, Trajectory, Intensity, Diffusion, On-time, On-rate
	xPos = kMargin + 10
	yPos = 255
	GroupBox tab5_grp4, pos={xPos, yPos}, size={780, 70}, title="Batch Analysis"
	
	yPos += 25
	Button tab5_btn_find, pos={xPos+10, yPos}, size={120, 30}
	Button tab5_btn_find, title="Find", proc=ColFindProc, fColor=(0,0,65535)
	
	Button tab5_btn_trajectory, pos={xPos+135, yPos}, size={120, 30}
	Button tab5_btn_trajectory, title="Trajectory", proc=ColTrajectoryProc, fColor=(0,0,65535)
	
	Button tab5_btn_intensity, pos={xPos+260, yPos}, size={120, 30}
	Button tab5_btn_intensity, title="Intensity", proc=ColIntensityProc, fColor=(0,0,65535)
	
	Button tab5_btn_diffusion, pos={xPos+385, yPos}, size={120, 30}
	Button tab5_btn_diffusion, title="Diffusion", proc=ColDiffusionProc, fColor=(0,0,65535)
	
	Button tab5_btn_ontime, pos={xPos+510, yPos}, size={120, 30}
	Button tab5_btn_ontime, title="On-time", proc=ColOntimeProc, fColor=(0,0,65535)
	
	Button tab5_btn_onrate, pos={xPos+635, yPos}, size={120, 30}
	Button tab5_btn_onrate, title="On-rate", proc=ColOnrateProc, fColor=(0,0,65535)
	
	// === Average Histograms===
	xPos = kMargin + 10
	yPos = 330
	GroupBox tab5_grp5, pos={xPos, yPos}, size={780, 70}, title="Average Histograms"
	
	yPos += 25
	Button tab5_btn_avgdist, pos={xPos+10, yPos}, size={145, 30}
	Button tab5_btn_avgdist, title="Distance", proc=ColAvgDistanceProc, fColor=(65535,43520,0)
	
	Button tab5_btn_avgint, pos={xPos+160, yPos}, size={145, 30}
	Button tab5_btn_avgint, title="Intensity", proc=ColAvgIntensityProc, fColor=(65535,43520,0)
	
	Button tab5_btn_avgdiff, pos={xPos+310, yPos}, size={145, 30}
	Button tab5_btn_avgdiff, title="Diffusion", proc=ColAvgDiffusionProc, fColor=(65535,43520,0)
	
	Button tab5_btn_avgontime, pos={xPos+460, yPos}, size={145, 30}
	Button tab5_btn_avgontime, title="On-time", proc=ColAvgOntimeProc, fColor=(65535,43520,0)
	
	Button tab5_btn_avgonrate, pos={xPos+610, yPos}, size={145, 30}
	Button tab5_btn_avgonrate, title="On-rate", proc=ColAvgOnrateProc, fColor=(65535,43520,0)
	
	// === Compare Parameters===
	xPos = kMargin + 10
	yPos = 405
	GroupBox tab5_grp7, pos={xPos, yPos}, size={780, 100}, title="Compare Parameters"
	
	// Average Histograms
	Variable btnWidth = 145
	Variable btnHeight = 30
	Variable popWidth = 145
	Variable spacing = 150
	
	yPos += 25
	// Affinity
	Button tab5_btn_cmpaffinity, pos={xPos+10, yPos}, size={btnWidth, btnHeight}
	Button tab5_btn_cmpaffinity, title="Affinity", proc=ColCmpAffinityProc, fColor=(0,52428,0)
	NVAR/Z gColAffParam = root:ColAffinityParam
	PopupMenu tab5_pop_affinity, pos={xPos+10, yPos+btnHeight+2}, size={popWidth, 20}
	PopupMenu tab5_pop_affinity, mode=(NVAR_Exists(gColAffParam) ? gColAffParam + 1 : 1), value="Kb;Density;Distance", proc=ColAffinityParamProc
	
	// Intensity
	Button tab5_btn_cmpint, pos={xPos+160, yPos}, size={btnWidth, btnHeight}
	Button tab5_btn_cmpint, title="Intensity", proc=ColCmpIntensityProc, fColor=(0,52428,0)
	NVAR/Z gColIntMode = root:ColIntensityMode
	PopupMenu tab5_pop_intensity, pos={xPos+160, yPos+btnHeight+2}, size={popWidth, 20}
	PopupMenu tab5_pop_intensity, mode=(NVAR_Exists(gColIntMode) ? gColIntMode + 1 : 1), value="Simple;Fitting", proc=ColIntensityModeProc
	
	// D-state (Population)
	Button tab5_btn_cmpdiff, pos={xPos+310, yPos}, size={btnWidth, btnHeight}
	Button tab5_btn_cmpdiff, title="D-state", proc=ColCmpDiffusionProc, fColor=(0,52428,0)
	NVAR/Z gColDiffMode = root:ColDiffusionMode
	PopupMenu tab5_pop_diffusion, pos={xPos+310, yPos+btnHeight+2}, size={popWidth, 20}
	PopupMenu tab5_pop_diffusion, mode=(NVAR_Exists(gColDiffMode) ? gColDiffMode + 1 : 1), value="per Total;per Col;Steps", proc=ColDiffusionModeProc
	
	// On-time
	Button tab5_btn_cmpontime, pos={xPos+460, yPos}, size={btnWidth, btnHeight}
	Button tab5_btn_cmpontime, title="On-time", proc=ColCmpOntimeProc, fColor=(0,52428,0)
	NVAR/Z gColOntMode = root:ColOntimeMode
	PopupMenu tab5_pop_ontime, pos={xPos+460, yPos+btnHeight+2}, size={popWidth, 20}
	PopupMenu tab5_pop_ontime, mode=(NVAR_Exists(gColOntMode) ? gColOntMode + 1 : 1), value="Simple;Fitting", proc=ColOntimeModeProc
	
	// On-rate
	Button tab5_btn_cmponrate, pos={xPos+610, yPos}, size={btnWidth, btnHeight}
	Button tab5_btn_cmponrate, title="On-rate", proc=ColCmpOnrateProc, fColor=(0,52428,0)
	NVAR/Z gColOnrMode = root:ColOnrateMode
	PopupMenu tab5_pop_onrate, pos={xPos+610, yPos+btnHeight+2}, size={popWidth, 20}
	PopupMenu tab5_pop_onrate, mode=(NVAR_Exists(gColOnrMode) ? gColOnrMode + 1 : 1), value="On-event rate;k\\Bon\\M", proc=ColOnrateModeProc
	
	// === Status Information===
	xPos = kMargin + 10
	yPos = 510
	GroupBox tab5_grp6, pos={xPos, yPos}, size={780, 50}, title="Colocalization Status"
	
	yPos += 22
	TitleBox tab5_status, pos={xPos+10, yPos}, size={760, 25}
	TitleBox tab5_status, title="Ready for colocalization analysis", frame=1
End

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Tab 4: Statistics
// -----------------------------------------------------------------------------
static Function CreateStatisticsTab()
	Variable yPos = 40
	Variable xPos = kMargin + 10
	Variable groupWidth = 380
	
	// === Summary Plot===
	GroupBox tab6_grp2, pos={xPos, yPos}, size={groupWidth, 215}, title="Statistical Tests (Summary Plot)"
	
	// Run in Auto Analysis 
	CheckBox tab6_chk_autotest, pos={xPos+200, yPos-2}, size={180, kControlHeight}
	CheckBox tab6_chk_autotest, title="Run in Auto Analysis", variable=root:cRunAutoStatTest
	
	yPos += 25
	TitleBox tab6_title1, pos={xPos+10, yPos}, size={350, 20}
	TitleBox tab6_title1, title="Select Summary Plot, then click:", frame=0
	
	yPos += 25
	Button tab6_btn_ttest, pos={xPos+10, yPos}, size={170, 30}
	Button tab6_btn_ttest, title="Welch's t-Test", proc=TTestButtonProc
	
	Button tab6_btn_anova, pos={xPos+190, yPos}, size={170, 30}
	Button tab6_btn_anova, title="Welch's ANOVA", proc=ANOVAButtonProc
	
	yPos += 45
	TitleBox tab6_title3, pos={xPos+10, yPos}, size={150, 20}
	TitleBox tab6_title3, title="Post-hoc test:", frame=0
	
	yPos += 22
	Button tab6_btn_sidak, pos={xPos+10, yPos}, size={170, 30}
	Button tab6_btn_sidak, title="Sidak Correction", proc=SidakButtonProc
	
	// vs Control / All pairs
	CheckBox tab6_chk_vscontrol, pos={xPos+200, yPos}, size={80, 20}
	CheckBox tab6_chk_vscontrol, title="vs Control", value=0, mode=1, proc=SidakModeCheckProc
	
	CheckBox tab6_chk_allpairs, pos={xPos+290, yPos+2}, size={80, 20}
	CheckBox tab6_chk_allpairs, title="All pairs", value=1, mode=1, proc=SidakModeCheckProc
	
	yPos += 45
	TitleBox tab6_title4, pos={xPos+10, yPos}, size={150, 20}
	TitleBox tab6_title4, title="Output options:", frame=0
	
	yPos += 22
	CheckBox tab6_chk_cmdline, pos={xPos+10, yPos}, size={120, 20}
	CheckBox tab6_chk_cmdline, title="Command line", variable=root:cStatOutputCmdLine
	
	CheckBox tab6_chk_graph, pos={xPos+140, yPos}, size={80, 20}
	CheckBox tab6_chk_graph, title="Graph", variable=root:cStatOutputGraph
	
	CheckBox tab6_chk_table, pos={xPos+230, yPos}, size={80, 20}
	CheckBox tab6_chk_table, title="Table", variable=root:cStatOutputTable
	
	// Bracket display parameters (separate GroupBox below grp2)
	yPos += 35
	GroupBox tab6_grp_bracket, pos={xPos, yPos}, size={groupWidth, 55}, title="Significance Bracket"
	
	yPos += 22
	SetVariable tab6_sv_xoff, pos={xPos+8, yPos}, size={65, kControlHeight}
	SetVariable tab6_sv_xoff, title="X:", limits={-2,2,0.1}, value=root:StatBracket_XOffset
	
	SetVariable tab6_sv_starty, pos={xPos+80, yPos}, size={70, kControlHeight}
	SetVariable tab6_sv_starty, title="Y0:", limits={1.0,2.0,0.05}, value=root:StatBracket_StartY
	
	SetVariable tab6_sv_stepy, pos={xPos+157, yPos}, size={68, kControlHeight}
	SetVariable tab6_sv_stepy, title="dY:", limits={0.03,0.50,0.01}, value=root:StatBracket_StepY
	
	SetVariable tab6_sv_tickh, pos={xPos+232, yPos}, size={75, kControlHeight}
	SetVariable tab6_sv_tickh, title="Tick:", limits={0.01,0.20,0.01}, value=root:StatBracket_TickH
	
	SetVariable tab6_sv_tgap, pos={xPos+314, yPos}, size={60, kControlHeight}
	SetVariable tab6_sv_tgap, title="*:", limits={0.01,0.30,0.01}, value=root:StatBracket_TextGap
	
	yPos += 30
	TitleBox tab6_title2, pos={xPos+10, yPos}, size={350, 40}
	TitleBox tab6_title2, title="All tests assume unequal variances", frame=0
End

// =============================================================================
// Button Procedures - 
// =============================================================================

// --- Tab 0: Common ---
Function InitParamsButtonProc(ctrlName) : ButtonControl
	String ctrlName
	InitializeGlobalParameters()
	UpdateStatusBar("Parameters initialized")
	UpdateFormatStatus()
End

Function SaveSettingsButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// 
	Variable refNum
	String fileName
	
	Open/D/F="CSV Files (*.csv):.csv;"/M="Save Settings As" refNum
	fileName = S_fileName
	
	if(strlen(fileName) == 0)
		UpdateStatusBar("Save cancelled")
		return 0
	endif
	
	// 
	Open refNum as fileName
	
	// 
	fprintf refNum, "Parameter,Value\r\n"
	
	// ===  ===
	WriteParamToFile(refNum, "framerate")
	WriteParamToFile(refNum, "FrameNum")
	WriteParamToFile(refNum, "scale")
	WriteParamToFile(refNum, "ROIsize")
	WriteParamToFile(refNum, "MinFrame")
	WriteParamToFile(refNum, "PixNum")
	WriteParamToFile(refNum, "ExCoef")
	WriteParamToFile(refNum, "QE")
	WriteParamToFile(refNum, "IntensityMode")
	
	// ===  ===
	WriteParamToFile(refNum, "cAAS2")
	WriteParamToFile(refNum, "cAAS4")
	WriteParamToFile(refNum, "cHMM")
	WriteParamToFile(refNum, "Dstate")
	WriteParamToFile(refNum, "cHMM2")
	WriteParamToFile(refNum, "Dstate2")
	
	// ===  ===
	WriteParamToFile(refNum, "cRunMSD")
	WriteParamToFile(refNum, "cRunStepSize")
	WriteParamToFile(refNum, "cRunIntensity")
	WriteParamToFile(refNum, "cRunLP")
	WriteParamToFile(refNum, "cRunDensity")
	WriteParamToFile(refNum, "cRunMolDensity")
	WriteParamToFile(refNum, "cRunOffrate")
	WriteParamToFile(refNum, "cRunOnrate")
	WriteParamToFile(refNum, "cRunStateTransition")
	WriteParamToFile(refNum, "cRunTrajectory")
	WriteParamToFile(refNum, "cUseAlignedTraj")
	WriteParamToFile(refNum, "LThreshold")
	WriteParamToFile(refNum, "cSuppressOutput")
	
	// ===  ===
	WriteParamToFile(refNum, "cRunAutoStatTest")
	WriteParamToFile(refNum, "cStatOutputCmdLine")
	WriteParamToFile(refNum, "cStatOutputGraph")
	WriteParamToFile(refNum, "cStatOutputTable")
	
	// ===  ===
	WriteParamToFile(refNum, "MeanIntGauss")
	WriteParamToFile(refNum, "SDIntGauss")
	WriteParamToFile(refNum, "SDIntLognorm")
	WriteParamToFile(refNum, "IhistBin")
	WriteParamToFile(refNum, "IhistDim")
	WriteParamToFile(refNum, "MinOligomerSize")
	WriteParamToFile(refNum, "MaxOligomerSize")
	WriteParamToFile(refNum, "IntNormByS0")
	WriteParamToFile(refNum, "cSumLogNorm")
	WriteParamToFile(refNum, "LogIntensityScale")
	WriteParamToFile(refNum, "cFixMean")
	WriteParamToFile(refNum, "cFixSD")
	WriteParamToFile(refNum, "cFixIntParameters")
	
	// ===  ===
	WriteParamToFile(refNum, "LPhistBin")
	WriteParamToFile(refNum, "LPhistDim")
	
	// ===  ===
	WriteParamToFile(refNum, "FitType")
	WriteParamToFile(refNum, "AreaRangeMSD")
	WriteParamToFile(refNum, "ThresholdMSD")
	WriteParamToFile(refNum, "InitialD0")
	WriteParamToFile(refNum, "InitialL")
	WriteParamToFile(refNum, "InitialEpsilon")
	WriteParamToFile(refNum, "Efix")
	WriteParamToFile(refNum, "InitialAlpha")
	WriteParamToFile(refNum, "AlphaFix")
	WriteParamToFile(refNum, "cMoveAve")
	WriteParamToFile(refNum, "StepHistBin")
	WriteParamToFile(refNum, "StepHistDim")
	WriteParamToFile(refNum, "StepDeltaTMin")
	WriteParamToFile(refNum, "StepDeltaTMax")
	WriteParamToFile(refNum, "StepFitMinStates")
	WriteParamToFile(refNum, "StepFitMaxStates")
	WriteParamToFile(refNum, "StepFitD1")
	WriteParamToFile(refNum, "StepFitScale")
	
	// ===  ===
	WriteParamToFile(refNum, "RHistBin")
	WriteParamToFile(refNum, "RHistDim")
	WriteParamToFile(refNum, "DSmoothing")
	WriteParamToFile(refNum, "DensityStartFrame")
	WriteParamToFile(refNum, "DensityEndFrame")
	
	// === On-time (Off-rate)  ===
	WriteParamToFile(refNum, "cORC")
	WriteParamToFile(refNum, "ExpMin_off")
	WriteParamToFile(refNum, "ExpMax_off")
	WriteParamToFile(refNum, "InitialTau1_off")
	WriteParamToFile(refNum, "TauScale_off")
	WriteParamToFile(refNum, "InitialA1_off")
	WriteParamToFile(refNum, "AScale_off")
	WriteParamToFile(refNum, "cKinOutputTau")
	
	// === On-rate  ===
	WriteParamToFile(refNum, "InitialTauon")
	WriteParamToFile(refNum, "InitialVon")
	WriteParamToFile(refNum, "cUseDensityForOnrate")
	WriteParamToFile(refNum, "OnArea")
	
	// === Colocalization ===
	WriteParamToFile(refNum, "ColIndex")
	WriteParamToFile(refNum, "cSameHMMD")
	WriteParamToFile(refNum, "MaxDistance")
	WriteParamToFile(refNum, "MaxDratio")
	WriteParamToFile(refNum, "ColMinFrame")
	WriteParamToFile(refNum, "ColRoom")
	WriteParamToFile(refNum, "ColIntHistBin")
	WriteParamToFile(refNum, "ColIntHistDim")
	WriteParamToFile(refNum, "ColTau1")
	WriteParamToFile(refNum, "ColTauScale")
	WriteParamToFile(refNum, "ColA1")
	WriteParamToFile(refNum, "ColAScale")
	WriteParamToFile(refNum, "ColWeightingMode")
	WriteParamToFile(refNum, "ColAreaMode")
	WriteParamToFile(refNum, "ColAffinityParam")
	WriteParamToFile(refNum, "ColIntensityMode")
	WriteParamToFile(refNum, "ColDiffusionMode")
	WriteParamToFile(refNum, "ColOntimeMode")
	WriteParamToFile(refNum, "ColOnrateMode")
	WriteParamToFile(refNum, "ColOutputChannel")
	
	// === Segmentation ===
	WriteParamToFile(refNum, "MaxSegment")
	WriteParamToFile(refNum, "SegDuration")
	
	// === Timelapse ===
	WriteParamToFile(refNum, "LigandNumTL")
	WriteParamToFile(refNum, "TimeInterval")
	WriteParamToFile(refNum, "TimePoints")
	WriteParamToFile(refNum, "TimeStimulation")
	WriteParamToFile(refNum, "TL_NormMethod")
	WriteParamToFile(refNum, "TL_DataSource")
	
	// === Input Format ===
	WriteParamToFile(refNum, "cTrackMate")
	WriteParamToFile(refNum, "cVBSPT")
	WriteParamToFile(refNum, "cImage")
	WriteParamToFile(refNum, "PVHistBin")
	WriteParamToFile(refNum, "PVHistDim")

	// === Layout ===
	WriteParamToFile(refNum, "LayoutPageW")
	WriteParamToFile(refNum, "LayoutPageH")
	WriteParamToFile(refNum, "LayoutDivW")
	WriteParamToFile(refNum, "LayoutDivH")
	WriteParamToFile(refNum, "LayoutGap")
	WriteParamToFile(refNum, "LayoutOffset")
	
	// === Significance Bracket ===
	WriteParamToFile(refNum, "StatBracket_XOffset")
	WriteParamToFile(refNum, "StatBracket_TextGap")
	WriteParamToFile(refNum, "StatBracket_StartY")
	WriteParamToFile(refNum, "StatBracket_StepY")
	WriteParamToFile(refNum, "StatBracket_TickH")
	
	Close refNum
	
	UpdateStatusBar("Settings saved to: " + fileName)
	Print "Settings saved to: " + fileName
End

// 
static Function WriteParamToFile(refNum, paramName)
	Variable refNum
	String paramName
	
	String fullPath = "root:" + paramName
	NVAR/Z v = $fullPath
	if(NVAR_Exists(v))
		fprintf refNum, "%s,%g\r\n", paramName, v
	endif
End

Function LoadSettingsButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// 
	Variable refNum
	String fileName
	
	Open/R/D/F="CSV Files (*.csv):.csv;"/M="Load Settings" refNum
	fileName = S_fileName
	
	if(strlen(fileName) == 0)
		UpdateStatusBar("Load cancelled")
		return 0
	endif
	
	// 
	Open/R refNum as fileName
	
	String line, paramName, paramValue
	Variable value
	
	// 
	FReadLine refNum, line
	
	// 
	do
		FReadLine refNum, line
		if(strlen(line) == 0)
			break
		endif
		
		// 
		paramName = StringFromList(0, line, ",")
		paramValue = StringFromList(1, line, ",")
		
		// 
		paramName = ReplaceString("\r", paramName, "")
		paramName = ReplaceString("\n", paramName, "")
		paramValue = ReplaceString("\r", paramValue, "")
		paramValue = ReplaceString("\n", paramValue, "")
		
		value = str2num(paramValue)
		
		// 
		SetGlobalParamByName(paramName, value)
	while(1)
	
	Close refNum
	
	// 
	UpdateFormatStatus()
	
	// Sync popup modes with loaded values
	NVAR/Z loadedFitType = root:FitType
	if(NVAR_Exists(loadedFitType))
		PopupMenu tab2_fittype, win=SMI_MainPanel, mode=(loadedFitType + 1)
	endif
	NVAR/Z lColAffinity = root:ColAffinityParam
	if(NVAR_Exists(lColAffinity))
		PopupMenu tab5_pop_affinity, win=SMI_MainPanel, mode=(lColAffinity + 1)
		PopupMenu tab9_pop_affinity, win=SMI_MainPanel, mode=(lColAffinity + 1)
	endif
	NVAR/Z lColIntensity = root:ColIntensityMode
	if(NVAR_Exists(lColIntensity))
		PopupMenu tab5_pop_intensity, win=SMI_MainPanel, mode=(lColIntensity + 1)
		PopupMenu tab9_pop_intensity, win=SMI_MainPanel, mode=(lColIntensity + 1)
	endif
	NVAR/Z lColDiffusion = root:ColDiffusionMode
	if(NVAR_Exists(lColDiffusion))
		PopupMenu tab5_pop_diffusion, win=SMI_MainPanel, mode=(lColDiffusion + 1)
		PopupMenu tab9_pop_diffusion, win=SMI_MainPanel, mode=(lColDiffusion + 1)
	endif
	NVAR/Z lColOntime = root:ColOntimeMode
	if(NVAR_Exists(lColOntime))
		PopupMenu tab5_pop_ontime, win=SMI_MainPanel, mode=(lColOntime + 1)
		PopupMenu tab9_pop_ontime, win=SMI_MainPanel, mode=(lColOntime + 1)
	endif
	NVAR/Z lColOnrate = root:ColOnrateMode
	if(NVAR_Exists(lColOnrate))
		PopupMenu tab5_pop_onrate, win=SMI_MainPanel, mode=(lColOnrate + 1)
		PopupMenu tab9_pop_onrate, win=SMI_MainPanel, mode=(lColOnrate + 1)
	endif
	NVAR/Z lColOutCh = root:ColOutputChannel
	if(NVAR_Exists(lColOutCh))
		PopupMenu tab5_pop_channel, win=SMI_MainPanel, mode=(lColOutCh + 1)
		PopupMenu tab9_pop_outchan, win=SMI_MainPanel, mode=(lColOutCh + 1)
		PopupMenu tab9_pop_channel, win=SMI_MainPanel, mode=(lColOutCh + 1)
	endif
	NVAR/Z lColWtMode = root:ColWeightingMode
	if(NVAR_Exists(lColWtMode))
		PopupMenu tab5_pop_weighting, win=SMI_MainPanel, mode=(lColWtMode + 1)
		PopupMenu tab9_pop_weighting, win=SMI_MainPanel, mode=(lColWtMode + 1)
	endif
	NVAR/Z lTL_NormMeth = root:TL_NormMethod
	if(NVAR_Exists(lTL_NormMeth))
		PopupMenu tab7_popup_normby, win=SMI_MainPanel, mode=(lTL_NormMeth + 1)
		PopupMenu tab7_popup_normby2, win=SMI_MainPanel, mode=(lTL_NormMeth + 1)
	endif
	NVAR/Z lTL_DataSrc = root:TL_DataSource
	if(NVAR_Exists(lTL_DataSrc))
		PopupMenu tab7_popup_datasource, win=SMI_MainPanel, mode=(lTL_DataSrc + 1)
	endif
	
	// Sync IntensityMode popup
	NVAR/Z lIntMode = root:IntensityMode
	if(NVAR_Exists(lIntMode))
		PopupMenu tab0_intensitymode, win=SMI_MainPanel, mode=(lIntMode + 1)
	endif

	UpdateStatusBar("Settings loaded from: " + fileName)
	Print "Settings loaded from: " + fileName
End

// 
static Function SetGlobalParamByName(paramName, value)
	String paramName
	Variable value
	
	String fullPath = "root:" + paramName
	NVAR/Z v = $fullPath
	if(NVAR_Exists(v))
		v = value
	else
		// Create variable if not found (backward compatibility: new params in settings file)
		Variable/G $fullPath = value
	endif
End

// --- Tab 1: Data Loading ---
Function LoadDataButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// 
	EnsureGlobalParameters()
	
	// user-defined name
	NVAR cUseUserDefined = root:cUseUserDefinedName
	Variable useUserDefined = cUseUserDefined
	
	String sampleName = ""
	String fullPath = ""
	
	if(useUserDefined)
		// Read SampleName from global variable (same as FullAllAnalysisProc)
		SVAR/Z gSampleName = root:gSampleNameInput
		if(SVAR_Exists(gSampleName))
			sampleName = gSampleName
		endif
		
		if(strlen(sampleName) == 0)
			DoAlert 0, "Please enter a sample name"
			return 0
		endif
		
		// Open folder dialog to get path
		GetFileFolderInfo/D/Q
		fullPath = S_Path
		
		if(strlen(fullPath) == 0)
			UpdateStatusBar("Cancelled")
			return 0
		endif
	else
		// SampleName
		// 
		GetFileFolderInfo/D/Q
		fullPath = S_Path
		
		if(strlen(fullPath) == 0)
			UpdateStatusBar("Cancelled")
			return 0
		endif
		
		// SampleName
		sampleName = ExtractFolderName(fullPath)
		
		if(strlen(sampleName) == 0)
			DoAlert 0, "Could not extract folder name"
			return 0
		endif
		
		// 
		SetVariable tab1_samplename, win=SMI_MainPanel, value=_STR:sampleName
		SVAR/Z gSampleName = root:gSampleNameInput
		if(SVAR_Exists(gSampleName))
			gSampleName = sampleName
		endif
	endif
	
	// 
	NVAR/Z cAAS4 = root:cAAS4
	NVAR/Z cHMM = root:cHMM
	NVAR/Z Dstate = root:Dstate
	
	Variable isAAS4 = 0
	Variable isHMM = 0
	Variable dstateVal = 4
	if(NVAR_Exists(cAAS4))
		isAAS4 = cAAS4
	endif
	if(NVAR_Exists(cHMM))
		isHMM = cHMM
	endif
	if(NVAR_Exists(Dstate))
		dstateVal = Dstate
	endif
	
	String formatStr = ""
	if(isAAS4)
		formatStr = "AAS4"
	else
		formatStr = "AAS2"
	endif
	if(isHMM)
		formatStr += " + HMM (n=" + num2str(dstateVal) + ")"
	endif
	
	// Step 1: Load Data
	UpdateStatusBar("Loading " + formatStr + " data...")
	Variable numLoaded = 0
	
	if(strlen(fullPath) > 0)
		// Path specified (both user-defined and auto mode)
		numLoaded = SMI_LoadDataPath(fullPath, sampleName)
	else
		// Fallback: open file dialog
		numLoaded = SMI_LoadData(sampleName)
	endif
	
	if(numLoaded == 0)
		UpdateStatusBar("No data loaded")
		return 0
	endif
	
	// 
	SetCurrentSampleName(sampleName)
	
	// Step 2: Convert TraceMatrix time base
	UpdateStatusBar("Converting time base...")
	MakeTraceMatrixTimeBase(sampleName)
	
	// Step 3: Make Analysis Waves with NaN separators
	UpdateStatusBar("Creating analysis waves...")
	MakeAnalysisWavesS0(sampleName)
	
	// Step 4: HMMDstate
	NVAR/Z cHMM2 = root:cHMM
	NVAR/Z Dstate2 = root:Dstate
	if(NVAR_Exists(cHMM2) && cHMM2 == 1 && NVAR_Exists(Dstate2) && Dstate2 > 0)
		UpdateStatusBar("Separating by Dstate...")
		MakeAnalysisWavesHMM(sampleName)
	endif
	
	// Step 5: Create Results folder
	CreateResultsFolder(sampleName)
	
	// Step 6: Segmentation Split (Seg≥1)
	NVAR/Z MaxSegment = root:MaxSegment
	if(NVAR_Exists(MaxSegment) && MaxSegment >= 1)
		UpdateStatusBar("Splitting by Segment...")
		RunSegmentationSplit(sampleName)
	endif
	
	UpdateStatusBar("Complete: " + num2str(numLoaded) + " cells (" + formatStr + ")")
	UpdateDataInfo(sampleName)
	UpdateFormatStatus()
End

Function LPHistButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	// ===  ===
	UpdateStatusBar("Creating localization precision histogram...")
	CalculateLPHistogram(sampleName)
	DisplayLPHistogram(sampleName)
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			UpdateStatusBar("Creating LP histogram (Seg" + num2str(segIdx) + ")...")
			CalculateLPHistogram(sampleName, basePath=basePath, waveSuffix=segSuffix)
			DisplayLPHistogram(sampleName, basePath=basePath, waveSuffix=segSuffix)
			// 
			StatsResultsMatrix(basePath, sampleName, "")
		endfor
	endif
	
	UpdateStatusBar("Localization precision histogram created")
End

Function DensityGcountButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	// ===  ===
	UpdateStatusBar("Running Density analysis (Ripley K-function)...")
	Density_Gcount(sampleName)
	DisplayDensityGcount(sampleName)
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			UpdateStatusBar("Running Density analysis (Seg" + num2str(segIdx) + ")...")
			Density_Gcount(sampleName, basePath=basePath, waveSuffix=segSuffix)
			DisplayDensityGcount(sampleName, basePath=basePath, waveSuffix=segSuffix)
			// 
			StatsResultsMatrix(basePath, sampleName, "")
		endfor
	endif
	
	UpdateStatusBar("Density analysis complete")
End

Function MolDensityButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	// ===  ===
	UpdateStatusBar("Calculating molecular density...")
	Variable result
	result = CalculateMolecularDensity(sampleName)
	
	// 
	if(result == 1)
		DisplayMolecularDensity(sampleName)
		UpdateStatusBar("Molecular density calculation complete")
	else
		UpdateStatusBar("Molecular density calculation aborted - prerequisites not met")
	endif
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			UpdateStatusBar("Calculating molecular density (Seg" + num2str(segIdx) + ")...")
			CalculateMolecularDensity(sampleName, basePath=basePath, waveSuffix=segSuffix)
			DisplayMolecularDensity(sampleName, basePath=basePath, waveSuffix=segSuffix)
			// 
			StatsResultsMatrix(basePath, sampleName, "")
		endfor
	endif
End

// Fit Func
Function CheckHistogramFitConsistency(sampleName)
	String sampleName
	
	// Fit Func
	NVAR/Z cSumLogNorm = root:cSumLogNorm
	Variable wantLogScale = 0
	if(NVAR_Exists(cSumLogNorm) && cSumLogNorm == 1)
		wantLogScale = 1
	endif
	
	// 
	String FolderName = sampleName + "1"
	SetDataFolder root:$(sampleName):$(FolderName)
	
	NVAR/Z LogIntensityScale = LogIntensityScale
	Variable histIsLogScale = 0
	if(NVAR_Exists(LogIntensityScale) && LogIntensityScale == 1)
		histIsLogScale = 1
	endif
	
	SetDataFolder root:
	
	// 
	if(wantLogScale != histIsLogScale)
		String msg
		if(wantLogScale)
			msg = "Warning: LogNorm fitting selected but histogram was created with linear scale.\n\n"
			msg += "Please re-create histogram with LogNorm selected, then try fitting again."
		else
			msg += "Warning: Gauss fitting selected but histogram was created with log scale.\n\n"
			msg += "Please re-create histogram with Gauss selected, then try fitting again."
		endif
		DoAlert 0, msg
		return 0
	endif
	
	return 1
End

Function IntAICButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	// Fit Func
	if(!CheckHistogramFitConsistency(sampleName))
		return 0
	endif
	
	NVAR minOlig = root:MinOligomerSize
	NVAR maxOlig = root:MaxOligomerSize
	
	UpdateStatusBar("Running Global AIC model selection...")
	GlobalAICModelSelection(sampleName, minOlig, maxOlig)
	DisplayPopulationGraph(sampleName)
	UpdateStatusBar("Global AIC model selection complete")
End

Function RunMSDButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	NVAR fitType = root:FitType
	
	// === Total===
	UpdateStatusBar("Running full MSD analysis...")
	CalculateMSD(sampleName)
	FitMSD_Safe(sampleName, fitType)
	DisplayMSDGraphHMM(sampleName)
	
	// 
	UpdateStatusBar("Updating statistics...")
	StatsResultsMatrix("root", sampleName, "")
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			
			// Seg
			String segSamplePath = basePath + ":" + sampleName
			if(!DataFolderExists(segSamplePath))
				Printf "Seg%d folder not found: %s, skipping\r", segIdx, segSamplePath
				continue
			endif
			
			UpdateStatusBar("Running MSD analysis (Seg" + num2str(segIdx) + ")...")
			CalculateMSD(sampleName, basePath=basePath, waveSuffix=segSuffix)
			FitMSD_Safe(sampleName, fitType, basePath=basePath, waveSuffix=segSuffix)
			DisplayMSDGraphHMM(sampleName, basePath=basePath, waveSuffix=segSuffix)
			StatsResultsMatrix(basePath, sampleName, "")
		endfor
	endif
	
	UpdateStatusBar("MSD analysis complete")
	UpdateSMIResults(sampleName)
End

// : Step Hist + Fit Step
Function RunStepHistButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	NVAR/Z cHMM = root:cHMM
	
	// Step 1: 
	UpdateStatusBar("Calculating step size histogram...")
	CalculateStepSizeHistogramHMM(sampleName)
	
	// Step 2: 
	ControlInfo/W=SMI_MainPanel tab2_stepminstates
	Variable minStates = V_Value
	ControlInfo/W=SMI_MainPanel tab2_stepmaxstates
	Variable maxStates = V_Value
	
	if(minStates < 1)
		minStates = 1
	endif
	if(maxStates > 5)
		maxStates = 5
	endif
	if(minStates > maxStates)
		Variable temp = minStates
		minStates = maxStates
		maxStates = temp
	endif
	
	UpdateStatusBar("Fitting step size distribution...")
	if(NVAR_Exists(cHMM) && cHMM == 1)
		FitStepSizeDistributionHMM(sampleName, 1)
	else
		if(minStates == maxStates)
			FitStepSizeDistributionHMM(sampleName, minStates)
		else
			FitStepSizeWithAIC_NonHMM(sampleName, minStates, maxStates)
		endif
	endif
	
	DisplayStepSizeHistogramHMM(sampleName)
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			
			UpdateStatusBar("Calculating step size histogram (Seg" + num2str(segIdx) + ")...")
			CalculateStepSizeHistogramHMM(sampleName, basePath=basePath, waveSuffix=segSuffix)
			
			UpdateStatusBar("Fitting step size (Seg" + num2str(segIdx) + ")...")
			if(NVAR_Exists(cHMM) && cHMM == 1)
				FitStepSizeDistributionHMM(sampleName, 1, basePath=basePath, waveSuffix=segSuffix)
			else
				if(minStates == maxStates)
					FitStepSizeDistributionHMM(sampleName, minStates, basePath=basePath, waveSuffix=segSuffix)
				else
					// FitStepSizeWithAIC_NonHMM basePath
				endif
			endif
			
			DisplayStepSizeHistogramHMM(sampleName, basePath=basePath, waveSuffix=segSuffix)
			
			// 
			StatsResultsMatrix(basePath, sampleName, "")
		endfor
	endif
	
	UpdateStatusBar("Step size histogram analysis complete")
End

// : Intensity Histogram + Fit
Function RunIntHistButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	// LogNorm
	NVAR/Z cSumLogNorm = root:cSumLogNorm
	Variable useLogScale = 0
	if(NVAR_Exists(cSumLogNorm) && cSumLogNorm == 1)
		useLogScale = 1
	endif
	
	// 
	NVAR maxOlig = root:MaxOligomerSize
	NVAR/Z cFixMean = root:cFixMean
	NVAR/Z cFixSD = root:cFixSD
	
	Variable fixMean = 0, fixSD = 0
	if(NVAR_Exists(cFixMean))
		fixMean = cFixMean
	endif
	if(NVAR_Exists(cFixSD))
		fixSD = cFixSD
	endif
	
	// === Total (root:SampleName) ===
	// Step 1: 
	if(useLogScale)
		UpdateStatusBar("Creating log-intensity histogram...")
		CreateIntensityHistogramLog(sampleName)
	else
		UpdateStatusBar("Creating intensity histogram...")
		CreateIntensityHistogram(sampleName)
	endif
	
	// Step 2: 
	UpdateStatusBar("Global fitting intensity distribution...")
	GlobalFitIntensity(sampleName, maxOlig, fixMean, fixSD)
	
	// Step 3: 
	DisplayIntensityHistGraph(sampleName)
	DisplayPopulationGraph(sampleName)
	
	// Step 4: 
	StatsResultsMatrix("root", sampleName, "")
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			
			// Seg
			String segSamplePath = basePath + ":" + sampleName
			if(!DataFolderExists(segSamplePath))
				Printf "Seg%d folder not found: %s, skipping\r", segIdx, segSamplePath
				continue
			endif
			
			Printf "=== Intensity Analysis Seg%d ===\r", segIdx
			
			// LogbasePath
			UpdateStatusBar("Creating intensity histogram (Seg" + num2str(segIdx) + ")...")
			CreateIntensityHistogram(sampleName, basePath=basePath, waveSuffix=segSuffix)
			
			// 
			UpdateStatusBar("Global fitting (Seg" + num2str(segIdx) + ")...")
			GlobalFitIntensity(sampleName, maxOlig, fixMean, fixSD, basePath=basePath, waveSuffix=segSuffix)
			
			// 
			DisplayIntensityHistHMM(sampleName, basePath=basePath, waveSuffix=segSuffix)
			
			// PopulationMean Oligomer SizeCompare
			CalculatePopulationFromCoefEx(sampleName, basePath, segSuffix)
			
			// 
			StatsResultsMatrix(basePath, sampleName, "")
		endfor
	endif
	
	UpdateStatusBar("Intensity histogram analysis complete")
End

Function MSDHeatmapButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// Δt max >= 2 Heatmap
	NVAR/Z StepDeltaTMax = root:StepDeltaTMax
	if(NVAR_Exists(StepDeltaTMax) && StepDeltaTMax < 2)
		DoAlert 0, "Heatmap requires Δt max ≥ 2"
		return 0
	endif
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	UpdateStatusBar("Creating MSD Heatmap...")
	CreateMSDHeatmap(sampleName)
	UpdateStatusBar("MSD Heatmap complete")
End

// Duration (On-time) 
Function DurationButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	// ===  ===
	UpdateStatusBar("Running Duration (On-time) analysis...")
	Duration_Gcount(sampleName)
	
	// Total
	StatsResultsMatrix("root", sampleName, "")
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			UpdateStatusBar("Running Duration analysis (Seg" + num2str(segIdx) + ")...")
			Duration_Gcount(sampleName, basePath=basePath, waveSuffix=segSuffix)
			// 
			StatsResultsMatrix(basePath, sampleName, "")
		endfor
	endif
	
	UpdateStatusBar("Duration analysis complete")
End

Function FitTypePopupProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	// MSD Fit Type: 1=Free, 2=Confined, 3=Confined+Err, 4=Anomalous, 5=Anomalous+Err
	Variable/G root:FitType = popNum - 1
End

Function IntFitTypePopupProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	// Intensity Fit Type: 1=Gauss, 2=LogNorm
	NVAR cSumGauss = root:cSumGauss
	NVAR cSumLogNorm = root:cSumLogNorm
	
	if(popNum == 1)
		cSumGauss = 1
		cSumLogNorm = 0
	else
		cSumGauss = 0
		cSumLogNorm = 1
	endif
End

// Auto-update OnArea when PixNum or scale changes: OnArea = (PixNum * scale)^2
Function UpdateDerivedParamsProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	if(sva.eventCode != 1 && sva.eventCode != 2 && sva.eventCode != 8)
		return 0
	endif
	NVAR PixNum = root:PixNum
	NVAR scale = root:scale
	NVAR OnArea = root:OnArea
	OnArea = (PixNum * scale) * (PixNum * scale)
	return 0
End

// Use Density
Function UseDensityCheckProc(ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
End

// On-rate
Function OnrateButtonProc2(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	NVAR/Z cUseDensity = root:cUseDensityForOnrate
	
	// DensityDensity
	if(NVAR_Exists(cUseDensity) && cUseDensity == 1)
		Variable numFolders = CountDataFolders(sampleName)
		if(numFolders > 0)
			String firstFolder = sampleName + "1"
			String folderPath = "root:" + sampleName + ":" + firstFolder + ":"
			Wave/Z ParaDensityAvg = $(folderPath + "ParaDensityAvg")
			
			if(!WaveExists(ParaDensityAvg))
				DoAlert 0, "Density analysis has not been performed.\n\nPlease run 'Density' analysis first (in Intensity tab),\nor uncheck 'Use Density result' to use fixed area."
				return 0
			endif
		endif
	endif
	
	// ===  ===
	UpdateStatusBar("Running on-rate analysis...")
	OnrateAnalysisWithOption(sampleName)
	
	// Total
	StatsResultsMatrix("root", sampleName, "")
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			UpdateStatusBar("Running on-rate analysis (Seg" + num2str(segIdx) + ")...")
			OnrateAnalysisWithOption(sampleName, basePath=basePath, waveSuffix=segSuffix)
			// 
			StatsResultsMatrix(basePath, sampleName, "")
		endfor
	endif
	
	UpdateStatusBar("On-rate analysis complete")
End

// State Transition
Function StateTransitionButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	UpdateStatusBar("Running state transition analysis...")
	RunStateTransitionAnalysis(sampleName)
	UpdateStatusBar("State transition analysis complete")
End

// Use user-defined name 
Function UserDefinedNameCheckProc(ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	// 
	DoWindow SMI_MainPanel
	if(V_flag == 0)
		return 0
	endif
	
	// Sample Name/
	Variable disableVal = checked ? 0 : 2
	
	// tab0 (AutoAnalysis)
	SetVariable tab0_samplename, win=SMI_MainPanel, disable=disableVal
End

// AAS v2 v4
Function AAS2CheckProc(ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR/Z cAAS2 = root:cAAS2
	NVAR/Z cAAS4 = root:cAAS4
	
	if(checked)
		// v2ONv4OFF
		if(NVAR_Exists(cAAS4))
			cAAS4 = 0
		endif
	endif
End

// AAS v4 v2
Function AAS4CheckProc(ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR/Z cAAS2 = root:cAAS2
	NVAR/Z cAAS4 = root:cAAS4
	
	if(checked)
		// v4ONv2OFF
		if(NVAR_Exists(cAAS2))
			cAAS2 = 0
		endif
	endif
End

// -----------------------------------------------------------------------------
// Intensity Mode PopupMenu 
// 0=Raw Intensity, 1=Photon number
// -----------------------------------------------------------------------------
Function IntensityModePopProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR/Z IntensityMode = root:IntensityMode
	if(!NVAR_Exists(IntensityMode))
		Variable/G root:IntensityMode = 1
		NVAR IntensityMode = root:IntensityMode
	endif
	
	IntensityMode = popNum - 1  // PopupMenu is 1-indexed, IntensityMode is 0-indexed
	
	if(IntensityMode == 0)
		Print "Intensity mode: Raw Intensity"
	else
		Print "Intensity mode: Photon number (Raw × ExCoef/QE)"
	endif
End

// -----------------------------------------------------------------------------
// Mol Density
// Mol DensityIntensity HistogramDensity
// -----------------------------------------------------------------------------
Function MolDensityCheckProc(ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	if(checked)
		// Mol DensityONIntensity HistogramDensityON
		NVAR/Z cRunIntensity = root:cRunIntensity
		NVAR/Z cRunDensity = root:cRunDensity
		
		if(NVAR_Exists(cRunIntensity) && cRunIntensity == 0)
			cRunIntensity = 1
			Print "Note: Intensity Histogram automatically enabled (required for Mol Density)"
		endif
		
		if(NVAR_Exists(cRunDensity) && cRunDensity == 0)
			cRunDensity = 1
			Print "Note: Density automatically enabled (required for Mol Density)"
		endif
	endif
End

// -----------------------------------------------------------------------------
// Diffusion 
// -----------------------------------------------------------------------------
Function FullDiffusionTabProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	// 
	NVAR/Z cRunMSD = root:cRunMSD
	NVAR/Z cRunStepSize = root:cRunStepSize
	NVAR fitType = root:FitType
	
	Variable doMSD = NVAR_Exists(cRunMSD) ? cRunMSD : 1
	Variable doStepSize = NVAR_Exists(cRunStepSize) ? cRunStepSize : 1
	
	if(!doMSD && !doStepSize)
		DoAlert 0, "No Diffusion analysis enabled.\nCheck MSD or Step Size in Diffusion tab."
		return 0
	endif
	
	UpdateStatusBar("Running Diffusion analysis...")
	
	if(doMSD)
		Print "--- MSD Analysis ---"
		SMI_AnalyzeMSD(sampleName, fitType)
	endif
	
	if(doStepSize)
		Print "--- Step Size Analysis ---"
		SMI_AnalyzeStepSize(sampleName)
	endif
	
	// 
	UpdateStatusBar("Updating statistics...")
	StatsResultsMatrix("root", sampleName, "")
	
	UpdateStatusBar("Diffusion analysis complete")
	UpdateSMIResults(sampleName)
End

// -----------------------------------------------------------------------------
// Intensity 
// -----------------------------------------------------------------------------
Function FullIntensityTabProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	// 
	NVAR/Z cRunIntensity = root:cRunIntensity
	NVAR/Z cRunLP = root:cRunLP
	NVAR/Z cRunDensity = root:cRunDensity
	NVAR/Z cRunMolDensity = root:cRunMolDensity
	NVAR maxOlig = root:MaxOligomerSize
	
	Variable doIntensity = NVAR_Exists(cRunIntensity) ? cRunIntensity : 1
	Variable doLP = NVAR_Exists(cRunLP) ? cRunLP : 1
	Variable doDensity = NVAR_Exists(cRunDensity) ? cRunDensity : 1
	Variable doMolDensity = NVAR_Exists(cRunMolDensity) ? cRunMolDensity : 1
	
	if(!doIntensity && !doLP && !doDensity && !doMolDensity)
		DoAlert 0, "No Intensity analysis enabled.\nCheck options in Intensity tab."
		return 0
	endif
	
	UpdateStatusBar("Running Intensity analysis...")
	
	if(doIntensity)
		Print "--- Intensity Histogram Analysis ---"
		SMI_AnalyzeIntensity(sampleName, maxOlig)
	endif
	
	if(doLP)
		Print "--- Localization Precision Analysis ---"
		SMI_AnalyzeLP(sampleName)
	endif
	
	if(doDensity)
		Print "--- Density Analysis ---"
		SMI_AnalyzeDensity(sampleName)
	endif
	
	if(doMolDensity)
		Print "--- Molecular Density Analysis ---"
		SMI_AnalyzeMolDensity(sampleName)
	endif
	
	// 
	UpdateStatusBar("Updating statistics...")
	StatsResultsMatrix("root", sampleName, "")
	
	UpdateStatusBar("Intensity analysis complete")
	UpdateSMIResults(sampleName)
End

// -----------------------------------------------------------------------------
// Kinetics 
// -----------------------------------------------------------------------------
Function FullKineticsTabProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	// 
	NVAR/Z cRunOffrate = root:cRunOffrate
	NVAR/Z cRunOnrate = root:cRunOnrate
	NVAR/Z cRunStateTransition = root:cRunStateTransition
	NVAR/Z cHMM = root:cHMM
	
	Variable doOffrate = NVAR_Exists(cRunOffrate) ? cRunOffrate : 1
	Variable doOnrate = NVAR_Exists(cRunOnrate) ? cRunOnrate : 1
	Variable doStateTransition = NVAR_Exists(cRunStateTransition) ? cRunStateTransition : 1
	Variable isHMM = NVAR_Exists(cHMM) ? cHMM : 0
	
	if(!doOffrate && !doOnrate && !doStateTransition)
		DoAlert 0, "No Kinetics analysis enabled.\nCheck options in Kinetics tab."
		return 0
	endif
	
	UpdateStatusBar("Running Kinetics analysis...")
	
	if(doOffrate)
		Print "--- Off-rate (Duration) Analysis ---"
		Duration_Gcount(sampleName)
	endif
	
	if(doOnrate)
		Print "--- On-rate Analysis ---"
		OnrateAnalysisWithOption(sampleName)
	endif
	
	// HMMState Transition
	if(isHMM && doStateTransition)
		Print "--- State Transition Analysis ---"
		RunStateTransitionAnalysis(sampleName)
	endif
	
	// 
	UpdateStatusBar("Updating statistics...")
	StatsResultsMatrix("root", sampleName, "")
	
	UpdateStatusBar("Kinetics analysis complete")
	UpdateSMIResults(sampleName)
End

// Single Analysis 
Function FullAllAnalysisProc(ctrlName) : ButtonControl
	String ctrlName

	//
	NVAR/Z cUseUserDefined = root:cUseUserDefinedName
	Variable useUserDefined = NVAR_Exists(cUseUserDefined) ? cUseUserDefined : 0
	
	// SampleName
	SVAR/Z gSampleName = root:gSampleNameInput
	
	String sampleName = ""
	String fullPath = ""
	Variable analysisResult = 0
	
	if(useUserDefined)
		// SampleName
		if(SVAR_Exists(gSampleName))
			sampleName = gSampleName
		endif
		
		if(strlen(sampleName) == 0)
			DoAlert 0, "Please enter a sample name"
			return 0
		endif
		
		UpdateStatusBar("Single Analysis (user-defined name)...")
		
		// 
		GetFileFolderInfo/D/Q
		fullPath = S_Path
		
		if(strlen(fullPath) == 0)
			UpdateStatusBar("Cancelled")
			return 0
		endif
		
		// SampleNameLoad
		analysisResult = SingleSampleAnalysis(fullPath, sampleName)
	else
		// SampleName
		UpdateStatusBar("Single Analysis (folder name)...")
		
		// 
		GetFileFolderInfo/D/Q
		fullPath = S_Path
		
		if(strlen(fullPath) == 0)
			UpdateStatusBar("Cancelled")
			return 0
		endif
		
		// SampleName
		sampleName = ExtractFolderName(fullPath)
		
		if(strlen(sampleName) == 0)
			DoAlert 0, "Could not extract folder name"
			return 0
		endif
		
		// CommonLoad
		if(SVAR_Exists(gSampleName))
			gSampleName = sampleName
		endif
		
		analysisResult = SingleSampleAnalysis(fullPath, sampleName)
	endif
	
	if(analysisResult == -1)
		UpdateStatusBar("Analysis failed - no data loaded")
		DoAlert 0, "No data loaded. Please check your data files and format settings."
		return 0
	endif
	
	// 
	SetCurrentSampleName(sampleName)
	
	UpdateStatusBar("Single Analysis complete: " + sampleName)
	UpdateSMIResults(sampleName)
	UpdateDataInfo(sampleName)
End

// Auto Analysis All Batch → Clear Graph → Clear Table → Average → Compare
Function AutoAnalysisAllProc(ctrlName) : ButtonControl
	String ctrlName
	
	Printf "========================================\r"
	Print "=== Auto Analysis All  ==="
	Printf "========================================\r"
	
	// Step 1: Batch Analysis
	Print "Step 1/6: Batch Analysis..."
	BatchAnalysisProc("auto")
	
	// Step 2: Clear All Graphs
	Print "Step 2/6: Clear All Graphs..."
	ClearAllGraphs()
	
	// Step 3: Clear All Tables
	Print "Step 3/6: Clear All Tables..."
	ClearAllTables()
	
	// Step 4: Average All
	Print "Step 4/6: Average All..."
	AverageAllButtonProc("auto")
	
	// Step 5: Compare All
	Print "Step 5/6: Compare All..."
	CompareAllButtonProc("auto")
	
	// Step 6: Cleanup temporary waves
	Print "Step 6/6: Cleanup temporary waves..."
	CleanupTempWaves(verbose=0)
	
	Printf "========================================\r"
	Print "=== Auto Analysis All  ==="
	Printf "========================================\r"
	
	UpdateStatusBar("Auto Analysis All complete")
End

// Reanalyze All: run full analysis pipeline on all existing Igor data folders (skip Load)
// Automatically enumerates root: folders, excluding system/utility folders and Index_*
Function ReanalyzeAllProc(ctrlName) : ButtonControl
	String ctrlName

	// Enumerate all sample folders (same filter as GetAnalyzedSampleList)
	String sampleList = GetAnalyzedSampleList()
	if(CmpStr(sampleList, "(No samples loaded)") == 0)
		DoAlert 0, "No sample folders found in Igor."
		return -1
	endif

	Variable numSamples = ItemsInList(sampleList)
	Printf "Reanalyze All: found %d sample folders\r", numSamples

	EnsureGlobalParameters()

	Variable ii, successCount = 0
	String oneSample
	Variable sampleResult

	Printf "========================================\r"
	Printf "=== Reanalyze All (%d samples) ===\r", numSamples
	Printf "========================================\r"

	for(ii = 0; ii < numSamples; ii += 1)
		oneSample = StringFromList(ii, sampleList)
		Printf "\r========== [%d/%d] %s ==========\r", ii+1, numSamples, oneSample
		sampleResult = ReanalyzeSingleSample(oneSample)
		if(sampleResult > 0)
			successCount += 1
		endif
	endfor

	// Post-processing (same as AutoAnalysisAllProc)
	Print "Reanalyze: Clear All Graphs..."
	ClearAllGraphs()

	Print "Reanalyze: Clear All Tables..."
	ClearAllTables()

	Print "Reanalyze: Average All..."
	AverageAllButtonProc("auto")

	Print "Reanalyze: Compare All..."
	CompareAllButtonProc("auto")

	Print "Reanalyze: Cleanup..."
	CleanupTempWaves(verbose=0)

	Printf "========================================\r"
	Printf "=== Reanalyze All Complete: %d / %d ===\r", successCount, numSamples
	Printf "========================================\r"

	UpdateStatusBar("Reanalyze All complete: " + num2str(successCount) + " / " + num2str(numSamples) + " samples")
End

// Batch Analysis 
Function BatchAnalysisProc(ctrlName) : ButtonControl
	String ctrlName
	
	// 
	EnsureGlobalParameters()
	
	UpdateStatusBar("Select parent folder containing sample folders...")
	
	// 
	GetFileFolderInfo/D/Q
	String parentPath = S_Path
	
	if(strlen(parentPath) == 0)
		UpdateStatusBar("Cancelled")
		return 0
	endif
	
	Printf "========================================\r"
	Printf "Batch Analysis\r"
	Printf "Parent folder: %s\r", parentPath
	Printf "========================================\r"
	
	// 
	Variable numSamples
	numSamples = BatchAutoAnalysis(parentPath)
	
	if(numSamples <= 0)
		UpdateStatusBar("Batch Analysis failed - no sample folders found")
		DoAlert 0, "No sample folders found in the selected directory."
		return 0
	endif
	
	UpdateStatusBar("Batch Analysis complete: " + num2str(numSamples) + " samples")
	
	// 
	SVAR/Z gSampleName = root:gCurrentSampleName
	if(SVAR_Exists(gSampleName) && strlen(gSampleName) > 0)
		UpdateSMIResults(gSampleName)
		UpdateDataInfo(gSampleName)
	endif
End

// Average All Run in Auto AnalysisAverage
Function AverageAllButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// 
	EnsureGlobalParameters()
	
	Printf "========================================\r"
	Print "Average All Analysis "
	Printf "========================================\r"
	
	UpdateStatusBar("Running Average All...")
	
	// EnsureGlobalParameters
	NVAR cRunMSD = root:cRunMSD
	NVAR cRunStepSize = root:cRunStepSize
	NVAR cRunIntensity = root:cRunIntensity
	NVAR cRunLP = root:cRunLP
	NVAR cRunDensity = root:cRunDensity
	NVAR cRunMolDensity = root:cRunMolDensity
	NVAR cRunOffrate = root:cRunOffrate
	NVAR cRunOnrate = root:cRunOnrate
	NVAR cRunStateTransition = root:cRunStateTransition
	NVAR cRunTrajectory = root:cRunTrajectory
	
	Variable doMSD = cRunMSD
	Variable doStepSize = cRunStepSize
	Variable doIntensity = cRunIntensity
	Variable doLP = cRunLP
	Variable doDensity = cRunDensity
	Variable doMolDensity = cRunMolDensity
	Variable doOffrate = cRunOffrate
	Variable doOnrate = cRunOnrate
	Variable doStateTransition = cRunStateTransition
	Variable doTrajectory = cRunTrajectory
	
	// MSD Average
	if(doMSD)
		Print "--- Average MSD ---"
		StatsMSDButtonProc("auto")
	endif
	
	// Stepsize Histogram Average
	if(doStepSize)
		Print "--- Average Stepsize Histogram ---"
		AverageStepHistButtonProc("auto")
		Print "--- Average Heatmap ---"
		AverageHeatmapButtonProc("auto")
	endif
	
	// Intensity Histogram Average
	if(doIntensity)
		Print "--- Average Intensity Histogram ---"
		AverageIntHistButtonProc("auto")
	endif
	
	// Localization Precision Average
	if(doLP)
		Print "--- Average Localization Precision ---"
		AverageLPHistButtonProc("auto")
	endif
	
	// Molecular Density Average
	if(doMolDensity)
		Print "--- Average Molecular Density ---"
		AverageMolDensButtonProc("auto")
	endif
	
	// Off-rate (On-time) Average
	if(doOffrate)
		Print "--- Average On-time ---"
		AverageOntimeButtonProc("auto")
	endif
	
	// On-rate Average
	if(doOnrate)
		Print "--- Average On-rate ---"
		AverageOnrateButtonProc("auto")
	endif
	
	// Average Aligned Trajectory
	if(doTrajectory)
		Print "--- Average Aligned Trajectory ---"
		// BatchSampleListGetSampleFolderList
		String trajSampleList = ""
		Wave/T/Z BatchSampleList = root:BatchSampleList
		if(WaveExists(BatchSampleList))
			Variable numBatchSamples = numpnts(BatchSampleList)
			Variable bIdx
			for(bIdx = 0; bIdx < numBatchSamples; bIdx += 1)
				String bSmplName = BatchSampleList[bIdx]
				// "(skipped)"
				if(StringMatch(bSmplName, "*skipped*") == 0)
					trajSampleList += bSmplName + ";"
				endif
			endfor
		else
			trajSampleList = GetSampleFolderList()
		endif
		
		Variable numTrajSamples = ItemsInList(trajSampleList)
		for(bIdx = 0; bIdx < numTrajSamples; bIdx += 1)
			String trajSampleName = StringFromList(bIdx, trajSampleList)
			Print "  Processing: " + trajSampleName
			CreateAverageAlignedTrajectory(trajSampleName)
		endfor
	endif
	
	// State Transition Average
	if(doStateTransition)
		Print "--- Average State Transition ---"
		AverageStateTransButtonProc("auto")
	endif
	
	Printf "========================================\r"
	Print "Average All Analysis "
	Printf "========================================\r"
	
	UpdateStatusBar("Average All completed")
End

Function TTestButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// 
	String targetGraph = WinName(0, 1)
	if(strlen(targetGraph) == 0)
		DoAlert 0, "Please select a Summary Plot (Compare_D_S* or Compare_L_S*)"
		return 0
	endif
	
	UpdateStatusBar("Running Welch's t-test on " + targetGraph + "...")
	RunMultipleComparisonTest(0)  // 0 = Welch's t-test
	UpdateStatusBar("Welch's t-test completed")
End

Function ANOVAButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// 
	String targetGraph = WinName(0, 1)
	if(strlen(targetGraph) == 0)
		DoAlert 0, "Please select a Summary Plot (Compare_D_S* or Compare_L_S*)"
		return 0
	endif
	
	UpdateStatusBar("Running Welch's ANOVA on " + targetGraph + "...")
	RunMultipleComparisonTest(1)  // 1 = Welch's ANOVA
	UpdateStatusBar("Welch's ANOVA completed")
End

Function SidakButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// 
	String targetGraph = WinName(0, 1)
	if(strlen(targetGraph) == 0)
		DoAlert 0, "Please select a Summary Plot (Compare_D_S* or Compare_L_S*)"
		return 0
	endif
	
	// 
	ControlInfo/W=SMI_MainPanel tab6_chk_vscontrol
	Variable vsControl = V_Value
	
	if(vsControl)
		UpdateStatusBar("Running Sidak Correction (vs Control) on " + targetGraph + "...")
		RunMultipleComparisonTest(2)  // 2 = vs Control
		UpdateStatusBar("Sidak Correction (vs Control) completed")
	else
		UpdateStatusBar("Running Sidak Correction (All pairs) on " + targetGraph + "...")
		RunMultipleComparisonTest(3)  // 3 = All pairs
		UpdateStatusBar("Sidak Correction (All pairs) completed")
	endif
End

Function SidakModeCheckProc(ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	// 
	if(StringMatch(ctrlName, "*vscontrol*"))
		CheckBox tab6_chk_vscontrol, win=SMI_MainPanel, value=1
		CheckBox tab6_chk_allpairs, win=SMI_MainPanel, value=0
	else
		CheckBox tab6_chk_vscontrol, win=SMI_MainPanel, value=0
		CheckBox tab6_chk_allpairs, win=SMI_MainPanel, value=1
	endif
End

// Kineticsτ/k
Function KinOutputModeCheckProc(ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR/Z cKinOutputTau = root:cKinOutputTau
	if(!NVAR_Exists(cKinOutputTau))
		Variable/G root:cKinOutputTau = 1
		NVAR cKinOutputTau = root:cKinOutputTau
	endif
	
	// 
	if(StringMatch(ctrlName, "*outtau*"))
		CheckBox tab4_chk_outtau, win=SMI_MainPanel, value=1
		CheckBox tab4_chk_outk, win=SMI_MainPanel, value=0
		cKinOutputTau = 1
	else
		CheckBox tab4_chk_outtau, win=SMI_MainPanel, value=0
		CheckBox tab4_chk_outk, win=SMI_MainPanel, value=1
		cKinOutputTau = 0
	endif
End

// =============================================================================
// Helper Functions
// =============================================================================

static Function UpdateStatusBar(message)
	String message
	
	DoWindow SMI_MainPanel
	if(V_Flag)
		TitleBox statusBar, win=SMI_MainPanel, title=message
	endif
	DoUpdate
End

static Function UpdateDataInfo(sampleName)
	String sampleName
	
	Variable numFolders = CountDataFolders(sampleName)
	String info = "Sample: " + sampleName + "\r"
	info += "Data folders: " + num2str(numFolders) + "\r"
	
	if(numFolders > 0)
		String firstFolder = sampleName + "1"
		if(DataFolderExists("root:" + sampleName + ":" + firstFolder))
			SetDataFolder root:$(sampleName):$(firstFolder)
			Wave/Z Xum_S0
			if(WaveExists(Xum_S0))
				info += "Points in first folder: " + num2str(numpnts(Xum_S0))
			endif
			Wave/Z TraceMatrix
			if(WaveExists(TraceMatrix))
				info += "\rTraceMatrix: " + num2str(DimSize(TraceMatrix, 0)) + " rows x " + num2str(DimSize(TraceMatrix, 1)) + " cols"
			endif
			Wave/Z Ctr
			if(WaveExists(Ctr))
				info += "\rHMM Ctr: " + num2str(numpnts(Ctr)) + " states"
			endif
			SetDataFolder root:
		endif
	endif
	
	TitleBox tab1_info, win=SMI_MainPanel, title=info
End

static Function UpdateFormatStatus()
	// 
	NVAR/Z cAAS4 = root:cAAS4
	NVAR/Z cHMM = root:cHMM
	NVAR/Z Dstate = root:Dstate
	NVAR/Z MaxSegment = root:MaxSegment
	
	Variable isAAS4 = 0
	Variable isHMM = 0
	Variable dstateVal = 4
	Variable maxSeg = 0
	if(NVAR_Exists(cAAS4))
		isAAS4 = cAAS4
	endif
	if(NVAR_Exists(cHMM))
		isHMM = cHMM
	endif
	if(NVAR_Exists(Dstate))
		dstateVal = Dstate
	endif
	if(NVAR_Exists(MaxSegment))
		maxSeg = MaxSegment
	endif
	
	String formatStr = "Format: "
	if(isAAS4)
		formatStr += "AAS4"
	else
		formatStr += "AAS2"
	endif
	
	if(isHMM)
		formatStr += " + HMM (n=" + num2str(dstateVal) + ")"
	else
		formatStr += " (no HMM)"
	endif
	
	if(maxSeg > 0)
		formatStr += " Seg=" + num2str(maxSeg)
	endif
	
	DoWindow SMI_MainPanel
	if(V_Flag)
		TitleBox tab1_format_status, win=SMI_MainPanel, title=formatStr
	endif
End

static Function UpdateSMIResults(sampleName)
	String sampleName
	
	String results = "Sample: " + sampleName + " | "
	
	// Check for results
	String folderPath = "root:" + sampleName + ":" + sampleName + "1:"
	if(DataFolderExists("root:" + sampleName + ":" + sampleName + "1"))
		SetDataFolder root:$(sampleName):$(sampleName + "1")
		
		// Diffusion results
		Wave/Z fit_MSD_avg
		if(WaveExists(fit_MSD_avg))
			results += "Diff:✓ "
		endif
		
		// Intensity results  
		Wave/Z coef_Int_S0
		if(WaveExists(coef_Int_S0))
			results += "Int:✓ "
		endif
		
		// Duration results
		Wave/Z ParaDuration
		if(WaveExists(ParaDuration))
			results += "Off:✓ "
		endif
		
		// On-rate results
		Wave/Z ParaOnrate
		if(WaveExists(ParaOnrate))
			results += "On:✓ "
		endif
		
		// Density results
		Wave/Z ParaDensityAvg
		if(WaveExists(ParaDensityAvg))
			results += "Dens:✓ "
		endif
		
		SetDataFolder root:
	endif
	
	// Check Matrix folder
	if(DataFolderExists("root:" + sampleName + ":Matrix"))
		SetDataFolder root:$(sampleName):Matrix
		Variable numMatrixWaves = CountObjects("", 1)
		SetDataFolder root:
		results += "| Matrix(" + num2str(numMatrixWaves) + ") "
	endif
	
	// Check Results folder
	if(DataFolderExists("root:" + sampleName + ":Results"))
		SetDataFolder root:$(sampleName):Results
		Variable numResultWaves = CountObjects("", 1)
		SetDataFolder root:
		results += "| Stats(" + num2str(numResultWaves) + ") "
	endif
	
	if(strlen(results) < 30)
		results += "No results yet"
	endif
	
	TitleBox tab0_results, win=SMI_MainPanel, title=results
End

// -----------------------------------------------------------------------------
// Compare Lower Bound 
// -----------------------------------------------------------------------------
Function CompareLowerBoundProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	NVAR/Z cHMM = root:cHMM
	if(!NVAR_Exists(cHMM) || cHMM != 1)
		DoAlert 0, "Compare Lower Bound requires HMM data."
		return 0
	endif
	
	UpdateStatusBar("Creating Lower Bound comparison plots...")
	CompareLowerBound(sampleName)
	UpdateStatusBar("Lower Bound comparison complete")
End

Function TraceButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	// ===  ===
	UpdateStatusBar("Creating trace plots...")
	Trace_HMM(sampleName)
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			UpdateStatusBar("Creating trace plots (Seg" + num2str(segIdx) + ")...")
			Trace_HMM(sampleName, basePath=basePath, waveSuffix=segSuffix)
		endfor
	endif
	
	UpdateStatusBar("Trace plots complete")
End

Function AlignedTrajectoryButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String sampleName
	sampleName = GetCurrentSampleName()
	if(strlen(sampleName) == 0)
		return 0
	endif
	
	// ===  ===
	UpdateStatusBar("Creating origin-aligned trajectories...")
	CreateOriginAlignedTrajectory(sampleName)
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			UpdateStatusBar("Creating aligned trajectories (Seg" + num2str(segIdx) + ")...")
			CreateOriginAlignedTrajectory(sampleName, basePath=basePath, waveSuffix=segSuffix)
		endfor
	endif
	
	UpdateStatusBar("Origin-aligned trajectories complete")
End

Function AvgAlignedTrajectoryButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	UpdateStatusBar("Creating average aligned trajectory...")
	
	// BatchSampleListGetSampleFolderList
	String trajSampleList = ""
	Wave/T/Z BatchSampleList = root:BatchSampleList
	if(WaveExists(BatchSampleList))
		Variable numBatchSamples = numpnts(BatchSampleList)
		Variable bIdx
		for(bIdx = 0; bIdx < numBatchSamples; bIdx += 1)
			String bSmplName = BatchSampleList[bIdx]
			// "(skipped)"
			if(StringMatch(bSmplName, "*skipped*") == 0)
				trajSampleList += bSmplName + ";"
			endif
		endfor
	else
		trajSampleList = GetSampleFolderList()
	endif
	
	Variable numTrajSamples = ItemsInList(trajSampleList)
	for(bIdx = 0; bIdx < numTrajSamples; bIdx += 1)
		String trajSampleName = StringFromList(bIdx, trajSampleList)
		Print "  Processing: " + trajSampleName
		CreateAverageAlignedTrajectory(trajSampleName)
	endfor
	
	UpdateStatusBar("Average aligned trajectory complete")
End

// L thresholdProcData Loading
Function LThreshSyncProc(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	// Data LoadingKinetics
	SetVariable tab4_sv_lthresh, win=SMI_MainPanel, value=_NUM:varNum
End

// L thresholdProcKinetics
Function LThreshKinSyncProc(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	// KineticsData Loading
	SetVariable tab1_sv_lthresh, win=SMI_MainPanel, value=_NUM:varNum
End

// S0
Function DisplayTraceS0(SampleName)
	String SampleName
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m
	String FolderName
	
	NVAR scale = root:scale
	NVAR PixNum = root:PixNum
	Variable ImageSize = scale * PixNum
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Wave/Z Xum_S0, Yum_S0
		if(!WaveExists(Xum_S0))
			Printf ": %s Xum_S0\r", FolderName
			continue
		endif
		
		// 
		Display/K=1 Yum_S0 vs Xum_S0
		ModifyGraph rgb(Yum_S0)=(65535,0,0)
		ModifyGraph mode=0, msize=1
		
		// 
		ModifyGraph width={Aspect,1}, height={Aspect,1}
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=16, font="Arial"
		Label bottom "X µm"
		Label left "Y µm"
		SetAxis bottom 0, ImageSize
		SetAxis left 0, ImageSize
		ModifyGraph gbRGB=(0,0,0)
		ModifyGraph tickRGB(bottom)=(65535,65535,65535)
		ModifyGraph tickRGB(left)=(65535,65535,65535)
		
		String graphTitle = FolderName + " Trace (S0)"
		DoWindow/T kwTopWin, graphTitle
	endfor
	
	SetDataFolder root:
End

// =============================================================================
// Tab 6: Timelapse Analysis - 
// =============================================================================
static Function CreateTimelapseTab()
	Variable xPos = kMargin
	Variable yPos = 40
	Variable innerX, innerY
	Variable groupWidth = kPanelWidth - 2*kMargin - 20
	Variable btnWidth = 130
	Variable btnHeight = 28
	Variable btnWidthSmall = 100
	
	// ----- Group 1: Timelapse Parameters -----
	GroupBox tab7_grp_params, pos={xPos, yPos}, size={groupWidth, 90}, title="Timelapse Parameters"
	
	innerX = xPos + 10
	innerY = yPos + 20
	
	// 1
	SetVariable tab7_ligandnum, pos={innerX, innerY}, size={110, 20}
	SetVariable tab7_ligandnum, title="Conditions:", value=root:LigandNumTL
	SetVariable tab7_ligandnum, limits={1, 20, 1}
	
	SetVariable tab7_interval, pos={innerX+120, innerY}, size={120, 20}
	SetVariable tab7_interval, title="Interval (min):", value=root:TimeInterval
	SetVariable tab7_interval, limits={0.1, 1000, 1}
	
	SetVariable tab7_points, pos={innerX+250, innerY}, size={120, 20}
	SetVariable tab7_points, title="Time points:", value=root:TimePoints
	SetVariable tab7_points, limits={1, 100, 1}
	
	SetVariable tab7_stimtime, pos={innerX+380, innerY}, size={150, 20}
	SetVariable tab7_stimtime, title="Stimulation (min):", value=root:TimeStimulation
	SetVariable tab7_stimtime, limits={0, 1000, 1}
	
	// Data SourcePer Channel / Colocalization
	TitleBox tab7_lbl_datasource, pos={innerX+540, innerY+3}, size={70, 20}
	TitleBox tab7_lbl_datasource, title="Data Source:", frame=0, fStyle=1
	
	NVAR/Z gTL_DataSrc = root:TL_DataSource
	if(!NVAR_Exists(gTL_DataSrc))
		Variable/G root:TL_DataSource = 0  // 0=Per Channel, 1=Colocalization
		NVAR/Z gTL_DataSrc = root:TL_DataSource
	endif
	PopupMenu tab7_popup_datasource, pos={innerX+620, innerY}, size={130, 20}
	PopupMenu tab7_popup_datasource, mode=(gTL_DataSrc + 1), value="Single Channel;Colocalization", proc=TL_DataSourceProc
	
	innerY += 25
	
	// Create Sample List 
	Button tab7_btn_createsamplelist, pos={innerX, innerY}, size={btnWidth+20, btnHeight}
	Button tab7_btn_createsamplelist, title="Create Sample List", proc=TL_CreateSampleListButtonProc
	Button tab7_btn_createsamplelist, fColor=(51664,44236,58982), fSize=12
	
	TitleBox tab7_lbl_paraminfo, pos={innerX+165, innerY+5}, size={400, 20}
	TitleBox tab7_lbl_paraminfo, title="* Set parameters, then Create Sample List before running Compare All", frame=0, fStyle=2
	
	// ----- Group 2: Violin Plot (Selected Parameter) -----
	yPos += 98
	GroupBox tab7_grp_violin, pos={xPos, yPos}, size={groupWidth, 100}, title="Summary Plot (Selected Parameter)"
	
	innerX = xPos + 10
	innerY = yPos + 18
	
	// Update List 
	Button tab7_btn_updatelist, pos={innerX, innerY-2}, size={110, 24}
	Button tab7_btn_updatelist, title="Update List", proc=TL_UpdateListButtonProc
	Button tab7_btn_updatelist, fColor=(51664,44236,58982), fSize=12
	
	// 
	TitleBox tab7_lbl_param, pos={innerX+120, innerY+3}, size={70, 20}
	TitleBox tab7_lbl_param, title="Parameter:", frame=0, fStyle=1
	
	// 
	String/G root:TL_ParameterList = "_none_"
	
	PopupMenu tab7_popup_param, pos={innerX+190, innerY}, size={200, 20}
	PopupMenu tab7_popup_param, mode=1, value=#"root:TL_ParameterList"
	
	innerY += 30
	
	// Original / Normalize / Difference - 
	Button tab7_btn_original, pos={innerX, innerY}, size={130, 28}
	Button tab7_btn_original, title="Original", proc=TL_OriginalButtonProc
	Button tab7_btn_original, fColor=(0,0,65535), fSize=12
	
	Button tab7_btn_normalize, pos={innerX+140, innerY}, size={130, 28}
	Button tab7_btn_normalize, title="Normalize", proc=TL_NormalizeButtonProc
	Button tab7_btn_normalize, fColor=(0,0,65535), fSize=12
	
	Button tab7_btn_difference, pos={innerX+280, innerY}, size={130, 28}
	Button tab7_btn_difference, title="Difference", proc=TL_DifferenceButtonProc
	Button tab7_btn_difference, fColor=(0,0,65535), fSize=12
	
	// Mean / Each cell
	NVAR/Z gTL_NormMeth = root:TL_NormMethod
	if(!NVAR_Exists(gTL_NormMeth))
		Variable/G root:TL_NormMethod = 0  // 0=Mean, 1=Each cell
		NVAR/Z gTL_NormMeth = root:TL_NormMethod
	endif
	TitleBox tab7_lbl_normby, pos={innerX+420, innerY+5}, size={85, 20}
	TitleBox tab7_lbl_normby, title="Normalized by:", frame=0, fStyle=1
	PopupMenu tab7_popup_normby, pos={innerX+510, innerY+2}, size={100, 22}
	PopupMenu tab7_popup_normby, mode=(gTL_NormMeth + 1), value="Mean;Each cell", proc=TL_NormMethodProc
	
	// 
	innerY += 32
	TitleBox tab7_lbl_violininfo, pos={innerX, innerY}, size={450, 20}
	TitleBox tab7_lbl_violininfo, title="* Select parameter from dropdown, then create summary plot", frame=0, fStyle=2
	
	// ----- Group 3: Compare All -----
	yPos += 108
	GroupBox tab7_grp_compareall, pos={xPos, yPos}, size={groupWidth, 75}, title="Compare All (TL_SampleList based)"
	
	innerX = xPos + 10
	innerY = yPos + 22
	
	// Original All / Normalize All / Difference All 
	Button tab7_btn_originalall, pos={innerX, innerY}, size={btnWidth, btnHeight}
	Button tab7_btn_originalall, title="Original All", proc=TL_OriginalAllButtonProc
	Button tab7_btn_originalall, fColor=(65535,40000,0), fSize=12
	
	Button tab7_btn_normalizeall, pos={innerX+btnWidth+10, innerY}, size={btnWidth, btnHeight}
	Button tab7_btn_normalizeall, title="Normalize All", proc=TL_NormalizeAllButtonProc
	Button tab7_btn_normalizeall, fColor=(65535,40000,0), fSize=12
	
	Button tab7_btn_differenceall, pos={innerX+2*(btnWidth+10), innerY}, size={btnWidth, btnHeight}
	Button tab7_btn_differenceall, title="Difference All", proc=TL_DifferenceAllButtonProc
	Button tab7_btn_differenceall, fColor=(65535,40000,0), fSize=12
	
	// Group 2
	TitleBox tab7_lbl_normby2, pos={innerX+420, innerY+5}, size={85, 20}
	TitleBox tab7_lbl_normby2, title="Normalized by:", frame=0, fStyle=1
	PopupMenu tab7_popup_normby2, pos={innerX+510, innerY+2}, size={100, 22}
	PopupMenu tab7_popup_normby2, mode=(gTL_NormMeth + 1), value="Mean;Each cell", proc=TL_NormMethodProc
	
	innerY += 35
	TitleBox tab7_lbl_compareinfo, pos={innerX, innerY}, size={500, 20}
	TitleBox tab7_lbl_compareinfo, title="* Run Compare All first. Line plots are created automatically with summary plots.", frame=0, fStyle=2
	
	// ----- Group 4: Layout Settings -----
	yPos += 85
	GroupBox tab7_grp_layout, pos={xPos, yPos}, size={groupWidth, 130}, title="Layout Settings"
	
	innerX = xPos + 10
	innerY = yPos + 18
	
	// --- Row 1: Paper + Size + Offset + Gap ---
	TitleBox tab7_lbl_paper, pos={innerX, innerY+2}, size={35, 16}, title="Paper:", frame=0, fStyle=1
	PopupMenu tab7_pop_papersize, pos={innerX+35, innerY}, size={60, 20}
	PopupMenu tab7_pop_papersize, title="", mode=2, value="Letter;A4;Custom"
	PopupMenu tab7_pop_papersize, proc=TL_PaperSizePopupProc
	
	SetVariable tab7_sv_width, pos={innerX+100, innerY}, size={55, 18}
	SetVariable tab7_sv_width, title="W:", value=root:LayoutPageW, limits={4,20,0.1}
	
	SetVariable tab7_sv_height, pos={innerX+160, innerY}, size={55, 18}
	SetVariable tab7_sv_height, title="H:", value=root:LayoutPageH, limits={4,20,0.1}
	
	TitleBox tab7_lbl_unit1, pos={innerX+218, innerY+2}, size={15, 16}, title="in", frame=0
	
	SetVariable tab7_sv_offset, pos={innerX+240, innerY}, size={70, 18}
	SetVariable tab7_sv_offset, title="Offset:", value=root:LayoutOffset, limits={0,50,1}
	
	SetVariable tab7_sv_gap, pos={innerX+320, innerY}, size={60, 18}
	SetVariable tab7_sv_gap, title="Gap:", value=root:LayoutGap, limits={0,20,0.5}
	
	TitleBox tab7_lbl_unit2, pos={innerX+385, innerY+2}, size={20, 16}, title="mm", frame=0
	
	innerY += 23
	
	// --- Row 2: Division + Output + Checkboxes + Contrast ---
	TitleBox tab7_lbl_div, pos={innerX, innerY+2}, size={45, 16}, title="Division:", frame=0, fStyle=1
	SetVariable tab7_sv_divw, pos={innerX+50, innerY}, size={50, 18}
	SetVariable tab7_sv_divw, title="W:", value=root:LayoutDivW, limits={1,10,1}
	
	SetVariable tab7_sv_divh, pos={innerX+105, innerY}, size={50, 18}
	SetVariable tab7_sv_divh, title="H:", value=root:LayoutDivH, limits={1,10,1}
	
	TitleBox tab7_lbl_output, pos={innerX+165, innerY+2}, size={40, 16}, title="Output:", frame=0, fStyle=1
	PopupMenu tab7_pop_output, pos={innerX+210, innerY}, size={70, 20}
	PopupMenu tab7_pop_output, title="", mode=3, value="Graph;PNG;SVG"
	
	CheckBox tab7_chk_nolabel, pos={innerX+295, innerY}, size={90, 18}
	CheckBox tab7_chk_nolabel, title="No XY Label", variable=root:LayoutNoLabel
	
	CheckBox tab7_chk_notitle, pos={innerX+400, innerY}, size={100, 18}
	CheckBox tab7_chk_notitle, title="No Image title", variable=root:LayoutNoTitle
	
	innerY += 25
	
	// --- Row 3: Mol Density Image → Create Layout + Clear ---
	Button tab7_btn_moldensityimage, pos={innerX, innerY-2}, size={130, 26}
	Button tab7_btn_moldensityimage, title="Mol Density Image", proc=TL_DxIImageButtonProc
	Button tab7_btn_moldensityimage, fStyle=1, fColor=(0,0,65535)
	
	TitleBox tab7_lbl_arrow, pos={innerX+138, innerY+2}, size={20, 16}, title="→", frame=0, fSize=14
	
	Button tab7_btn_createlayout, pos={innerX+160, innerY-2}, size={110, 26}
	Button tab7_btn_createlayout, title="Create Layout", proc=TL_CreateLayoutButtonProc
	Button tab7_btn_createlayout, fStyle=1, fColor=(32768,32768,65535)
	
	// Clear buttons
	TitleBox tab7_lbl_clear, pos={innerX+285, innerY+2}, size={30, 16}, title="Clear:", frame=0, fStyle=1
	Button tab7_btn_clearlayout, pos={innerX+318, innerY}, size={50, 22}
	Button tab7_btn_clearlayout, title="Layout", proc=ClearAllLayoutProc
	Button tab7_btn_cleargraph, pos={innerX+373, innerY}, size={50, 22}
	Button tab7_btn_cleargraph, title="Graph", proc=ClearAllGraphProc
	
	innerY += 28
	
	// --- Row 4: Scale + Contrast min/max +  ---
	SetVariable tab7_sv_scalefont, pos={innerX, innerY}, size={80, 18}
	SetVariable tab7_sv_scalefont, title="Scale:", value=root:LayoutScaleFontSize, limits={6,24,1}
	
	TitleBox tab7_lbl_contrast, pos={innerX+90, innerY+2}, size={50, 16}, title="Contrast:", frame=0, fStyle=1
	SetVariable tab7_dximinval, pos={innerX+150, innerY}, size={80, 18}
	SetVariable tab7_dximinval, title="min:", value=root:DIhistImageMin, limits={0, 1, 0.00001}
	
	SetVariable tab7_dximaxval, pos={innerX+240, innerY}, size={75, 18}
	SetVariable tab7_dximaxval, title="max:", value=root:DIhistImageMax, limits={0, 1, 0.1}
	
	TitleBox tab7_lbl_layoutinfo, pos={innerX+330, innerY}, size={200, 20}
	TitleBox tab7_lbl_layoutinfo, title="* ColorScale added automatically.", frame=0, fStyle=2
	
	SetDataFolder root:
End

// =============================================================================
// Tab 7: Layout - 2
// =============================================================================
static Function CreateLayoutTab()
	Variable xPos = kMargin
	Variable yPos = 40
	
	// 
	Variable colWidth = 395      // 
	Variable colGap = 10         // 
	Variable topRowHeight = 195  // 
	Variable botRowHeight = 175  // 
	Variable btnH_L = 28         // 
	Variable btnH_S = 20         // 
	Variable btnW_S = 75         // 
	Variable rowH = 24           // 
	Variable lblW = 40           // 
	Variable btnGap = 5          // 
	
	// ==========================================================================
	// Batch Analysis
	// ==========================================================================
	Button tab8_btn_batch, pos={xPos, yPos}, size={140, 36}
	Button tab8_btn_batch, title="▶ Batch Analysis", proc=BatchAnalysisProc, fStyle=1, fColor=(0,0,65535)
	
	yPos += 45
	
	// ==========================================================================
	// : Single Analysis 
	// ==========================================================================
	Variable singleX = xPos
	Variable singleY = yPos
	GroupBox tab8_grp_single, pos={singleX, singleY}, size={colWidth, topRowHeight}, title="Single Analysis"
	
	Variable innerY = singleY + 18
	Variable innerX = singleX + 10
	Variable btnX = innerX + lblW
	
	// Single Analysis + SampleName
	Button tab8_btn_single, pos={innerX, innerY}, size={115, btnH_L}
	Button tab8_btn_single, title="▶ Single Analysis", proc=FullAllAnalysisProc, fStyle=1, fColor=(0,0,65535)
	
	PopupMenu tab8_pop_sample, pos={innerX+125, innerY+2}, size={140, 20}
	PopupMenu tab8_pop_sample, mode=1, value=#"GetAnalyzedSampleList()"
	PopupMenu tab8_pop_sample, proc=LayoutSamplePopupProc
	
	CheckBox tab8_chk_userdefined, pos={innerX+275, innerY+5}, size={100, 18}
	CheckBox tab8_chk_userdefined, title="User-defined", variable=root:cUseUserDefinedName
	CheckBox tab8_chk_userdefined, proc=LayoutUserDefinedCheckProc
	
	innerY += btnH_L + 8
	
	// --- Data ---
	TitleBox tab8_lbl_s_data, pos={innerX, innerY+2}, size={lblW, 16}, title="Data:", frame=0, fStyle=1
	Button tab8_btn_s_load, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_load, title="Load Data", proc=LoadDataButtonProc, fColor=(0,0,65535)
	Button tab8_btn_s_trace, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_trace, title="Trajectory", proc=TraceButtonProc, fColor=(0,0,65535)
	Button tab8_btn_s_aligned, pos={btnX+(btnW_S+btnGap)*2, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_aligned, title="Aligned Traj", proc=AlignedTrajectoryButtonProc, fColor=(0,0,65535)
	
	innerY += rowH
	
	// --- Diffusion ---
	TitleBox tab8_lbl_s_diff, pos={innerX, innerY+2}, size={lblW, 16}, title="Diff:", frame=0, fStyle=1
	Button tab8_btn_s_msd, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_msd, title="MSD", proc=RunMSDButtonProc, fColor=(0,0,65535)
	Button tab8_btn_s_step, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_step, title="Stepsize", proc=RunStepHistButtonProc, fColor=(0,0,65535)
	Button tab8_btn_s_heat, pos={btnX+(btnW_S+btnGap)*2, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_heat, title="Heatmap", proc=MSDHeatmapButtonProc, fColor=(0,0,65535)
	
	innerY += rowH
	
	// --- Intensity ---
	TitleBox tab8_lbl_s_int, pos={innerX, innerY+2}, size={lblW, 16}, title="Int:", frame=0, fStyle=1
	Button tab8_btn_s_int, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_int, title="Intensity", proc=RunIntHistButtonProc, fColor=(0,0,65535)
	Button tab8_btn_s_lp, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_lp, title="LP", proc=LPHistButtonProc, fColor=(0,0,65535)
	Button tab8_btn_s_dens, pos={btnX+(btnW_S+btnGap)*2, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_dens, title="Particle Dens", proc=DensityGcountButtonProc, fColor=(0,0,65535)
	Button tab8_btn_s_moldens, pos={btnX+(btnW_S+btnGap)*3, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_moldens, title="Mol Dens", proc=MolDensityButtonProc, fColor=(0,0,65535)
	
	innerY += rowH
	
	// --- Kinetics ---
	TitleBox tab8_lbl_s_kin, pos={innerX, innerY+2}, size={lblW, 16}, title="Kin:", frame=0, fStyle=1
	Button tab8_btn_s_dur, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_dur, title="On-time", proc=DurationButtonProc, fColor=(0,0,65535)
	Button tab8_btn_s_onrate, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_onrate, title="On-rate", proc=OnrateButtonProc2, fColor=(0,0,65535)
	Button tab8_btn_s_state, pos={btnX+(btnW_S+btnGap)*2, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_s_state, title="State Trans", proc=StateTransitionButtonProc, fColor=(0,0,65535)
	
	// ==========================================================================
	// : Average All 
	// ==========================================================================
	Variable avgX = xPos + colWidth + colGap
	Variable avgY = yPos
	GroupBox tab8_grp_average, pos={avgX, avgY}, size={colWidth, topRowHeight}, title="Average All"
	
	innerY = avgY + 18
	innerX = avgX + 10
	btnX = innerX + lblW
	
	// Average All
	Button tab8_btn_avgall, pos={innerX, innerY}, size={115, btnH_L}
	Button tab8_btn_avgall, title="▶ Average All", proc=AverageAllButtonProc, fStyle=1, fColor=(65535,43520,0)
	
	innerY += btnH_L + 8
	
	// --- Data ---
	TitleBox tab8_lbl_a_data, pos={innerX, innerY+2}, size={lblW, 16}, title="Data:", frame=0, fStyle=1
	Button tab8_btn_a_aligned, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_a_aligned, title="Aligned Traj", proc=AvgAlignedTrajectoryButtonProc, fColor=(65535,43520,0)
	
	innerY += rowH
	
	// --- Diffusion ---
	TitleBox tab8_lbl_a_diff, pos={innerX, innerY+2}, size={lblW, 16}, title="Diff:", frame=0, fStyle=1
	Button tab8_btn_a_msd, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_a_msd, title="MSD", proc=StatsMSDButtonProc, fColor=(65535,43520,0)
	Button tab8_btn_a_step, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_a_step, title="Stepsize", proc=AverageStepHistButtonProc, fColor=(65535,43520,0)
	Button tab8_btn_a_heat, pos={btnX+(btnW_S+btnGap)*2, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_a_heat, title="Heatmap", proc=AverageHeatmapButtonProc, fColor=(65535,43520,0)
	
	innerY += rowH
	
	// --- Intensity ---
	TitleBox tab8_lbl_a_int, pos={innerX, innerY+2}, size={lblW, 16}, title="Int:", frame=0, fStyle=1
	Button tab8_btn_a_int, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_a_int, title="Intensity", proc=AverageIntHistButtonProc, fColor=(65535,43520,0)
	Button tab8_btn_a_lp, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_a_lp, title="LP", proc=AverageLPHistButtonProc, fColor=(65535,43520,0)
	Button tab8_btn_a_moldens, pos={btnX+(btnW_S+btnGap)*2, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_a_moldens, title="Mol Dens", proc=AverageMolDensButtonProc, fColor=(65535,43520,0)
	
	innerY += rowH
	
	// --- Kinetics ---
	TitleBox tab8_lbl_a_kin, pos={innerX, innerY+2}, size={lblW, 16}, title="Kin:", frame=0, fStyle=1
	Button tab8_btn_a_dur, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_a_dur, title="On-time", proc=AverageOntimeButtonProc, fColor=(65535,43520,0)
	Button tab8_btn_a_onrate, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_a_onrate, title="On-rate", proc=AverageOnrateButtonProc, fColor=(65535,43520,0)
	Button tab8_btn_a_state, pos={btnX+(btnW_S+btnGap)*2, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_a_state, title="State Trans", proc=AverageStateTransButtonProc, fColor=(65535,43520,0)
	
	// ==========================================================================
	// : Compare All 
	// ==========================================================================
	yPos += topRowHeight + 10
	Variable cmpY = yPos
	GroupBox tab8_grp_compare, pos={xPos, cmpY}, size={colWidth, botRowHeight}, title="Compare All"
	
	innerY = cmpY + 18
	innerX = xPos + 10
	btnX = innerX + lblW
	
	// Compare All
	Button tab8_btn_cmpall, pos={innerX, innerY}, size={115, btnH_L}
	Button tab8_btn_cmpall, title="▶ Compare All", proc=CompareAllButtonProc, fStyle=1, fColor=(0,52428,0)
	
	innerY += btnH_L + 8
	
	// --- Data ---
	TitleBox tab8_lbl_c_data, pos={innerX, innerY+2}, size={lblW, 16}, title="Data:", frame=0, fStyle=1
	Button tab8_btn_c_lb, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_c_lb, title="Lower Bound", proc=CompareLowerBoundProc, fColor=(0,52428,0)
	
	innerY += rowH
	
	// --- Diffusion ---
	TitleBox tab8_lbl_c_diff, pos={innerX, innerY+2}, size={lblW, 16}, title="Diff:", frame=0, fStyle=1
	Button tab8_btn_c_msd, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_c_msd, title="MSD", proc=CompareMSDParamsButtonProc, fColor=(0,52428,0)
	Button tab8_btn_c_dstate, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_c_dstate, title="D-state", proc=CompareDstateButtonProc, fColor=(0,52428,0)
	
	innerY += rowH
	
	// --- Intensity ---
	TitleBox tab8_lbl_c_int, pos={innerX, innerY+2}, size={lblW, 16}, title="Int:", frame=0, fStyle=1
	Button tab8_btn_c_int, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_c_int, title="Intensity", proc=CompareIntensityButtonProc, fColor=(0,52428,0)
	Button tab8_btn_c_lp, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_c_lp, title="LP", proc=CompareLPButtonProc, fColor=(0,52428,0)
	Button tab8_btn_c_dens, pos={btnX+(btnW_S+btnGap)*2, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_c_dens, title="Particle Dens", proc=CompareDensityButtonProc, fColor=(0,52428,0)
	Button tab8_btn_c_moldens, pos={btnX+(btnW_S+btnGap)*3, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_c_moldens, title="Mol Dens", proc=CompareMolDensButtonProc, fColor=(0,52428,0)
	
	innerY += rowH
	
	// --- Kinetics ---
	TitleBox tab8_lbl_c_kin, pos={innerX, innerY+2}, size={lblW, 16}, title="Kin:", frame=0, fStyle=1
	Button tab8_btn_c_dur, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_c_dur, title="On-time", proc=CompareOntimeButtonProc, fColor=(0,52428,0)
	Button tab8_btn_c_onrate, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_c_onrate, title="On-rate", proc=CompareOnrateButtonProc, fColor=(0,52428,0)
	Button tab8_btn_c_state, pos={btnX+(btnW_S+btnGap)*2, innerY}, size={btnW_S, btnH_S}
	Button tab8_btn_c_state, title="State Trans", proc=CompareStateTransButtonProc, fColor=(0,52428,0)
	
	// ==========================================================================
	// : Layout Settings 
	// ==========================================================================
	Variable optX = xPos + colWidth + colGap
	Variable optY = cmpY
	GroupBox tab8_grp_settings, pos={optX, optY}, size={colWidth, botRowHeight}, title="Layout Settings"
	
	innerY = optY + 20
	innerX = optX + 10
	
	// --- Row 1: Paper Size ---
	TitleBox tab8_lbl_paper, pos={innerX, innerY+2}, size={45, 16}, title="Paper:", frame=0, fStyle=1
	PopupMenu tab8_pop_papersize, pos={innerX+45, innerY}, size={70, 20}
	PopupMenu tab8_pop_papersize, title="", mode=2, value="Letter;A4;Custom"
	PopupMenu tab8_pop_papersize, proc=PaperSizePopupProc
	
	SetVariable tab8_sv_width, pos={innerX+125, innerY}, size={70, 18}
	SetVariable tab8_sv_width, title="W:", value=root:LayoutPageW, limits={4,20,0.1}
	
	SetVariable tab8_sv_height, pos={innerX+200, innerY}, size={70, 18}
	SetVariable tab8_sv_height, title="H:", value=root:LayoutPageH, limits={4,20,0.1}
	
	TitleBox tab8_lbl_unit1, pos={innerX+275, innerY+2}, size={30, 16}, title="[in]", frame=0
	
	innerY += 25
	
	// --- Row 2: Page Offset and Graph Gap ---
	SetVariable tab8_sv_offset, pos={innerX, innerY}, size={100, 18}
	SetVariable tab8_sv_offset, title="Offset:", value=root:LayoutOffset, limits={0,50,1}
	TitleBox tab8_lbl_unit2, pos={innerX+105, innerY+2}, size={30, 16}, title="[mm]", frame=0
	
	SetVariable tab8_sv_gap, pos={innerX+150, innerY}, size={100, 18}
	SetVariable tab8_sv_gap, title="Gap:", value=root:LayoutGap, limits={0,20,0.5}
	TitleBox tab8_lbl_unit3, pos={innerX+255, innerY+2}, size={30, 16}, title="[mm]", frame=0
	
	innerY += 25
	
	// --- Row 3: Division + Output Format ---
	TitleBox tab8_lbl_div, pos={innerX, innerY+2}, size={50, 16}, title="Division:", frame=0, fStyle=1
	SetVariable tab8_sv_divw, pos={innerX+55, innerY}, size={55, 18}
	SetVariable tab8_sv_divw, title="W:", value=root:LayoutDivW, limits={1,10,1}
	
	SetVariable tab8_sv_divh, pos={innerX+120, innerY}, size={55, 18}
	SetVariable tab8_sv_divh, title="H:", value=root:LayoutDivH, limits={1,10,1}
	
	// Output Format: SVG
	TitleBox tab8_lbl_output, pos={innerX+185, innerY+2}, size={45, 16}, title="Output:", frame=0, fStyle=1
	PopupMenu tab8_pop_output, pos={innerX+230, innerY}, size={75, 20}
	PopupMenu tab8_pop_output, title="", mode=3, value="Graph;PNG;SVG"
	
	innerY += 25
	
	// --- Row 4: Create Layout Button () + Clear All  ---
	Button tab8_btn_createlayout, pos={innerX, innerY-2}, size={120, 26}
	Button tab8_btn_createlayout, title="Create Layout", proc=CreateLayoutButtonProc, fStyle=1, fColor=(32768,32768,65535)
	
	// Clear All 
	GroupBox tab8_grp_clearall, pos={innerX+130, innerY-5}, size={215, 30}, title=""
	TitleBox tab8_lbl_clearall, pos={562, 388}, size={50, 18}
	TitleBox tab8_lbl_clearall, title="Clear All", frame=0, fStyle=1
	Button tab8_btn_clearlayout, pos={605, 384}, size={50, 18}
	Button tab8_btn_clearlayout, title="Layout", proc=ClearAllLayoutProc
	Button tab8_btn_cleartable, pos={660, 384}, size={50, 18}
	Button tab8_btn_cleartable, title="Table", proc=ClearAllTableProc
	Button tab8_btn_cleargraph, pos={715, 384}, size={50, 18}
	Button tab8_btn_cleargraph, title="Graph", proc=ClearAllGraphProc
	
	innerY += 35
	
	// --- Row 5: Information ---
	TitleBox tab8_lbl_info, pos={innerX, innerY}, size={370, 32}
	TitleBox tab8_lbl_info, title="Shortcuts: Ctrl+7=Clear Layout, Ctrl+8=Clear Table, Ctrl+9=Clear Graph", frame=0, fStyle=2
End

// =============================================================================
// Tab 9: Layout Colocalization - Colocalization
// =============================================================================
static Function CreateLayoutColTab()
	Variable xPos = kMargin
	Variable yPos = 40
	
	// Layout Single
	Variable colWidth = 395      // 
	Variable colGap = 10         // 
	Variable topRowHeight = 195  // 
	Variable botRowHeight = 175  // 
	Variable btnH_L = 28         // 
	Variable btnH_S = 20         // 
	Variable btnW_S = 75         // 
	Variable rowH = 24           // 
	Variable lblW = 40           // 
	Variable btnGap = 5          // 
	
	// ==========================================================================
	// Colocalization Settings
	// ==========================================================================
	GroupBox tab9_grp_colset, pos={xPos, yPos}, size={colWidth*2+colGap, 36}, title="Colocalization Settings"
	
	Variable innerY = yPos + 15
	Variable innerX = xPos + 10
	
	// Col Index
	SetVariable tab9_sv_colindex, pos={innerX, innerY}, size={110, 18}
	SetVariable tab9_sv_colindex, title="Col Index:", value=root:ColIndex, limits={1, 99, 1}
	
	// Max Distance
	SetVariable tab9_sv_maxdist, pos={innerX+120, innerY}, size={130, 18}
	SetVariable tab9_sv_maxdist, title="Max Dist [nm]:", value=root:MaxDistance, limits={10, 1000, 10}
	
	// Min Frames
	SetVariable tab9_sv_minframe, pos={innerX+260, innerY}, size={110, 18}
	SetVariable tab9_sv_minframe, title="Min Frames:", value=root:ColMinFrame, limits={1, 100, 1}
	
	// Same HMM D-state 
	CheckBox tab9_chk_samedstate, pos={innerX+380, innerY}, size={120, 18}
	CheckBox tab9_chk_samedstate, title="Same HMM D-state", variable=root:cSameHMMD
	
	// Make Target Lists 
	Button tab9_btn_makelist, pos={innerX+520, innerY-2}, size={120, 22}
	Button tab9_btn_makelist, title="Make Target Lists", proc=ColMakeListProc, fColor=(0,0,65535)
	
	// Output: 
	TitleBox tab9_lbl_outchan, pos={innerX+650, innerY+2}, size={40, 16}, title="Output:", frame=0
	NVAR/Z gColOutCh = root:ColOutputChannel
	PopupMenu tab9_pop_outchan, pos={innerX+695, innerY}, size={75, 18}
	PopupMenu tab9_pop_outchan, title="", mode=(NVAR_Exists(gColOutCh) ? gColOutCh + 1 : 1), value="Both;C1;C2", proc=ColChannelModeProc
	
	yPos += 45
	
	// ==========================================================================
	// : Batch Analysis (Single) 
	// ==========================================================================
	Variable singleX = xPos
	Variable singleY = yPos
	GroupBox tab9_grp_single, pos={singleX, singleY}, size={colWidth, topRowHeight}, title="Batch Analysis (Single)"
	
	innerY = singleY + 18
	innerX = singleX + 10
	Variable btnX = innerX + lblW
	
	// Analyze Colocalization 
	Button tab9_btn_analyze, pos={innerX, innerY}, size={180, btnH_L}
	Button tab9_btn_analyze, title="▶ Analyze Colocalization", proc=ColAnalyzeProc, fStyle=1, fColor=(0,0,65535)
	
	innerY += btnH_L + 8
	
	// --- Row 1: Find/Trajectory ---
	TitleBox tab9_lbl_s_data, pos={innerX, innerY+2}, size={lblW, 16}, title="Data:", frame=0, fStyle=1
	Button tab9_btn_find, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab9_btn_find, title="Find", proc=ColFindProc, fColor=(0,0,65535)
	Button tab9_btn_trajectory, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab9_btn_trajectory, title="Trajectory", proc=ColTrajectoryProc, fColor=(0,0,65535)
	
	innerY += rowH
	
	// --- Row 2: Intensity ---
	TitleBox tab9_lbl_s_int, pos={innerX, innerY+2}, size={lblW, 16}, title="Int:", frame=0, fStyle=1
	Button tab9_btn_intensity, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab9_btn_intensity, title="Intensity", proc=ColIntensityProc, fColor=(0,0,65535)
	
	innerY += rowH
	
	// --- Row 3: Diffusion ---
	TitleBox tab9_lbl_s_diff, pos={innerX, innerY+2}, size={lblW, 16}, title="Diff:", frame=0, fStyle=1
	Button tab9_btn_diffusion, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab9_btn_diffusion, title="Diffusion", proc=ColDiffusionProc, fColor=(0,0,65535)
	
	innerY += rowH
	
	// --- Row 4: On-time/On-rate ---
	TitleBox tab9_lbl_s_kin, pos={innerX, innerY+2}, size={lblW, 16}, title="Kin:", frame=0, fStyle=1
	Button tab9_btn_ontime, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab9_btn_ontime, title="On-time", proc=ColOntimeProc, fColor=(0,0,65535)
	Button tab9_btn_onrate, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab9_btn_onrate, title="On-rate", proc=ColOnrateProc, fColor=(0,0,65535)
	
	// ==========================================================================
	// : Average Histograms 
	// ==========================================================================
	Variable avgX = xPos + colWidth + colGap
	Variable avgY = yPos
	GroupBox tab9_grp_average, pos={avgX, avgY}, size={colWidth, topRowHeight}, title="Average Histograms"
	
	innerY = avgY + 18
	innerX = avgX + 10
	btnX = innerX + lblW
	
	// Average All 
	Button tab9_btn_avgall, pos={innerX, innerY}, size={180, btnH_L}
	Button tab9_btn_avgall, title="▶ Average Histograms", proc=ColAvgHistProc, fStyle=1, fColor=(65535,43520,0)
	
	innerY += btnH_L + 8
	
	// --- Row 1: Distance ---
	TitleBox tab9_lbl_a_data, pos={innerX, innerY+2}, size={lblW, 16}, title="Data:", frame=0, fStyle=1
	Button tab9_btn_avgdist, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab9_btn_avgdist, title="Distance", proc=ColAvgDistanceProc, fColor=(65535,43520,0)
	
	innerY += rowH
	
	// --- Row 2: Intensity ---
	TitleBox tab9_lbl_a_int, pos={innerX, innerY+2}, size={lblW, 16}, title="Int:", frame=0, fStyle=1
	Button tab9_btn_avgint, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab9_btn_avgint, title="Intensity", proc=ColAvgIntensityProc, fColor=(65535,43520,0)
	
	innerY += rowH
	
	// --- Row 3: Diffusion ---
	TitleBox tab9_lbl_a_diff, pos={innerX, innerY+2}, size={lblW, 16}, title="Diff:", frame=0, fStyle=1
	Button tab9_btn_avgdiff, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab9_btn_avgdiff, title="Diffusion", proc=ColAvgDiffusionProc, fColor=(65535,43520,0)
	
	innerY += rowH
	
	// --- Row 4: On-time/On-rate ---
	TitleBox tab9_lbl_a_kin, pos={innerX, innerY+2}, size={lblW, 16}, title="Kin:", frame=0, fStyle=1
	Button tab9_btn_avgontime, pos={btnX, innerY}, size={btnW_S, btnH_S}
	Button tab9_btn_avgontime, title="On-time", proc=ColAvgOntimeProc, fColor=(65535,43520,0)
	Button tab9_btn_avgonrate, pos={btnX+(btnW_S+btnGap), innerY}, size={btnW_S, btnH_S}
	Button tab9_btn_avgonrate, title="On-rate", proc=ColAvgOnrateProc, fColor=(65535,43520,0)
	
	// ==========================================================================
	// : Compare Parameters 
	// ==========================================================================
	yPos += topRowHeight + 10
	Variable cmpY = yPos
	GroupBox tab9_grp_compare, pos={xPos, cmpY}, size={colWidth, botRowHeight}, title="Compare Parameters"
	
	innerY = cmpY + 18
	innerX = xPos + 10
	btnX = innerX + lblW
	
	// Compare All 
	Button tab9_btn_cmpall, pos={innerX, innerY}, size={180, btnH_L}
	Button tab9_btn_cmpall, title="▶ Compare Parameters", proc=ColCompareProc, fStyle=1, fColor=(0,52428,0)
	
	innerY += btnH_L + 8
	
	// --- 65 + 5 = 70---
	TitleBox tab9_lbl_c_param, pos={innerX, innerY+2}, size={lblW, 16}, title="Param:", frame=0, fStyle=1
	Button tab9_btn_cmpaffinity, pos={btnX-6, innerY}, size={65, btnH_S}
	Button tab9_btn_cmpaffinity, title="Affinity", proc=ColCmpAffinityProc, fColor=(0,52428,0)
	Button tab9_btn_cmpint, pos={btnX+70-6, innerY}, size={65, btnH_S}
	Button tab9_btn_cmpint, title="Intensity", proc=ColCmpIntensityProc, fColor=(0,52428,0)
	Button tab9_btn_cmpdiff, pos={btnX+140-6, innerY}, size={65, btnH_S}
	Button tab9_btn_cmpdiff, title="D-state", proc=ColCmpDiffusionProc, fColor=(0,52428,0)
	Button tab9_btn_cmpontime, pos={btnX+210-6, innerY}, size={65, btnH_S}
	Button tab9_btn_cmpontime, title="On-time", proc=ColCmpOntimeProc, fColor=(0,52428,0)
	Button tab9_btn_cmponrate, pos={btnX+280-6, innerY}, size={65, btnH_S}
	Button tab9_btn_cmponrate, title="On-rate", proc=ColCmpOnrateProc, fColor=(0,52428,0)
	
	innerY += rowH + 2
	
	// --- ---
	NVAR/Z gColAffinity = root:ColAffinityParam
	NVAR/Z gColIntensity = root:ColIntensityMode
	NVAR/Z gColDiffusion = root:ColDiffusionMode
	NVAR/Z gColOntime = root:ColOntimeMode
	NVAR/Z gColOnrate = root:ColOnrateMode
	
	TitleBox tab9_lbl_c_mode, pos={innerX, innerY+2}, size={lblW, 16}, title="Mode:", frame=0, fStyle=1
	PopupMenu tab9_pop_affinity, pos={btnX-6, innerY}, size={65, 18}
	PopupMenu tab9_pop_affinity, title="", mode=(NVAR_Exists(gColAffinity) ? gColAffinity + 1 : 1), value="Kb;Density;Distance"
	PopupMenu tab9_pop_affinity, proc=ColAffinityModePopupProc
	
	PopupMenu tab9_pop_intensity, pos={btnX+70-6, innerY}, size={65, 18}
	PopupMenu tab9_pop_intensity, title="", mode=(NVAR_Exists(gColIntensity) ? gColIntensity + 1 : 1), value="Simple;Fitting"
	PopupMenu tab9_pop_intensity, proc=ColIntensityModePopupProc
	
	PopupMenu tab9_pop_diffusion, pos={btnX+140-6, innerY}, size={65, 18}
	PopupMenu tab9_pop_diffusion, title="", mode=(NVAR_Exists(gColDiffusion) ? gColDiffusion + 1 : 1), value="perTotal;perCol;Steps"
	PopupMenu tab9_pop_diffusion, proc=ColDiffusionModePopupProc
	
	PopupMenu tab9_pop_ontime, pos={btnX+210-6, innerY}, size={65, 18}
	PopupMenu tab9_pop_ontime, title="", mode=(NVAR_Exists(gColOntime) ? gColOntime + 1 : 1), value="Simple;Fitting"
	PopupMenu tab9_pop_ontime, proc=ColOntimeModePopupProc
	
	PopupMenu tab9_pop_onrate, pos={btnX+280-6, innerY}, size={65, 18}
	PopupMenu tab9_pop_onrate, title="", mode=(NVAR_Exists(gColOnrate) ? gColOnrate + 1 : 1), value="On-event;k_on"
	PopupMenu tab9_pop_onrate, proc=ColOnrateModePopupProc
	
	innerY += rowH + 2
	
	// --- Output/Weighting ---
	TitleBox tab9_lbl_c_output, pos={innerX, innerY+2}, size={40, 16}, title="Output:", frame=0, fStyle=1
	PopupMenu tab9_pop_channel, pos={innerX+45, innerY}, size={80, 18}
	PopupMenu tab9_pop_channel, title="", mode=(NVAR_Exists(gColOutCh) ? gColOutCh + 1 : 1), value="Both;C1;C2", proc=ColChannelModeProc
	
	TitleBox tab9_lbl_c_weight, pos={innerX+140, innerY+2}, size={55, 16}, title="Weighting:", frame=0, fStyle=1
	NVAR/Z gColWtMode = root:ColWeightingMode
	PopupMenu tab9_pop_weighting, pos={innerX+200, innerY}, size={80, 18}
	PopupMenu tab9_pop_weighting, title="", mode=(NVAR_Exists(gColWtMode) ? gColWtMode + 1 : 1), value="Particle;Molecule", proc=ColWeightingModeProc
	
	// ==========================================================================
	// : Layout Settings 
	// ==========================================================================
	Variable optX = xPos + colWidth + colGap
	Variable optY = cmpY
	GroupBox tab9_grp_settings, pos={optX, optY}, size={colWidth, botRowHeight}, title="Layout Settings"
	
	innerY = optY + 20
	innerX = optX + 10
	
	// --- Row 1: Paper Size ---
	TitleBox tab9_lbl_paper, pos={innerX, innerY+2}, size={45, 16}, title="Paper:", frame=0, fStyle=1
	PopupMenu tab9_pop_papersize, pos={innerX+45, innerY}, size={70, 20}
	PopupMenu tab9_pop_papersize, title="", mode=2, value="Letter;A4;Custom"
	PopupMenu tab9_pop_papersize, proc=PaperSizePopupProc
	
	SetVariable tab9_sv_width, pos={innerX+125, innerY}, size={70, 18}
	SetVariable tab9_sv_width, title="W:", value=root:LayoutPageW, limits={4,20,0.1}
	
	SetVariable tab9_sv_height, pos={innerX+200, innerY}, size={70, 18}
	SetVariable tab9_sv_height, title="H:", value=root:LayoutPageH, limits={4,20,0.1}
	
	TitleBox tab9_lbl_unit1, pos={innerX+275, innerY+2}, size={30, 16}, title="[in]", frame=0
	
	innerY += 25
	
	// --- Row 2: Page Offset and Graph Gap ---
	SetVariable tab9_sv_offset, pos={innerX, innerY}, size={100, 18}
	SetVariable tab9_sv_offset, title="Offset:", value=root:LayoutOffset, limits={0,50,1}
	TitleBox tab9_lbl_unit2, pos={innerX+105, innerY+2}, size={30, 16}, title="[mm]", frame=0
	
	SetVariable tab9_sv_gap, pos={innerX+150, innerY}, size={100, 18}
	SetVariable tab9_sv_gap, title="Gap:", value=root:LayoutGap, limits={0,20,0.5}
	TitleBox tab9_lbl_unit3, pos={innerX+255, innerY+2}, size={30, 16}, title="[mm]", frame=0
	
	innerY += 25
	
	// --- Row 3: Division + Output Format ---
	TitleBox tab9_lbl_div, pos={innerX, innerY+2}, size={50, 16}, title="Division:", frame=0, fStyle=1
	SetVariable tab9_sv_divw, pos={innerX+55, innerY}, size={55, 18}
	SetVariable tab9_sv_divw, title="W:", value=root:LayoutDivW, limits={1,10,1}
	
	SetVariable tab9_sv_divh, pos={innerX+120, innerY}, size={55, 18}
	SetVariable tab9_sv_divh, title="H:", value=root:LayoutDivH, limits={1,10,1}
	
	// Output Format: SVG
	TitleBox tab9_lbl_output, pos={innerX+185, innerY+2}, size={45, 16}, title="Output:", frame=0, fStyle=1
	PopupMenu tab9_pop_output, pos={innerX+230, innerY}, size={75, 20}
	PopupMenu tab9_pop_output, title="", mode=3, value="Graph;PNG;SVG"
	
	innerY += 25
	
	// --- Row 4: Create Layout Button + Clear All  ---
	Button tab9_btn_createlayout, pos={innerX, innerY-2}, size={120, 26}
	Button tab9_btn_createlayout, title="Create Layout", proc=ColCreateLayoutButtonProc, fStyle=1, fColor=(32768,32768,65535)
	
	// Clear All Layout Single - 
	GroupBox tab9_grp_clearall, pos={innerX+130, innerY-5}, size={215, 30}, title=""
	TitleBox tab9_lbl_clearall, pos={562, 388}, size={50, 18}
	TitleBox tab9_lbl_clearall, title="Clear All", frame=0, fStyle=1
	Button tab9_btn_clearlayout, pos={605, 384}, size={50, 18}
	Button tab9_btn_clearlayout, title="Layout", proc=ClearAllLayoutProc
	Button tab9_btn_cleartable, pos={660, 384}, size={50, 18}
	Button tab9_btn_cleartable, title="Table", proc=ClearAllTableProc
	Button tab9_btn_cleargraph, pos={715, 384}, size={50, 18}
	Button tab9_btn_cleargraph, title="Graph", proc=ClearAllGraphProc
	
	innerY += 35
	
	// --- Row 5: Information ---
	TitleBox tab9_lbl_info, pos={innerX, innerY}, size={370, 32}
	TitleBox tab9_lbl_info, title="Shortcuts: Ctrl+7=Clear Layout, Ctrl+8=Clear Table, Ctrl+9=Clear Graph", frame=0, fStyle=2
End

// Layout ColProcColocalization tab
Function ColAffinityModePopupProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	Variable/G root:ColAffinityParam = popNum - 1  // 0=Kb, 1=Density, 2=Distance
End

// Colocalization LayoutCreate Layout Proc
Function ColCreateLayoutButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// Layout
	NVAR pageW = root:LayoutPageW
	NVAR pageH = root:LayoutPageH
	NVAR offset_mm = root:LayoutOffset
	NVAR gap_mm = root:LayoutGap
	NVAR divW = root:LayoutDivW
	NVAR divH = root:LayoutDivH
	
	// Output Format
	ControlInfo/W=SMI_MainPanel tab9_pop_output
	Variable outputMode = V_Value - 1  // 0=Graph, 1=PNG, 2=SVG
	
	// ColocalizationLayout
	CreateColocalizationLayout(pageW, pageH, offset_mm, gap_mm, divW, divH, outputMode)
End

Function ColIntensityModePopupProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	Variable/G root:ColIntensityMode = popNum - 1  // 0=Simple, 1=Fitting
End

Function ColDiffusionModePopupProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	Variable/G root:ColDiffusionMode = popNum - 1  // 0=perTotal, 1=perCol, 2=Steps
End

Function ColOntimeModePopupProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	Variable/G root:ColOntimeMode = popNum - 1  // 0=Simple, 1=Fitting
End

Function ColOnrateModePopupProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	Variable/G root:ColOnrateMode = popNum - 1  // 0=On-event, 1=k_on
End

// -----------------------------------------------------------------------------
// Layout Tab Proc Functions
// -----------------------------------------------------------------------------
Function LayoutSamplePopupProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	SVAR/Z gSampleName = root:gSampleNameInput
	if(SVAR_Exists(gSampleName))
		gSampleName = popStr
	endif
	SetCurrentSampleName(popStr)
End

// Common Tab 
Function CommonSamplePopupProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	// gCurrentSampleName
	SVAR/Z gCurrentSample = root:gCurrentSampleName
	if(SVAR_Exists(gCurrentSample))
		gCurrentSample = popStr
	else
		String/G root:gCurrentSampleName = popStr
	endif
	
	// SampleName
	SVAR/Z gSampleName = root:gSampleNameInput
	if(SVAR_Exists(gSampleName))
		gSampleName = popStr
	endif
	SetCurrentSampleName(popStr)
	
	// Use user-defined nameON
	NVAR/Z cUseUserDefined = root:cUseUserDefinedName
	if(NVAR_Exists(cUseUserDefined))
		cUseUserDefined = 1
	endif
	
	// SampleName
	DoWindow SMI_MainPanel
	if(V_flag)
		SetVariable tab0_samplename, win=SMI_MainPanel, disable=0
		CheckBox tab0_chk_userdefined, win=SMI_MainPanel, value=1
	endif
	
	// 
	UpdateSMIResults(popStr)
	UpdateDataInfo(popStr)
End

// 
Function RefreshSampleListProc(ctrlName) : ButtonControl
	String ctrlName
	
	// PopupMenu
	PopupMenu tab0_pop_sample, win=SMI_MainPanel, mode=1, value=#"GetAnalyzedSampleList()"
	PopupMenu tab8_pop_sample, win=SMI_MainPanel, mode=1, value=#"GetAnalyzedSampleList()"
	
	Print "Sample list refreshed"
End

Function LayoutUserDefinedCheckProc(ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR/Z cUseUserDefined = root:cUseUserDefinedName
	if(NVAR_Exists(cUseUserDefined))
		cUseUserDefined = checked
	endif
End

Function PaperSizePopupProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR pageW = root:LayoutPageW
	NVAR pageH = root:LayoutPageH
	
	if(popNum == 1)  // Letter
		pageW = 8.5
		pageH = 11
	elseif(popNum == 2)  // A4
		pageW = 8.27
		pageH = 11.69
	endif
	// popNum == 3 (Custom) 
End

// Timelapse tabPaperSize Proc
Function TL_PaperSizePopupProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	// 
	PaperSizePopupProc(ctrlName, popNum, popStr)
End

Function CreateLayoutButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// Layout
	NVAR pageW = root:LayoutPageW
	NVAR pageH = root:LayoutPageH
	NVAR offset_mm = root:LayoutOffset
	NVAR gap_mm = root:LayoutGap
	NVAR divW = root:LayoutDivW
	NVAR divH = root:LayoutDivH
	
	// Output Mode1=Graph, 2=PNG, 3=SVG → 0, 1, 2
	ControlInfo/W=SMI_MainPanel tab8_pop_output
	Variable outputMode = V_Value - 1  // PopupMenu1-based-1
	
	// SampleName
	ControlInfo/W=SMI_MainPanel tab8_pop_sample
	String sampleName = S_Value
	
	// 
	if(StringMatch(sampleName, "(No samples loaded)"))
		sampleName = ""
	endif
	
	// 
	CreateAutoLayout(sampleName, pageW, pageH, offset_mm, gap_mm, divW, divH, outputMode)
End

// Timelapse tabCreate Layout ProcMolDensImg_*
Function TL_CreateLayoutButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// Layout
	NVAR pageW = root:LayoutPageW
	NVAR pageH = root:LayoutPageH
	NVAR offset_mm = root:LayoutOffset
	NVAR gap_mm = root:LayoutGap
	NVAR divW = root:LayoutDivW
	NVAR divH = root:LayoutDivH
	
	// Output Mode
	ControlInfo/W=SMI_MainPanel tab7_pop_output
	Variable outputMode = V_Value - 1
	
	// MolDensImg_*
	TL_CreateMolDensLayout(pageW, pageH, offset_mm, gap_mm, divW, divH, outputMode)
End

// -----------------------------------------------------------------------------
// Clear All Proc Functions
// -----------------------------------------------------------------------------
Function ClearAllLayoutProc(ctrlName) : ButtonControl
	String ctrlName
	ClearAllLayouts()
End

Function ClearAllTableProc(ctrlName) : ButtonControl
	String ctrlName
	ClearAllTables()
End

Function ClearAllGraphProc(ctrlName) : ButtonControl
	String ctrlName
	ClearAllGraphs()
End

// 
Function ClearAllLayouts()
	String layoutList = WinList("*", ";", "WIN:4")
	Variable i, numLayouts = ItemsInList(layoutList)
	String layoutName
	
	for(i = 0; i < numLayouts; i += 1)
		layoutName = StringFromList(i, layoutList)
		DoWindow/K $layoutName
	endfor
	
	Printf "Cleared %d layouts\r", numLayouts
End

Function ClearAllTables()
	String tableList = WinList("*", ";", "WIN:2")
	Variable i, numTables = ItemsInList(tableList)
	String tableName
	
	for(i = 0; i < numTables; i += 1)
		tableName = StringFromList(i, tableList)
		DoWindow/K $tableName
	endfor
	
	Printf "Cleared %d tables\r", numTables
End

Function ClearAllGraphs()
	String graphList = WinList("*", ";", "WIN:1")
	Variable i, numGraphs = ItemsInList(graphList)
	String graphName
	
	for(i = 0; i < numGraphs; i += 1)
		graphName = StringFromList(i, graphList)
		// 
		if(!StringMatch(graphName, "*Panel*"))
			DoWindow/K $graphName
		endif
	endfor
	
	Printf "Cleared %d graphs\r", numGraphs
End

// =============================================================================
// Timelapse Tab Button Procedures
// =============================================================================

// ----- Parameters Group -----
Function TL_CreateSampleListButtonProc(ctrlName) : ButtonControl
	String ctrlName
	TL_CreateSampleList()
End

// ----- Selected Parameter Group (Blue buttons) -----
Function TL_UpdateListButtonProc(ctrlName) : ButtonControl
	String ctrlName
	TL_UpdateParameterPopup()
End

Function TL_OriginalButtonProc(ctrlName) : ButtonControl
	String ctrlName
	TL_ProcessSelectedParameter(0)  // mode 0 = Original
End

Function TL_NormalizeButtonProc(ctrlName) : ButtonControl
	String ctrlName
	TL_ProcessSelectedParameter(1)  // mode 1 = Normalize
End

Function TL_DifferenceButtonProc(ctrlName) : ButtonControl
	String ctrlName
	TL_ProcessSelectedParameter(2)  // mode 2 = Difference
End

// ----- Compare All Group (Orange buttons) -----
Function TL_OriginalAllButtonProc(ctrlName) : ButtonControl
	String ctrlName
	TL_OriginalCompareAll()
End

Function TL_NormalizeAllButtonProc(ctrlName) : ButtonControl
	String ctrlName
	TL_NormalizeCompareAll()
End

Function TL_DifferenceAllButtonProc(ctrlName) : ButtonControl
	String ctrlName
	TL_DifferenceCompareAll()
End

// ----- Density Group (Green buttons) -----
Function TL_DxIImageButtonProc(ctrlName) : ButtonControl
	String ctrlName
	TL_CreateDxIImage()
End

