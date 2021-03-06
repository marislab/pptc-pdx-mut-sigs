### new signature tool - can handle samples separately
# install.packages("devtools")
# devtools::install_github(repo = "raerose01/deconstructSigs")
# source("https://bioconductor.org/biocLite.R")
# biocLite("BSgenome.Hsapiens.UCSC.hg19")
library(deconstructSigs)
library(readxl)

#### run mutsigs analysis - cosmic ######################################################################
setwd("~")
# set directories for saving files, specify histology of interest
home <- "~/Desktop/mutsig-demo/"
hist <- "all"
# create new directories in home
dir.create(file.path(home,"signatures"))
dir.create(file.path(home,"signatures/bysample"))
dir.create(file.path(home,"figures"))
dir.create(file.path(home,"figures/signatures"))

# load pptc.merge file; 240 PDXs
load(paste0(home,"2019-02-14-allpdx-clean-maf-240.rda"), verbose = T)
sig.df <- pptc.merge[,c("Tumor_Sample_Barcode","Chromosome","Start_position","Reference_Allele","Tumor_Seq_Allele2")]

# require Sample, chr, pos, ref, alt
names(sig.df) <- c("Sample", "chr", "pos", "ref", "alt")
unique(sig.df$Sample)

# list of samples
samplelist <- as.list(unique(sig.df$Sample))

# convert to deconstructSigs input - warning message for samples with <50 mutations
sigs.input <- mut.to.sigs.input(mut.ref = sig.df,
                                sample.id = "Sample", 
                                chr = "chr", 
                                pos = "pos", 
                                ref = "ref", 
                                alt = "alt",
                                bsg = BSgenome.Hsapiens.UCSC.hg19)

# remove samples with less than 50 muts (24 PDXs)
remove <- c("ALL-58", "OS-36-SJ", "OS-32", "Rh-30R", "COG-N-453x", 
            "COG-N-452x", "Rh-30", "COG-N-623x", "ALL-80", "NCH-CA-1", 
            "ALL-105", "ICB-1744MB", "ALL-82", "IC-22909PNET-rIII", "ALL-102", 
            "COG-N-618x", "ALL-46", "NCH-WT-7", "NCH-WT-4","IC-6634GBM", 
            "COG-N-603x", "ICb-9850PNET", "MLL-5", "COG-N-619x")
new.df <- subset(sig.df, !(sig.df$Sample %in% remove))
unique(new.df$Sample)
samplelist <- as.list(unique(new.df$Sample)) # write over sold samplelist

# convert to deconstructSigs input without samples <50 muts, no warning
sigs.input <- mut.to.sigs.input(mut.ref = new.df, 
                                sample.id = "Sample", 
                                chr = "chr", 
                                pos = "pos", 
                                ref = "ref", 
                                alt = "alt",
                                bsg = BSgenome.Hsapiens.UCSC.hg19)
head(sigs.input)

# determine the signatures contributing to each samples
for (each in samplelist) {
  
  test = whichSignatures(tumor.ref = sigs.input, 
                         signatures.ref = signatures.cosmic,
                         sample.id = each, 
                         contexts.needed = TRUE,
                         tri.counts.method = 'exome')
  names(test)
  
  weights <- as.data.frame(test$weights)
  weights$Model <- rownames(weights)
  weights <- weights[,c(28,1:27)]
  names(weights)
  weights$Unknown <- test$unknown
  write.table(weights, paste(home, "signatures/bysample/", Sys.Date(), "-", each, "-signature-weights.txt",
                             sep = ""), sep = "\t", col.names = T, row.names = T, quote = F)
  
  write.table(test$tumor, paste(home,  "signatures/bysample/", Sys.Date(), "-", each, "-tumor-trinucleotide-context.txt",
                                sep = ""), sep = "\t", col.names = T, row.names = T, quote = F)
  write.table(test$product, paste(home,  "signatures/bysample/", Sys.Date(), "-", each, "-product-trinucleotide-context.txt",
                                  sep = ""), sep = "\t", col.names = T, row.names = T, quote = F)
  
  pdf(paste(home,"figures/signatures/", Sys.Date(), "-", each, "-signatures.pdf", sep = ""), width = 11, height = 8.5)
  plotSignatures(test)
  makePie(test)
  dev.off()
  
}

# rbind all dataframes
allweights <- dir(path = paste(home, "signatures/bysample/", sep= ""), 
                  pattern = "weights.txt", recursive=F, full.names=T)

comb.weights <- do.call("rbind",lapply(allweights, FUN=function(files){read.table(files,header=TRUE, sep="\t")}))
comb.weights$Model <- rownames(comb.weights)
comb.weights <- comb.weights[,c(ncol(comb.weights),1:(ncol(comb.weights)-1))] # reorganize headers
head(comb.weights)
write.table(comb.weights, paste(home, Sys.Date(), "-allpdx-signature-weights.txt", sep = ""), 
            sep = "\t", col.names = T, row.names = F, quote = F)

sort(colnames(comb.weights))

# generate PDF histograms of each model, all signatures
for (each in colnames(comb.weights[,2:ncol(comb.weights)])){
  pdf(paste(home,"/figures/signatures/", Sys.Date(), "-", each, "-histograms.pdf", sep = ""), width = 11, height = 8.5)
  hist(comb.weights[,each], breaks =20, main = each)
  dev.off()
}


#### prepare mutsig figures - cosmic #######################################################################
home <- "~/Desktop/mutsig-demo/"

# import comb.weights
comb.weights <- read.delim(paste0(home,"2019-02-27-allpdx-signature-weights.txt"),header=T,as.is=T,sep="\t")

# design cosmic signature meanings
Signature <- c("Signature.1","Signature.2","Signature.3","Signature.4","Signature.5","Signature.6","Signature.7","Signature.8",
               "Signature.9","Signature.10","Signature.11","Signature.12","Signature.13","Signature.14","Signature.15","Signature.16",
               "Signature.17","Signature.18","Signature.19","Signature.20","Signature.21","Signature.22","Signature.23","Signature.24",
               "Signature.25","Signature.26","Signature.27","Signature.28","Signature.29","Signature.30")
Category <- c("5-mC deamination","APOBEC","DNA repair","Tobacco mutagens","Unknown","DNA repair","UV exposure","Unknown",
              "Hypermutation and/or MSI","Hypermutation and/or MSI","TMZ treatment","Unknown","APOBEC","Hypermutation and/or MSI",
              "DNA repair","Unknown","Unknown","Unknown","Unknown","DNA repair","Hypermutation and/or MSI","Aristolochic acid exposure",
              "Unknown","Aflatoxin exposure","Unknown","DNA repair","Unknown","Unknown","Chewing tobacco exposure","Unknown")
def.final <- data.frame("Signature"=Signature,"Category"=Category)

# read in clinical data
laml.clin <- read.delim(paste0(home,"pptc-pdx-clinical-web.txt"),header=T,as.is=T,sep="\t")

# subset samples in PPTC with maf file
clin.pptc <- subset(laml.clin, DNA.Part.of.PPTC == "yes" & Have.maf == "yes")
setdiff(clin.pptc$Model, comb.weights$Model) # these are the samples with <50 mutations
col.to.keep <- c("Model","Histology","Histology.Detailed")
clin.pptc <- clin.pptc[,col.to.keep]

# merge weights and clinical data
weights.clin <- merge(clin.pptc, comb.weights)
table(weights.clin$Histology.Detailed)

# reshape the data to plot
library(tidyr)
headers <- names(weights.clin) # set gather to first Signature.X : last Signature.X
data.long <- gather(weights.clin, Signature, Measurement, Signature.28:Unknown, factor_key=TRUE)
data.long[data.long == 0] <- NA
data.complete <- data.long[complete.cases(data.long),]

# generate loop criteria (Detailed)
histos <- unique(data.complete$Histology.Detailed)

# design color dataframe
Colors <- c("#EA7075","#BE1E2D","#000000","#DAF1FC","#D49DC7","#C1A72F","#ED2891","#CEAC8F","#9EDDF9","#104A7F","#F9ED32","#97D1A9","#FBE3C7",
            "#007EB5","#D3C3E0","#FAD2D9","#754C29","#D97D25","#B2509E","#009444","#00AEEF","#CACCDB","#E8C51D","#F89420","#F8AFB3","#ED1C24",
            "#7E1918","#00A99D","#A084BD","#542C88","#6E7BA2","#F6B667","#3953A4")
Signature.col <- c("Signature.24","Free 2","Free 3","Signature.1","Signature.2","Signature.3","Signature.4","Signature.5","Signature.6","Signature.7",
                "Signature.8","Signature.9","Signature.10","Signature.11","Signature.12","Signature.13","Signature.14","Signature.15","Signature.16",
                "Signature.17","Signature.18","Signature.19","Signature.20","Signature.21","Signature.25","Signature.26","Signature.29","Signature.P1",
                "Signature.R1","Signature.R2","Signature.R3F","Signature.U1","Signature.U2")
fig.colors <- data.frame("Colors"=Colors,"Signature"=Signature.col,stringsAsFactors = FALSE)


# generate figures
library(ggplot2)
source(paste0(home,"theme.R"))

for (histo in histos) {
  # subset each histology
  data.complete.sub <- subset(data.complete, data.complete$Histology.Detailed == histo)
  data.complete.sub1 <- subset(data.complete.sub, data.complete.sub$Measurement >= .1) # subset samples that have >0.1 cosine similarity value
  test.sub <- as.data.frame(table(data.complete.sub1$Signature))
  # generate proportion of models with >0.1 (e.g. a histology with 2 models each with >0.1 will yield a proportion of 1 in that histology)
  test.sub$Proportion <- test.sub$Freq/(length(unique(data.complete.sub1$Model))) 
  colnames(test.sub)[colnames(test.sub) == "Var1"] <- "Signature"
  # merge signature meanings, colors, and test subset data - remove signatures with no presentation across the histologies
  histo.toplot0 <- merge(test.sub, def.final)
  histo.toplot1 <- merge(histo.toplot0,fig.colors)
  to.remove <- c("Unknown","Tobacco mutagens","UV exposure","Aflatoxin exposure","UV exposure","TMZ treatment")
  histo.toplot2 <- subset(histo.toplot1, !(Category %in% to.remove))
  histo.toplot2$Category <- factor(histo.toplot2$Category, levels = c("APOBEC","Hypermutation and/or MSI", "DNA repair", "5-mC deamination"))
  
  # create dataframe to add specific colors for each sig
  color.df <- histo.toplot2[,c(1,5)]
  color.df$Signature <- gsub("Signature.","",color.df$Signature)
  color.df$Signature <- as.numeric(color.df$Signature)
  color.df.sort <- color.df[order(color.df$Signature),]
  plot.colors <- color.df.sort$Colors

  # generate plots
  temp.plotname = paste(home, "/figures/", Sys.Date(), "-", "HistologyDetailed-10cutoff-labels-",histo, "-sig-proportions.pdf", sep = "")
  pdf(temp.plotname, width = 8, height = 5)
  temp.plot <- ggplot(data=histo.toplot2, aes(x= Category, y=Proportion, fill = Signature)) +
    geom_bar(stat="identity") + coord_flip() + scale_fill_manual(values = plot.colors) +
    theme_Publication() + scale_y_continuous(breaks = seq(0,2,by=0.5)) + labs(x ="", y = "Proportion of Models") # +
    # # remove axis titles and legend for publication figure, change to 3 x 3
    # theme(legend.position="none",axis.title.x=element_blank(),axis.text.y=element_blank(),
    #       axis.text.x = element_text(colour="black", size = 20),axis.title=element_text(colour="black", size = 18, face="bold"))
  print(temp.plot)
  dev.off()
}


# determine N for each model
for (histo in histos) {
  # subset each histology
  print(histo)
  data.complete.sub <- subset(data.complete, data.complete$Histology.Detailed == histo)
  print(length(unique(data.complete.sub$Model)))
}
