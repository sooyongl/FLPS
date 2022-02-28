# rm(list = ls())
library(rstan)
library(foreach)
library(doParallel)
library(Rmpi)

for(i in list.files("R", full.names = T, pattern = "r$")) source(i);rm(i)
source_funs <- ls()
# condition ---------------------------------------------------------------
lvmodel <- c("rasch","2pl","gpcm","grm")
nsample <- c(500, 1000)
nitem   <- c(100)
fnitem  <- expand.grid(nsample=nsample, nitem=nitem, lvmodel=lvmodel)

lvmodel <- c("rasch","2pl","gpcm","grm")
nsample <- c(1000)
nitem   <- c(50, 200)
fnsize  <- expand.grid(nsample=nsample, nitem=nitem, lvmodel=lvmodel)
cond_table <- rbind(fnitem,fnsize)

cond_table$linearity <- T
cond_table_correct <- cond_table
# cond_table$linearity <- F
# cond_table_incorrect <- cond_table

# cond_table <- rbind(cond_table_correct, cond_table_incorrect)

expand.grid.df <- function(...) Reduce(function(...) merge(..., by=NULL), list(...))
cond_table <- expand.grid.df(cond_table, data.frame(rep = 1:10))

# core setting ------------------------------------------------------------
# cl <- getMPIcluster()
# doParallel::registerDoParallel(cl)

n_cores <- detectCores() - 2; print(n_cores)
cl <- parallel::makeCluster(n_cores)
doSNOW::registerDoSNOW(cl)

# condition filter --------------------------------------------------------
cond_table <- cond_table[cond_table$nsample  == 1000 & cond_table$nitem  == 50 & cond_table$linearity == T,]

# loop --------------------------------------------------------------------
oo <- foreach(
  i = 1:nrow(cond_table),
  .packages = c("rstan"),
  # .errorhandling = 'remove'
  .export = source_funs
  # .options.snow = opts
) %dopar% {

  # set.seed(i)
  nsample     <- cond_table$nsample[i]
  nitem       <- cond_table$nitem[i]
  linearity   <- cond_table$linearity[i]
  lvmodel     <- as.character(cond_table$lvmodel[i])
  rep         <- cond_table$rep[i]

  # generate data ------------------------------------------
  sim_condition <- list(
    N       = nsample, # sample size
    R2Y     = 0.5,
    R2eta   = 0.2,
    linear  = linearity,
    ydist   = "n",
    lambda  = 0.6,
    nsec    = nitem,
    nfac    = 1,
    lvmodel = lvmodel
  )
  sdat <- do.call("makeDat", sim_condition)

  # run stan ----------------------------------------------------------------
  stanfilename <- paste0("inst/stan/ps", toupper(ifelse(lvmodel=="2pl", "irt", lvmodel)),"_univ.stan")
  fit <- rstan::stan(
    file   = stanfilename,
    data   = sdat$stan_dt,
    chain  = 2,
    cores  = 1,
    iter   = 5000,
    warmup = 2000
  )

  o <- list(fit=fit, sdat=sdat)

  filename <- paste0(paste(nsample, nitem, lvmodel, linearity, rep,sep = "_"),".rds")

  saveRDS(o, file.path("results",filename))
  #sdat

  NA
}
# stopCluster(cl)
