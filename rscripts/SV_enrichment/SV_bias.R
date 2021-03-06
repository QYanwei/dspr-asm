library(ggplot2)
library(viridis)
rm(list = ls())
setwd('/Users/jje/Google\ Drive/DSPR_pacbio/Manuscript/Figures/SV_enrichment/')
binsamp <- function(start, end, size, poplen, popstate, desc = FALSE) {
  crit <- poplen >= start & poplen <= end
  n <- sum(crit)
  k <- sum(popstate[crit])
  if (desc) {
    return(c(start, end, size, k, n-k))
  } else {
    return(rhyper(nn = 1, m = k, n = n-k, k = size))
  }
}

binsampV <- Vectorize(FUN = binsamp, vectorize.args = c('start', 'end', 'size'))

sampprob <- function(target, population, N = length(target), min = 1e-10) {
  fit <- density(x = target)
  mod <- smooth.spline(x = fit$x, y = fit$y)
  prob <- predict(population, object = mod)
  popfit <- density(x = population)
  popmod <- smooth.spline(x = popfit$x, y = popfit$y)
  popprob <- predict(population, object = popmod)
  ret <- prob$y/popprob$y
  ret[ret < 0] <- min
  return(ret)
}

dat <- read.table('sv_cand_lengthc.txt')

datC <- subset(x = dat, V3 == 'C')
datQ <- subset(x = dat, V3 == 'Q')

sampleMat <- matrix(
data = c(
  1111, 1510, 1,
  1523, 2528, 14,
  2583, 3281, 6,
  6284, 7283, 1,
  10231, 17561, 7,
  40102, 50101, 1,
  55605, 65604, 1,
  118436, 158435, 1
  ), byrow = TRUE, nc = 3
)

#binsampx <- replicate(n = 1e5, binsampV(start = sampleMat[,1], end = sampleMat[,2], size = sampleMat[,3], poplen = datC$V4, popstate = datC$V2))
binsampx <- as.matrix(read.table(file = 'montecarlo2.txt', header = FALSE, colClasses = 'numeric'))

hyperhist <- t(binsampV(start = sampleMat[,1], end = sampleMat[,2], size = sampleMat[,3], poplen = datC$V4, popstate = datC$V2, desc = TRUE))
colnames(hyperhist) <- c('start', 'end', 'n', 'K', 'N-K')

samptab <- table(colSums(binsampx))
cols <- rep('gray', length(samptab))
cols[as.numeric(names(samptab)) >= sum(datQ$V2)] <- 'red'

#write.table(x = binsampx, file = 'montecarlo2.txt', row.names = FALSE, col.names = FALSE)

plottab <- data.frame(probability = samptab/sum(samptab), cat = ifelse(test = cols == 'gray', yes = 'lt', no = 'gte'))
colnames(plottab)[1:2] <- c('num', 'probability')

o <- sum(datQ$V2)
e <- mean(colSums(binsampx))
print(c(o, e, 100*(o-e)/e))

print(sum(colSums(binsampx) >= sum(datQ$V2)))/ncol(binsampx)

p <- ggplot(data = plottab) +
  geom_bar(aes(x = num, y = probability, fill = cat), stat = 'identity') +
  scale_x_discrete(name = 'number of candidate gene SVs in Monte Carlo sample', labels = levels(factor(plottab$num)), breaks = as.numeric(levels(factor(plottab$num)))) +
  theme_bw() + 
  theme(legend.position = 'none') + 
  scale_fill_manual(values = plasma(n = 4)[c(3,1)]) + 
  ggtitle(label = 'enrichment of SVs in QTL candidate genes') +
  NULL


svg(filename = 'sv_enrichment2.svg', width = 5, height = 3)
print(p)
dev.off()
cairo_pdf(filename = 'sv_enrichment2.pdf', width = 4.5, height = 3)
print(p)
dev.off()

