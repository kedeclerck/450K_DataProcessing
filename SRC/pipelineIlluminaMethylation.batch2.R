# 2011-2012-2013
# Bonder
# bonder.m.j @ gmail.com
#
# This function performs a complete Illumina 450K array data preprocessing other normalization methods, for a data batch (set of 450K "plates").
#
pipelineIlluminaMethylation.batch2 <- function(
	PATH_PROJECT_DATA,
	PATH_Annot,
	projectName,
	qcAfterMerging = FALSE,
	nbBeads.threshold,
	detectionPval.threshold,
	detectionPval.perc.threshold,
	detectionPval.perc.threshold2,
	sampleSelection,
	probeSNP_LIST,
	XY.filtering,
	colorBias.corr,
	average.U.M.Check,
	minimalAverageChanelValue = minimalAverageChanelValue,
	maxratioDifference = maxratioDifference,
	bg.adjust,
	PATH,
	QCplot=TRUE,
	betweenSampleCorrection = TRUE,
	includeQuantileNormOverChanel = includeQuantileNormOverChanel,
	alfa=100,
	NormProcedure,
	medianReplacement = TRUE,
	MvalueConv
 ){

	####################################
	# Get project pathes and load data #
	####################################
	subProjects <- dir(PATH_PROJECT_DATA)
	
	unMeth <- NULL
	meth <- NULL
	detectionPval <- NULL
	annotation <- NULL
	sampleAnnotationInfomation <- NULL
	path2sampleList <- NULL
  
	readFromIdat <- FALSE
	readFromOriginalInput <- FALSE
	
	#for all subprojects
	for(i in 1:length(subProjects)){
	  
    methLumi_data <- NULL
		projectName_batch <- subProjects[i]
		sampleTable <- dir(paste(PATH_PROJECT_DATA, projectName_batch, "/", sep=""), pattern="TableSample")
		controlTable <- dir(paste(PATH_PROJECT_DATA, projectName_batch, "/", sep=""), pattern="TableControl")
		cat("\n# ")
		cat("Processing sub-project: ", projectName_batch, "\n")

    #####
    if(length(sampleTable) < 1 && length(controlTable) < 1 && length(list.files(paste(PATH_PROJECT_DATA, projectName_batch, "/", sep=""), pattern=".idat"))>0){
      
      barcode<- list.files(paste(PATH_PROJECT_DATA, projectName_batch, "/", sep=""), pattern=".idat")
      
      barcode <- gsub("_Grn.idat","",x=barcode)
      barcode <- gsub("_Red.idat","",x=barcode)
      barcodes <- unique(barcode)
      sample2keep <- NULL
      
      if(sampleSelection){
        sampleList <- dir(paste(PATH_PROJECT_DATA, projectName_batch, "/", sep=""), pattern = "sampleList")
        path2sampleList <- paste(PATH_PROJECT_DATA, projectName_batch, "/", sampleList, sep="")
        
        if(length(sampleList) == 1){
          sample2keep <- read.table(file=path2sampleList, sep="\t", header=FALSE, quote="")[[1]]
          
        } else {
          warning <- "\tWARNING ! List for sample selection: too many / less files matching with pattern 'SampleList' ! \n"
          #print(sampleList)
          cat(warning)
          return(warning)
        }
      }
      if(!(is.null(sample2keep))){
        barcodes <- intersect(barcodes,sample2keep);
      }
      
      if(length(barcodes)<2){
        cat("\n\tSkipped folder: ",projectName_batch,"\n")
        cat("\t to little samples")
        next;
      }
      
      cat("\n\tStart data loading...\n")      
      methLumi_dataTmpData <- methylumIDAT(barcodes, idatPath=paste(PATH_PROJECT_DATA, projectName_batch, "/", sep=""), n=T)
      methLumi_dataTmpData <- as(methLumi_dataTmpData, 'MethyLumiM')
      
      cat("\tProject sample nb: ", length(barcodes), ".\n")
      cat("\tData dimensions: ", dim(methLumi_dataTmpData)[1],"x", dim(methLumi_dataTmpData)[2], ".\n")
      cat("\t...data loaded..\n\n")
      
      if(is.null(sampleAnnotationInfomation)){
        annotationFile <- paste(PATH_Annot,"/ProbeAnnotation/ProbeInformationSample.txt", sep="")
        if(file.exists(annotationFile)){
          sampleAnnotationInfomation <- read.AnnotatedDataFrame(file=annotationFile,header=T, sep="\t", quote = "")
		  sampleAnnotationInfomation<- sampleAnnotationInfomation[order(sampleAnnotationInfomation$TargetID),]
        } else {
          cat("No annotation file present can not read .idat files.\nSkipping directory.\n")
          next;
        }
      }
      
      #############################
      # starts data preprocessing #
      #############################
      
      methLumi_data <- preprocessIlluminaMethylationIdat(
        qcAfterMerging = qcAfterMerging,
        methLumi_dataTmpData,
        sampleAnnotationInfomation,
        projectName = projectName_batch,
        nbBeads.threshold = nbBeads.threshold,
        detectionPval.threshold = detectionPval.threshold,
        detectionPval.perc.threshold = detectionPval.perc.threshold,
        detectionPval.perc.threshold2 = detectionPval.perc.threshold2,
        probeSNP_LIST,
        XY.filtering = XY.filtering,
        colorBias.corr = colorBias.corr,
        average.U.M.Check = average.U.M.Check,
        minimalAverageChanelValue = minimalAverageChanelValue,
        maxratioDifference = maxratioDifference,
        bg.adjust = bg.adjust,
        PATH = PATH_RES,
        QCplot = QCplot
      )
      rm(methLumi_dataTmpData)
      
      if(is.null(methLumi_data)){
        next;
      }
      
      readFromIdat=TRUE
      
    } else {
  		if(length(sampleTable) > 1){
  			warning <- "\tWARNING ! Sample table: too many files matching with pattern 'TableSample' ! \n"
  			cat(warning)
  			return(warning)
  		}
  		if(length(sampleTable) < 1){
  			warning <- "\tWARNING ! Sample table: no file matching with pattern 'TableSample' ! \n"
  			cat(warning)
  			return(NULL)
  		}
  		if(length(controlTable) > 1){
  			warning <- "\tWARNING ! Control table: too many files matching with pattern 'TableControl' ! \n"
  			cat(warning)
  			return(warning)
  		}
  		if(length(controlTable) < 1){
  			warning <- "\tWARNING ! Control table: no file matching with pattern 'TableControl' ! \n"
  			cat(warning)
  			return(warning)	
  		}
      
  		
  		if(sampleSelection){
  			sampleList <- dir(paste(PATH_PROJECT_DATA, projectName_batch, "/", sep=""), pattern = "sampleList")
  			path2sampleList <- paste(PATH_PROJECT_DATA, projectName_batch, "/", sampleList, sep="")
  
  			if(length(sampleList) > 1){
  				warning <- "\tWARNING ! List for sample selection: too many files matching with pattern 'SampleList' ! \n"
  				cat(warning)
  				return(warning)
  			}
  			if(length(sampleList) < 1){
  				warning <- "\tWARNING ! List for sample selection: no file matching with pattern 'SampleList' ! \n"
  				path2sampleList <- NULL
  				cat(warning)
  			}
  		}
  		else{path2sampleList <- NULL}
  
  		path2data <- paste(PATH_PROJECT_DATA, projectName_batch, "/", sampleTable, sep="")
  		path2controlData <- paste(PATH_PROJECT_DATA, projectName_batch, "/", controlTable, sep="")
  		
  		cat("\tSample table: ", path2data, "\n")
  		cat("\tControl table: ", path2controlData, "\n")
      if(!is.null(path2sampleList)){
  		  cat("\tSample list (for sample selection): ", path2sampleList, "\n")
  	  }
  		#############################
  		# starts data preprocessing #
  		#############################
  
  		methLumi_data <- preprocessIlluminaMethylation(
  		  qcAfterMerging = qcAfterMerging,
  			path2data = path2data,
  			path2controlData = path2controlData,
  			projectName = projectName_batch,
  			nbBeads.threshold = nbBeads.threshold,
  			detectionPval.threshold = detectionPval.threshold,
  			detectionPval.perc.threshold = detectionPval.perc.threshold,
  			detectionPval.perc.threshold2 = detectionPval.perc.threshold2,
  			sample2keep = path2sampleList,
  			probeSNP_LIST,
  			XY.filtering = XY.filtering,
  			colorBias.corr = colorBias.corr,
  			average.U.M.Check = average.U.M.Check,
  			minimalAverageChanelValue = minimalAverageChanelValue,
  			maxratioDifference = maxratioDifference,
  			bg.adjust = bg.adjust,
  			PATH = PATH_RES,
  			QCplot = QCplot
  		)
      
  		if(is.null(methLumi_data)){
  		  next;
  		}
  		readFromOriginalInput=TRUE
    }
		
		
    
		################################################
		# Sub-project data & information concatenation #
		################################################

    if(readFromOriginalInput==TRUE && readFromIdat==TRUE){
      cat("Warning: In SWAN & NASEN & DASEN & M-ValCor2 preprocessing no mixing of input types is allowed.\n")
      return(NULL)
    }
    
    if(includeQuantileNormOverChanel){
      methLumi_data_un <-normalize.quantiles(as.matrix(unmethylated(methLumi_data)))
      colnames(methLumi_data_un) <- colnames(unmethylated(methLumi_data))
      rownames(methLumi_data_un) <- rownames(unmethylated(methLumi_data))
      unmethylated(methLumi_data) <- methLumi_data_un
      
      methLumi_data_me <- normalize.quantiles(as.matrix(methylated(methLumi_data)))
      colnames(methLumi_data_me) <- colnames(unmethylated(methLumi_data))
      rownames(methLumi_data_me) <- rownames(unmethylated(methLumi_data))
      methylated(methLumi_data) <- methLumi_data_me
      rm(methLumi_data_un, methLumi_data_me)
    }
    
		if(is.null(unMeth) && length(sampleNames(methLumi_data))>0){			
			unMeth <- unmethylated(methLumi_data)
			meth <- methylated(methLumi_data)
      qc <- intensitiesByChannel(QCdata(methLumi_data)) 
			rownames(qc[[1]]) <- toupper(rownames(qc[[1]]))
			rownames(qc[[2]]) <- toupper(rownames(qc[[2]]))
			
			cat("\t Chanels plate", i, " ok (", dim(unMeth)[1], "x", dim(unMeth)[2], ").\n")
			detectionPval <- assayDataElement(methLumi_data, "detection")
			cat("\t detection p-values plate", i, " ok (", dim(detectionPval)[1], "x", dim(detectionPval)[2], ").\n")
			#select "useful" probe annotations
			annotation <- fData(methLumi_data) ; rm(methLumi_data)
			index <- which(is.element(colnames(annotation), c("TargetID", "INFINIUM_DESIGN_TYPE", "RELATION_TO_UCSC_CPG_ISLAND", "UCSC_REFGENE_GROUP")))
      
			annotation <- annotation[,index]
		} else if(length(sampleNames(methLumi_data))>0){
      print(dim(methLumi_data))
			#concatenate 'chanels'
      
			cat("\t Chanel_", i, " ok (", dim(unmethylated(methLumi_data))[1], "x", dim(unmethylated(methLumi_data))[2], ").\n")
			detectionPval_i <- assayDataElement(methLumi_data, "detection")
			cat("\t For all sub-projects: chanel matrices concatenation & detection p-value matrices concatenation.\n")
			qc_i <- intensitiesByChannel(QCdata(methLumi_data))
			rownames(qc_i[[1]]) <- toupper(rownames(qc_i[[1]]))
			rownames(qc_i[[2]]) <- toupper(rownames(qc_i[[2]]))
      
			rownames(qc_i[[2]]) <- gsub(pattern="NORM_A", replacement="NORM_A.", rownames(qc_i[[1]]))
			rownames(qc_i[[2]]) <- gsub(pattern="NORM_A", replacement="NORM_A.", rownames(qc_i[[2]]))
			
      if(length(which(colnames(unmethylated(methLumi_data))%in%colnames(unMeth)))!=0){
        cat("Warning: duplicate samples are inputed. Please check input again an retry.\n")
        return(NULL)
      }

      id1 <- which(tolower(rownames(qc[[1]])) %in% tolower(rownames(qc_i[[1]])))
			id2 <- which(rownames(qc_i[[1]]) %in% rownames(qc[[1]]))
      
			which(rownames(qc[[1]]) %in% toupper(rownames(qc_i[[1]])))
      
			qc[[1]] <- cbind(qc[[1]], qc_i[[1]])
			qc[[2]] <- cbind(qc[[2]], qc_i[[2]])
			
			if(length(rownames(meth)) == length(rownames(methylated(methLumi_data)))){
				if(all(rownames(meth) == rownames(methylated(methLumi_data)))){
					meth <- cbind(meth, methylated(methLumi_data))
					unMeth <- cbind(unMeth, unmethylated(methLumi_data))
				} else {
					unMeth_i <- unmethylated(methLumi_data)
					meth_i <- methylated(methLumi_data)
					
					unMeth_i<- as.matrix(unMeth_i[which(rownames(unMeth_i) %in% rownames(unMeth)),])
					meth_i<- as.matrix(meth_i[which(rownames(meth_i) %in% rownames(meth)),])
					
					unMeth<- as.matrix(unMeth[which(rownames(unMeth) %in% rownames(unMeth_i)),])
					meth<- as.matrix(meth[which(rownames(meth) %in% rownames(meth_i)),])
					
					meth <- cbind(meth[order(rownames(meth)),], meth_i[order(rownames(meth_i)),])
					unMeth <- cbind(unMeth[order(rownames(unMeth)),], unMeth_i[order(rownames(unMeth_i)),])
          
					rm(unMeth_i)
					rm(meth_i)
				}
			} else {
				unMeth_i <- unmethylated(methLumi_data)
				meth_i <- methylated(methLumi_data)
				
				unMeth_i<- as.matrix(unMeth_i[which(rownames(unMeth_i) %in% rownames(unMeth)),])
				meth_i<- as.matrix(meth_i[which(rownames(meth_i) %in% rownames(meth)),])
				
				unMeth<- as.matrix(unMeth[which(rownames(unMeth) %in% rownames(unMeth_i)),])
				meth<- as.matrix(meth[which(rownames(meth) %in% rownames(meth_i)),])
				
				meth <- cbind(meth[order(rownames(meth)),], meth_i[order(rownames(meth_i)),])
				unMeth <- cbind(unMeth[order(rownames(unMeth)),], unMeth_i[order(rownames(unMeth_i)),])
				
        rm(unMeth_i)
				rm(meth_i)
			}
      
      detectionPval <- concatenateMatrices(detectionPval, detectionPval_i) ; rm(detectionPval_i)
      annotation <- annotation[ which(is.element(annotation$TargetID, rownames(unMeth))),]
      
			rm(qc_i)
			
			cat("\t Chanels ok (", dim(unMeth)[1], "x", dim(unMeth)[2], ").\n")
			cat("\t detection p-values ok (", dim(detectionPval)[1], "x", dim(detectionPval)[2], ").\n")
		}
	}
	
	if(is.null(unMeth) || is.null(meth)){
		return(NULL)
	}
  
	if(qcAfterMerging){
	  t <- qcAfterMerg(
	    unMeth, 
	    detectionPval, 
	    detectionPval.threshold = detectionPval.threshold,
	    detectionPval.perc.threshold = detectionPval.perc.threshold,
	    detectionPval.perc.threshold2 = detectionPval.perc.threshold2,
	    PATH = PATH
	  )
	  unMeth <- t[[1]]
	  detectionPval <- t[[2]]

	  meth <- meth[which(rownames(meth)%in%rownames(unMeth)),which(colnames(meth)%in%colnames(unMeth))]
	}
  

	############################################################################################
	# Extraction of SNP probes ("rs" probes)
	############################################################################################
	
	indexSNP <- grep(pattern="rs*", x=rownames(unMeth))
	if(length(indexSNP)>0){
		mSNP <- log2((meth[indexSNP,]+alfa)/(unMeth[indexSNP,]+alfa))
		
    detectionPvalSNP <- detectionPval[indexSNP,]
		detectionPval <- detectionPval[-indexSNP,]
		
		write.table(mSNP, file=paste(PATH_RES, projectName, "_betaSNPprobes.txt", sep=""), quote=FALSE, sep="\t", col.names = NA)
		write.table(detectionPvalSNP, file=paste(PATH_RES, projectName, "_detectionPvalueSNPprobes.txt", sep=""), quote=FALSE, sep="\t", col.names = NA)
	}
	
	indexSNP <- grep(pattern="rs*", x=rownames(unMeth))
	if(length(indexSNP)>0){
		unMeth <- unMeth[-indexSNP,]
		meth <- meth[-indexSNP,]
	}	
	
	
	############################################################################################								
	# start data normalization (subset quantile normalization per probe annotation categories) #
	############################################################################################
	
	if(NormProcedure=="None2"){
    
	  write.table(unMeth, file=paste(PATH_RES, projectName, "_U_Signal.txt", sep=""), quote=FALSE, sep="\t", col.names = NA)
	  write.table(meth, file=paste(PATH_RES, projectName, "_M_Signal.txt", sep=""), quote=FALSE, sep="\t", col.names = NA)
    
	  beta <- getBetaMj(u=unMeth, m=meth, alfa=alfa)
    head(beta)
    
    rm(unMeth, meth)
    
	  if(betweenSampleCorrection){
	    beta2 <- normalize.quantiles(as.matrix(beta))
	    rownames(beta2) <- rownames(beta)
	    colnames(beta2) <- colnames(beta)
	    beta <- beta2
	    rm(beta2)
	  }
	  data.preprocess.norm <- list(beta, detectionPval)
	  names(data.preprocess.norm) <- c("beta", "detection.pvalue")
    
	} else if(NormProcedure=="SWAN" && MvalueConv){
		data.preprocess.norm <- normalizeIlluminaMethylationSWAN2(
			detect.pval = detectionPval,
			unMeth,
			meth,
			qc,
      alfa,
			betweenSampleCorrection = betweenSampleCorrection
		)
	} else if(NormProcedure=="SWAN"){
	  data.preprocess.norm <- normalizeIlluminaMethylationSWAN(
	    detect.pval = detectionPval,
	    unMeth,
	    meth,
	    qc,
	    alfa,
	    betweenSampleCorrection = betweenSampleCorrection
	  )
	} else if(NormProcedure=="M-ValCor2"){
	  data.preprocess.norm <- normalizeIlluminaMethylationMValCor2(
	    unMeth,
	    meth,
      detect.pval = detectionPval,
	    annotation,
	    QCplot,
	    PATH_RES,
	    alfa,
	    betweenSampleCorrection = betweenSampleCorrection,
	    medianReplacement
	  )
	} else if (NormProcedure=="NASEN"){
	  data.preprocess.norm <- normalizeIlluminaMethylationNASEN(
	    detect.pval = detectionPval,
	    unMeth,
	    meth,
	    qc,
	    annotation,
	    alfa,
	    MvalueConv,
	    betweenSampleCorrection = betweenSampleCorrection
	  )
	} else {
		data.preprocess.norm <- normalizeIlluminaMethylationDASEN(
			detect.pval = detectionPval,
			unMeth,
			meth,
			qc,
			annotation,
			alfa,
			MvalueConv,
			betweenSampleCorrection = betweenSampleCorrection
		)
	}

	return(data.preprocess.norm)
}
