#Logistic model fit to weekly sonata theft data

library(ggplot2)

data=read.csv("data/weekly_sonata_logistic-10-4-24.csv")
data$index=c(1:364)
N.logistic <- function(x, K, r0,c,b){
  return(K/(1 + exp(-r0*(x-c)))+b)
  }

model=nls(theft ~ N.logistic(index, K, r0,c,b), data = data, 
    start = list(K = 50, r0 = .5,c=200,b=30))

#print the fitted parameters

summary(model)

#graph the logistic function with fitted parameters



K = coef(model)[1] #K2 in the main text
r0 = coef(model)[2]
c = coef(model)[3]
b = coef(model)[4] #K1 in the main text

cat("***Logistic model fit***\n")

cat("K2: ",K,", r0: ",r0,", c: ",c,", K1: ",b)

#K = 5.455e+01 #K2 in the main text
#r0 = 6.689e-02
#c=2.435e+02
#b=3.662e+01 #K1 in the main text


data$logistic=0
for(i in 1:364){
  data$logistic[i]=N.logistic(i,K,r0,c,b)
}

data$mxb=.9121274*(data$index-243)+N.logistic(243,K,r0,c,b)
data$constant=b
ggplot(data)+geom_point(aes(x=index,y=theft))+geom_line(aes(x=index,y=logistic))+
  geom_line(aes(x=index,y=mxb),color="red")+ylim(0,150)+xlab("week")+annotate("text",x=214,y=100,label="week = 214",color="darkgreen")+
  geom_line(aes(x=index,y=constant),color="blue")+theme_bw()+geom_vline(aes(xintercept = 214),colour = "darkgreen")


