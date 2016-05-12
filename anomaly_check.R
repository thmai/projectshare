setwd('/Users/xianhui/Downloads/')
file = 'XD edit suvery input template.xlsx - Cleaned Data.csv'
data = read.csv(file)
surveyee = data[,1]
data = data[,-1]
str(data) # 2050 surveyees, 157 answers 

library(outliers)
chisq.out.test(as.numeric(data[,1]))
outliers = data.frame()
ave = c()
lqr = c()
uqr = c()
for (i in c(1:ncol(data))){
  ave[i] = unname(mean(as.numeric(data[,i]),na.rm=T))-0
  lqr[i] = unname(mean(as.numeric(data[,i]),na.rm=T))-unname(quantile(as.numeric(data[,i]),0.25,na.rm=T))
  uqr[i] = unname(quantile(as.numeric(data[,i]),0.75,na.rm=T))-unname(mean(as.numeric(data[,i]),na.rm=T))
  for (j in c(1:nrow(data))){
    if (is.na(data[j,i])){
      outliers[j,i] = 0
    } else
    if ((as.numeric(data[j,i])<(ave[i]-lqr[i])) || (as.numeric(data[j,i])>(ave[i]+uqr[i]))){
      outliers[j,i] = 1
    } else outliers[j,i] = 0
  }
}
