library(dplyr)

zygomorphy <- read.csv("zygomorphy_length.csv")
zygomorphy.avg <- zygomorphy %>% group_by(herbarium) %>% summarise(species = first(species), collectnum = first(collectnum), zygomorphylong = mean(zygomorphylong), zygomorphyshort = mean(zygomorphyshort), zygomorphyratio = mean(zygomorphyratio))

pedicel <- read.csv("pedicel_length.csv")
pedicel.avg <- pedicel %>% group_by(herbarium) %>% summarise(species = first(species), collectnum = first(collectnum), pedicellength = mean(pedicellength))

campanulation <- read.csv("campanulation_length.csv")
campanulation.avg <- campanulation %>% group_by(herbarium) %>% summarise(species = first(species), collectnum = first(collectnum), sinus = mean(sinus), ovary = mean(ovary), sinusovaryratio = mean(sinusovaryratio))

flowerlength <- read.csv("flower_length.csv")
flowerlength.avg <- flowerlength %>% group_by(herbarium) %>% summarise(species = first(species), collectnum = first(collectnum), flowerlength = mean(flowerlength))

cymule <- read.csv("cymule_branch.csv")
cymule.avg <- cymule %>% group_by(herbarium) %>% summarise(species = first(species), collectnum = first(collectnum), branchlength = mean(branchlength))

thyrse <- read.csv("thyrse_length.csv")
thyrse.avg <- thyrse %>% group_by(herbarium) %>% summarise(species = first(species), collectnum = first(collectnum), thyrselength = mean(thyrselength))

petal <- read.csv("petal_exsertion.csv")
petal.avg <- petal %>% group_by(herbarium) %>% summarise(species = first(species), collectnum = first(collectnum), petalexsertion = mean(petalexsertion))

# Make combined dataframe
combined <- merge(zygomorphy.avg, pedicel.avg, by = "herbarium")
combined <- merge(combined, campanulation.avg, by = "herbarium")
combined <- merge(combined, flowerlength.avg, by = "herbarium")
combined <- merge(combined, cymule.avg, by = "herbarium")
combined <- merge(combined, thyrse.avg, by = "herbarium")
combined <- merge(combined, petal.avg, by = "herbarium")


# Remove duplicate columns from the merge
combined <- combined[, !duplicated(colnames(combined), fromLast = TRUE)]
combined$species.y <- NULL
combined$species.x <- NULL
combined$collectnum.y <- NULL
combined$collectnum.x <- NULL


# Define species as a model factor
combined$species <- as.factor(combined$species)

# Normalize data matrix
combined.nonnormalized <- combined
combined <- rapply(combined,scale,c("numeric","integer"),how="replace")

# Build the discriminant
library(MASS)
discriminant <- lda(species ~ zygomorphylong + zygomorphyshort + zygomorphyratio + sinus + ovary + sinusovaryratio + flowerlength + branchlength + thyrselength + pedicellength + petalexsertion, data = combined, na.action="na.omit")

# Classification success
discriminant.jackknife <- lda(species ~ zygomorphylong + zygomorphyshort + zygomorphyratio + sinus + ovary + sinusovaryratio+ flowerlength + branchlength + thyrselength + pedicellength + petalexsertion, data = combined, na.action="na.omit", CV = TRUE)
ct <- table(combined$species, discriminant.jackknife$class)
sum(diag(prop.table(ct)))

# Predict species by the discriminant function
discriminant.prediction <- predict(discriminant)

# Create dataframe for plotting
plotdata <- data.frame(type = combined$species, lda = discriminant.prediction$x)

library(ggplot2)
ggplot(plotdata) + geom_point(aes(lda.LD1, lda.LD2, colour = type), size = 2.5)

# Multivariate MANOVA
res.man <- manova(cbind(zygomorphylong, zygomorphyshort, zygomorphyratio, sinus, ovary, sinusovaryratio, flowerlength, branchlength, thyrselength, pedicellength, petalexsertion) ~ species, data = combined)
summary(res.man)

# Break down variable importance
summary.aov(res.man)

# Assess species pairwise significance
# You must drop perfectly correlated values or you will get a rank deficiency error
library(devtools)
install_github("pmartinezarbizu/pairwiseAdonis/pairwiseAdonis")
library(pairwiseAdonis)
pairwise.adonis(combined[,c("zygomorphylong", "zygomorphyshort", "zygomorphyratio", "sinus", "ovary", "sinusovaryratio", "flowerlength", "branchlength", "thyrselength", "pedicellength", "petalexsertion")], combined$species, sim.method = "euclidean", p.adjust.m = "hochberg", perm = 10000)

## Confusion matrix
#library(class)
## K-nearest neighbor classification
## This is a bit ad hoc as the training and test datasets are the same
#nn_classification <- knn(log(combined[,c("zygomorphylong","zygomorphyshort", "sinus", "ovary", "sinusovaryratio", "flowerlength", "branchlength", "thyrselength")]), log(combined[,c("zygomorphylong","zygomorphyshort", "sinus", "ovary", "sinusovaryratio", "flowerlength", "branchlength", "thyrselength")]), combined$species.x, k = 3)
#confusion_matrix = table(nn_classification, combined$species.x)
#confusion_matrix
#accuracy = sum(nn_classification == combined$species.x)/length(combined$species.x)
#accuracy

# Univariate boxplots

p1 <- ggplot(combined.nonnormalized, aes(y=sinusovaryratio, x=species)) + geom_boxplot() + xlab("") + ylab("Campanulation ratio") + theme(axis.text.x = element_text(angle = 45))
p2 <- ggplot(combined.nonnormalized, aes(y=branchlength, x=species)) + geom_boxplot() + xlab("") + ylab("Cymule branch length (mm)") + theme(axis.text.x = element_text(angle = 45))
p3 <- ggplot(combined.nonnormalized, aes(y=zygomorphyratio, x=species)) + geom_boxplot() + xlab("") + ylab("Zygomorphy ratio") + theme(axis.text.x = element_text(angle = 45))
p4 <- ggplot(combined.nonnormalized, aes(y=pedicellength * 10, x=species)) + geom_boxplot() + xlab("") + ylab("Pedicel length (mm)") + theme(axis.text.x = element_text(angle = 45))
p5 <- ggplot(combined.nonnormalized, aes(y=flowerlength * 10, x=species)) + geom_boxplot() + xlab("") + ylab("Flower length (mm)") + theme(axis.text.x = element_text(angle = 45))
p6 <- ggplot(combined.nonnormalized, aes(y=thyrselength, x=species)) + geom_boxplot() + xlab("") + ylab("Thyrse length (mm)") + theme(axis.text.x = element_text(angle = 45))
p7 <- ggplot(combined.nonnormalized, aes(y=petalexsertion * 10, x=species)) + geom_boxplot() + xlab("") + ylab("Petal exsertion (mm)") + theme(axis.text.x = element_text(angle = 45)) # Check the units

library(gridExtra)
grid.arrange(p1, p2, p3, p4, p5, p6, p7, nrow = 2)


## PCA analysis
#pca <- prcomp(log(combined[,c("zygomorphylong","zygomorphyshort", "zygomorphyratio", "sinus", "ovary", "sinusovaryratio", "flowerlength", "branchlength", "thyrselength", "pedicellength")]), center = TRUE, scale = TRUE)
## Dropping zygomorphy and doing log transformation improved grouping
#pca <- prcomp(log(combined[,c("zygomorphylong","zygomorphyshort", "sinus", "ovary", "sinusovaryratio", "flowerlength", "branchlength", "thyrselength", "pedicellength")]), center = TRUE, scale = TRUE)
## Dropping campanulation and log transformation
#pca <- prcomp(log(combined[,c("flowerlength", "branchlength", "thyrselength", "pedicellength")]), center = TRUE, scale = TRUE)
#
#
## Plot PCA
#library(ggfortify)
## PCA with 90% confidence ellipses
#autoplot(pca, data = combined, colour = 'species.x', frame = TRUE, frame.type = 'norm', level = 0.9) # PCA plot
## PCA with plots of loadings
#autoplot(pca, data = combined, colour = 'species.x', loadings = TRUE, loadings.label = TRUE, loadings.label.size = 3) # PCA plot with loadings



## Univariate ANOVA
#summary(aov(branchlength ~ species.x, data = combined))
#summary(aov(sinusovaryratio ~ species.x, data = combined))
#summary(aov(zygomorphyratio ~ species.x, data = combined))
#summary(aov(pedicellength ~ species.x, data = combined))
#summary(aov(flowerlength ~ species.x, data = combined))
#summary(aov(thyrselength ~ species.x, data = combined))
