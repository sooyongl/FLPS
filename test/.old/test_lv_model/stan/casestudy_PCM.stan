functions {
  real pcm(int y, real theta, vector beta) {
    vector[rows(beta) + 1] unsummed;
    vector[rows(beta) + 1] probs;
    unsummed = append_row(rep_vector(0.0, 1), theta - beta);
    probs = softmax(cumulative_sum(unsummed));
    return categorical_lpmf(y + 1 | probs);
  }
}
data {
  int<lower=1> I;                // # items
  int<lower=1> J;                // # persons
  int<lower=1> N;                // # responses
  int<lower=1,upper=I> ii[N];    // i for n
  int<lower=1,upper=J> jj[N];    // j for n
  int<lower=0> y[N];             // response for n; y = 0, 1 ... m_i
}
transformed data {
  int m;                         // # parameters per item (same for all items)
    m = max(y);
}
parameters {
  vector[m] beta[I];
  vector[J] theta;
  real<lower=0> sigma;
}
model {
  for(i in 1:I)
    beta[i] ~ normal(0, 9);
  theta ~ normal(0, sigma);
  sigma ~ exponential(.1);
  for (n in 1:N)
    target += pcm(y[n], theta[jj[n]], beta[ii[n]]);
}
[n]], beta[ii[n]]);
}
