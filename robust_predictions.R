robust_predictions <- function(mod, predict.df, rob, cluster = NULL, level = 0.95){
  
  ##Written by Joshua Gubler ~  http://scholar.byu.edu/jgubler
  ##Last updated on 26 June 2014
  ##Updated by Baobao Zhang
  ##This provides an option for robust (including cluster robust) or non-robust standard errors
  ##Note: when estimating a polynomial, you must create the quadratic/cubic as a separate variable first!!  This is also the best procedure when estimating logged effects.  However, when estimating interaction effects, there is no need to create a separate interaction term.
  ##Also note, that for this function to work well, you must input factor variables with more than two levels individually (as indiviual dummies).
  
  if(missing(predict.df)){ predict1.df <- mod$model }
  require(sandwich, quietly = TRUE)
  require(lmtest, quietly = TRUE)
  tt <- terms(mod)
  Terms <- delete.response(tt)
  m.mat <- model.matrix(Terms,data=(if(missing(predict.df)){predict1.df}else{predict.df}))
  t1 <- mod$model
  fit <- as.vector(m.mat %*% mod$coef)
  
  if(missing(rob)){
    varcov <- vcov(mod)
    se.fit <- sqrt(diag(m.mat%*%varcov%*%t(m.mat)))
    ci.lower <- fit + qnorm((1-level)/2)*se.fit
    ci.upper <- fit + qnorm((1+level)/2)*se.fit
  }
  else{
    ##To generate the robust covariance matrix
    X <- model.matrix(mod)
    u2 <- residuals(mod)^2
    if (is.null(cluster)) {
      XDX <- 0 
      for(i in 1:nrow(X)) {
        XDX <- XDX + u2[i]*X[i,]%*%t(X[i,])
      }
      # degrees of freedom adjustment
      dfc <- sqrt(nrow(X))/sqrt(nrow(X)-ncol(X))
      # inverse(X'X)
      XX1 <- solve(t(X)%*%X)  
      # Variance calculation (Bread x meat x Bread)
      robcov <- XX1 %*% XDX %*% XX1
      se.fit <- dfc*sqrt(diag(m.mat%*%robcov%*%t(m.mat)))
    } else { # cluster robust standard errors
      M <- length(unique(cluster))
      N <- length(cluster)
      K <- mod$rank
      # degrees of freedom adjustment
      dfc <- (M/(M-1))*((N-1)/(N-K))
      # meat
      XDX <- crossprod(apply(estfun(mod), 2, function(x) tapply(x, cluster, sum)))/N
      # variance calculation 
      vcovCL <- dfc*sandwich(mod, meat=XDX)
      se.fit <- sqrt(diag(m.mat%*%vcovCL%*%t(m.mat)))
    }
    ci.lower <- fit + qnorm((1-level)/2)*se.fit
    ci.upper <- fit + qnorm((1+level)/2)*se.fit
  }
  
  pred.df <- data.frame(predicted.value=fit,se=se.fit,ci.lower=ci.lower,ci.upper=ci.upper)
  nm <-deparse(substitute(mod))
  mdlname1 <- paste(nm,"allpred.df",sep=".")
  mdlname2 <- paste(nm,"pred.df",sep=".")
  if(missing(predict.df)){
    allpred.df <- cbind(m.mat,t1[1],pred.df)
    assign(mdlname1,allpred.df,envir = .GlobalEnv)}
  else{assign(mdlname2,pred.df,envir = .GlobalEnv)}
  
  pred.df
  
  #Example prediction plots (this one with avginc as a polynomial)
  
  #require(ggplot2)
  #predplot <- ggplot(pred.df,aes(avginc,testscr)) + geom_point() + theme_bw() 
  #predplot + geom_line(aes(pred.dfavginc,pred.dfpredicted.value)) + geom_errorbar(aes(ymin=pred.dfci.lower95,ymax=pred.dfci.upper95))
}