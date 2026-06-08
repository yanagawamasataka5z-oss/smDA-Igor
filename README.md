[smDA_v5_4_6e_UserManual.md](https://github.com/user-attachments/files/24967474/smDA_v5_4_6e_UserManual.md)
# smDA
## single-molecule Dynamics Analyzer

**Version 5.4.6e**

# User Manual

**Masataka Yanagawa**  
Laboratory of Molecular Pharmacology  
Graduate School of Pharmaceutical Sciences, Kyoto University

*January 2026*

---

## Table of Contents

1. [Introduction](#1-introduction)
   - 1.1 [Key Features](#11-key-features)
   - 1.2 [System Requirements](#12-system-requirements)
2. [Installation](#2-installation)
   - 2.1 [File Structure](#21-file-structure)
   - 2.2 [Installation Steps](#22-installation-steps)
3. [Quick Start Guide](#3-quick-start-guide)
   - 3.1 [Opening the Panel](#31-opening-the-panel)
   - 3.2 [Panel Overview](#32-panel-overview)
   - 3.3 [Basic Workflow](#33-basic-workflow)
4. [Data Format](#4-data-format)
   - 4.1 [Input Data Formats](#41-input-data-formats)
   - 4.2 [Folder Structure](#42-folder-structure)
5. [Analysis Methods](#5-analysis-methods)
   - 5.0 [Data Visualization](#50-data-visualization)
   - 5.1 [Diffusion Analysis](#51-diffusion-analysis)
   - 5.2 [Intensity and Density Analysis](#52-intensity-and-density-analysis)
   - 5.3 [Kinetic Analysis](#53-kinetic-analysis)
   - 5.4 [Colocalization Analysis](#54-colocalization-analysis)
6. [Parameter Reference](#6-parameter-reference)
   - 6.1 [Measurement Parameters](#61-measurement-parameters)
   - 6.2 [Data Format Settings](#62-data-format-settings)
   - 6.3 [Diffusion Analysis Parameters](#63-diffusion-analysis-parameters)
   - 6.4 [Intensity Analysis Parameters](#64-intensity-analysis-parameters)
7. [Step-by-Step Analysis Guide](#7-step-by-step-analysis-guide)
   - 7.1 [Single Sample Analysis](#71-single-sample-analysis)
   - 7.2 [Batch Analysis (Multiple Samples)](#72-batch-analysis-multiple-samples)
   - 7.3 [Colocalization Analysis](#73-colocalization-analysis)
8. [Output and Export](#8-output-and-export)
   - 8.1 [Data Structure](#81-data-structure)
   - 8.2 [Key Output Waves](#82-key-output-waves)
   - 8.3 [Exporting Graphs](#83-exporting-graphs)
9. [Statistical Analysis](#9-statistical-analysis)
   - 9.1 [Available Tests](#91-available-tests)
   - 9.2 [Running Statistical Tests](#92-running-statistical-tests)
   - 9.3 [Interpreting Results](#93-interpreting-results)
   - 9.4 [Graph Size Settings](#94-graph-size-settings)
10. [Troubleshooting](#10-troubleshooting)
    - 10.1 [Common Issues](#101-common-issues)
    - 10.2 [Igor Pro Tips](#102-igor-pro-tips)
11. [References and Citations](#11-references-and-citations)
    - 11.1 [Software Citation](#111-software-citation)
    - 11.2 [Related Publications](#112-related-publications)
    - 11.3 [Resources](#113-resources)

---

## 1. Introduction

smDA (single-molecule Dynamics Analyzer) is a comprehensive software package for analyzing single-molecule imaging (SMI) data. Originally developed as smDynamicsAnalyzer for Igor Pro 8, version 4.x represents a complete refactoring with modular architecture, improved performance, and enhanced analysis capabilities.

### 1.1 Key Features

- **Diffusion Analysis:** MSD-Δt plot analysis, step size histogram analysis with AIC-based model selection, VB-HMM clustering support
- **Intensity Analysis:** Oligomer size estimation through intensity histogram fitting with Gaussian or Log-normal distributions
- **Kinetic Analysis:** Off-rate analysis from trajectory duration, On-rate analysis from cumulative events
- **Particle Density:** Mean local density estimation using Ripley K-function
- **Colocalization Analysis:** Dual-color interaction analysis with kinetic parameters
- **Statistical Comparison:** Multiple sample comparison with ANOVA and post-hoc tests
- **Batch Processing:** Automated analysis of multiple samples with standardized output

### 1.2 System Requirements

- Igor Pro 9.0 or later (64-bit recommended)
- Windows 10/11 or macOS 10.14+ (both platforms supported)
- Minimum 8 GB RAM (16 GB recommended for large datasets)
- Display resolution: 1920×1080 or higher recommended

---

## 2. Installation

### 2.1 File Structure

smDA v4.2.0e consists of 14 procedure files (.ipf) that must be loaded together:

| File | Description |
|------|-------------|
| SMI_Main.ipf | Main entry point and menu definitions |
| SMI_Panel.ipf | GUI panel with tabbed interface |
| SMI_Core.ipf | Core utility functions and global parameters |
| SMI_FitFunctions.ipf | Fitting functions (Gaussian, exponential, etc.) |
| SMI_DataLoader.ipf | Data loading from CSV files |
| SMI_Diffusion.ipf | MSD and step size analysis |
| SMI_Intensity.ipf | Intensity histogram analysis |
| SMI_Kinetics.ipf | Off-rate and On-rate analysis |
| SMI_Statistics.ipf | Statistical analysis and matrix operations |
| SMI_Comparison.ipf | Sample comparison and visualization |
| SMI_Colocalization.ipf | Dual-color colocalization analysis |
| SMI_Segmentation.ipf | Trajectory segmentation |
| SMI_Timelapse.ipf | Time-lapse analysis |
| SMI_Layout.ipf | Graph layout and export |

### 2.2 Installation Steps

**★ Easiest Method (Recommended):** Open Igor Pro 9, then drag and drop all 14 .ipf files directly into the Igor Pro window. Igor will automatically open and compile all procedures.

**Alternative Method:**
1. Extract all .ipf files to a folder
2. Open Igor Pro 9 and select File → Open File → Procedure...
3. Load all 14 .ipf files
4. Compile procedures (Macros → Compile)
5. Initialize smDA from the smDA menu or run `SMI_Initialize()` in command line

---

## 3. Quick Start Guide

### 3.1 Opening the Panel

After installation, open the main panel using one of these methods:
- **Menu:** smDA → Open Panel (or press Ctrl+2 / Cmd+2)
- **Command:** `SMI_CreatePanel()`

### 3.2 Panel Overview

The main panel contains 10 tabs for different analysis functions:

| Tab | Function |
|-----|----------|
| Auto Analysis | Main workflow control with one-click batch analysis |
| Data Loading | Load single-molecule tracking data |
| Diffusion | MSD and step size analysis settings |
| Intensity | Intensity histogram and oligomer analysis |
| Kinetics | Off-rate and On-rate analysis |
| Colocalization | Dual-color colocalization analysis |
| Statistics | Statistical test settings and graph options |
| Timelapse | Time-lapse data analysis |
| Layout Single | Export layouts for single-color data |
| Layout Col | Export layouts for colocalization data |

### 3.3 Basic Workflow

**For single sample analysis:**
1. Set measurement parameters (framerate, scale, etc.) in the Auto Analysis tab
2. Select data format (AAS v2/v4, HMM mode)
3. Click "Single Analysis" to select a folder and run analysis

**For batch analysis (multiple samples):**
1. Organize data folders with consistent naming
2. Click "Auto Analysis" to run: Batch → Average → Compare
3. View comparison plots in the Comparison folder

---

## 4. Data Format

### 4.1 Input Data Formats

smDA uses CSV files output from the Auto Analysis System (AAS) for single-molecule tracking data:

#### 4.1.1 Tracking Data Format (*_data.csv)

Single-molecule tracking results from AAS. File naming convention: `[basename]_data.csv`
- **AAS v2:** Earlier version format
- **AAS v4:** Current version with extended columns

Required columns: Frame, X position (pixels), Y position (pixels), Intensity

#### 4.1.2 HMM Format (*_hmm.csv)

VB-HMM analysis output in CSV format. File naming convention: `[basename]_hmm.csv`

The HMM CSV file contains trajectory data with diffusion state assignments from VB-HMM clustering analysis.

Required columns:
- Frame number and trajectory index
- X, Y coordinates (pixels)
- Intensity values
- Diffusion state assignment (option, one to five states)

### 4.2 Folder Structure

Data files should be organized in a single folder. Each cell measurement should have both *_data.csv and *_hmm.csv files:

```
SampleName/
    ├── cell1_data.csv
    ├── cell1_hmm.csv
    ├── cell2_data.csv
    ├── cell2_hmm.csv
    ├── cell3_data.csv
    └── cell3_hmm.csv
```

> **Note:** When HMM mode is disabled, only *_data.csv files are required.

---

## 5. Analysis Methods

### 5.0 Data Visualization

Before running quantitative analysis, visualize trajectory data using the Data Loading tab:

- **Trajectory:** Displays raw XY trajectories for all particles in original positions.
- **Origin-Aligned Trajectory:** Aligns all trajectories to common origin (0,0). Color-coded by HMM state when available.
- **Average Aligned Trajectory:** Creates averaged origin-aligned trajectories across all cells in a sample.

### 5.1 Diffusion Analysis

#### 5.1.1 MSD-Δt Plot Analysis

The mean-squared displacement (MSD) is calculated for each trajectory and fitted to determine diffusion parameters.

**Time-averaged MSD:**

$$\text{MSD}(n\Delta t) = \frac{1}{N-1-n} \sum_{j} \left[ (x_{j+n} - x_j)^2 + (y_{j+n} - y_j)^2 \right]$$

**Fitting models - Confined diffusion:**

$$\text{MSD}(\Delta t) = \frac{L^2}{3} \left[ 1 - \exp\left( -\frac{12 D_0 \Delta t}{L^2} \right) \right] + 4\varepsilon^2$$

Where D₀ is the diffusion coefficient [μm²/s], α is the anomalous exponent, L is confinement length [μm], and ε is localization error [μm].

#### 5.1.2 Step Size Histogram Analysis

Displacement histograms are fitted with multiple diffusion state models:

$$P(r) = \sum_{i} A_i \cdot \frac{r}{2 D_i \Delta t} \cdot \exp\left( -\frac{r^2}{4 D_i \Delta t} \right)$$

The optimal number of states n is selected using AIC (Akaike Information Criterion):

$$\text{AIC} = n \cdot \ln\left( \frac{\text{RSS}}{n} \right) + 2k$$

### 5.2 Intensity and Density Analysis

#### 5.2.1 Intensity Analysis

Oligomer size distribution is estimated by fitting intensity histograms with sum of Gaussian functions:

$$P(x) = \sum_{n} A_n \cdot \exp\left( -\frac{(x - nI)^2}{2n\sigma^2} \right)$$

Where I and σ are the mean and SD of single-molecule intensity, and n is the oligomer size.

#### 5.2.2 Density Analysis

Molecular density is estimated from local density measurements within a specified radius r around each detected molecule. The analysis calculates the number of detected molecules, measurement area, and average density per frame.

### 5.3 Kinetic Analysis

#### 5.3.1 Off-rate Analysis

Trajectory duration distributions are fitted with sum of exponential functions:

$$P(t) = \sum_{i=1}^{n} A_i \cdot \exp\left( -\frac{t}{\tau_i} \right)$$

The off-rate constant k = 1/τ reflects the apparent dissociation rate.

#### 5.3.2 On-rate Analysis

Cumulative event number is fitted to estimate the on-rate:

$$f(t) = V_0 \cdot \tau \cdot \left( 1 - \exp\left( -\frac{t}{\tau} \right) \right), \quad \text{On‑rate} = \frac{V_0}{\text{Area}_{\text{cell}}}$$

### 5.4 Colocalization Analysis

Two-channel colocalization analysis detects molecular interactions between differently labeled proteins.

#### 5.4.1 Colocalization Detection

Colocalization is defined when particles from two channels are within a specified distance threshold (typically 100-200 nm) for at least one frame. The distance threshold should account for localization precision and chromatic aberration.

#### 5.4.2 Binding Constant (Kb) Calculation

The apparent binding constant Kb is calculated from the colocalization ratio and molecular densities:

$$K_b = \frac{\rho_{\text{col}}}{\rho_{\text{free},1} \times \rho_{\text{free},2}}$$

where ρ_col is the colocalized step density (colocalized steps/overlapping area/number of frames), ρ_free,1 and ρ_free,2 are the free (non-colocalized) step densities for each channel.

Higher Kb values indicate stronger molecular interactions between the two labeled species.

---

## 6. Parameter Reference

### 6.1 Measurement Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| Rate [s/f] | 0.03 | Frame rate (seconds per frame) |
| Frames | 100 | Total number of frames |
| Scale | 0.065 | Pixel size [μm/pixel] |
| ROI [pix] | 12 | Region of interest size for tracking |
| Min frame | 15 | Minimum trajectory length |
| Pix Num | 512 | Image size in pixels |
| ExCoef | 0.23 | Electron conversion coefficient [e⁻/count] |
| QE | 0.80 | Quantum efficiency |
| Intensity | Photon number | Output mode: Raw Intensity or Photon number |

### 6.2 Data Format Settings

| Setting | Description |
|---------|-------------|
| AAS v2/v4 | AAS output format version |
| HMM | Enable VB-HMM data loading (*_hmm.csv) |
| n (Dstate) | Number of diffusion states (1-5) |
| Seg | Maximum segment number for segmentation analysis |

### 6.3 Diffusion Analysis Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| Range [frames] | 20 | Maximum lag time for MSD |
| Threshold [%] | 1 | Data threshold percentage |
| Time Average | ON | Use time-averaged MSD |
| D₀ | 0.05 | Initial diffusion coefficient [μm²/s] |
| Alpha | 1 | Initial anomalous exponent |
| L | 0.1 | Initial confinement length [μm] |
| Epsilon | 0.005 | Localization error [μm²] |
| Fix ε | ON | Fix epsilon during fitting |

### 6.4 Intensity Analysis Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| Min Oligomers | 2 | Minimum oligomer size for AIC selection |
| Max Oligomers | 8 | Maximum oligomer size for AIC selection |
| Hist Bin | 25 | Histogram bin size [a.u.] |
| Hist Dim | 200 | Histogram dimension |
| Mean Int | 250 | Initial single-molecule intensity |
| SD Int | 100 | Initial intensity standard deviation |
| Fix Mean/SD | OFF | Fix mean and SD during fitting |
| Norm by total | ON | Normalize by total particle number |

---

## 7. Step-by-Step Analysis Guide

### 7.1 Single Sample Analysis

**Step 1: Configure Parameters**  
Open the Auto Analysis tab and set measurement parameters matching your experimental conditions (framerate, pixel scale, etc.).

**Step 2: Select Data Format**  
Choose the appropriate input format (AAS v2/v4). Enable HMM checkbox if using VB-HMM clustered data (*_hmm.csv files).

**Step 3: Run Single Analysis**  
Click the blue "Single Analysis" button and select a folder containing your tracking data files. The analysis will proceed through: Load → Diffusion → Intensity → Kinetics.

**Step 4: Review Results**  
Results are stored in the Data Browser under `root:SampleName:`. Individual cell data is in numbered subfolders, averaged results in `:Results`, and matrix data in `:Matrix`.

### 7.2 Batch Analysis (Multiple Samples)

**Step 1: Organize Data**  
Create separate folders for each experimental condition (e.g., Control, Drug1, Drug2), each containing individual cell data files (*_data.csv, *_hmm.csv).

**Step 2: Run Auto Analysis**  
Click "Auto Analysis" and select the parent folder containing all condition folders. This runs: Batch analysis → Average all → Compare all.

**Step 3: View Comparison Plots**  
Comparison graphs (violin plots, bar charts) are automatically generated in the `root:Comparison` folder. Select graphs and run statistical tests from the Statistics tab.

### 7.3 Colocalization Analysis

**Step 1: Prepare Dual-Color Data**  
Analyze both channels separately using Single/Batch Analysis with HMM mode enabled.

**Step 2: Create Target Lists**  
Go to the Colocalization tab and click "Make List" to create paired sample lists for ch1 and ch2.

**Step 3: Run Colocalization**  
Set colocalization parameters (distance threshold, D ratio) and click "Analyze" to find colocalization events and extract kinetic parameters.

---

## 8. Output and Export

### 8.1 Data Structure

Results are organized in Igor Pro's hierarchical data folder structure:

```
root:
  ├── SampleName/
  │   ├── SampleName1/    (Cell 1 data)
  │   ├── SampleName2/    (Cell 2 data)
  │   ├── Results/        (Averaged results)
  │   └── Matrix/         (Cell-by-cell matrix)
  └── Comparison/         (Comparison plots)
```

### 8.2 Key Output Waves

| Wave Name | Description |
|-----------|-------------|
| MSD_avg_S0 | Averaged MSD for state 0 (total) |
| D_fit_S0 | Fitted diffusion coefficient |
| L_fit_S0 | Fitted confinement length |
| Int_Hist_S0 | Intensity histogram |
| Pop_S0 | Oligomer population distribution |
| P_Duration_S0 | Off-rate decay curve |
| CumOnEvent_S0 | Cumulative on-events |
| ParticleDens_S0 | Particle density |
| MolDens_S0 | Molecular density |

### 8.3 Exporting Graphs

Use the Layout tabs to create publication-ready figure layouts:

1. Configure page size (A4, Letter, Custom)
2. Set graph arrangement (rows × columns)
3. Choose output format (Graph window, PNG, SVG)
4. Click "Create Layout" to generate figures

---

## 9. Statistical Analysis

### 9.1 Available Tests

smDA provides the following statistical tests for comparing experimental conditions:

- **Welch's t-test:** For comparing two groups with potentially unequal variances
- **One-way ANOVA:** For comparing three or more groups
- **Šidák correction:** Multiple comparison correction, available in two modes:
  - *vs control:* Compares each group against a designated control group
  - *all pairs:* Compares all possible pairs of groups

### 9.2 Running Statistical Tests

1. Configure test settings in the Statistics tab (test mode: "All pairs" or "vs Control", output options)
2. Click the "Compare" button in each analysis tab to run statistical tests on the summary plots
3. Significance markers are automatically added to graphs
4. A table of p-values and statistics is generated

### 9.3 Interpreting Results

Significance levels are indicated as follows:
- \* p < 0.05
- \*\* p < 0.01
- \*\*\* p < 0.001

### 9.4 Graph Size Settings

Summary plot dimensions can be configured in the Compare tab:

**Graph Width:** Set width in points (default 150). Height is calculated as Width × 0.618 (golden ratio).

---

## 10. Troubleshooting

### 10.1 Common Issues

**Issue:** "Wave not found" error  
**Solution:** Ensure data format settings match your input files. Check that HMM checkbox is enabled for *_hmm.csv data.

**Issue:** Fitting fails with error  
**Solution:** Adjust initial parameter values (D₀, Mean Int) closer to expected values. Reduce the number of fit states if data is sparse.

**Issue:** Empty histograms or plots  
**Solution:** Check that Min frame setting is not larger than your trajectory lengths. Verify histogram bin and dimension settings.

### 10.2 Igor Pro Tips

- **Data Browser:** Press Ctrl+B (Win) or Cmd+B (Mac) to open and navigate the data structure
- **Close all graphs:** Press Ctrl+9 / Cmd+9 or use smDA menu
- **Close all tables:** Press Ctrl+8 / Cmd+8 or use smDA menu
- **Duplicate graph:** Press Ctrl+D / Cmd+D with graph window selected

---

## 11. References and Citations

### 11.1 Software Citation

When using smDA for published research, please cite:

[1] Yoda T, et al. A practical guide to multicolor live-cell single-molecule imaging. bioRxiv. 2026. doi: xxx

[2] Yanagawa M, Sako Y. Workflows of the Single-Molecule Imaging Analysis in Living Cells: Tutorial Guidance to the Measurement of the Drug Effects on a GPCR. Methods Mol Biol. 2021;2274:391-441. doi: 10.1007/978-1-0716-1258-3_32

### 11.2 Related Publications

[3] Abe M, Yanagawa M, et al. Single-molecule behavior and cell-growth regulation in human RTKs. bioRxiv. 2026. doi: 10.64898/2025.12.29.696957

[4] Kuramoto R, et al. Membrane-domain compartmentalization of active GPCRs by β-arrestins through PtdIns(4,5)P2 binding. Nat Chem Biol. 2025. doi: 10.1038/s41589-025-01967-4

[5] Carino CMC, et al. Signal profiles and spatial regulation of β-arrestin recruitment through Gβ5 and GRK3 at the μ-opioid receptor. Eur J Pharmacol. 2025;987:177151. doi: 10.1016/j.ejphar.2024.177151

[6] Abe M, et al. Bilateral regulation of EGFR activity and local PI(4,5)P2 dynamics in mammalian cells observed with superresolution microscopy. eLife. 2024;13:e101652. doi: 10.7554/eLife.101652

[7] Yoda T, et al. Four-color single-molecule imaging system for tracking GPCR dynamics with fluorescent HiBiT peptide. Biophys Physicobiol. 2024;21(3):e210020. doi: 10.2142/biophysico.bppb-v21.0020

[8] Kuwashima Y, et al. TRPV4-dependent Ca2+ influx determines cholesterol dynamics at the plasma membrane. Biophys J. 2024;123(7):867-884. doi: 10.1016/j.bpj.2024.02.030

[9] Kawakami K, Yanagawa M, et al. Heterotrimeric Gq proteins act as a switch for GRK5/6 selectivity underlying β-arrestin transducer bias. Nat Commun. 2022;13(1):487. doi: 10.1038/s41467-022-28056-7

[10] Kuwashima Y, et al. Comparative Analysis of Single-Molecule Dynamics of TRPV1 and TRPV4 Channels in Living Cells. Int J Mol Sci. 2021;22(16):8473. doi: 10.3390/ijms22168473

[11] Akiyama M, et al. DNA-Based Synthetic Growth Factor Surrogates with Fine-Tuned Agonism. Angew Chem Int Ed Engl. 2021;60(42):22745-22752. doi: 10.1002/anie.202105314

[12] Yanagawa M, et al. Single-molecule diffusion-based estimation of ligand effects on G protein-coupled receptors. Sci Signal. 2018;11(548). doi: 10.1126/scisignal.aao1917

### 11.3 Resources

- **GitHub Repository:** https://github.com/masataka-yanagawa/IgorPro8-smDynamicsAnalyzer
- **Igor Pro:** https://www.wavemetrics.com/products/igorpro
- **AAS (Zido):** https://eng.zido.co.jp

---

*--- End of Manual ---*
