For user defined functions you can’t input a constrained type. Declare sigma as a matrix instead of a cov_matrix.

Is there a reason why you’re writing your own? Your implementation above will be much slower than the inbuilt. Or even writing it in a more computationally efficient way. A few notes,

we try to avoid explicitly calling inverse on a matrix
the cholesky parameterization will be faster and more numerically stable
there is a log_determinant function
If you have a matrix X where the rows equal the number of observations then a more efficient version of the mvn using the cholesky parameterization in the functions block will look like

 real mvn_cholesky_lpdf(matrix X, matrix mu, matrix L) {
    int K = rows(L);
    int N = rows(X);
    real sqrt_det = -N * sum(log(diagonal(L)));
    real norm_const =  -K * N * 0.5 * log(2 * pi());
    real mahab = sum(columns_dot_self(mdivide_left_tri_low(L, (X' - mu))));
    
    return norm_const + sqrt_det - 0.5 * mahab;
  }
  
  


real binormal_cdf(real z1, real z2, real rho) {
  if (z1 != 0 || z2 != 0) {
    real denom = fabs(rho) < 1.0 ? sqrt((1 + rho) * (1 - rho)) 
                                 : not_a_number();
    real a1 = (z2 / z1 - rho) / denom;
    real a2 = (z1 / z2 - rho) / denom;
    real product = z1 * z2;
    real delta = product < 0 || (product == 0 && (z1 + z2) < 0);
    return 0.5 * (Phi(z1) + Phi(z2) - delta)
                 - owens_t(z1, a1) - owens_t(z2, a2);
  }
  return 0.25 + asin(rho) / (2 * pi());
}


cov_matrix[k] mat; or

matrix[k, k] mat;

transformed parameters {
  matrix[k, k] custome_cov;
  
  for(i in 1:k) {
    for(j in 1:k) {
	   
	  if (i == j | i > j) { // 2 1
      custome_cov[j, i] = mat[i, j];
    } else { // i < j 1 2
      custome_cov[j, i] = mat[j, i];
    }
	}
  }

}


real mvn_lpdf(vector X, vector mu, matrix sigma) {

  real e_part = 0.0;
  real logl = 0.0;

  //int n = row(X);
  //int k = col(X);
  
  e_part = (X - mu)' * inverse(sigma) * (X - mu);
  
  logl = log(2*pi()) + log(determinant(Sigma))
  logl = -.5*logl - .5*exp_part

  return logl
}



functions {
  real unit_normal_lpdf(real y) {
    return normal_lpdf(y | 0, 1);
  }
}


In general, if foo_lpdf is defined to consume  N + 1 arguments, then

y ~ foo(theta1, ..., thetaN);

target += foo_lpdf(y | theta1, ..., thetaN);


parameters {
  matrix[K, nfac] beta;
  cov_matrix[nfac] Sigma;
}
model {
  vector[nfac] mu[N];
  
  for (n in 1:N)
    mu[n] = beta * x[n];

  y ~ multi_normal(mu, Sigma);
}

  real rsm(int y, real theta, real beta, vector kappa) {
    vector[rows(kappa) + 1] unsummed;
    vector[rows(kappa) + 1] probs;
    unsummed = append_row(rep_vector(0, 1), theta - beta - kappa);
    probs = softmax(cumulative_sum(unsummed));
    return categorical_lpmf(y + 1 | probs);
  }

  real rsm(int y, real theta, real beta, real alpha) {
    vector[rows(kappa) + 1] unsummed;
    vector[rows(kappa) + 1] probs;
    unsummed = append_row(rep_vector(0, 1), beta + alpha*theta);
    probs = softmax(cumulative_sum(unsummed));
    return categorical_lpmf(y + 1 | probs);
  }
