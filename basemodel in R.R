knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width=7.5,
  fig.path = "vigfig-"
)
library(LKT)
library(ggplot2)
library(pROC)
library(glmnet)
library(crayon)
library(dplyr)
library(boot)
# precomputed as per https://ropensci.org/blog/2019/12/08/precompute-vignettes/
set.seed(41)
val<-largerawsample

#clean it up
val$KC..Default.<-val$Problem.Name
# make it a data table
val= setDT(val)

#make unstratified folds for crossvaldiations
val$fold<-sample(1:5,length(val$Anon.Student.Id),replace=T)

# make student stratified folds (for crossvalidation for unseen sample)
unq = sample(unique(val$Anon.Student.Id))
sfold = rep(1:5,length.out=length(unq))
val$fold = rep(0,length(val[,1]))
for(i in 1:5){val$fold[which(val$Anon.Student.Id %in% unq[which(sfold==i)])]=i}

# get the times of each trial in seconds from 1970
val$CF..Time.<-as.numeric(as.POSIXct(as.character(val$Time),format="%Y-%m-%d %H:%M:%S"))

#make sure it is ordered in the way the code expects
val<-val[order(val$Anon.Student.Id, val$CF..Time.),]

#create a binary response column to predict and extract only data with a valid value
val$CF..ansbin.<-ifelse(tolower(val$Outcome)=="correct",1,ifelse(tolower(val$Outcome)=="incorrect",0,-1))
val<-val[val$CF..ansbin.==0 | val$CF..ansbin.==1,]

# create durations
val$Duration..sec.<-(val$CF..End.Latency.+val$CF..Review.Latency.+500)/1000

# this function needs times and durations but you don't need it if you don't want to model time effects
val <- computeSpacingPredictors(val, "KC..Default.") #allows recency, spacing, forgetting features to run
val <- computeSpacingPredictors(val, "KC..Cluster.") #allows recency, spacing, forgetting features to run
val <- computeSpacingPredictors(val, "Anon.Student.Id") #allows recency, spacing, forgetting features to run
val <- computeSpacingPredictors(val, "CF..Correct.Answer.") #allows recency, spacing, forgetting features to run

modelob <- LKT(data = val, interc=TRUE,dualfit = FALSE,factrv = 1e11,
               components = c("Anon.Student.Id","KC..Default.","KC..Default.")
               ,features = c("logitdec", "linesuc","recency"),seedpars =c(0.98, 0.24))
#save(val,file="..\\LKTCloze.RData")