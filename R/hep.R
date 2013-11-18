hepData <- read.csv("hepEdited.csv", header = TRUE)
head (hepData)
dim(hepData)
hepNew <- hepData[complete.cases(hepData), ]
head (hepNew)
dim(hepNew)

library(lattice)

# to get an idea of the frequency of each type in the data
barchart(hepData$Bx, ylab="Type", col = "green3")

# to save a plot
postscript("hepFreq.eps")
barchart(hepNew$Bx, ylab="Type", col = "green3")
dev.off

# split data according to type, Bx
hepSplit = split(hepNew, hepNew$Bx)
head(hepSplit$I)
head(hepSplit$II)
head(hepSplit$III)

# get the number of values in each type
dim(hepSplit$I)
dim(hepSplit$II)
dim(hepSplit$III)

# randomise and split for type I
rand = sample(nrow(hepSplit$I))
newHepI = hepSplit$I[rand,];
newHepI.train = newHepI[1:58,]
newHepI.test = newHepI[59:86,]

# randomise and split for type II
rand = sample(nrow(hepSplit$II))
newHepII = hepSplit$II[rand,];
newHepII.train = newHepII[1:64,]
newHepII.test = newHepII[65:95,]

# randomise and split for type III
rand = sample(nrow(hepSplit$III))
newHepIII = hepSplit$III[rand,];
newHepIII.train = newHepIII[1:30,]
newHepIII.test = newHepIII[31:44,]

# combine test and train data sets back into two sets and randomise them
hepTrain = rbind(newHepI.train, newHepII.train, newHepIII.train)
rand = sample(nrow(hepTrain))
hepTrain = hepTrain[rand,];

hepTest = rbind(newHepI.test, newHepII.test, newHepIII.test)
rand = sample(nrow(hepTest))
hepTest = hepTest[rand,];

# now it is time to classify the data to predict hepatitis type usimg a decsion tree
install.packages("tree")
library(tree)
require(rpart)
new.tree = rpart(Bx~., data=hepTrain, method="class")

postscript("dt01.eps")
plot(new.tree, uniform=TRUE, main="Classification of Hepatitis Severity")
text(new.tree, use.n=TRUE, all=TRUE, cex=.8)
dev.off()

# compute the confusion matrix
pred = predict(new.tree, newdata = hepTrain, type = "class")
confmat = table(hepTrain$Bx, pred)
print(confmat)

printcp(new.tree)
postscript("ct01.eps")
plotcp(new.tree)
dev.off()
summary(new.tree)

# to prune the tree
pnew.tree = prune(new.tree, cp=new.tree$cptable[which.min(new.tree$cptable[,"xerror"]), "CP"])
postscript("pt01.eps")
plot(pnew.tree, uniform=TRUE, main="Pruned Classification Tree of Hepatitis Severity")
text(pnew.tree, use.n=TRUE, all=TRUE, cex=.8)
dev.off()

# use decsion tree on test data
pred = predict(new.tree, newdata = hepTest, type = "class")
confmat = table(hepTest$Bx, pred)
print(confmat)
err.test = 1 - (confmat[1,1] + confmat[2,2] + confmat[3,3])/sum(confmat)
err.test

