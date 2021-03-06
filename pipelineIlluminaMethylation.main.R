# 2011-2012-2013
# Nizar TOULEIMAT
# nizar.touleimat @ cng.com
# Marc Jan Bonder
# m.j.bonder @ umcg.nl
#
############################
# Release data: 06-06-2014 #
############################
#
########################################################################################################
#                                                 Warning                                              #
# Added new probe annotation to replace the default genome studio probe annotations.                   #
# This can be changed by renaming the probe annotation files in: ".\ADDITIONAL_INFO\ProbeAnnotation\". #
# With the new annotation SQN with "relationToSequence" is no longer supported                         #
########################################################################################################
#
#######################
#### TO READ FIRST ####
#######################
# This script, when sourced ( source("pipelineIlluminaMethylation.main.R") ), loads raw methylation data and performs a complete preprocessing and normalization of a batch of Illumina 450K data (corresponding to different plates).
# Please read and change carefully! Read up untill: "NOW YOU CAN SOURCE THIS SCRIPT !"
#
#################
# Pre-requisites:
# - install last 'lumi' and 'methylumi' bioconductor packages
# - all pacakges that are used: "lumi", "methylumi", "RPMM", "preprocessCore", "minfi", "matrixStats" and "IlluminaHumanMethylation450k.db"
# - data format (1 raw data):
#	- raw idat files
# - data format (2 genomestudio):
#	- raw methylation data: methylation data have to be extracted with GenomeStudio in two text files, one corresponding to sample methylation informations and the second one to control probe informations.
#		- sample methylation informations: must contain the following columns in addition to the columns pre-selected by GenomeStudio(before exporting to '.txt' files the extracted informations).
#  		. Index
#			. TargetID
#			. INFINIUM_DESIGN_TYPE
#			. Color_Channel
#			. CHR
#			. Mapinfo (probe position for hg19
#			. COORDINATE_36 (probe position for hg18)
#			. STRAND
#			. Probe_SNPS
#			. Probe_SNPS_10
#			. UCSC_Refgene_Name
#			. UCSC_Refgene_Accession
#			. UCSC_Refgene_Group
#			. Relation_To_UCSC_CPG_Island
#			. DetectionPval
#			. Signal_A
#			. Signal_B
#			. Avg_NBEADS_A
#			. Avg_NBEADS_B
#		- control probes methylation informations: all columns
#		- additional data:
#			- sample IDs list in case of only a subset of the loaded samples have to be processed and normalized (to remove control samples for example): simple text file, with no header and with one sample ID per line.
#			- probe IDs list for probe filtering (probe associated to frequent SNP for example): simple text file with one probe ID per line.
#				We provide 36 lists of probes associated to frequent SNP obtained from the 1000 genome project (these 36 lists correspond to 18 different human populations. See ADDITIONAL_INFO folder) :
# 				- list of probes associated to SNP with alternative allele frequency >= 5% (the most stringent list)
# 				- list of probes associated to SNP with alternative allele frequency >= 10%
#			We consider that a probe is associated to a frequent SNP if a frequent SNP is located inside the probe sequence or if it is located in +1 (for Infinium I probes) or +2 (for Infinium II probes) position from probe's query site.
#
####################
# PIPELINE'S STEPS #
####################
#
# (optional) Extract methylation data with annotation informations with GenomeStudio software.
# 1. Check that methylation data files and additionnal information files have the required format.
# 2. Open R environment (R console).
# 3. Increase the memory that R can use. In Windows, use the command 'memory.limit(20000)' for example.
# 4. set all pathes and pipeline options.
# 5. Source this script, in R environment, by using the command 'source("pathToThisScript/pipelineIlluminaMethylation.R").
# 6. Results are automatically saved, in 4 files (beta values, detection p-values and the same informations for SNP probes ("rs" probes that are removed befor data normalization)), as matrices.
# 7. Start the "real" exciting work !
#
#
###########
# OUTPUTS #
###########
#
# In the folder defined by the PATH_RES variable (see below) you will find:
#	- xxxx_signifPvalStats_threshold0.01.txt file : for each plate, per sample QC results (# and % of probes associated to a detection value lower than 0.01 (by default)
#	- xxx_beta.txt : normalized beta values for all plates (an m x n matrix where m rows represent probes and n columns represent samples)
# - xxx__beta_intermediate.txt : non-normalized beta values for all plates, values are filtered and background & color corrected (an m x n matrix where m rows represent probes and n columns represent samples)
#	- xxxx_detectionPvalue.txtv : normalized detection p-values for all plates (an m x n matrix where m rows represent probes and n columns represent samples)
#	- xxx_beta.RData : R compressed archive representing normalized beta values for all plates (an m x n matrix where m rows represent probes and n columns represent samples)
#	- xxxx_detectionPvalue.RData : R compressed archive representing normalized detection p-values for all plates (an m x n matrix where m rows represent probes and n columns represent samples)
#	- xxxx_betaSNPprobes.csv : beta values (non normalized) for SNP related probes, for all plates (an m' x n' matrix where m' rows represent probes and n' columns represent samples)
#	- xxxx_detectionPvalueSNPprobes.csv : detection p-values (non normalized) for SNP related probes, for all plates (an m' x n' matrix where m' rows represent probes and n' columns represent samples)
#	- QC plots :
#		. Hierarchical clustering plots : euclidean distance with Ward agglomerative method. 4 plots.
#		. Methylation profile plots: 4 plots.
#			# xxx_beta.raw.jpeg: one plot per plate. Raw beta values.
#			# xxx_beta.filter.jpeg: one plot per plate. Raw beta values after sample and probe filtering.
#			# xxx_beta.preproc.jpeg: one plot per plate. Corrected beta values, after color bias correction and background subtraction.
#			# xxx_beta.preproc.norm.jpeg: one plot for all plates. Normalized beta values
#
##############################
###### VARIABLES TO SET ######
##############################
#
### PATHs to files and folders
#set working directory (If necessary)
setwd("")
#
# If working on Windows set this:
#memory.limit(20000)
#
# set PATH to R pipeline's scripts for script sourcing
PATH_SRC <- "./SRC/"
#
# set PATH to R pipeline's additional information for script sourcing
PATH_Annot <- "./ADDITIONAL_INFO/"
#
# set PATH to results folder
PATH_RES <- "./RES/"
#
# set PATH to a folder of "projects" where each project corresponds to a folder of 450K plate extracted data. Only subfolders for plates can exist, otherwise the program will try to open any existing file as folder and crash.
# For original Tost input these requrements for data extraction, inc naming necessary:
#	- control probes file: file name must starts with the pattern "TableControl"
#	- raw sample methylation file: file name must starts with the pattern "TableSample"
#	- sample IDs file for sample selection (not compulsory): file name must contain the pattern "sampleList" ** Also needed for idat filtering
PATH_PROJECT_DATA <- "./DATA/"
#
## set PATH to the file with frequent SNP informations, on which SNP filtering is based. If = NULL, no probe removed. Can handle arrays of filenames.
#PATH_ProbeSNP_LIST <- c(paste(PATH_Annot, "/ProbeFiltering/freq5percent/probeToFilter_450K_1000G_omni2.5.hg19.EUR_alleleFreq5percent_50bp_wInterroSite.txt", sep=""), paste(PATH_Annot, "/ProbeFiltering/ProbesBindingNonOptimal/Source&BSProbesMappingMultipleTimesOrNotBothToBSandNormalGenome.txt", sep=""))
PATH_ProbeSNP_LIST <- c(paste(PATH_Annot, "/ProbeFiltering/freq1percent/probeToFilter_450K_GoNL.hg19.ALL_alleleFreq1percent.txt", sep=""), paste(PATH_Annot, "/ProbeFiltering/ProbesBindingNonOptimal/Source&BSProbesMappingMultipleTimesOrNotBothToBSandNormalGenome.txt", sep=""))
#PATH_ProbeSNP_LIST <- NULL
#
#######################################
### set pipeline options and parameters
#
# The name that will be given to result files
projectName = "ILLUMINA450K"
#
####################
#Sample and probe QC
#
#Perform bead and P-value filtering after final merging.
qcAfterMerging = TRUE
# Minimal bead number for considering that a probe worked. If = NULL, does not perform bead nb. based filtering. Probes with less beads will get a P-value of 1.
nbBeads.threshold = 3
#
# Threshold for detection p-values significance. A signal is considered as significant if its associated detection p-values < this threshold (0.01 by default).
detectionPval.threshold = 0.01
#
# Percentage of significant probe methylation signals in a given sample (by default, >80% for "good quality" samples). This is used for samples QC and filtering. All samples that do not respect this condition will be removed from the analysis.
# If set to NULL this will not be performed
detectionPval.perc.threshold = NULL
#
# Percentage of significant sample methylation signals in a given probe (by default, >1% for "good quality" probes). This is used for probe QC and filtering. All probes that do not respect this condition will be removed from the analysis.
# If set to NULL this will not be performed
detectionPval.perc.threshold2 = NULL
#
# if 'TRUE' a additional sample filtering based on average M and U values is preformed. 
average.U.M.Check = FALSE
#
#Cut-offs are designed based on a set of >65000 450k samples. Minimum was set to 25% quantile - 1.5 * IQR, ratio was set to 75% quantile + 3* IQR. All ratios where transformed so they were higher than 1, the factor in the IQR was also chosen to be higher due to this.
minimalAverageChanelValue = 1966.538
maxratioDifference = 1.691505
#
# If sampleSelection= FALSE , all loaded samples will be processed and normalized, if sampleSelection = TRUE, a sample IDs text list, with no header and with the pattern "sampleList" in file name, will be loaded and used to select the samples to preprocess and normalize.
sampleSelection = F
#
# if "allosomal" only X and Y probes are returned, if "autosomal" only the non X and Y probes are returned. Any other value will return every thing.
XY.filtering = "autosomal"
#
###################
######Normalization
#
#Set alfa, used during transformation from U + M to Beta value
alfa = 100
#
# if 'TRUE' performs a color bias correction of methylated and unmethylated signals, per plate.
# Set to "no" for DASEN or NASEN. For other processes this is the only place where color bias correction is performed.
colorBias.corr = FALSE
#
#
# If "separatecolors", performs a separate color bg adjustement (recommended), if "unseparatecolors" performs a non separate color bg adjustement , if "no" don't perform any bg adjustement.
# Set to "no" for DASEN or NASEN. For other processes this is the only place where background correction is performed.
bg.adjust = "no"
#
# Do QN before normalization, on the individual chanels
# This is performed over each sub-project individualy.
includeQuantileNormOverChanel = FALSE
#
# If QCplot==TRUE, performs and plots hierarchical clustering and plots methylation density curves.
QCplot=FALSE
#
# Select the normalization procedure. Switch between SQN / SWAN / M-Value / M-value2 / DASEN correction and BMIQ. If not given this will default to SQN
#
#Normalization procedure by Touleimat & Tost.
#NormProcedure = "SQN"
  # Setting specific for SQN
  # Specifying which kind of probe annotation to use for probe categories construction, must be one of "relationToCpG" or "relationToSequence". We recommand the more robust option: probeAnnotationsCategory = "relationToCpG".
  probeAnnotationsCategory = "relationToCpG"
#
#Normalization procedure by Maksimovic et al.
#NormProcedure = "SWAN"
#
#Normalization procedure by Teschendorff et al.
#NormProcedure = "BMIQ"
#
#Normalization procedure by Dedeurwaerder et al. (Based on beta values)
#NormProcedure = "M-ValCor"
#
#Normalization procedure by Dedeurwaerder et al. (Based on M-values directly.)
#NormProcedure = "M-ValCor2"
#
#Normalization procedure by Pidsley et al.
NormProcedure = "DASEN"
#
#Normalization procedure by Pidsley et al.
#NormProcedure = "NASEN"
#
#No normalization
#NormProcedure = "None"
#
#No normalization
#NormProcedure = "None2"
#
#When using M-val do a Median replacement for missing values.
medianReplacement = FALSE;
#
# Include a QN after final normalization.
betweenSampleCorrection = FALSE
#
# Output M-Values.
MvalueConv = TRUE
#
# Write Rdata / txt / both
outputType = "both"
#
##############################################
#####  NOW YOU CAN SOURCE THIS SCRIPT !  #####
##############################################
#####
#####
##############################################
###### source scripts and load libraries #####
##############################################
require(lumi)
require(methylumi)
require(RPMM)
require(preprocessCore)
require(minfi)
require(matrixStats)
require(IlluminaHumanMethylation450k.db)

source(paste(PATH_SRC,"loadMethylumi2.R", sep=""))
source(paste(PATH_SRC,"lumiMethyR2.R", sep=""))
source(paste(PATH_SRC,"preprocessIlluminaMethylation.R", sep=""))
source(paste(PATH_SRC,"getMethylumiBeta.R", sep=""))
source(paste(PATH_SRC,"concatenateMatrices.R", sep=""))
source(paste(PATH_SRC,"normalizeIlluminaMethylation.R", sep=""))
source(paste(PATH_SRC,"nbBeadsFilter.R", sep=""))
source(paste(PATH_SRC,"detectionPval.filter.R", sep=""))
source(paste(PATH_SRC,"getSamples.R", sep=""))
source(paste(PATH_SRC,"filterXY.R", sep=""))
source(paste(PATH_SRC,"robustQuantileNorm_Illumina450K.R", sep=""))
source(paste(PATH_SRC,"coRankedMatrices.R", sep=""))
source(paste(PATH_SRC,"referenceQuantiles.R", sep=""))
source(paste(PATH_SRC,"adaptRefQuantiles.R", sep=""))
source(paste(PATH_SRC,"getQuantiles.R", sep=""))
source(paste(PATH_SRC,"normalize.quantiles2.R", sep=""))
source(paste(PATH_SRC,"robustQuantileNorm_Illumina450K.probeCategories.R", sep=""))
source(paste(PATH_SRC,"dataDetectPval2NA.R", sep=""))
source(paste(PATH_SRC,"uniqueAnnotationCategory.R", sep=""))
source(paste(PATH_SRC,"findAnnotationProbes.R", sep=""))
source(paste(PATH_SRC,"pipelineIlluminaMethylation.batch.R", sep=""))
source(paste(PATH_SRC,"pipelineIlluminaMethylation.batch2.R", sep=""))
source(paste(PATH_SRC,"plotQC.R", sep=""))
source(paste(PATH_SRC,"plotMethylationDensity.R", sep=""))
source(paste(PATH_SRC,"hclustPlot.R", sep=""))
source(paste(PATH_SRC,"Additions/BMIQ_1.3_Pipeline.R", sep=""))
source(paste(PATH_SRC,"Additions/swan2.R", sep=""))
source(paste(PATH_SRC,"Additions/Type2_M-value_Correction.R", sep=""))
source(paste(PATH_SRC,"Additions/dasen.R", sep=""))
source(paste(PATH_SRC,"Additions/nasen.R", sep=""))
source(paste(PATH_SRC,"Average_U+M.filter.R", sep=""))
#
#
#
{
  if(is.character(PATH_ProbeSNP_LIST)){
    if(length(PATH_ProbeSNP_LIST)==1){
      probeSNP_LIST <- unlist(read.table(file=PATH_ProbeSNP_LIST, quote="", sep="\t", header=TRUE))  
    } else {
      probeSNP_LIST <- NULL
      for(id in 1:length(PATH_ProbeSNP_LIST)){
        probeSNP_LIST <- union(probeSNP_LIST, unlist(read.table(file=PATH_ProbeSNP_LIST[id], quote="", sep="\t", header=TRUE)))
      }
    }
  } 
  else{
    probeSNP_LIST <- NULL
  }
}
#
data.preprocess.norm <- NULL
print(paste(NormProcedure ,"normalization procedure"))
if(NormProcedure != "SWAN" && NormProcedure != "DASEN" && NormProcedure != "M-ValCor2" && NormProcedure != "NASEN" && NormProcedure != "None2"){
  data.preprocess.norm <- pipelineIlluminaMethylation.batch(
    PATH_PROJECT_DATA,
    PATH_Annot = PATH_Annot,
    projectName = projectName,
    qcAfterMerging = qcAfterMerging,
    nbBeads.threshold = nbBeads.threshold,
    detectionPval.threshold = detectionPval.threshold,
    detectionPval.perc.threshold = detectionPval.perc.threshold,
    detectionPval.perc.threshold2 = detectionPval.perc.threshold2,
    sampleSelection = sampleSelection,
    probeSNP_LIST = probeSNP_LIST,
    XY.filtering = XY.filtering,
    colorBias.corr = colorBias.corr,
    average.U.M.Check = average.U.M.Check,
    minimalAverageChanelValue = minimalAverageChanelValue,
    maxratioDifference = maxratioDifference,
    bg.adjust = bg.adjust,
    PATH = PATH_RES,
    QCplot = QCplot,
    betweenSampleCorrection = betweenSampleCorrection,
    includeQuantileNormOverChanel = includeQuantileNormOverChanel,
    alfa,
    NormProcedure,
    medianReplacement
  )
} else {
  data.preprocess.norm <- pipelineIlluminaMethylation.batch2(
    PATH_PROJECT_DATA,
    PATH_Annot = PATH_Annot,
    projectName = projectName,
    qcAfterMerging = qcAfterMerging,
    nbBeads.threshold = nbBeads.threshold,
    detectionPval.threshold = detectionPval.threshold,
    detectionPval.perc.threshold = detectionPval.perc.threshold,
    detectionPval.perc.threshold2 = detectionPval.perc.threshold2,
    sampleSelection = sampleSelection,
    probeSNP_LIST = probeSNP_LIST,
    XY.filtering = XY.filtering,
    colorBias.corr = colorBias.corr,
    average.U.M.Check = average.U.M.Check,
    minimalAverageChanelValue = minimalAverageChanelValue,
    maxratioDifference = maxratioDifference,
    bg.adjust = bg.adjust,
    PATH = PATH_RES,
    QCplot = QCplot,
    betweenSampleCorrection = betweenSampleCorrection,
    includeQuantileNormOverChanel = includeQuantileNormOverChanel,
    alfa,
    NormProcedure,
    medianReplacement,
    MvalueConv
  )
}

if(is.null(data.preprocess.norm)){
  print("No samples selected")
  stop()
}

beta <- data.preprocess.norm$beta
detection.pvalue <- data.preprocess.norm$detection.pvalue

if(MvalueConv){
  if(NormProcedure != "M-ValCor2" && NormProcedure != "SWAN" && NormProcedure != "DASEN" && NormProcedure != "NASEN"){
    for(i in 1:ncol(beta)){
      beta1 <- beta[,i]
      m1 <- log2(beta1/(1 - beta1))  
      beta[,i] <- m1
    }
  }
  
  if(outputType=="txt" || outputType=="both"){
    write.table(beta, file=paste(PATH_RES, projectName, "_Mval.txt", sep=""), quote=FALSE, sep="\t", col.names = NA)
    write.table(detection.pvalue, file=paste(PATH_RES, projectName, "_detectionPvalue.txt", sep=""), sep="\t", col.names = NA)
  }
  if(outputType=="Rdata" || outputType=="both"){
    save(beta, file=paste(PATH_RES, projectName, "_Mval.RData", sep=""))
    save(detection.pvalue, file=paste(PATH_RES, projectName, "_detectionPvalue.RData", sep=""))
  }
} else {
  if(NormProcedure == "M-ValCor2"){
    for(i in 1:ncol(beta)){
      beta1 <- beta[,i]
      tmp1 <- 2^beta1/(2^beta1+1)
      beta[,i] <- tmp1
    }
  }
  
  if(outputType=="txt" || outputType=="both"){
    write.table(beta, file=paste(PATH_RES, projectName, "_beta.txt", sep=""), quote=FALSE, sep="\t", col.names = NA)
    write.table(detection.pvalue, file=paste(PATH_RES, projectName, "_detectionPvalue.txt", sep=""), sep="\t", col.names = NA)
  }
  if(outputType=="Rdata" || outputType=="both"){
    save(beta, file=paste(PATH_RES, projectName, "_beta.RData", sep=""))
    save(detection.pvalue, file=paste(PATH_RES, projectName, "_detectionPvalue.RData", sep=""))
  }
}

if(QCplot){
  plotQC(data.preprocess.norm$beta, figName=paste(projectName, "_beta.preproc.norm", sep=""), PATH = PATH_RES)
}
