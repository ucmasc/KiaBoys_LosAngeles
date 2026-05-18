data {
  int N;
  int sales[N];
}
parameters {
  real<lower=0> mu;
  real<lower=0> sig;
  real<lower=0> c;
}

model {
  mu ~ exponential(.1);
  sig ~ exponential(.1);
  c ~ exponential(.1);
  for (i in 1:N){
    sales[i]~poisson(c*exp(-pow((i-mu),2.0)/(2.0*sig*sig)));
  }
}
