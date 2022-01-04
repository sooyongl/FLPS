#' S3 generic for latent model data generation
#'
generate <- function(info, ...) {
  UseMethod("generate", info)
}


#' get information for data generation ready
#'
parsForLVM <- function(..., data_type = "1pl") {

  info <- list(...)
  class(info) <- append(class(info), data_type)

  return(info)
}

generateLV <- function(...) {

  info <- list(...)
  class(info) <- append(class(info), info$lv_model)

  N      <- info$N
  nsec   <- info$nsec
  lambda <- info$lambda

  lv.gen.dt <- generate(info)

  lv.par <- lv.gen.dt$lv.par
  grad <- lv.gen.dt$resp

  # nworked <- sample(1:nsec,N/2,replace=TRUE,prob=dexp(1:nsec,rate=1/lambda))
  nworked <- rep(floor(nsec * lambda), N/2)

  studentM <- do.call("c", lapply(seq(N/2),function(n) rep(n,each=nworked[n])))
  section <- do.call("c", lapply(seq(N/2),
                                 function(n) {
                                   sort(sample(1:nsec, nworked[n],
                                               replace = FALSE))}))
  ss <- cbind(studentM, section)
  grad <- sapply(1:dim(ss)[1], function(n) grad[ss[n,1], ss[n,2]] )


  list(

    lv.par = lv.par,
    lv.resp = lv.gen.dt$resp,
    grad = grad,
    studentM = studentM,
    section = section
  )
}

## #~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~# ##
##                    IRT model                    ##
## #~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~# ##

#' generate IRT parameters
#'
genIRTparam <- function(items = 20, nrCat = 4, model = "GPCM", same.nrCat = T){

  if(same.nrCat){
    gj <- rep(nrCat - 1, items)
  } else{
    gj <- rpois(items, nrCat - 1)
    gj[gj > nrCat - 1] <- nrCat - 1
    gj[gj < 1] <- 1
  }
  res <- matrix(NA, items, (max(gj) + 1))

  # alphaj <- rlnorm(items, 0, 0.5)
  alphaj <- runif(items, 0.7, 1.4)

  for (i in 1:items) {
    pars <- sort(rnorm(gj[i], 0, 1))
    res[i, 1:(length(pars) + 1)] <- c(alphaj[i], pars)
  }

  if(model == "binary"){

    res <- cbind(res[,1],rowMeans(res[,2:nrCat-1])) %>% data.frame()
    name <- c("alphaj","beta")
    colnames(res) <- name

  } else {
    name <- c("a",paste("b", 1:(ncol(res)-1)))
    colnames(res) <- name
    res <- data.frame(res, K_j = gj)
  }

  return(res)
}

#' methods for rasch model
#'
generate.rasch <- function(.x, ...) {.Class <- "dich"; NextMethod()}

#' method for 1PL model
#'
generate.1pl   <- function(.x, ...) {.Class <- "dich"; NextMethod()}

#' method for 2PL model
#'
generate.2pl   <- function(.x, ...) {.Class <- "dich"; NextMethod()}

#' method for 3PL model
#'
generate.3pl   <- function(.x, ...) {.Class <- "dich"; NextMethod()}

#' method for all dichotomous IRT model
#'
generate.dich <- function(info, D = 1){
  # set up for data generation
  theta <- info$theta; nitem <- info$nsec; lv_info <- info$lv_info

  nexaminee <- length(theta)
  nitem <- nitem

  ipar <- lv_info$ipar
  a <- ipar$a
  b <- ipar$b
  g <- ipar$g

  # data generation
  pr <- matrix(NA, nexaminee, nitem)
  for (j in 1:nexaminee){
    pr[j,] <- g + (1 - g) / (1 + exp(-D * (a * (theta[j] - b))))
  }
  resp <- (matrix(runif(nexaminee*nitem), nexaminee, nitem) < pr) * 1

  ipar <- data.frame(a = a, b = b, c = g)
  return(list(resp = resp, lv.par = ipar))
}


#' method for Polytomous Response: GPCM
#'
generate.gpcm <- function(info){
  ## Generate responses for multiple people to multiple items

  ## Pr(X_{ij} = k | \theta_i)
  ##    \propto \exp (  \sum_{l=0}^k (a_j \theta_i + b_{jl} ) )

  ## 'ipar' Need to have labels, ("a", "b1", ... "bK", "K_j")

  ## | Debug ---------------
  # theta <- theta[i]; # i <- 6
  # ipar = rbind(diff);
  # ipar <- ipar[1:nitemtl,]
  # ipar <- pool[iset,2:(maxitemsc+2)]
  ## ------------------------|

  # set up for data generation
  theta <- info$theta; lv_info <- info$lv_info; ipar <- lv_info$ipar

  # getResponse(theta[1], ipar[1,], model=model,  D = 1.7)

  # data generation
  # set.seed(seednum)
  nitem <- dim(ipar)[1]
  disc <- ipar[,"a"]
  loc <- ipar[,grep("b", colnames(ipar))]
  K_j <- ipar[,"K_j"]
  maxK <- max(K_j)

  resp <- matrix(NA, length(theta), nitem)

  for (i in 1:length(theta)){# i<-1

    ### Compute item response category functions
    pr <- matrix(NA, nitem, maxK + 1) # each row: P(X=0), ... ,P(X=K_j)
    for (j in 1:nitem) { # j <- 1
      exps_k <- rep(0, K_j[j]+1) # Exponentials at k = 0, ... , K_j
      exps_k[1] <- exp(0)
      for (k in 1:K_j[j]){ # h <- 1
        exps_k[k+1] <- exp( k * disc[j] * theta[i] + sum(loc[j, 1:k]) )
      }
      pr[j, 1:(K_j[j]+1)] <- exps_k / sum(exps_k)
    } # end of j

    cumpr <- matrix(NA, nitem, maxK+1)
    for (j in 1:nitem){ # j <- 1
      for (k in 1:(K_j[j]+1)){# h <- 1
        cumpr[j, k] <- sum(pr[j, 1:k])
      }
    }

    tmp <- 1 * (cumpr >= matrix(rep(runif(nitem), maxK+1), nrow=nitem, ncol=maxK+1))
    for (j in 1:nitem){ # j <- 1
      if (sum(tmp[j,], na.rm=T)==(K_j[j]+1)){ # if all cumprs (including cpr_0) are larger than u
        resp[i, j] <- 0
      } else {
        resp[i, j] <- min(which(tmp[j,]==1, arr.ind=T)) - 1
      }
    }

  }

  return(list(resp = resp + 1, lv.par = ipar))
}

#' method for Polytomous Response: GRM
#'
generate.grm <- function(info) {
  print("not yet")
}

#' method for Polytomous Response: NRM
#'
generate.nominal <- function(info) {
  print("not yet")
}

#' method for Polytomous Response: Response Time (Lognormal)
#'
generate.ln <- function(info){
  # set up for data generation
  tau <- info$tau; ipar <- info$ipar

  # data generation
  nexaminee <- length(tau)
  nitem <- nrow(ipar)
  alp <- ipar[,"alp"]; bet <- ipar[,"bet"]

  retime <- matrix(NA, nexaminee, nitem)
  for (j in 1:nexaminee){
    retime[j,] <- rlnorm(nitem, bet-tau[j], 1/alp)
    #m <- bet - tau[j]
    #s <- 1/alp
    #logmu <- log(m^2 / sqrt(s^2 + m^2))
    #logsd <- sqrt(log(1 + (s^2 / m^2)))
  }
  return(retime)
}

#' method for genderating sem data
#'
generate.sem <- function(info) {

  # set up for data generation
  theta <- info$theta; nitem <- info$nsec; lv_info <- info$lv_info

  cpar <- lv_info$cpar

  loadings <- matrix(cpar$loading, ncol = 1)
  residuals <- diag(loadings %*% cov(matrix(theta)) %*% t(loadings)) * .4

  if(is.null(dim(theta))) {
    n_sample <- length(theta)
    theta <- matrix(theta)

  } else {
    n_sample <- dim(theta)[1]
  }

  residuals <- MASS::mvrnorm(n_sample,
                             rep(0, nitem),
                             diag(residuals),
                             empirical = T)

  # data generation
  latent <- tcrossprod(theta, loadings)
  resp <- latent + residuals

  return(list(resp = resp, lv.par = loadings))
}

#' method for genderating lgm data
#'
generate.lgm <- function(info) {

  # set up for data generation
  theta <- info$theta; ntp <- info$nsec; lv_info <- info$lv_info

  loadings <- lv_info$time_loading
  # residuals <- diag(loadings %*% cov(theta) %*% t(loadings)) * .4
  residuals <- diag(var(theta[,1]) * .4, nrow(loadings))

  if(is.null(dim(theta))) {
    n_sample <- length(theta)
    theta <- matrix(theta)

  } else {
    n_sample <- dim(theta)[1]
  }

  residuals <- MASS::mvrnorm(n = n_sample,
                             mu = rep(0, nrow(loadings)),
                             Sigma = residuals,
                             empirical = T)

  # data generation
  latent <- tcrossprod(theta, loadings)
  resp <- latent + residuals

  # test
  # library(lavaan)
  # cov(theta); colMeans(theta)
  # growth(model = "I =~ 1*X1+1*X2+1*X3+1*X4+1*X5+1*X6+1*X7+1*X8+1*X9+1*X10+1*X11+1*X12+1*X13+1*X14+1*X15+1*X16+1*X17+1*X18+1*X19+1*X20
  #        S =~ 0*X1+1*X2+2*X3+3*X4+4*X5+5*X6+6*X7+7*X8+8*X9+9*X10+10*X11+11*X12+12*X13+13*X14+14*X15+15*X16+16*X17+17*X18+18*X19+19*X20",
  #        data = data.frame(resp)) %>% summary()


  return(list(resp = resp, lv.par = loadings))
}

## #~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~# ##
##                   Mixture model                 ##
## #~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~# ##

class_assign <- function(...) {
  eta <- list(...)

  # eta$ref <- rep(0, length(eta[[1]]))
  # eta <- lapply(eta, exp)
  # eta <- do.call("cbind", eta)
  #
  # sum_eta <- apply(eta, 1, function(x) Reduce(sum, x))
  # clasS_prob <- apply(eta, 2, function(x) x / (sum_eta))
  #
  # assignment <- apply(clasS_prob, 1, function(x) { (dim(clasS_prob)[2] + 1) - which.max(x)})
  #
  # assignment

  # vector of probabilities
  vProb = cbind(exp(0), exp(eta[[1]]))

  # multinomial draws
  mChoices = t(apply(vProb, 1, rmultinom, n = 1, size = 1))
  assignment = cbind.data.frame(class = apply(mChoices, 1, function(x) which(x==1)))

  assignment
}

# https://mc-stan.org/users/documentation/case-studies/Latent_class_case_study.html#data-generation-and-label-switching

# generate lca data ---------------------------------------------------
generate.lca <- function(info) {

  # n_class <- info$n_class

  n_indi <- info$nsec
  theta <- info$theta
  # seperation <- info$seperation
  n_class <- info$lv_info$nclass
  seperation <- info$lv_info$separation
  seperation <- c(seperation, 1- seperation)

  latent_class <- class_assign(theta)
  class_prop <- table(latent_class)

  # Measurement models within classes
  data <- lapply(1:length(class_prop), function(i) {

    class_n_size <- class_prop[i]

    row_data <- mvtnorm::rmvnorm(n = class_n_size,
                                 mean = rep(0, n_indi),
                                 sigma = diag(n_indi))

    continuousData <- row_data
    threshold = c(1 - seperation[i])

    quants <- sapply(1:(dim(continuousData)[2]), function(i) {
      quantile(continuousData[,i], probs = threshold[1])
    })

    ordinalData <- sapply(1:n_indi, function(i) {
      as.numeric(cut(as.vector(continuousData[,i]),c(-Inf,quants[i],Inf)))
    })

    useData <- data.frame(ordinalData)
    names(useData) <- paste0("x", 1:dim(useData)[2])

    useData$class <- i

    useData
  })
  resp <- do.call('rbind', data)
  resp <- resp - 1

  idx <- data.frame(latent_class, id = 1:nrow(latent_class))
  idx <- idx[order(idx$class),]

  resp$id <- idx$id
  resp <- resp[order(resp$id),]
  resp$id <- NULL

  return(list(lv.par = seperation, resp = as.matrix(resp)))
}

# generate lpa data ---------------------------------------------------
generate.lpa <- function(info) {

  n_indi <- info$nsec
  theta <- info$theta
  n_class <- info$lv_info$nclass
  separation <- info$lv_info$separation # this is Mahalanobis Distance; James Peugh & Xitao Fan(2013)

  if(separation == 1) {
    mean_list <- list()

    mean_list[[1]] <- rep(1, n_indi)
    mean_list[[2]] <- rep(1.41, n_indi)

  }
  if(separation == 2) {
    mean_list <- list()

    mean_list[[1]] <- rep(1, n_indi)
    mean_list[[2]] <- rep(1.58, n_indi)

  }

  latent_class <- class_assign(theta)
  class_prop <- table(latent_class)
  #
  # # Measurement models within classes
  data <- lapply(1:length(class_prop), function(i) {

    class_n_size <- class_prop[i]

    row_data <- mvtnorm::rmvnorm(n = class_n_size,
                                 mean = mean_list[[i]],
                                 sigma = diag(n_indi))

    useData <- data.frame(row_data)

    useData$class <- i
    names(useData) <- paste0("x", 1:dim(useData)[2], "class")
    useData
  })
  #
  # data <- do.call('rbind', data)
  #
  # return(data)

  resp <- do.call('rbind', data)

  idx <- data.frame(latent_class, id = 1:nrow(latent_class))
  idx <- idx[order(idx$class),]

  resp$id <- idx$id
  resp <- resp[order(resp$id),]
  resp$id <- NULL

  return(list(lv.par = separation, resp = as.matrix(resp)))
}

# generate general mixture data -------------------------------------------
generate.mixture <- function(info) {

 # return(data)
  print("not yet")
}










