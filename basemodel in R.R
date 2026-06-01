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



modelob <- LKT(data = val, interc=TRUE,dualfit = FALSE,factrv = 1e11,
               components = c("Anon.Student.Id","KC..Default.","KC..Default.")
               ,features = c("logitdec", "logfail","ppes"),seedpars =c(0.98, 0.5407546,0.14173,0.2880232,0.7837061))
#save(val,file="..\\LKTCloze.RData")



modelob <- LKT(data = val, interc=TRUE,dualfit = FALSE,factrv = 1e11,
               components = c("Anon.Student.Id","KC..Default.","KC..Default.")
               ,features = c("logitdec", "recency","ppes"),seedpars =c(0.98,.24, 0.5407546,0.14173,0.2880232,0.7837061))
logitdec Anon.Student.Id 0.965862988986121
recency KC..Default. 0.506658174759911
ppes KC..Default. 0.666776241413688 0.00323086343731414 0.395159444462192 0.313567171860063
ppesKC..Default.+recencyKC..Default.+logitdecAnon.Student.Id+1
McFaddens R2 logistic: 0.232595
LogLike logistic: -29148.723657
step par values =0.965863,0.5066582,0.6667762,0.003230863,0.3951594,0.3135672




modelob <- LKT(data = val, interc=TRUE,dualfit = FALSE,factrv = 1e11,
               components = c("Anon.Student.Id","KC..Default.","KC..Default.")
               ,features = c("logitdec", "recency","ppes"),fixedpars =c(0.965863,0.5066582,0.6667762,0.003230863,0.3951594,0.3135672))

modelob$coefs



> modelob <- LKT(data = val, interc=TRUE,dualfit = FALSE,factrv = 1e11,
                 +                components = c("Anon.Student.Id","KC..Default.","KC..Default.")
                 +                ,features = c("logitdec", "recency","ppes"),fixedpars =c(0.965863,0.5066582,0.6667762,0.003230863,0.3951594,0.3135672))
logitdec Anon.Student.Id 0.965863
recency KC..Default. 0.5066582
ppes KC..Default. 0.6667762 0.003230863 0.3951594 0.3135672
ppesKC..Default.+recencyKC..Default.+logitdecAnon.Student.Id+1
McFadden's R2 logistic: 0.232595
LogLike logistic: -29148.7236548
>
> modelob$coefs
                        coefficient
(Intercept)              -0.7725027
ppesKC..Default.          1.5937255
recencyKC..Default.      11.9969903
logitdecAnon.Student.Id   0.6198172
>


"calculateProbability": "p.ppes = pFunc.ppesFromTimes(p.stimSuccessCount, p.stimTotalTests, p.stimTimeHistory, 0.6667762, 0.003230863, 0.3951594, 0.3135672); p.recency = pFunc.recency(p.stimSecsSinceLastShown, 0.5066582); p.logitdec = pFunc.logitdec(p.overallOutcomeHistory.slice(Math.max(p.overallOutcomeHistory.length - 60, 0), p.overallOutcomeHistory.length), 0.965863); p.y = -0.7725027 + 1.5937255 * p.ppes + 11.9969903 * p.recency + 0.6198172 * p.logitdec; p.probability = 1.0 / (1.0 + Math.exp(-p.y)); return p"



modelob <- LKT(data = val, interc=TRUE,dualfit = FALSE,factrv = 1e11,
               components = c("Anon.Student.Id","KC..Default.","KC..Default.","KC..Default.")
               ,features = c("logitdec", "recency","ppes","logsuc"),seedpars =c(0.965863,0.5066582,0.6667762,0.303230863,0.3951594,0.3135672))



"calculateProbability": "p.ppes = pFunc.ppesFromTimes(p.stimSuccessCount, p.stimTotalTests, p.stimTimeHistory, 0.6441441, 0.08130677, 0.1362004, 0.7191809); p.y = -0.77 + .665 * pFunc.logitdec(p.overallOutcomeHistory.slice(Math.max(p.overallOutcomeHistory.length - 60, 0), p.overallOutcomeHistory.length), .966) + .51 * p.stimSuccessCount + 11.1 * p.ppes; p.probability = 1.0 / (1.0 + Math.exp(-p.y)); return p"
