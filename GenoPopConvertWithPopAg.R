subset.GenePop2 <- function(GenePop,subs=NULL,keep=TRUE,dir,sPop=NULL, agPop=FALSE, agPopFrame=NULL){
  
## GenePop = the genepop file with all loci 
## subs = the loci names of interest or a vector which corresponds the the order of which
  ## they appear in the genepop file. (i.e. subs <- c(1,2,3,4)) would return the first 4 loci
## keep = logical vector which defines whether you want to remove the loci or keep them. 
  ## the default is to keep them (keep=TRUE) assuming you are removing neutral markers and only keeping the subs ("Outliers")
## sPops is the populations of interest. Note these are specified in the order which they appear in the
  ##    original Genepop file. i.e. first pop = 1 second pop = 2  or the text based origin 
  ##    Examples Numeric: sPop=c(1,3,4,7) text: sPop=c("BMR", "GRR","GHR","TRS")

## Function for inserting rows
  insert.vals <- function(Vec,breaks,newVal){
    break.space <- 1:(length(breaks))
    breaks <- breaks+break.space-1 #To space out the insertion points.
    newvec <- rep(NA,length(Vec)+length(breaks)) #Preallocate memory by creating final dataframe.
    for(i in 1:length(breaks)){newvec[breaks[i]]=newVal} #Insert added rows into new dataframe>
    x <- 1:length(newvec)
    x <- x[-(breaks)] #Finding the rows of the new dataframe that will receive old rows
    for(i in 1:length(Vec)){newvec[x[i]]=Vec[i]} 
    return(newvec)}
 
  #Libraries
  
  #Check to make sure the packages required are there
  packages <- c("dplyr", "tidyr", "stringr") ## which packages do we need?
  if (length(setdiff(packages, rownames(installed.packages()))) > 0) { ### checks that the required packages are among those 
    ## installed by comparing the differences in the length of a vector of items included in list (i.e. is package among all installed)
    install.packages(setdiff(packages, rownames(installed.packages())))  ## if a package is not installed, insall it
  } ### this will only work if someone has the CRAN mirror set (I would assume everyone would?)

  #load each library
    require(dplyr)
    require(tidyr)
    require(stringr)
  
## Stacks version information
    stacks.version <- GenePop[1,] # this could be blank or any other source. First row is ignored by GenePop

#Remove first label of the stacks version
    GenePop <- as.vector(GenePop)
    GenePop <- GenePop[-1,]

#Add an index column to Genepop and format as a dataframe
    GenePop <- data.frame(data=GenePop,ind=1:length(GenePop))
    GenePop$data <- as.character(GenePop$data)

#ID the rows which flag the Populations
    Pops  <-  which(GenePop$data == "Pop" | GenePop$data =="pop" | GenePop$data == "POP")
    npops  <-  1:length(Pops)

## Seperate the data into the column headers and the rest
    ColumnData <- GenePop[1:(Pops[1]-1),"data"]
    snpData <- GenePop[Pops[1]:NROW(GenePop),]

#Get a datafile with just the snp data no pops
    tempPops <- which(snpData$data=="Pop"| snpData$data =="pop" | snpData$data == "POP") ## Changed because we allowed
## alternate spelling on line 48, so had to change this so it would identify properly and not make an empty DF
    snpData <- snpData[-tempPops,]

#Seperate the snpdata
#First we pull out the population data which follows
#"TEXT ,  "
    temp <- separate(snpData,data,into=c("Pops","snps"),sep=",")
    temp$snps <- substring(temp$snps,3) # delete the extra spaces at the beginning
    temp2 <- as.data.frame(do.call(rbind, strsplit(temp$snps," "))) #split characters by spaces
  
    #Contingency to see if R read in the top line as the "stacks version"
    #if (length(temp2)!=length(ColumnData)){colnames(temp2) <- c(stacks.version,ColumnData)}
    #if (length(temp2)==length(ColumnData)){colnames(temp2) <- ColumnData}
    #if (length(temp2)!=length(ColumnData)){stacks.version="No stacks version specified"}
    colnames(temp2) <- ColumnData
## Get the Alpha names from the 
    NamePops=temp[,1] # Names of each
    NameExtract=str_extract(NamePops, "[A-Z]+" ) # extract the text from the individuals names to denote population

## Now add the population tags using npops (number of populations and Pops for the inter differences)
     tPops <- c(Pops,NROW(GenePop))
      PopIDs <- NULL
          for (i in 2:length(tPops)){
            hold <- tPops[i]-tPops[i-1]-1
            if(i==length(tPops)){hold=hold+1}
            pophold <- rep(npops[i-1],hold)
            PopIDs <- c(PopIDs,pophold)
          }
    
    temp2$Pop <- PopIDs;rm(hold,pophold,tPops,PopIDs)

## Now subset out the the data according to the specified loci and whether or not you want to keep them. 
    
    if(is.numeric(subs))
      { #column number instead of name depending on the output from Outlier detection
          
          if(!keep) # neutral
          {
            if(length(subs)>0){reqCols <- temp2[,-subs]}
            if(length(subs)==0){reqCols <- temp2}
          }
          
          
          if(keep) # outliers or loci under divergent selection
          {
            PopInd=which(names(temp2)=="Pop")
            if(length(subs)>0){reqCols <- temp2[,c(subs,PopInd)]}
            if(length(subs)==0){reqCols <- temp2}
          }
      
    }
    
    if(!is.numeric(subs))
      { #column name
        
      if(!keep)# neutral
          {
            if(length(subs)>0){reqCols <- temp2[,-which(names(temp2)%in%subs)]}
            if(length(subs)==0){reqCols <- temp2}
          }
        
        if(keep)# outliers or loci under divergent selection
            {
            if(length(subs)>0){reqCols <- temp2[,c(subs,"Pop")]}
            if(length(subs)==0){reqCols <- temp2}
            }
      }
        
## Now subset the rows 
    # is a population subset required
    if(length(sPop)>0){
      
      if(sum(is.numeric(sPop))>0){ # if the subsetted populations are numeric
      ind <- which(reqCols$Pop %in% sPop) # index where the populations are
      reqCols <- reqCols[ind,]
      temp <- temp[ind,]
      temp2 <- temp2[ind,]
      }
      
      if(sum(is.numeric(sPop))==0){ # if the subsetted populations are character indexes
        reqCols <- reqCols[which(NameExtract %in% sPop),]
        temp <- temp[which(NameExtract %in% sPop),]
        temp2 <- temp2[which(NameExtract %in% sPop),]
      }
      
      
    } # end of subset population if statement
    
    
    if(agPop==FALSE){
    reqCols <- reqCols[,-length(reqCols)] # delete the "Pop" data * last column

#Now recompile the GenePop format
    
    #the number of individuals for all popualtions but the last (Pop tagged to the end)
    PopLengths <- table(temp2$Pop)[-length(table(temp2$Pop))]
    
    
    #Get the row numbers where population "Pop" tag will be inserted
    #if(length(table(temp2$Pop))==1){return(print("Need more than one populations for subsetting"))}
    
    if(length(table(temp2$Pop))==2){PopPosition = PopLengths+1}
    
    if(length(table(temp2$Pop))>2){ 
          PopPosition <- c(PopLengths[1]+1,rep(NA,(length(PopLengths)-1)))
          for (i in 2:length(PopLengths)){
            PopPosition[i] <- PopLengths[i]+PopPosition[i-1]
          }
    }
    
    
    # paste together the Loci as one long integer seperated for each loci by a space
    Loci <- do.call(paste,c(reqCols[,], sep=" "))
    
    #Grab the Population tags that each invididual had following the format ID_,__
    PopVec <- paste(gsub(pattern = " ",replacement = "",temp$Pop)," ,  ",sep="")
    
    #Paste these to the Loci
    Loci <- paste(PopVec,Loci,sep="")
    
    #Insert the value of "Pop" which partitions the data among populations #only if more than one population
    if(length(table(temp2$Pop))!=1){Loci <- insert.vals(Vec=Loci,breaks=PopPosition,newVal="Pop")}
    
    #Add the first "Pop" label
    Loci <- c("Pop",Loci) 
    
    ## Add the column labels and the stacks version
    
    if(is.numeric(subs))
      { #Column numbers
        if(!keep)
        {
          PopInd=which(names(temp2)=="Pop")
          if(length(subs)==0){Output <- c(stacks.version,names(temp2)[-PopInd],Loci)}
          if(length(subs)>0){Output <- c(stacks.version,names(temp2)[-c(subs,PopInd)],Loci)}
        }
        
        if(keep)
        {
          PopInd=which(names(temp2)=="Pop")
          if(length(subs)==0){Output <- c(stacks.version,names(temp2)[-PopInd],Loci)}
          if(length(subs)>0){Output <- c(stacks.version,names(reqCols),Loci)}
        }
    }
    
    if(!is.numeric(subs))
    { # column names
      if(!keep)
      {
        if(length(subs)==0){Output <- c(stacks.version,names(temp2)[-length(names(temp2))],Loci)}
        if(length(subs)>0){Output <- c(stacks.version,names(temp2)[-which(names(temp2)%in%c(subs,"Pop"))],Loci)}
      }
      
      if(keep)
      {
        if(length(subs)==0){Output <- c(stacks.version,names(temp2)[-length(names(temp2))],Loci)}
        if(length(subs)>0){Output <- c(stacks.version,subs,Loci)}
      }
    }
    
    
    
    }### END OF IF agpop = FALSE
    
     if(agPop==TRUE){
      
        which(names(temp2) == "Pop")
        which(NameExtract %in% agPopFrame$Opop)
        temp3 <- temp2[,-which(names(temp2) == "Pop")]
        temp3$agPop = NameExtract
        tempAgPop <- temp3[which(NameExtract %in% agPopFrame$Opop),]
        tempAgPop <- merge(x = tempAgPop, y = agPopFrame, by.y = "Opop", by.x = "agPop")
        
        tempAgPop <- tempAgPop[order(tempAgPop$AgPop), ]
        
        PopLengths <- table(tempAgPop$AgPop)[-length(tempAgPop$AgPop)]
        
       if(length(table(tempAgPop$AgPop))==2){PopPosition = PopLengths[1]+1}
    
    if(length(table(tempAgPop$AgPop))>2){ 
          PopPosition <- c(PopLengths[1]+1,rep(NA,(length(PopLengths)-1)))
          for (i in 2:length(PopLengths)){
            PopPosition[i] <- PopLengths[i]+PopPosition[i-1]
          }
    }
    
        tempAgPop <- tempAgPop[-which(colnames(tempAgPop)=="AgPop")]
        tempAgPop$agPop <- paste0(tempAgPop$agPop, " ,  ")
    #tempAgPop <- tempAgPop[,-which(names(tempAgPop)=="AgPop")]
    #AddPop <- tempAgPop$agPop
    #tempAgPop$agPop <- paste0(tempAgPop$agPop, " ,  ")
    #AddPop <- paste0(AddPop, " ,  ")
    # paste together the Loci as one long integer seperated for each loci by a space
    #tempAgPop <- tempAgPop[,-which(names(tempAgPop)== "agPop")]
    #Loci <- paste0(AddPop, tempAgPop)
    Loci <- do.call(paste,c(tempAgPop[,], sep=" "))
    
   
    #Insert the value of "Pop" which partitions the data among populations #only if more than one population
    Loci <- insert.vals(Vec=Loci,breaks=PopPosition,newVal="Pop")
    
    #Add the first "Pop" label
    Loci <- c("Pop",Loci) 
    
    insNames <- names(tempAgPop)
    
    insNames <- insNames[-which(insNames == "agPop")]
    #insNames <- insNames[-which(insNames == "AgPop")]
    
    Output <- c(stacks.version, insNames, Loci)
        
      
    } ### END of if agPop = TRUE statement
    
    
    
    # Save the file
    write.table(Output,dir,col.names=FALSE,row.names=FALSE,quote=FALSE)

#} #End function