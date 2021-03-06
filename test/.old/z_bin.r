library(blavaan)

model <- '
   # latent variable definitions
     ind60 =~ x1 + x2 + x3
     dem60 =~ y1 + y2 + y3 + y4
     dem65 =~ y5 + y6 + y7 + y8
   # regressions
     dem60 ~ ind60
     dem65 ~ ind60 + dem60
   # residual covariances
     y1 ~~ y5
     y2 ~~ y4 + y6
     y3 ~~ y7
     y4 ~~ y8
     y6 ~~ y8
'
fit <- bsem(model, data = PoliticalDemocracy, mcmcfile = T)
summary(fit)



# setClass("foo", representation(x = "numeric"))
# setClass("bar", contains = "foo")
# #
# setGeneric("foobar", function(object, ...) standardGeneric("foobar"))
# #
# setMethod("foobar", "foo", function(object, another.argument = FALSE, ...) {
#   print(paste("in foo-method:", another.argument))
#   if (another.argument) object@x^3
#   else object@x^2
# })
# #
# setMethod("foobar", "bar", function(object, another.argument = FALSE, ...) {
#   print(paste("in bar-method:", another.argument))
#   object@x <- sqrt(object@x)
#   callNextMethod(object, another.argument, ...)
# })
# o1 <- new("bar", x = 4)
# #
# foobar(o1, another.argument = TRUE)
