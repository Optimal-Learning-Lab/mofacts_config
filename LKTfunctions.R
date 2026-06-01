#' @importFrom graphics boxplot
#' @importFrom methods new
#' @importFrom stats aggregate deviance as.formula ave binomial coef cor glm lm logLik median nobs optim predict qlogis quantile
#' @importFrom utils packageVersion
#' @importFrom graphics axis legend matplot mtext par
#' @importFrom SparseM as.matrix.csr

#' Fits Weibull RT Model with Activation Effects
#'
#' @description
#' Fits response time distribution using Weibull model with activation-dependent
#' scale parameter. Uses hybrid variance approach: subject effects are estimated
#' once and scaled, sigma_trial is estimated post-hoc.
#'
#' Model structure:
#'   RT = t0 + Weibull(k, lambda)
#'   log(lambda) = log(lambda0) - beta1 * qlogis(p) + scale_subject * u_s_fixed[s] + eps_trial
#'   where u_s_fixed are computed once before optimization, then scaled during fitting
#'
#' The function minimizes a weighted combination of:
#'   1. Quantile MSE: matches overall RT distribution shape
#'   2. Point-wise MSE: matches individual RT predictions (if mse_weight > 0)
#'
#' Hybrid variance approach prevents parameter instability:
#'   - subject effects are fixed up to a learned scale factor
#'   - sigma_trial: estimated post-hoc from log-scale residuals
#'
#' @param rt Numeric vector of response times (correct trials only, in seconds)
#' @param p Numeric vector of success probabilities (from LKT accuracy model)
#' @param subject_id Factor/character vector of subject identifiers (optional)
#' @param sigma_trial_init Numeric, initial within-subject SD (used as fixed trial noise; not optimized)
#' @param eps Numeric, small value to prevent log(0) errors (default 1e-6)
#' @param n_quantiles Integer, number of quantiles for distribution matching (default 20)
#' @param n_sim Integer, deprecated parameter kept for compatibility (default 1)
#' @param mse_weight Numeric in [0,1], weight for point-wise MSE vs quantile matching.
#'   0 = pure quantile matching (default), 1 = pure MSE minimization.
#'   Higher weight = better point predictions, lower weight = better distribution shape
#' @param t0_fixed Numeric, fixed minimum RT in seconds (if NULL, will be optimized)
#'
#' @return List containing:
#'   \item{k}{Weibull shape parameter}
#'   \item{lambda0}{Base scale parameter}
#'   \item{beta1}{Activation effect (negative = faster RT with higher activation)}
#'   \item{scale_subject}{Scaling factor for subject effects (adjusts magnitude of u_s_fixed)}
#'   \item{sigma_trial}{Post-hoc trial noise SD}
#'   \item{t0}{Minimum RT}
#'   \item{subject_effects}{Named vector of subject-specific deviations}
#'   \item{var_partition}{List with activation/subject/trial variance proportions}
#'   \item{predict}{Function(p, subject_effect, add_noise, truncate) for RT prediction}
#'   \item{sse}{Combined loss value}
#'   \item{r_squared}{R² fit quality metric}
#'   \item{conv}{Convergence code from optim (0 = success)}
#'   \item{n_obs}{Number of observations used}
#'   \item{n_subjects}{Number of unique subjects}
#'   \item{max_rt}{Maximum observed RT}
fit_weibull_activation <- function(rt, p, subject_id = NULL,
                                   sigma_trial_init = NULL,  # Fixed trial noise (not optimized)
                                   eps = 1e-6,
                                   n_quantiles = 20, n_sim = 1, mse_weight = 0, t0_fixed = NULL) {

  ##----------------------------------------------------------------------------
  ## 1. DATA PREPARATION
  ##----------------------------------------------------------------------------
  # Clean data
  ok <- is.finite(rt) & is.finite(p) & rt > 0 & p > eps & p < (1 - eps)
  rt <- rt[ok]; p <- p[ok]

  if (!is.null(subject_id)) {
    subject_id <- subject_id[ok]
  }

  # Compute activation from probability
  A <- stats::qlogis(p)

  # Get unique subjects and create mapping
  if (!is.null(subject_id) && length(unique(subject_id)) > 1) {
    unique_subjects <- unique(subject_id)
    n_subjects <- length(unique_subjects)
    # Map subject IDs to indices
    subject_idx <- match(subject_id, unique_subjects)
  } else {
    n_subjects <- 1
    subject_idx <- rep(1, length(rt))
  }

  # Estimate subject effects ONCE before optimization
  # Subject effect = mean log(lambda) for each subject
  # These will be FIXED throughout optimization
  u_s_fixed <- numeric(n_subjects)
  if (n_subjects > 1) {
    t0_init <- if (!is.null(t0_fixed)) t0_fixed else min(rt)

    for (s in 1:n_subjects) {
      idx_s <- which(subject_idx == s)
      if (length(idx_s) > 0) {
        rt_s <- rt[idx_s]
        rt_adj <- pmax(rt_s - t0_init, eps)
        u_s_fixed[s] <- mean(log(rt_adj), na.rm = TRUE)
      }
    }
    u_s_fixed <- u_s_fixed - mean(u_s_fixed, na.rm = TRUE)
  }

  # Prefit sigma_trial from residual SD if not provided
  if (is.null(sigma_trial_init)) {
    t0_prefit <- if (!is.null(t0_fixed)) t0_fixed else min(rt)
    rt_adj_prefit <- pmax(rt - t0_prefit, eps)
    log_rt_adj_prefit <- log(rt_adj_prefit)
    if (n_subjects > 1) {
      prefit_df <- data.frame(log_rt_adj = log_rt_adj_prefit, A = A, subj = factor(subject_idx))
      prefit_fit <- stats::lm(log_rt_adj ~ A + subj, data = prefit_df)
    } else {
      prefit_df <- data.frame(log_rt_adj = log_rt_adj_prefit, A = A)
      prefit_fit <- stats::lm(log_rt_adj ~ A, data = prefit_df)
    }
    sigma_trial_init <- stats::sd(prefit_fit$residuals, na.rm = TRUE)
  }

  # Quantile matching setup (fixed draws for deterministic objective)
  prob_seq <- seq(0.05, 0.95, length.out = n_quantiles)
  obs_quantiles <- stats::quantile(rt, probs = prob_seq, na.rm = TRUE)
  u_fixed <- stats::runif(length(rt))
  z_trial_fixed <- stats::rnorm(length(rt))
  sigma_trial_fixed <- sigma_trial_init

  ##----------------------------------------------------------------------------
  ## 2. OBJECTIVE FUNCTION: Quantile Matching + Optional RT Prediction
  ##----------------------------------------------------------------------------
  # Fits Weibull parameters to minimize:
  #   - Quantile MSE: Match overall RT distribution shape
  #   - Point-wise MSE: Match individual trial predictions (optional, weighted)
  #
  # Hybrid variance approach:
  #   sigma_trial: estimated post-hoc (not optimized)
  objective <- function(par) {
    # Extract parameters
    k <- exp(par[1])
    lambda0 <- exp(par[2])
    beta1 <- par[3]
    scale_subject <- exp(par[4])  # NEW: scales the fixed subject effects
    t0 <- if (!is.null(t0_fixed)) t0_fixed else exp(par[5])

    # NOTE: u_s_fixed is from closure (estimated once before optimization)
    # NOTE: scale_subject is OPTIMIZED to adjust magnitude of u_s_fixed

    # 1. Construct per-trial scale using activation + scaled subject effects + fixed trial noise
    subj_effects <- scale_subject * u_s_fixed[subject_idx]
    log_lambda <- log(lambda0) - beta1 * A + subj_effects + sigma_trial_fixed * z_trial_fixed
    lambda_vec <- exp(log_lambda)

    # 2. Quantile matching component
    rt_sim <- t0 + stats::qweibull(u_fixed, shape = k, scale = lambda_vec)
    sim_quantiles <- stats::quantile(rt_sim, probs = prob_seq, na.rm = TRUE)
    quantile_mse <- mean((obs_quantiles - sim_quantiles)^2)

    # 3. Point-wise MSE component (if mse_weight > 0)
    if (mse_weight > 0) {
      # Compute deterministic predictions (marginal mean incl. trial noise)
      noise_bias <- exp(0.5 * sigma_trial_fixed^2)
      pred_rt <- numeric(length(rt))
      for (i in seq_along(rt)) {
        # Expected lambda at mean subject effect (0) + mean trial effect (0)

        subj_effect <- scale_subject * u_s_fixed[subject_idx[i]]
        lambda_i <- lambda0 * exp(-beta1 * A[i] + subj_effect)
        pred_rt[i] <- t0 + lambda_i * gamma(1 + 1/k) * noise_bias

      }
      rt_mse <- mean((log(rt) - log(pred_rt))^2)

      # Weighted combination (quantile MSE in seconds^2, RT MSE normalized by variance)
      combined_loss <- (1 - mse_weight) * quantile_mse + mse_weight * rt_mse
      return(combined_loss)
    } else {
      # Pure quantile matching (default behavior)
      return(quantile_mse)
    }
  }

  ##----------------------------------------------------------------------------
  ## 3. INITIAL PARAMETER VALUES
  ##----------------------------------------------------------------------------
  # Parameters to optimize:
  #   - k (Weibull shape, log-scale)
  #   - lambda0 (base scale, log-scale)
  #   - beta1 (activation weight)
  #   - scale_subject (scaling factor for u_s_fixed, log-scale) - NEW
  #   - t0 (minimum RT, log-scale if not fixed)
  # Note: sigma_trial is fixed for quantile matching; post-hoc sigma is reported

  if (!is.null(t0_fixed)) {
    # Fixed t0: optimize 4 parameters
    rt_adjusted <- stats::median(rt) - t0_fixed
    rt_adjusted <- max(rt_adjusted, 0.0005)  # Prevent negative/zero values
    init <- c(
      log(1.5),                      # k (shape)
      log(rt_adjusted),              # lambda0
      0.5,                           # beta1
      log(1.0)                       # scale_subject (neutral start)
    )
  } else {
    # Optimize 5 parameters including t0
    t0_init <- min(rt)
    rt_adjusted <- stats::median(rt) - t0_init
    rt_adjusted <- max(rt_adjusted, 0.0005)
    init <- c(
      log(1.5),                      # k (shape)
      log(rt_adjusted),    # lambda0
      0.5,                           # beta1
      log(1.0),                      # scale_subject (neutral start)
      log(1.0)                       # t0
    )
  }

  ##----------------------------------------------------------------------------
  ## 4. RUN OPTIMIZATION (TWO-PASS WITH UPDATED SUBJECT EFFECTS)
  ##----------------------------------------------------------------------------
  run_optim <- function(init_par) {
    if (!is.null(t0_fixed)) {
      cat("Fitting Weibull with FIXED t0 =", round(t0_fixed, 4), "sec")
    }
    if (mse_weight > 0) {
      cat(" | quantile matching + RT prediction (weight:", mse_weight, ")...\n")
    } else {
      cat(" | via quantile matching...\n")
    }
    opt_res <- stats::optim(init_par, objective, method = "Nelder-Mead",
                           control = list(maxit = 500, reltol = 1e-6))
    cat("  Optimization complete (Loss:", round(opt_res$value, 4), ")\n")
    opt_res
  }

  opt <- run_optim(init)

    beta1_pass1 <- opt$par[3]
    t0_pass1 <- if (!is.null(t0_fixed)) t0_fixed else exp(opt$par[5])
    rt_adj_all <- pmax(rt - t0_pass1, eps)
    log_rt_adj <- log(rt_adj_all)
    for (s in 1:n_subjects) {
      idx_s <- which(subject_idx == s)
      if (length(idx_s) > 0) {
        u_s_fixed[s] <- mean(log_rt_adj[idx_s] + beta1_pass1 * A[idx_s], na.rm = TRUE)
      }
    }
    u_s_fixed <- u_s_fixed - mean(u_s_fixed, na.rm = TRUE)
    opt <- run_optim(opt$par)


  ##----------------------------------------------------------------------------
  ## 5. REPORT LOSS BREAKDOWN (for weighted objective)
  ##----------------------------------------------------------------------------
  # Re-evaluate objective components with fitted parameters to show
  # quantile vs point-prediction trade-off
  if (mse_weight > 0) {
    # Extract final parameters
    k_final <- exp(opt$par[1])
    lambda0_final <- exp(opt$par[2])
    beta1_final <- opt$par[3]
    scale_subject_final <- exp(opt$par[4])
    t0_final <- if (!is.null(t0_fixed)) t0_fixed else exp(opt$par[5])

    # Use the fixed subject effects with fitted scaling (same as used in optimization)
    subj_effects_final <- scale_subject_final * u_s_fixed[subject_idx]
    log_lambda_final <- log(lambda0_final) - beta1_final * A + subj_effects_final +
                        sigma_trial_fixed * z_trial_fixed
    lambda_vec_final <- exp(log_lambda_final)
    rt_sim_final <- t0_final + stats::qweibull(u_fixed, shape = k_final, scale = lambda_vec_final)
    sim_quantiles_final <- stats::quantile(rt_sim_final, probs = prob_seq, na.rm = TRUE)
    quantile_mse_final <- mean((obs_quantiles - sim_quantiles_final)^2)

    # Compute the same log-scale RT loss used by the optimizer
    noise_bias_final <- exp(0.5 * sigma_trial_fixed^2)
    pred_rt_final <- numeric(length(rt))
    for (i in seq_along(rt)) {
      subj_effect_final <- scale_subject_final * u_s_fixed[subject_idx[i]]
      lambda_i_final <- lambda0_final * exp(-beta1_final * A[i] + subj_effect_final)
      pred_rt_final[i] <- t0_final + lambda_i_final * gamma(1 + 1/k_final) * noise_bias_final
    }

    rt_mse_final <- mean((log(rt) - log(pred_rt_final))^2)

    # Calculate traditional R² for reference
    ss_res_final <- sum((rt - pred_rt_final)^2)
    ss_tot_final <- sum((rt - mean(rt))^2)
    r2_actual_final <- 1 - (ss_res_final / ss_tot_final)

    cat("  Loss breakdown:\n")
    cat("    Quantile MSE:", round(quantile_mse_final, 4), "| weight:", round(1 - mse_weight, 4),
        "| contribution:", round((1 - mse_weight) * quantile_mse_final, 4), "\n")
    cat("    Log-RT MSE:", round(rt_mse_final, 4), "| R²:", round(r2_actual_final, 4),
        "| weight:", round(mse_weight, 4), "| contribution:", round(mse_weight * rt_mse_final, 4), "\n")
  }

  ##----------------------------------------------------------------------------
  ## 6. EXTRACT PARAMETERS AND ESTIMATE SUBJECT EFFECTS
  ##----------------------------------------------------------------------------
  # Estimate subject effects as residual deviations from population model
  # For subject s: u_s = mean(log(observed_lambda_s) - log(predicted_lambda_s))
  # where lambda = (RT - t0) / Weibull_mean_scale

  k <- exp(opt$par[1])
  lambda0 <- exp(opt$par[2])
  beta1 <- opt$par[3]
  scale_subject <- exp(opt$par[4])  # NEW: scaling factor for subject effects
  t0 <- if (!is.null(t0_fixed)) t0_fixed else exp(opt$par[5])

  # Use the scaled subject effects (u_s_fixed estimated once, then scaled by fitted parameter)
  if (n_subjects > 1) {
    subject_effect_map <- scale_subject * u_s_fixed
    names(subject_effect_map) <- unique_subjects
  } else {
    subject_effect_map <- NULL
  }
  sigma_subject <- if (n_subjects > 1) {
    stats::sd(as.numeric(u_s_fixed), na.rm = TRUE)
  } else {
    0
  }

  # Post-hoc estimate of trial noise from residuals in log(scale) space
  subj_effects_by_trial <- scale_subject * u_s_fixed[subject_idx]
  rt_adj_post <- pmax(rt - t0, eps)
  resid_log_lambda <- log(rt_adj_post) -
    (log(lambda0) - beta1 * A + subj_effects_by_trial)
  sigma_trial <- stats::sd(resid_log_lambda, na.rm = TRUE)

  ##----------------------------------------------------------------------------
  ## 7. VARIANCE PARTITIONING
  ##----------------------------------------------------------------------------
  # Decompose log(lambda) variance into three components:
  #   var(log_lambda) = beta1^2 * var(A) + var(subject_effects) + sigma_trial^2
  # Each component represents:
  #   - Activation: Effect of learning/success probability on RT
  #   - Subject: Stable individual differences (fast vs slow responders)
  #   - Trial: Trial-to-trial noise/randomness

  var_activation <- beta1^2 * stats::var(A, na.rm = TRUE)
  var_subject <- scale_subject^2 * stats::var(u_s_fixed, na.rm = TRUE)  # Actual variance of scaled subject effects
  var_trial <- sigma_trial^2
  var_total <- var_activation + var_subject + var_trial

  prop_activation <- var_activation / var_total
  prop_subject <- var_subject / var_total
  prop_trial <- var_trial / var_total

  # Store max RT for truncation
  max_rt_obs <- max(rt, na.rm = TRUE)

  # Calculate R² for the final model (marginal mean predictions with subject effects)
  noise_bias_post <- exp(0.5 * sigma_trial^2)
  pred_rt_final <- numeric(length(rt))
  for (i in seq_along(rt)) {
    # Get estimated subject effect using subject_idx
    if (!is.null(subject_effect_map) && n_subjects > 1) {
      subj_effect <- subject_effect_map[subject_idx[i]]
    } else {
      subj_effect <- 0
    }
    lambda_i_final <- lambda0 * exp(-beta1 * A[i] + subj_effect)
    pred_rt_final[i] <- t0 + lambda_i_final * gamma(1 + 1/k) * noise_bias_post
  }
  ss_res_final <- sum((rt - pred_rt_final)^2)
  ss_tot_final <- sum((rt - mean(rt))^2)
  r_squared_final <- 1 - (ss_res_final / ss_tot_final)

  cat("  Final R² (with total subject effects):", round(r_squared_final, 4), "\n")

  ##----------------------------------------------------------------------------
  ## 8. CREATE PREDICTION FUNCTION
  ##----------------------------------------------------------------------------
  # Returns closure that predicts RT from probability p
  # Modes:
  #   - add_noise=FALSE: Deterministic (marginal mean RT given p and subject effect)
  #   - add_noise=TRUE: Stochastic (sample with trial noise, matches real distribution)

  predict_fun <- function(pnew, subject_effect = 0, add_noise = FALSE,
                          truncate = TRUE, return_components = FALSE) {
    pnew <- as.numeric(pnew)
    pnew <- pmax(pmin(pnew, 1 - eps), eps)
    A_new <- stats::qlogis(pnew)
    lambda_base <- lambda0 * exp(-beta1 * A_new)

    if (add_noise) {
      # Vary scale parameter, then sample from Weibull
      # Add subject effect and trial noise to log(scale)
      trial_noise <- stats::rnorm(length(pnew), 0, sigma_trial)
      log_lambda_i <- log(lambda_base) + subject_effect + trial_noise
      lambda_i <- exp(log_lambda_i)

      # Draw from Weibull with noisy scale parameter and add t0.
      weibull_u <- stats::runif(length(pnew))
      rt_sim <- t0 + stats::qweibull(weibull_u, shape = k, scale = lambda_i)

      # Truncate at observed max if requested
      if (truncate) {
        rt_sim <- pmin(rt_sim, max_rt_obs)
      }
      if (return_components) {
        return(list(
          rt = rt_sim,
          trial_noise = trial_noise,
          log_lambda = log_lambda_i,
          lambda = lambda_i,
          weibull_u = weibull_u
        ))
      }
      rt_sim
    } else {
      # Deterministic prediction (marginal mean, with optional subject effect)
      noise_bias <- exp(0.5 * sigma_trial^2)
      rt_det <- t0 + lambda_base * gamma(1 + 1/k) * exp(subject_effect) * noise_bias
      if (return_components) {
        return(list(
          rt = rt_det,
          trial_noise = rep(0, length(pnew)),
          log_lambda = log(lambda_base) + subject_effect,
          lambda = lambda_base * exp(subject_effect),
          weibull_u = rep(NA_real_, length(pnew))
        ))
      }
      rt_det
    }
  }

  list(
    k = k,
    lambda0 = lambda0,
    beta1 = beta1,
    scale_subject = scale_subject,  # NEW: fitted scaling factor for subject effects
    sigma_trial = sigma_trial,
    t0 = t0,
    sse = opt$value,
    r_squared = r_squared_final,
    conv = opt$convergence,
    n_obs = length(rt),
    n_subjects = if (!is.null(subject_id)) n_subjects else NA,
    max_rt = max(rt, na.rm = TRUE),
    sigma_subject = sigma_subject,
    subject_effects = subject_effect_map,
    var_partition = list(
      activation = prop_activation,
      subject = prop_subject,
      trial = prop_trial
    ),
    predict = predict_fun
  )
}



#' @title computeSpacingPredictors
#' @description Compute repetition spacing time based features from input data CF..Time. and/or CF..reltime.
#' @description which will be automatically computed from Duration..sec. if not present themselves.
#' @param data is a dataset with Anon.Student.Id and CF..ansbin.
#' @param KCs are the components for which spaced features will be specified in LKT
#' @return data which is the same frame with the added spacing relevant columns.
#' @export
computeSpacingPredictors <- function(data, KCs) {
  if (!("CF..reltime." %in% colnames(data))) {
    data$CF..reltime. <- practiceTime(data)
  }
  if (!("CF..Time." %in% colnames(data))) {
    data$CF..Time. <- data$CF..reltime.
  }
  for (i in KCs) {
    data$index <- paste(eval(parse(text = paste("data$", i, sep = ""))), data$Anon.Student.Id, sep = "")
    eval(parse(text = paste("data$", i, "spacing <- componentspacing(data,data$index,data$CF..Time.)", sep = "")))
    #eval(parse(text = paste("data$", i, "previousstudy <- prevstudy(data,data$index,data$Outcome)", sep = "")))
    eval(parse(text = paste("data$", i, "relspacing <- componentspacing(data,data$index,data$CF..reltime.)", sep = "")))
    eval(parse(text = paste("data$", i, "prev <- componentprev(data,data$index,data$CF..ansbin.)", sep = "")))
    eval(parse(text = paste("data$", i, "meanspacing <- meanspacingf(data,data$index,data$", i, "spacing)", sep = "")))
    eval(parse(text = paste("data$", i, "relmeanspacing <- meanspacingf(data,data$index,data$", i, "relspacing)", sep = "")))
    eval(parse(text = paste("data$", i, "spacinglagged <- laggedspacingf(data,data$index,data$", i, "spacing)", sep = "")))
  }
  return(data)
}

#' @title LKT
#' @import lme4
#' @import glmnet
#' @importFrom glmnetUtils cva.glmnet
#' @import data.table
#' @import LiblineaR
#' @import Matrix
#' @import cluster
#' @description Compute a logistic regression model of learning for input data.
#' @param data A dataset with Anon.Student.Id and CF..ansbin.
#' @param components A vector of factors that can be used to compute each features for each subject.
#' @param features a vector methods to use to compute a feature for the component.
#' @param connectors Character vector of formula operators ("+", ":", "*"); defaults to "+" if unspecified
#' @param fixedpars a vector of parameters for all features+components.
#' @param seedpars a vector of parameters for all features+components to seed non-linear parameter search.
#' @param interacts A list of components that interacts with component by feature in the main specification.
#' @param curvefeats vector of columns to use with "diff" functions
#' @param dualfit TRUE or FALSE, fit a simple latency using logit. Requires Duration..sec. column in data.
#' @param interc TRUE or FALSE, include a global intercept.
#' @param verbose provides more output in some cases.
#' @param epsilon passed to LiblineaR
#' @param cost passed to LiblineaR
#' @param lowb lower bound for non-linear optimizations
#' @param highb upper bound for non-linear optimizations
#' @param type passed to LiblineaR
#' @param maketimes Boolean indicating whether to create time based features (or may be precomputed)
#' @param bias passed to LiblineaR
#' @param maxitv passed to nonlinear optimization a maxit control
#' @param autoKC a vector to indicate whether to use autoKC for the component (0) or the k for the numebr of clusters
#' @param autoKCcont a vector of text strings set to "rand" for component to make autoKC assignment to cluster is randomized (for comaprison)
#' @param nosolve causes the function to return a sparse data matrix of the features, rather than a solution
#' @param factrv controls the optim() function
#' @param usefolds Numeric Vector | Specifies the folds for model fitting in LKT; the features are still calculated across all folds to compute test fold fit externally
#' @param distribution Latency model distribution: "exp" (default) or "Weibull". Requires dualfit=TRUE and Duration..sec. column.
#' @param weibull_mse_weight Weight for RT prediction component in Weibull fitting (0-1, default 0). Typical range: 0.0001-0.001 for light regularization.
#' @param weibull_t0_fixed Optional fixed value for t0 (minimum RT in seconds). If provided, t0 will not be optimized. Default NULL estimates t0 from data.
#' @param latency_question_type_filter Optional string to filter RT data by question type. If provided, only trials where CF..Question.Type. equals this value will be used for latency model fitting (e.g., "Multiple Choice"). Default NULL uses all trials.
#' @return list of values "model", "coefs", "r2", "prediction", "nullmodel", "latencymodel", "optimizedpars","subjectrmse", "newdata", and "automat"
#' @export
LKT <- function(data,usefolds = NA,
                components,
                features,
                fixedpars = NA,
                seedpars = NA,
                interacts = NA,
                curvefeats = NA,
                dualfit = FALSE,
                interc = FALSE,
                verbose = TRUE,
                epsilon = 1e-4,
                cost = 512,
                lowb=.00001,
                highb=.99999,
                type = 0,
                maketimes = FALSE,
                bias = 0,
                maxitv=100,
                factrv=1e12,
                nosolve=FALSE,
                autoKC=rep(0,length(components)),
                autoKCcont = rep("NA",length(components)),
                connectors= rep("+",max(1,length(components)-1)),
                distribution = "exp",
                weibull_mse_weight = 0,
                weibull_t0_fixed = NULL,
                latency_question_type_filter = NULL) {
  connectors<-c("+",connectors)
  if (maketimes) {
    if (!("CF..reltime." %in% colnames(data))) {
      data$CF..reltime. <- practiceTime(data)
    }
    if (!("CF..Time." %in% colnames(data))) {
      data$CF..Time. <- data$CF..reltime.
    }
  }
  if (!("Outcome" %in% colnames(data))) {
    data$Outcome <- ifelse(data$CF..ansbin. == 1, "CORRECT", "INCORRECT")
  }
  if (!("CF..ansbin." %in% colnames(data))) {
    data$CF..ansbin. <- ifelse(data$Outcome == "CORRECT", 1, 0)
  }


  # Check for spacing predictor requirements and auto-compute if needed

  spacing_dependent_features <- c("recency", "recencystudy", "recencytest", "recencysuc", "recencyfail", "ppe", "ppes", "ppef")

  # Check each feature-component pair for spacing predictor requirements
  missing_spacing_components <- c()
  features_needing_spacing <- c()

  for (i in 1:length(features)) {
    feature <- gsub("[$@]", "", features[i])
    component <- components[i]

    # Check if this feature needs spacing predictors
    if (feature %in% spacing_dependent_features) {
      features_needing_spacing <- c(features_needing_spacing, feature)

      # Check if spacing columns exist for this specific component
      spacing_col <- paste0(component, "spacing")
      if (!spacing_col %in% colnames(data)) {
        missing_spacing_components <- c(missing_spacing_components, component)
      }
    }
  }

  # Remove duplicates
  features_needing_spacing <- unique(features_needing_spacing)
  missing_spacing_components <- unique(missing_spacing_components)

  # Auto-compute missing spacing predictors with user feedback
  if (length(missing_spacing_components) > 0) {
    if (verbose) {
      cat("LKT: Features", paste(features_needing_spacing, collapse = ", "),
          "require spacing predictors.\n")
      cat("LKT: Auto-computing spacing predictors for components:",
          paste(missing_spacing_components, collapse = ", "), "...\n")
    }

    for (comp in missing_spacing_components) {
      if (verbose) {
        cat("LKT: Computing spacing predictors for component '", comp, "'...\n", sep = "")
      }
      data <- suppressWarnings(computeSpacingPredictors(data, comp))
    }

    if (verbose) {
      cat("LKT: Spacing predictors computed successfully. Proceeding with model fitting.\n")
    }
  }

  equation <- "CF..ansbin.~ "
  e <- new.env()

  # will collect per‑feature nonlinear parameters as we loop

  param_tracker <- vector("list", length(features))
  names(param_tracker) <- gsub("[@$]", "", features)   # strip suffixes

  e$data <- data
  e$fixedpars <- fixedpars
  e$seedpars <- seedpars
  e$counter <- 0
  e$flag <- FALSE
  e$df<-list()
  modelfun <- function(seedparameters) {
    # initialize counts and vars for this optimization step
    k <- 0
    optimparcount <- 1
    fixedparcount <- 1
    m <- 1
    if (interc == TRUE) {
      eq <- "1"
    } else {
      eq <- "0"
    }

    e$counter <- e$counter + 1
    for (i in features) {
      k <- k + 1

      # prepare feature inputs

      #setup the curvilinear feature input for inverted U shaped learning features
      if(!is.na(curvefeats[k])){
        e$data$curvefeat<- paste(eval(parse(text = paste("e$data$", curvefeats[k],sep = ""))), sep = "")
        e$data$curvefeat<-as.numeric(e$data$curvefeat)
      }
      else if ("pred" %in% colnames(e$data)){
        e$data$curvefeat<-e$data$pred
      }


      # retrieve nonlinear parameters for i

      if (gsub("[$@]", "", i) %in% c(
        "powafm", "recency", "recencystudy", "recencytest","recencysuc", "recencyfail", "errordec", "propdec", "propdec2",
        "logitdec","logitdecevol","baseratepropdec", "base", "expdecafm", "expdecsuc", "expdecfail", "dashafm", "dashsuc", "dashfail",
        "base2", "base4", "basesuc", "basefail", "logit", "base2suc", "base2fail", "ppe", "ppes", "ppef",
        "base5suc", "base5fail","logsucadj"
      )) {
        if (is.na(e$fixedpars[m])) { # if not fixed them optimize it
          para <- seedparameters[optimparcount]
          e$flag <- TRUE
          optimparcount <- optimparcount + 1
        }
        else {
          if (e$fixedpars[m] >= 1 & e$fixedpars[m] %% 1 == 0) { # if fixed is set to 1 or more, interpret it as an indicator to use optimized parameter
            para <- seedparameters[e$fixedpars[m]]
          } else {
            para <- e$fixedpars[m]
          }
        } # otherwise just use it
        m <- m + 1
      }
      if (gsub("[$]", "", i) %in% c("base2", "base4", "base2suc", "base2fail", "ppe", "ppes", "ppef", "base5suc", "base5fail")) {
        if (is.na(e$fixedpars[m])) {
          parb <- seedparameters[optimparcount]
          optimparcount <- optimparcount + 1
        }
        else {
          if (e$fixedpars[m] >= 1 & e$fixedpars[m] %% 1 == 0) {
            parb <- seedparameters[e$fixedpars[m]]
          } else {
            parb <- e$fixedpars[m]
          }
        }
        m <- m + 1
      }
      if (gsub("[$]", "", i) %in% c("base4", "ppe", "ppes", "ppef", "base5suc", "base5fail")) {
        if (is.na(e$fixedpars[m])) {
          parc <- seedparameters[optimparcount]
          optimparcount <- optimparcount + 1
        }
        else {
          if (e$fixedpars[m] >= 1 & e$fixedpars[m] %% 1 == 0) {
            parc <- seedparameters[e$fixedpars[m]]
          } else {
            parc <- e$fixedpars[m]
          }
        }
        m <- m + 1
      }
      if (gsub("[$]", "", i) %in% c("base4", "ppe", "ppes", "ppef", "base5suc", "base5fail")) {
        if (is.na(e$fixedpars[m])) {
          pard <- seedparameters[optimparcount]
          optimparcount <- optimparcount + 1
        }
        else {
          if (e$fixedpars[m] >= 1 & e$fixedpars[m] %% 1 == 0) {
            pard <- seedparameters[e$fixedpars[m]]
          } else {
            pard <- e$fixedpars[m]
          }
        }
        m <- m + 1
      }
      if (gsub("[$]", "", i) %in% c("base5suc", "base5fail")) {
        if (is.na(e$fixedpars[m])) {
          pare <- seedparameters[optimparcount]
          optimparcount <- optimparcount + 1
        }
        else {
          if (e$fixedpars[m] >= 1 & e$fixedpars[m] %% 1 == 0) {
            pare <- seedparameters[e$fixedpars[m]]
          } else {
            pare <- e$fixedpars[m]
          }
        }
        m <- m + 1
      }

      #
      # optional clustering of components using PAM when
      # autoKC[k] specifies a number of clusters
      #
      if (autoKC[k] > 1) {
        # Clearing the 'CF..ansbin.' variable in preparation for aggregation
        CF..ansbin.<-NULL

        # Aggregating the data by the specified component and student ID, computing the mean of 'CF..ansbin.'
        aggdata <- e$data[,mean(CF..ansbin.), by=list(eval(parse(text=components[k])), Anon.Student.Id)]
        colnames(aggdata) <- c(components[k],'Anon.Student.Id','CF..ansbin.')
        aggdata <- aggdata[with(aggdata, order(eval(parse(text=components[k])))),]

        # Reshaping aggregated data to wide format, making students the columns
        mydata <- eval(parse(text=paste('dcast(aggdata,',components[k],' ~ Anon.Student.Id, value.var="CF..ansbin.")')))
        rownamesmydata <- eval(parse(text=paste('mydata$', components[k])))
        mydata <- mydata[,-1]  # Remove the first column containing component names

        # Replace NA values in the matrix with the mean of their respective columns
        nm <- names(mydata)[colSums(is.na(mydata)) != 0]
        mydata[, (nm) := lapply(nm, function(x) {
          x <- get(x)
          x[is.na(x)] <- mean(x, na.rm = TRUE)
          x
        })]

        # Apply logit transformation and limit extreme values
        mydata <- log(mydata/(1-mydata))
        mydata[mydata > 2] <- 2
        mydata[mydata < -2] <- -2
        rownames(mydata) <- rownamesmydata

        # Normalize the features by subtracting the mean from each
        mydata[, names(mydata) := lapply(.SD, function(x) x - mean(x)), .SDcols = names(mydata)]
        df <- mydata[, as.matrix(.SD) %*% t(as.matrix(.SD)), .SDcols = names(mydata)]
        df <- df / nrow(df)
        rownames(df) <- 1:nrow(mydata)
        colnames(df) <- rownames(mydata)
        rownames(df) <- colnames(df)

        # Cluster the features using Partitioning Around Medoids (PAM)
        cm <- pam(df, autoKC[k])
        KCmodel <- as.data.frame(cm$clustering)
        colnames(KCmodel)[1] <- paste("AC", k, sep="")

        # Convert cluster labels to character
        eval(parse(text=paste(sep="", "KCmodel$AC", k, "<-as.character(KCmodel$AC", k, ")")))

        # Optionally randomize cluster labels
        if (autoKCcont[k] == "rand") {
          eval(parse(text=paste(sep="", "KCmodel$AC", k, "<-sample(KCmodel$AC", k, ")")))
        }

        # Add cluster labels back to the main data frame
        KCmodel$rows <- rownames(KCmodel)
        e$df <- c(list(KCmodel), e$df)
        e$data <- merge(e$data, KCmodel, by.y = 'rows', by.x = components[k], sort = FALSE)
        components[k] <- paste("AC", k, sep="")
        e$data <- e$data[order(e$data$Anon.Student.Id, e$data$CF..Time.),]
      }

      if (e$flag == TRUE | e$counter < 2) {


        # build student-by-component indices and counts

        if (length(grep("%", components[k]))) {
          KCs <- strsplit(components[k], "%")


          e$data$index <- paste(eval(parse(text = paste("e$data$", KCs[[1]][1], sep = ""))), e$data$Anon.Student.Id, sep = "")
         e$data$indexcomp <- paste(eval(parse(text = paste("e$data$", KCs[[1]][1], sep = ""))), sep = "")


          #e$data$cor <- as.numeric(paste(eval(parse(text = paste("countOutcomeGen(e$data,e$data$index,\"CORRECT\",e$data$", KCs[[1]][2], ",\"", KCs[[1]][3], "\")", sep = "")))))
          #e$data$icor <- as.numeric(paste(eval(parse(text = paste("countOutcomeGen(e$data,e$data$index,\"INCORRECT\",e$data$", KCs[[1]][2], ",\"", KCs[[1]][3], "\")", sep = "")))))

          e$data$cor <- as.numeric(eval(parse(text = paste0(
            "countOutcomeGen(e$data, e$data$index, \"CORRECT\", e$data$", KCs[[1]][2],
            ", ", shQuote(KCs[[1]][3]), ")"

          ))))
          e$data$icor <- as.numeric(eval(parse(text = paste0(
            "countOutcomeGen(e$data, e$data$index, \"INCORRECT\", e$data$", KCs[[1]][2],
            ", ", shQuote(KCs[[1]][3]), ")"
          ))))

        }
        else # count an effect when both counted factor level and recipient factor level are specified
          if (length(grep("\\?", components[k]))) {
            KCs <- strsplit(components[k], "\\?")
            e$data$indexcomp <- NULL
            e$data$cor <- as.numeric(paste(eval(parse(text = paste("countOutcomeOther(e$data,e$data$Anon.Student.Id,\"CORRECT\",e$data$", KCs[[1]][3], ",\"", KCs[[1]][4], "\",e$data$", KCs[[1]][1], ",\"", KCs[[1]][2], "\")", sep = "")))))
            e$data$icor <- as.numeric(paste(eval(parse(text = paste("countOutcomeOther(e$data,e$data$Anon.Student.Id,\"INCORRECT\",e$data$", KCs[[1]][3], ",\"", KCs[[1]][4], "\",e$data$", KCs[[1]][1], ",\"", KCs[[1]][2], "\")", sep = "")))))
          }
        else { # normal KC type Q-matrix
          Anon.Student.Id<-index<-indexcomp<-NULL
          vec <- eval(parse(text = paste0("e$data$", components[k])))
          e$data[, index := do.call(paste0, list(vec, Anon.Student.Id))]
          e$data[, indexcomp := vec]
          if (!(i %in% c("numer", "intercept"))) {
            e$data$cor <- countOutcome(e$data, e$data$index, "CORRECT")
            e$data$icor <- countOutcome(e$data, e$data$index, "INCORRECT")
          }
        }
        components[k]<-gsub("\\s+", "", components[k])
        e$flag <- FALSE

        # computefeatures called ----
        if (right(i, 1) == "@") {
          # random effect: store feature as random intercept
          eval(parse(text = paste("e$data$", components[k],
                                  "<-computefeatures(e$data,i,para,parb,e$data$index,e$data$indexcomp,
                              parc,pard,pare,components[k])",
                                  sep = ""
          )))
        } else {
          # fixed effect: create single column feature
          if(nosolve==FALSE)
            {
            eval(parse(text = paste("e$data$", gsub("\\$", "", i), gsub("[%]", "", components[k]),
                                    "<-computefeatures(e$data,i,para,parb,e$data$index,e$data$indexcomp,
                              parc,pard,pare,components[k])", sep = "")))}
          else
            {
            eval(parse(text = paste("e$data$", gsub("\\$", "", i),if(exists("para"))
                                      {para}else{""}, gsub("[%]", "", components[k]),
                                      "<-computefeatures(e$data,i,para,parb,e$data$index,e$data$indexcomp,
                                        parc,pard,pare,components[k])",sep = "")))
                                    }
        }
      }




      if (verbose) {
        cat(paste(
          i, components[k], if (exists("para")) {
            para
          },
          if (exists("parb")) {
            parb
          }, if (exists("parc")) {
            parc
          },
          if (exists("pard")) {
            pard
          }, if (exists("pare")) {
            pare
          }, "\n"
        ))
      }

      # choose how this feature connects in the formula
      if (connectors[k] == "*") {
        connector <- "*"
      } else if (connectors[k] == ":") {
        connector <- ":"
      } else {
        connector <- "+"
      }
      if (right(i, 1) == "$") {
        # add the fixed effect feature to the model with a coefficient per level
        cleanfeat <- gsub("\\$", "", i)
        if (is.na(interacts[k])) {
          # standard way with a coefficient per component
          if(nosolve==FALSE){eval(parse(text = paste("eq<-paste(cleanfeat,components[k],\":e$data$\",components[k],
                                connector,eq,sep=\"\")")))}else{
                                  eval(parse(text = paste("eq<-paste(cleanfeat,if(exists(\"para\")){para}else{\"\"},components[k],\":e$data$\",components[k],
                                connector,eq,sep=\"\")")))
                                }
        }
        else {
          if(nosolve==FALSE){eval(parse(text = paste("eq<-paste(cleanfeat,components[k],\":e$data$\",components[k]
                                ,\":\",interacts[k]
                                ,connector,eq,sep=\"\")")))}else{
                                  eval(parse(text = paste("eq<-paste(cleanfeat,if(exists(\"para\")){para}else{\"\"},components[k],\":e$data$\",components[k]
                                ,\":\",interacts[k]
                                ,connector,eq,sep=\"\")")))
                                }
        }
      }

      else if (right(i, 1) == "@") {
        # add the random effect feature to the model with a coefficient per level
        eval(parse(text = paste("eq<-paste(\"(1|\",components[k],\")+\",eq,sep=\"\")")))
      }

      else {
        # add the fixed effect feature to the model with the same coefficient for all levels
        if (is.na(interacts[k])) {
          # standard way with single coefficient
          if(nosolve==FALSE){
            eval(parse(text = paste("eq<-paste(i,gsub('[%]','',components[k]),connector,eq,sep=\"\")")))
          }
          else
          {
            eval(parse(text = paste("eq<-paste(i,if(exists(\"para\")){para}else{\"\"},
                                      gsub('[%]','',components[k]),connector,eq,sep=\"\")")))
          }
        }
        else {
          if(nosolve==FALSE){
            eval(parse(text = paste("eq<-paste(i,gsub('[%]','',components[k]),\":\",interacts[k]
                                  ,connector,eq,sep=\"\")")))}else
                                  {
                                    eval(parse(text = paste("eq<-paste(i,if(exists(\"para\")){para}else{\"\"},gsub('[%]','',components[k]),\":\",interacts[k]
                                  ,connector,eq,sep=\"\")")))
                                  }}}

      # remember the parameters used for this feature

      param_tracker[[ gsub("[@$]", "", i) ]] <<-
        c(para = if (exists("para")) para else NA_real_,
          parb = if (exists("parb")) parb else NA_real_,
          parc = if (exists("parc")) parc else NA_real_,
          pard = if (exists("pard")) pard else NA_real_,
          pare = if (exists("pare")) pare else NA_real_)
      if (exists("para")) {rm(para)}
      if (exists("parb")) {rm(parb)}
      if (exists("parc")) {rm(parc)}
      if (exists("pard")) {rm(pard)}
      if (exists("pare")) {rm(pare)}
    }

    # fit main ----
    if (verbose) {
      cat(paste(eq, "\n"))
    }
    # build the regression formula from accumulated features
    e$form <- as.formula(paste(equation, eq, sep = ""))

    # choose solver: glmer for mixed models, LiblineaR otherwise
    if (any(grep("[@]", features)) & dualfit == FALSE) {
      cat(paste("Using glmer, which uses lme4 package, which is not efficient for large complex data and has memory limitations."))
      temp <- glmer(e$form, data = e$data, family = binomial(logit))
      fitstat <- logLik(temp)
    } else  {

      predictset <- sparse.model.matrix(e$form, e$data)
      predictset.csc <- new("matrix.csc",
                            ra = predictset@x,
                            ja = predictset@i + 1L,
                            ia = predictset@p + 1L,
                            dimension = predictset@Dim
      )
      predictset.csr <- as.matrix.csr(predictset.csc)
      predictset2 <- predictset.csr

      # fit with LiblineaR, repeating until valid probabilities are returned
      success <- FALSE
      if (nosolve == FALSE) {

        while (!success) {
        if( is.na(usefolds)[1]){
          temp <- LiblineaR(predictset2, e$data$CF..ansbin.,
                            bias = bias,
                            cost = cost, epsilon = epsilon, type = type)
        }else{
          temp <- LiblineaR(predictset2[e$data$fold %in% usefolds,], e$data$CF..ansbin.[e$data$fold %in% usefolds],
                            bias = bias,
                            cost = cost, epsilon = epsilon, type = type)}
        if(temp$ClassNames[1]==0){temp$W=temp$W*(-1)}
        modelvs <- data.frame(temp$W)
        colnames(modelvs) <- colnames(predictset)
        e$modelvs <- t(modelvs)
        colnames(e$modelvs) <- "coefficient"
        ####two versions
        if (is.na(usefolds)[1]) {
          e$data$pred <- pmin(pmax(
            predict(temp, predictset2, proba = TRUE)$probabilities[, 1],
            .00001
          ), .99999)

          success <- sum(is.nan(e$data$pred)) == 0 &
            sum(is.na(e$data$pred)) == 0
        }
        else{
          e$data$pred[e$data$fold %in% usefolds] <- pmin(pmax(
            predict(temp, predictset2[e$data$fold %in% usefolds, ], proba = TRUE)$probabilities[, 1],
            .00001
          ), .99999)

          success <- sum(is.nan(e$data$pred[e$data$fold %in% usefolds])) == 0 &
            sum(is.na(e$data$pred[e$data$fold %in% usefolds])) == 0

          if (verbose) {
            print(summary(e$data$pred[e$data$fold %in% usefolds]))
          }
        }}
        # check for success


        ####two versions
        e$predictset2=predictset2

        if( is.na(usefolds)[1])
        {fitstat <- sum(log(ifelse(e$data$CF..ansbin. == 1, e$data$pred, 1 - e$data$pred)))}
        else
        {fitstat <- sum(log(ifelse(e$data$CF..ansbin.[e$data$fold %in% usefolds] == 1,
                                   e$data$pred[e$data$fold %in% usefolds],
                                   1 - e$data$pred[e$data$fold %in% usefolds])))}}}


        ## latency model ----
        if (dualfit == TRUE) { #  latency model fitting
          # Step 1: Identify correct response trials
          correct_idx <- which(e$data$CF..ansbin. == 1)

          # Step 2: Extract data for correct responses only
          correct_rt <- e$data$Duration..sec.[correct_idx]
          correct_pred <- e$data$pred[correct_idx]

          # Step 3: Detect outliers using quantile method (safer than value matching)
          q1 <- quantile(correct_rt, 0.25, na.rm = TRUE)
          q3 <- quantile(correct_rt, 0.75, na.rm = TRUE)
          iqr <- q3 - q1
          lower_bound <- q1 - 1.5 * iqr
          upper_bound <- q3 + 1.5 * iqr

          outlier_idx_within_correct <- which(correct_rt < lower_bound | correct_rt > upper_bound)

          # Step 4: Remove outliers from rt, predictions, and subject IDs (keep aligned)
          correct_subject_id <- e$data$Anon.Student.Id[correct_idx]
          if (length(outlier_idx_within_correct) > 0) {
            clean_rt <- correct_rt[-outlier_idx_within_correct]
            clean_pred <- correct_pred[-outlier_idx_within_correct]
            clean_subject_id <- correct_subject_id[-outlier_idx_within_correct]
          } else {
            clean_rt <- correct_rt
            clean_pred <- correct_pred
            clean_subject_id <- correct_subject_id
          }

          # Step 5: Branch based on distribution type
          if (distribution == "exp") {
            # Exponential distribution fitting (original method)
            # Transform clean predictions to response time scale
            rt.pred.base <- exp(-qlogis(clean_pred))

            # Fit model with perfectly aligned clean data
            e$lm.rt <- lm(clean_rt ~ as.numeric(rt.pred.base))
            fitstat2 <- cor(clean_rt, predict(e$lm.rt, type = "response"))^2
            rt.predicted <- predict(e$lm.rt, type = "response")

            if (verbose) {
              # Debugging output for exponential latency model
              cat("=== LATENCY MODEL DEBUGGING (EXPONENTIAL) ===\n")
              cat("Original correct responses:", length(correct_rt), "\n")
              cat("Outliers removed:", length(outlier_idx_within_correct), "\n")
              cat("Clean data points:", length(clean_rt), "\n")
              coeffs <- coef(e$lm.rt)
              cat("Latency Intercept:", round(coeffs[1], 6), "\n")
              cat("Latency Scalar (F):", round(coeffs[2], 6), "\n")
              cat(paste("R2 (cor squared) latency: ", fitstat2, "\n", sep = ""))

              # Create histograms with matching x-axis for response times
              # Clean up any Rplots.pdf that gets created
              on.exit({
                if (file.exists("Rplots.pdf")) file.remove("Rplots.pdf")
              })

              par(mfrow = c(2, 2))

              # Calculate common x-axis range for response time plots
              rt_range <- range(c(clean_rt, rt.predicted), na.rm = TRUE)

              hist(clean_rt, main = "Clean Response Times", xlab = "Response Time (sec)", col = "lightblue", xlim = rt_range,breaks=40)
              hist(clean_pred, main = "Clean Predictions (Probability)", xlab = "Probability", col = "lightgreen")
              hist(rt.predicted, main = "Predicted Response Times", xlab = "Response Time (sec)", col = "orange", xlim = rt_range,breaks=40)
              plot(rt.predicted, clean_rt, main = "rt.pred vs clean_rt", xlab = "rt.pred", ylab = "clean_rt", xlim = rt_range, ylim = rt_range)
              abline(e$lm.rt, col = "red", lwd = 2)
              par(mfrow = c(1, 1))

              cat("=== END LATENCY DEBUGGING ===\n")
            }
          } else if (distribution == "Weibull") {
            ##------------------------------------------------------------------
            ## WEIBULL RT MODEL: Hybrid Variance Approach
            ##------------------------------------------------------------------

            ##--- Step 1: Prefit t0 for noise estimation (does not fix t0) ---##
            t0_prefit <- if (!is.null(weibull_t0_fixed)) weibull_t0_fixed else min(clean_rt, na.rm = TRUE)

            ##--- Step 2: Prefit sigma_trial ---##
            # Estimate trial noise after partialling out activation and subject effects.
            # Compute log(RT - t0) to work in additive log-space.
            if (verbose) {
              cat("Prefit t0 for noise estimate:", round(t0_prefit, 3), "sec\n")
            }
            log_rt_adjusted <- log(pmax(clean_rt - t0_prefit, 1e-6))
            A_prefit <- stats::qlogis(pmin(pmax(clean_pred, 1e-6), 1 - 1e-6))
            if (length(unique(clean_subject_id)) > 1) {
              prefit_df <- data.frame(log_rt_adjusted = log_rt_adjusted,
                                      A = A_prefit,
                                      subj = factor(clean_subject_id))
              prefit_fit <- stats::lm(log_rt_adjusted ~ A + subj, data = prefit_df)
            } else {
              prefit_df <- data.frame(log_rt_adjusted = log_rt_adjusted, A = A_prefit)
              prefit_fit <- stats::lm(log_rt_adjusted ~ A, data = prefit_df)
            }
            sigma_trial_init <- stats::sd(prefit_fit$residuals, na.rm = TRUE)

            if (verbose) {
              cat("Sigma_trial initial estimate:", round(sigma_trial_init, 4),
                  "(prefit residual SD; fixed for quantile matching)\n")
            }

            ##--- Step 3: Fit Weibull Model ---##
            # Optimize k, lambda0, beta1, scale_subject (t0 optional) with fixed subject effects
            weibull_fit <- fit_weibull_activation(
              rt = clean_rt,
              p  = clean_pred,
              subject_id = clean_subject_id,
              sigma_trial_init = sigma_trial_init,      # reference only (not optimized)
              mse_weight = weibull_mse_weight,
              t0_fixed = weibull_t0_fixed)

            ##--- Step 4: Generate Predictions ---##
            # Two types: stochastic (with noise) and deterministic (mean prediction)

            # Look up subject effects for each observation
            clean_subject_effects <- sapply(as.character(clean_subject_id), function(sid) {
              eff <- weibull_fit$subject_effects[sid]
              if (is.na(eff)) 0 else eff
            })

            # Stochastic predictions using fitted trial noise for shape fidelity
            rt.predicted <- weibull_fit$predict(clean_pred,
                                                subject_effect = clean_subject_effects,
                                                add_noise = TRUE,
                                                truncate = FALSE)
            fitstat2 <- cor(clean_rt, rt.predicted, use = "complete.obs")^2
            # Deterministic predictions (no trial noise) for clearer activation signal
            rt.predicted_det <- weibull_fit$predict(clean_pred,
                                                    subject_effect = clean_subject_effects,
                                                    add_noise = FALSE,
                                                    truncate = FALSE)

            e$weibull.rt <- weibull_fit
            ##--- Step 5: Diagnostics (if verbose) ---##
            # Print parameters, variance partitioning, fit quality, plots
            if (verbose) {
              if (weibull_mse_weight > 0) {
                cat("\n=== WEIBULL LATENCY MODEL (QUANTILE + RT PREDICTION) ===\n")
                cat("Objective weights: Quantile =", 1 - weibull_mse_weight, "| RT =", weibull_mse_weight, "\n")
              } else {
                cat("\n=== WEIBULL LATENCY MODEL (QUANTILE MATCHING) ===\n")
              }
              cat("Data:\n")
              cat("  Trials used for fitting:", length(clean_rt),
                  "(IQR-filtered from", length(correct_rt), "correct trials)\n")
              cat("  Unique subjects:", weibull_fit$n_subjects, "\n")
              cat("\nFitted Parameters:\n")
              cat("  Shape (k):", round(weibull_fit$k, 4), "\n")
              cat("  Lambda0:", round(weibull_fit$lambda0, 4), "\n")
              cat("  Beta1 (activation):", round(weibull_fit$beta1, 4), "\n")
              cat("  Scale_subject (subject scaling):", round(weibull_fit$scale_subject, 4), "\n")
              cat("  t0 (min RT):", round(weibull_fit$t0, 4), "sec\n")
              cat("\nPost-hoc Parameters:\n")
              cat("  Sigma_trial:", round(weibull_fit$sigma_trial, 4), "\n")
              if (!is.null(weibull_fit$subject_effects) &&
                  !is.null(clean_subject_id) &&
                  length(clean_subject_id) == length(clean_pred)) {
                eps <- 1e-6
                p_clamped <- pmax(pmin(clean_pred, 1 - eps), eps)
                A_by_trial <- stats::qlogis(p_clamped)
                subject_effects <- weibull_fit$subject_effects
                subj_effect_by_trial <- subject_effects[as.character(clean_subject_id)]
                activation_corr <- stats::cor(
                  A_by_trial,
                  as.numeric(subj_effect_by_trial),
                  use = "complete.obs"
                )
                cat("  corr(activation, subject effect) per-trial:", round(activation_corr, 4), "\n")
              }
              cat("\nVariance Partitioning:\n")
              cat("  Activation (beta1*A):", round(weibull_fit$var_partition$activation * 100, 1), "%\n")
              cat("  Subject effects:", round(weibull_fit$var_partition$subject * 100, 1), "%\n")
              cat("  Trial noise:", round(weibull_fit$var_partition$trial * 100, 1), "%\n")
              cat("\nFit Quality:\n")
              cat("  Combined loss:", round(weibull_fit$sse, 4), "\n")
              cat("  R² (deterministic):", round(weibull_fit$r_squared, 4), "\n")
              cat("  Convergence:", weibull_fit$conv, "\n")
              cat("  R² (stochastic sim):", round(fitstat2, 4), "\n")
              on.exit({ if (file.exists("Rplots.pdf")) file.remove("Rplots.pdf") })
              par(mfrow = c(2, 2))
              rt_plot_max <- 30
              rt_breaks <- seq(0, rt_plot_max, by = 1)
              rt_keep <- clean_rt <= rt_plot_max
              hist(clean_rt[rt_keep], main = "Clean Response Times", xlab = "Response Time (sec)",
                   col = "lightblue", xlim = c(0, rt_plot_max), breaks = rt_breaks)
              hist(clean_pred, main = "Clean Predictions (Probability)", xlab = "Probability",
                   col = "lightgreen")
              # Use fixed 1-second bins up to rt_plot_max for comparability
              pred_keep <- rt.predicted <= rt_plot_max
              hist(rt.predicted[pred_keep], main = "Predicted Response Times (Weibull Quantile Fit)",
                   xlab = "Response Time (sec)", col = "orange", xlim = c(0, rt_plot_max),
                   breaks = rt_breaks)
              scatter_keep <- rt.predicted <= rt_plot_max & clean_rt <= rt_plot_max
              plot(rt.predicted[scatter_keep], clean_rt[scatter_keep],
                   main = "Stochastic sim vs clean_rt",
                   xlab = "Weibull pred (stochastic)", ylab = "clean_rt",
                   xlim = c(0, rt_plot_max), ylim = c(0, rt_plot_max))
              abline(0, 1, col = "red", lwd = 2)
              par(mfrow = c(1, 1))
            }
          }

          else {
            stop("Unknown distribution type: ", distribution, ". Must be 'exp' or 'Weibull'")
          }
        }


        if(nosolve==FALSE){
          e$temp <- temp
          if( is.na(usefolds)[1]){
            e$nullmodel <- glm(as.formula(paste("CF..ansbin.~ 1", sep = "")), data = e$data, family = binomial(logit))
          }else{
            e$nullmodel <- glm(as.formula(paste("CF..ansbin.~ 1", sep = "")), data = e$data[e$data$fold %in% usefolds,],
                               family = binomial(logit))        }
          e$nullfit <- logLik(e$nullmodel)
          e$loglike <- fitstat
          e$mcfad <- round(1 - fitstat[1] / e$nullfit[1], 6)
          if (verbose) {
            cat(paste("McFadden's R2 logistic:", e$mcfad, "\n"))
            cat(paste("LogLike logistic:", round(fitstat, 8), "\n"))
          }
          if (length(seedparameters) > 0 & verbose) {
            cat(paste("step par values ="))
            cat(seedparameters, sep = ",")
            cat(paste("\n\n"))
          }
          -fitstat[1]
        } else {list(
          colnames(predictset),predictset2)}
      }



  if(nosolve==FALSE){
    parlength <-
      sum("powafm" == gsub("[$]", "", features)) +
      sum("recency" == gsub("[$]", "", features)) +
      sum("recencystudy" == gsub("[$]", "", features)) +
      sum("recencytest" == gsub("[$]", "", features)) +
      sum("recencysuc" == gsub("[$]", "", features)) +
      sum("recencyfail" == gsub("[$]", "", features)) +
      sum("logit" == gsub("[$]", "", features)) +
      sum("errordec" == gsub("[$]", "", features)) +
      sum("propdec" == gsub("[$]", "", features)) +
      sum("propdec2" == gsub("[$]", "", features)) +
      sum("logitdec" == gsub("[$]", "", features)) +
      sum("logsucadj" == gsub("[$]", "", features)) +
      sum("logitdecevol" == gsub("[$]", "", features)) +
      sum("baseratepropdec" == gsub("[$]", "", features)) +
      sum("base" == gsub("[$]", "", features)) +
      sum("expdecafm" == gsub("[$]", "", features)) +
      sum("expdecsuc" == gsub("[$]", "", features)) +
      sum("expdecfail" == gsub("[$]", "", features)) +
      sum("base2" == gsub("[$]", "", features)) * 2 +
      sum("base4" == gsub("[$]", "", features)) * 4 +
      sum("ppe" == gsub("[$]", "", features)) * 4 +
      sum("ppes" == gsub("[$]", "", features)) * 4 +
      sum("ppef" == gsub("[$]", "", features)) * 4 +
      sum("basefail" == gsub("[$]", "", features)) +
      sum("basesuc" == gsub("[$]", "", features)) +
      sum("base2suc" == gsub("[$]", "", features)) * 2 +
      sum("base2fail" == gsub("[$]", "", features)) * 2 +
      sum("dashafm" == gsub("[$]", "", features)) +
      sum("dashsuc" == gsub("[$]", "", features)) +
      sum("dashfail" == gsub("[$]", "", features)) +
      sum("base5suc" == gsub("[$]", "", features)) * 5 +
      sum("base5fail" == gsub("[$]", "", features)) * 5 -
      sum(!is.na(e$fixedpars))

    # number of seeds is just those pars specified and not fixed
    seeds <- e$seedpars[is.na(e$fixedpars)]
    seeds[is.na(seeds)] <- .5 # if not set seeds set to .5

    # optimize the model parameters with bounded L-BFGS-B
    if (parlength > 0) {
      optimizedpars <- optim(seeds, modelfun, method = c("L-BFGS-B"), lower = lowb,
                             upper = highb, control = list(maxit = maxitv,factr = factrv))
    } else
      # no nolinear parameters fit
    {
      modelfun(numeric(0))
    }

    # report
    if (dualfit == TRUE ) {
      failureLatency <- mean(e$data$Duration..sec.[which(e$data$CF..ansbin. == 0)],
                             na.rm=T)

      if (distribution == "exp") {
        Scalar <- coef(e$lm.rt)[2]
        Intercept <- coef(e$lm.rt)[1]
        if (verbose) {
          cat(paste("Failure latency: ", failureLatency, "\n"))
          cat(paste("Latency Scalar: ", Scalar, "\n",
                    "Latency Intercept: ", Intercept, "\n",
                    sep = ""))
        }
      }
    }
    # build a tidy summary of coefficients and nonlinear parameters
    model_spec <- build_model_specification(e$modelvs[, "coefficient"],
                                            features   = gsub("[@$]", "", features),
                                            components = components,
                                            param_tracker = param_tracker)



    model_spec_list <- list(model_spec)

    results <- list(
      "model" = e$temp,
      "coefs" = e$modelvs,
      "model_specification" = model_spec_list,
      "r2" = e$mcfad,
      "prediction" = if ("pred" %in% colnames(e$data)) {
        e$data$pred
      },
      "nullmodel" = e$nullmodel,
      "latencymodel" = if (dualfit == TRUE) {
        if (distribution == "Weibull") {
          list(e$weibull.rt, failureLatency)
        } else {
          list(e$lm.rt, failureLatency)
        }
      },
      "optimizedpars" = if (exists("optimizedpars")) {
        optimizedpars
      } else NA,
      "studentRMSE" = if ("pred" %in% colnames(e$data)) {
        aggregate(sqrt((e$data$pred - e$data$CF..ansbin.)^2),
                  by = list(e$data$Anon.Student.Id), FUN = mean)
        },
      "newdata" = e$data,
      "predictors" = e$predictset2,
      "loglike" = e$loglike,
      "automat" = e$df
    )}
   # results$studentRMSE[,2]<-sqrt(results$studentRMSE[,2])}
  else{
      results <- list(
        "lassodata"=modelfun(numeric(0)))}

  if (dualfit) {
    # extract latency fit values based on distribution type
    if (distribution == "exp") {
      # Exponential distribution parameters
      failure_latency_value   <- failureLatency   # mean latency on failures
      latency_scalar_value    <- coef(e$lm.rt)[2]
      latency_intercept_value <- coef(e$lm.rt)[1]

      # build a simple list of latency parameters
      lat_params <- list(
        distribution      = "exp",
        failure_latency   = failure_latency_value,
        latency_scalar    = latency_scalar_value,
        latency_intercept = latency_intercept_value
      )
    } else if (distribution == "Weibull") {
      # Weibull distribution parameters (MLE with activation)
      failure_latency_value <- failureLatency   # keep failure latency for consistency
      weibull_sigma_subject_value <- if (!is.null(e$weibull.rt$sigma_subject)) {
        as.numeric(e$weibull.rt$sigma_subject)
      } else if (!is.null(e$weibull.rt$subject_effects)) {
        scale_subject_value <- as.numeric(e$weibull.rt$scale_subject)
        subject_sd <- stats::sd(as.numeric(e$weibull.rt$subject_effects), na.rm = TRUE)
        if (is.finite(scale_subject_value) &&
            !is.na(scale_subject_value) &&
            abs(scale_subject_value) > .Machine$double.eps) {
          subject_sd / abs(scale_subject_value)
        } else {
          subject_sd
        }
      } else {
        NA_real_
      }

      # build a simple list of Weibull latency parameters
      lat_params <- list(
        distribution        = "Weibull",
        failure_latency     = failure_latency_value,
        weibull_k           = e$weibull.rt$k,
        weibull_lambda0     = e$weibull.rt$lambda0,
        weibull_beta1       = e$weibull.rt$beta1,
        weibull_scale_subject = e$weibull.rt$scale_subject,
        weibull_sigma_subject = weibull_sigma_subject_value,
        weibull_t0          = e$weibull.rt$t0,
        weibull_sigma_trial = e$weibull.rt$sigma_trial,
        weibull_var_activation = e$weibull.rt$var_partition$activation,
        weibull_var_subject = e$weibull.rt$var_partition$subject,
        weibull_var_trial   = e$weibull.rt$var_partition$trial,
        weibull_conv        = e$weibull.rt$conv,
        weibull_sse         = e$weibull.rt$sse,
        weibull_r_squared   = e$weibull.rt$r_squared,
        weibull_n_obs       = e$weibull.rt$n_obs,
        weibull_n_subjects  = e$weibull.rt$n_subjects,
        weibull_predict_function = e$weibull.rt$predict,
        weibull_subject_effects = e$weibull.rt$subject_effects
      )
    }

    # insert latency parameters as the second element in the results list
    results$model_specification[[2]] <- lat_params
  }
  return(results)
}




# Build a tidy model_specification from the fitted LKT object

build_model_specification <- function(coef_vec,
                                      features,
                                      components,
                                      param_tracker) {

  spec <- data.table(
    coefficient_name = names(coef_vec),
    feature          = NA_character_,
    component        = "global",
    component_level  = NA_character_
  )

  # map coefficient names to feature / component ----
  for (i in seq_len(nrow(spec))) {
    cn <- spec$coefficient_name[i]

    # student‑specific intercept
    if (grepl("^interceptAnon\\.Student\\.Id", cn)) {
      spec[i, `:=`(feature = "intercept",
                   component = "Anon.Student.Id",
                   component_level =
                     sub("^interceptAnon\\.Student\\.Id", "", cn))]
      next
    }

    # global intercept
    if (cn %in% c("(Intercept)", "intercept")) {
      spec$feature[i] <- "intercept"
      next
    }

    # everything else
    for (f in features) {
      plain_f <- gsub("[@$]", "", f)
      if (startsWith(cn, plain_f)) {
        spec$feature[i] <- plain_f
        for (cmp in components) {
          if (grepl(cmp, cn, fixed = TRUE)) {
            spec$component[i] <- cmp
            lv <- sub(paste0(".*", gsub("\\.", "\\\\.", cmp)), "", cn)
            lv <- sub("^\\.*", "", lv)
            spec$component_level[i] <- ifelse(nchar(lv), lv, NA)
            break
          }
        }
        break
      }
    }
  }

  #- add numeric coefficient ----
  spec[, coefficient := coef_vec[coefficient_name]]

  #- add nonlinear parameters (para…pare) ----
  #- add nonlinear parameters (para … pare) ----
  spec[, `:=`(para = NA_real_, parb = NA_real_,
              parc = NA_real_, pard = NA_real_,
              pare = NA_real_)]

  for (f in names(param_tracker)) {
    pars <- param_tracker[[f]]
    if (length(pars) == 0) pars <- rep(NA_real_, 5)      # safety
    spec[feature == f,
         `:=`(para = pars[1],
              parb = pars[2],
              parc = pars[3],
              pard = pars[4],
              pare = pars[5])]
  }


  spec[]
}


#' @title Predict for LKT Models
#' @import pROC
#' @importFrom stats glm
#' @importFrom stats plogis
#' @importFrom stats logLik
#' @importFrom stats binomial
#' @description Generates predictions and evaluates logistic regression models tailored for learning data, specifically designed for Logistic Knowledge Tracing (LKT) models. This function provides flexibility in returning either just the predicted probabilities or both the predictions and key evaluation statistics.
#' @param modelob An LKT model object containing necessary model coefficients and predictors for generating predictions.
#' @param data A dataset including predictor variables, the outcome variable `CF..ansbin.`, and fold information.
#' @param fold Optional. Numeric vector specifying which folds to include for prediction. If NULL or empty, uses all data.
#' @param min_pred_limit Minimum prediction limit. Default is 0.00001.
#' @param max_pred_limit Maximum prediction limit. Default is 0.99999.
#' @param return_stats Logical. If TRUE, returns both predictions and evaluation statistics (Log-Likelihood, AUC, RMSE, R^2). If FALSE, returns only the predictions.
#' @return If return_stats is FALSE, returns a list containing:
#' \itemize{
#'   \item \code{predictions}: The predicted probabilities for each observation in the specified fold(s).
#' }
#' If return_stats is TRUE, returns a list containing:
#' \itemize{
#'   \item \code{predictions}: The predicted probabilities for each observation in the specified fold(s).
#'   \item \code{LL}: Log-Likelihood of the model given the actual outcomes.
#'   \item \code{AUC}: Area Under the ROC Curve.
#'   \item \code{RMSE}: Root Mean Squared Error.
#'   \item \code{R2}: R-squared value, indicating the proportion of variance explained by the model.
#' }
#' @export
predict_lkt <- function(modelob, data, fold = NULL, return_stats = FALSE,
                        min_pred_limit = .00001, max_pred_limit = .99999) {
  # Check if fold is NULL or empty, use all data if so
  if (is.null(fold) || length(fold) == 0) {
    fold <- unique(data$fold)
  }

  # modelob$predictors and modelob$coefs are multiplied
  predictionsMatrix <- as.matrix(data[, modelob$predictors]) %*% modelob$coefs

  # Apply configurable min and max limits
  pred <- pmin(pmax(plogis(predictionsMatrix), min_pred_limit), max_pred_limit)
  pred <- pred[data$fold %in% fold]

  # Calculate Log-Likelihood, AUC, R2, and RMSE using actual values and predictions
  actuals <- data$CF..ansbin.[data$fold %in% fold]
  LL <- sum(log(ifelse(actuals == 1, pred, 1 - pred)))
  AUC <- pROC::auc(actuals, pred)[1]
  nullmodel <- glm(actuals ~ 1, family = binomial(logit))
  R2 <- round(1 - LL / logLik(nullmodel)[1], 6)
  RMSE <- sqrt(mean((actuals - pred)^2))

  # Return predictions and optionally evaluation statistics
  if (!return_stats) {
    return(list(predictions = pred))
  } else {
    return(list(predictions = pred, LL = LL, AUC = AUC, RMSE = RMSE, R2 = R2))
  }
}



#' @title computefeatures
#' @description Compute feature describing prior practice effect.
#' @param data copy of main data frame.
#' @param feat is the feature to be computed.
#' @param par1 nonlinear parameters used for nonlinear features.
#' @param par2 nonlinear parameters used for nonlinear features.
#' @param par3 nonlinear parameters used for nonlinear features.
#' @param par4 nonlinear parameters used for nonlinear features.
#' @param par5 nonlinear parameters used for nonlinear features.
#' @param index a student by component levels index
#' @param index2 a component levels index
#' @param fcomp the component  name.
#' @return a vector suitable for regression input.
#' @export
computefeatures <- function(data, feat, par1, par2, index, index2,
                             par3, par4, par5, fcomp) {
  mn <- Anon.Student.Id <- temptemp <- icor <- CF..ansbin. <- NULL

  # dispatch on feature name to generate a numeric vector ---
  feat <- gsub("[$@]", "", feat)
  if (feat == "intercept") {
    return(as.character(index2))
  }
  if (feat == "numer") {
    temp <- eval(parse(text = paste("data$", fcomp, sep = "")))
    return(temp)
  }
  if (feat == "lineafm") {
    return((data$cor + data$icor))
  }
  if (feat == "logafm") {
    return(log(1 + data$cor + data$icor))
  }
  if (feat == "powafm") {
    return((data$cor + data$icor)^par1)
  }
    if (feat == "recency") {
    eval(parse(text = paste("data$rec <- data$", fcomp, "spacing", sep = "")))
    return(ifelse(data$rec == 0, 0, data$rec^-par1))
  }
    if (feat == "recencytest") {
    eval(parse(text = paste("data$rec <- data$", fcomp, "spacing", sep = "")))
    eval(parse(text = paste("data$stu <- data$", fcomp, "previousstudy", sep = "")))
    return(ifelse(data$stu== 0, ifelse(data$rec == 0,0,data$rec^-par1),0))
  }
  if (feat == "recencystudy") {
    eval(parse(text = paste("data$rec <- data$", fcomp, "spacing", sep = "")))
    eval(parse(text = paste("data$stu <- data$", fcomp, "previousstudy", sep = "")))
    return(ifelse(data$stu== 1, ifelse(data$rec == 0,0,data$rec^-par1),0))
  }
  if (feat == "expdecafm") {
    return(ave(rep(1, length(data$CF..ansbin.)), index, FUN = function(x) slideexpdec(x, par1)))
  }
  if (feat == "base") {
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$CF..age. <- data$CF..Time. - data$mintime
    return(log(1 + data$cor + data$icor) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1)))
  }
  if (feat == "base2") {
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$minreltime <- ave(data$CF..reltime., index, FUN = min)
    data$CF..trueage. <- data$CF..Time. - data$mintime
    data$CF..intage. <- data$CF..reltime. - data$minreltime
    data$CF..age. <- (data$CF..trueage. - data$CF..intage.) * par2 + data$CF..intage.
    return(log(1 + data$cor + data$icor) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1)))
  }
  if (feat == "base4") {
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$minreltime <- ave(data$CF..reltime., index, FUN = min)
    data$CF..trueage. <- data$CF..Time. - data$mintime
    data$CF..intage. <- data$CF..reltime. - data$minreltime
    data$CF..age. <- (data$CF..trueage. - data$CF..intage.) * par2 + data$CF..intage.
    eval(parse(text = paste("data$meanspace <- data$", fcomp, "meanspacing", sep = "")))
    eval(parse(text = paste("data$meanspacerel <- data$", fcomp, "relmeanspacing", sep = "")))
    data$meanspace2 <- par2 * (data$meanspace - data$meanspacerel) + data$meanspacerel
    return(ifelse(data$meanspace <= 0,
                  par4 * log(1 + data$cor + data$icor) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1)),
                  data$meanspace2^par3 * log(1 + data$cor + data$icor) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1))
    ))
  }
  if (feat == "ppe") {
    data$Nc <- (data$cor + data$icor)^par1
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$Tn <- data$CF..Time. - data$mintime
    eval(parse(text = paste("data$space <- data$", fcomp, "spacinglagged", sep = "")))
    data$space <- ifelse(data$space == 0, 0, 1 / log(data$space + exp(1)))
    data$space <- ave(data$space, index, FUN = function(x) cumsum(x))
    data$space <- ifelse((data$cor + data$icor) <= 1, 0, data$space / (data$cor + data$icor - 1))
    data$tw <- ave(data$Tn, index, FUN = function(x) slideppetw(x, par4))
    return(data$Nc * data$tw^-(par2 + par3 * data$space))
  }
  if (feat == "ppes") {
    data$Nc <- (data$cor)^(par1)
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$Tn <- data$CF..Time. - data$mintime
    eval(parse(text = paste("data$space <- data$", fcomp, "spacinglagged", sep = "")))
    data$space <- ifelse(data$space == 0, 0, 1 / log(data$space + exp(1)))
    data$space <- ave(data$space, index, FUN = function(x) cumsum(x))
    data$space <- ifelse((data$cor + data$icor) <= 1, 0, data$space / (data$cor + data$icor - 1))
    data$tw <- ave(data$Tn, index, FUN = function(x) slideppetw(x, par4))

    ppes_result <- data$Nc * data$tw^-(par2 + par3 * data$space)

    # Optional debug logging when PPES_DEBUG option is set
    if (getOption("PPES_DEBUG", FALSE)) {
      log_file <- "ppes_debug.txt"
      final_idx <- length(ppes_result)
      if (final_idx > 0) {
        # Extract student ID from index if possible
        student_id <- if(length(index) >= final_idx) strsplit(index[final_idx], fcomp)[[1]][2] else "unknown"

        # Get item ID if available in data
        item_id <- if("CF..Stim.File.Index." %in% names(data)) data$CF..Stim.File.Index.[final_idx] else "unknown"

        # Only log the key inputs actually used by PPES
        final_cor <- data$cor[final_idx]
        final_icor <- data$icor[final_idx]
        cf_time_vector <- paste(round(data$CF..Time., 2), collapse = ",")
        final_ppes <- round(ppes_result[final_idx], 6)

        cat(paste(
          as.character(Sys.time()),  # timestamp
          student_id,                # student
          fcomp,                     # component/KC
          item_id,                   # item being computed for
          final_cor,                 # cor value used
          final_icor,                # icor value used
          cf_time_vector,            # CF..Time. vector used
          final_ppes,                # final ppes result
          sep = "\t"
        ), "\n", file = log_file, append = TRUE)
      }
    }

    return(ppes_result)
  }
  if (feat == "ppef") {
    data$Nc <- (data$icor)^(par1)
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$Tn <- data$CF..Time. - data$mintime
    eval(parse(text = paste("data$space <- data$", fcomp, "spacinglagged", sep = "")))
    data$space <- ifelse(data$space == 0, 0, 1 / log(data$space + exp(1)))
    data$space <- ave(data$space, index, FUN = function(x) cumsum(x))
    data$space <- ifelse((data$cor + data$icor) <= 1, 0, data$space / (data$cor + data$icor - 1))
    data$tw <- ave(data$Tn, index, FUN = function(x) slideppetw(x, par4))
    return(data$Nc * data$tw^-(par2 + par3 * data$space))
  }
  if (feat == "base5suc") {
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$minreltime <- ave(data$CF..reltime., index, FUN = min)
    data$CF..trueage. <- data$CF..Time. - data$mintime
    data$CF..intage. <- data$CF..reltime. - data$minreltime
    data$CF..age. <- (data$CF..trueage. - data$CF..intage.) * par2 + data$CF..intage.
    eval(parse(text = paste("data$meanspace <- data$", fcomp, "meanspacing", sep = "")))
    eval(parse(text = paste("data$meanspacerel <- data$", fcomp, "relmeanspacing", sep = "")))
    data$meanspace2 <- par2 * (data$meanspace - data$meanspacerel) + (data$meanspacerel)
    return(ifelse(data$meanspace <= 0,
                  par4 * 10 * (log((par5 * 10) + data$cor)) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1)),
                  data$meanspace2^par3 * (log((par5 * 10) + data$cor)) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1))
    ))
  }
  if (feat == "base5fail") {
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$minreltime <- ave(data$CF..reltime., index, FUN = min)
    data$CF..trueage. <- data$CF..Time. - data$mintime
    data$CF..intage. <- data$CF..reltime. - data$minreltime
    data$CF..age. <- (data$CF..trueage. - data$CF..intage.) * par2 + data$CF..intage.
    eval(parse(text = paste("data$meanspace <- data$", fcomp, "meanspacing", sep = "")))
    eval(parse(text = paste("data$meanspacerel <- data$", fcomp, "relmeanspacing", sep = "")))
    data$meanspace2 <- par2 * (data$meanspace - data$meanspacerel) + (data$meanspacerel)
    return(ifelse(data$meanspace <= 0,
                  par4 * 10 * (log((par5 * 10) + data$icor)) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1)),
                  data$meanspace2^par3 * (log((par5 * 10) + data$icor)) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1))
    ))
  }

  if (feat == "dashafm") {
    data$x <- ave(data$CF..Time., index, FUN = function(x) countOutcomeDash(x, par1))
    return(log(1 + data$x))
  }
  if (feat == "dashsuc") {
    dataV <- data.frame(data$CF..Time., data$Outcome, index)
    h <- countOutcomeDashPerf(dataV, "CORRECT", par1)
    return(log(1 + h))
  }
  # single factor dynamic features
  if (feat == "diffrelcor1") {
    return(countRelatedDifficulty1(data, data$index, "CORRECT"))
  }
  if (feat == "diffrelcor2") {
    return(countRelatedDifficulty2(data, data$index, "CORRECT"))
  }
  if (feat == "diffcor1") {
    return(countOutcomeDifficulty1(data, data$index, "CORRECT"))
  }
  if (feat == "diffcor2") {
    return(countOutcomeDifficulty2(data, data$index, "CORRECT"))
  }
  if (feat == "diffcorComp") {
    return(countOutcomeDifficulty1(data, data$index, "CORRECT") - countOutcomeDifficulty2(data, data$index, "CORRECT"))
  }
  if (feat == "diffincorComp") {
    return(countOutcomeDifficulty1(data, data$index, "INCORRECT") - countOutcomeDifficulty2(data, data$index, "INCORRECT"))
  }
  if (feat == "diffallComp") {
    return(countOutcomeDifficultyAll1(data, data$index) - countOutcomeDifficultyAll2(data, data$index))
  }
  if (feat == "diffincor1") {
    return(countOutcomeDifficulty1(data, data$index, "INCORRECT"))
  }
  if (feat == "diffincor2") {
    return(countOutcomeDifficulty2(data, data$index, "INCORRECT"))
  }
  if (feat == "diffall1") {
    return(countOutcomeDifficultyAll1(data, data$index))
  }
  if (feat == "diffall2") {
    return(countOutcomeDifficultyAll2(data, data$index))
  }
  if (feat == "logsuc") {
    return(log(1 + data$cor))
  }
  if (feat == "logsucadj") {
    return(log(1 + data$cor)/(par1*20+log(1 + data$cor)))
  }
  if (feat == "linesuc") {
    return(data$cor)
  }
  if (feat == "logfail") {
    return(log(1 + data$icor))
  }
  if (feat == "linefail") {
    return(data$icor)
  }
  if (feat == "recencyfail") {
    eval(parse(text = paste("data$rec <- data$", fcomp, "spacing", sep = "")))
    eval(parse(text = paste("data$prev <- data$", fcomp, "prev", sep = "")))
    return(ifelse(data$rec == 0, 0, (1 - data$prev) * data$rec^-par1))
  }
  if (feat == "recencysuc") {
    eval(parse(text = paste("data$rec <- data$", fcomp, "spacing", sep = "")))
    eval(parse(text = paste("data$prev <- data$", fcomp, "prev", sep = "")))
    return(ifelse(data$rec == 0, 0, data$prev * data$rec^-par1))
  }
  if (feat == "expdecsuc") {
    return(ave(data$CF..ansbin., index, FUN = function(x) slideexpdec(x, par1)))
  }
  if (feat == "expdecfail") {
    return(ave(1 - data$CF..ansbin., index, FUN = function(x) slideexpdec(x, par1)))
  }
  if (feat == "basesuc") {
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$CF..age. <- data$CF..Time. - data$mintime
    return(log(1 + data$cor) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1)))
  }
  if (feat == "basefail") {
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$CF..age. <- data$CF..Time. - data$mintime
    return(log(1 + data$icor) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1)))
  }
  if (feat == "base2fail") {
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$minreltime <- ave(data$CF..reltime., index, FUN = min)
    data$CF..trueage. <- data$CF..Time. - data$mintime
    data$CF..intage. <- data$CF..reltime. - data$minreltime
    data$CF..age. <- (data$CF..trueage. - data$CF..intage.) * par2 + data$CF..intage.
    return(log(1 + data$icor) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1)))
  }
  if (feat == "base2suc") {
    data$mintime <- ave(data$CF..Time., index, FUN = min)
    data$minreltime <- ave(data$CF..reltime., index, FUN = min)
    data$CF..trueage. <- data$CF..Time. - data$mintime
    data$CF..intage. <- data$CF..reltime. - data$minreltime
    data$CF..age. <- (data$CF..trueage. - data$CF..intage.) * par2 + data$CF..intage.
    return(log(1 + data$cor) * ave(data$CF..age., index, FUN = function(x) baselevel(x, par1)))
  }

  # double factor dynamic features
  if (feat == "linecomp") {
    return((data$cor - data$icor))
  }
  if (feat == "logit") {
    return(log((.1 + par1 * 30 + data$cor) / (.1 + par1 * 30 + data$icor)))
  }
  if (feat == "errordec") {
    return(ave(data$pred_ed - data$CF..ansbin., index, FUN = function(x) slideerrordec(x, par1)))
  }
  if (feat == "propdec") {
    return(ave(data$CF..ansbin., index, FUN = function(x) slidepropdec(x, par1)))
  }
  if (feat == "propdec2") {
    return(ave(data$CF..ansbin., index, FUN = function(x) slidepropdec2(x, par1)))
  }
  if (feat == "logitdec") {
    return(ave(data$CF..ansbin., index, FUN = function(x) slidelogitdec(x, par1)))
  }

  if (feat == "logitdecevol") {
    return(ave(data$CF..ansbin., index2, FUN = function(x) slidelogitdecfree(x, par1)))
  }
  if (feat == "baseratepropdec") {
    return(as.numeric(ave(index2, data$Anon.Student.Id, FUN = function(x) baserateslidedec(x, par1))))
  }
  if (feat == "prop") {
    ifelse(is.nan(data$cor / (data$cor + data$icor)), .5, data$cor / (data$cor + data$icor))
  }
}

# Boot function for LKT_HDI
boot_fn <- function(dat, n_students, comps, feats, ints = NA, fixeds, conns) {
  dat_ss = smallSet(dat, n_students)

  mod = LKT(setDT(dat_ss), interc = TRUE,
            components = comps, interacts = ints,
            features = feats, connectors = conns,
            fixedpars = fixeds,
            seedpars = c(NA), verbose = FALSE)
  return(mod$coefs)
}


#Given a par_reps matrix, computes HDI intervals for each column
get_hdi <- function(par_reps,cred_mass=.95){

  coef_hdi <- data.frame(
    "coef_name" = colnames(par_reps),
    "lower" = rep(NA,dim(par_reps)[2]),
    "upper" = rep(NA,dim(par_reps)[2]),
    "includes_zero" = rep(NA,dim(par_reps)[2]),
    "credMass" = cred_mass
  )
  intervals = apply(par_reps,MARGIN=2,FUN = hdi,credMass = cred_mass)
  coef_hdi$lower = intervals[1,]
  coef_hdi$upper = intervals[2,]
  coef_hdi$includes_zero = rep(0,length(intervals[1,])) %between% list(intervals[1,],intervals[2,])

  return(coef_hdi)
}
# custom duration function, experimental
getFeedDur <- function(data, index) {
  temp <- rep(0, length(data$CF..ansbin.))
  for (i in unique(index)) {
    le <- length(data$time_to_answer[index == i])
    subtemp <- data$time_since_prior_probe[index == i] - data$time_to_answer_inferred[index == i]
    subtemp <- subtemp[2:(le - 1)]
    subtemp <- c(subtemp, median(subtemp, na.rm = TRUE))
    # if huge outlier make median for subject from that subject from that index
    cutoff <- which(subtemp > 3600)
    subtemp[cutoff] <- median(subtemp[-cutoff], na.rm = TRUE)
    # function returns NA for feedDur if subject only did one trial in index
    # replaced with Median (overall) outside function
    temp[index == i] <- subtemp
  }
  return(temp)
}

# convenience function
right <- function(string, char) {
  substr(string, nchar(string) - (char - 1), nchar(string))
}

#' @title countOutcome
#' @description Compute the prior sum of the response appearing in the outcome column for the index
#' @param data the dataset to compute an outcome vector for
#' @param index the subsets to count over
#' @param response the actually response value being counted
#' @return the vector of the lagged cumulative sum.
#' @export
countOutcomeold <- function(data, index, response) {
  temp <- Outcome <- NULL
  data[, temp := cumsum(Outcome == response), by = index]
  data[Outcome == response, temp := temp - 1, by = index]
  data$temp
}

countOutcome <- function(data, index, response) {
  temp <- Outcome <- NULL
  data[, temp := cumsum(Outcome == response), by = index]
  data[Outcome == response, temp := temp - 1]
  return(data$temp)
}


countOutcomeDash <- function(times, scalev) {
  l <- length(times)
  v1 <- c(rep(0, l))
  v2 <- c(rep(0, l))
  v1[1] <- 0
  v2[1] <- v1[1] + 1
  if (l > 1) {
    spacings <- times[2:l] - times[1:(l - 1)]
    for (i in 2:l) {
      v1[i] <- v2[i - 1] * exp(-spacings[i - 1] / (scalev * 86400))
      v2[i] <- v1[i] + 1
    }
  }
  return(v1)
}

countOutcomeDashPerf <- function(datav, seeking, scalev) {
  temp <- rep(0, length(datav[, 1]))

  for (s in unique(datav[, 3])) {
    l <- length(datav[, 1][datav[, 3] == s])
    v1 <- c(rep(0, l))
    v2 <- c(rep(0, l))
    r <- as.character(datav[, 2][datav[, 3] == s]) == seeking
    v1[1] <- 0
    v2[1] <- v1[1] + r[1]
    if (l > 1) {
      spacings <- as.numeric(datav[, 1][datav[, 3] == s][2:l]) - as.numeric(datav[, 1][datav[, 3] == s][1:(l - 1)])
      for (i in 2:l) {
        v1[i] <- v2[i - 1] * exp(-spacings[i - 1] / (scalev * 86400))
        v2[i] <- v1[i] + r[i]
      }
    }
    temp[datav[, 3] == s] <- v1
  }
  return(temp)
}

# count confusable outcome difficulty effect
countOutcomeDifficulty1 <- function(data, index, r) {
  temp <- data$curvefeat
  temp <- ifelse(data$Outcome == r, temp, 0)
  data$temp <- ave(temp, index, FUN = function(x) as.numeric(cumsum(x)))
  data$temp <- data$temp - temp
  data$temp
}

countRelatedDifficulty1 <- function(data, index, r) {
  temp <- (data$contran)
  temp <- ifelse(data$Outcome == r, temp, 0)
  data$temp <- ave(temp, index, FUN = function(x) as.numeric(cumsum(x)))
  data$temp <- data$temp - temp
  data$temp
}

countRelatedDifficulty2 <- function(data, index, r) {
  temp <- (data$contran)^2
  temp <- ifelse(data$Outcome == r, temp, 0)
  data$temp <- ave(temp, index, FUN = function(x) as.numeric(cumsum(x)))
  data$temp <- data$temp - temp
  data$temp
}

countOutcomeDifficulty2 <- function(data, index, r) {
  temp <- data$curvefeat^2
  temp <- ifelse(data$Outcome == r, temp, 0)
  data$temp <- ave(temp, index, FUN = function(x) as.numeric(cumsum(x)))
  data$temp <- data$temp - temp
  data$temp
}

countOutcomeDifficultyAll1 <- function(data, index) {
  temp <- data$curvefeat

  data$temp <- ave(temp, index, FUN = function(x) as.numeric(cumsum(x)))
  data$temp <- data$temp - temp
  data$temp
}

countOutcomeDifficultyAll2 <- function(data, index) {
  temp <- data$curvefeat^2

  data$temp <- ave(temp, index, FUN = function(x) as.numeric(cumsum(x)))
  data$temp <- data$temp - temp
  data$temp
}

# specific cause to self
# notation indexfactor%sourcefactor%sourcevalue
# for the index (student by KC) count prior values if a particular source column equals value
# differential KC learning for each item within KC
countOutcomeGen <- function(data, index, item, sourcecol, sourc) {
  data$tempout <- paste(data$Outcome, sourcecol)
  item <- paste(item, sourc)
  data$temp <- as.numeric(ave(as.character(data$tempout), index, FUN = function(x) as.numeric(cumsum(tolower(x) == tolower(item)))))
  data$temp <- data$temp - as.numeric(tolower(as.character(data$tempout)) == tolower(item))
  as.numeric(data$temp)
}

# notation targetcol?whichtarget?sourcecol?whichsource
# specific cause to any
# for the index (student by KC) count prior values if a particular source column equals value
#      but only when a particular target value is in the target column is present
# item to item learning within skill
countOutcomeOther <- function(data, index, item, sourcecol, sourc, targetcol, target) {
  data$tempout <- paste(data$Outcome, sourcecol)
  item <- paste(item, sourc)
  targetcol <- as.numeric(targetcol == target)
  data$temp <- ave(as.character(data$tempout), index, FUN = function(x) as.numeric(cumsum(tolower(x) == tolower(item))))
  data$temp[tolower(as.character(data$tempout)) == tolower(item)] <- as.numeric(data$temp[tolower(as.character(data$tempout)) == tolower(item)]) - 1
  as.numeric(data$temp) * targetcol
}

# computes practice times using trial durations only
practiceTime <- function(data) {
  temp <- rep(0, length(data$CF..ansbin.))
  for (i in unique(data$Anon.Student.Id)) {
    if (length(data$Duration..sec.[data$Anon.Student.Id == i]) > 1) {
      temp[data$Anon.Student.Id == i] <-
        c(0, cumsum(data$Duration..sec.[data$Anon.Student.Id == i])
          [1:(length(cumsum(data$Duration..sec.[data$Anon.Student.Id == i])) - 1)])
    }
  }
  return(temp)
}

# computes spacing from prior repetition for index (in seconds)
componentspacing <- function(data, index, times) {

  temp <- numeric(nrow(data)) # initialize temp as a numeric vector

  # calculate the differences within each group and assign to temp
  temp <- ave(times, index, FUN=function(x) c(0, diff(x)))

  return(temp)
}

prevstudy <- function(data, index, outcomes) {

  temp <- logical(nrow(data)) # initialize temp as a numeric vector

  # calculate the differences within each group and assign to temp
  temp <- ave(outcomes, index, FUN=function(x) c(F, head(x,-1)=="STUDY"))

  return(temp)
}


componentprev <- function(data, index, answers) {
  prev_answers <- ave(answers, index, FUN = function(x) c(0, head(x, -1)))
  return(prev_answers)
}

# computes mean spacing
meanspacingf <- function(data, index, spacings) {  temp <- ave(spacings, index, FUN= function(x) {
    j <- length(x)
    tempx <- rep(0,j)
    if (j > 1) {
      tempx[2] <- -1
    }
    if (j == 3) {
      tempx[3] <- x[2]
    }
    if (j > 3) {
      tempx[3:j] <- cumsum(x[2:(j - 1)]) / (1:(j - 2))
    }
    tempx
  })

  return(temp)
}

laggedspacingf <- function(data, index, spacings) {

  temp <- ave(spacings, index, FUN=function(x) c(0, head(x, -1)))
  return(temp)
}

errordec <- function(v, d) {
  w <- length(v)
  sum((c(0, v[1:w]) * d^((w):0)) / sum(d^((w + 1):0)))
}

slideerrordec <- function(x, d) {
  v <- c(rep(0, length(x)))
  for (i in 1:length(x)) {
    v[i] <- errordec(x[1:i], d)
  }
  return(c(0, v[1:length(x) - 1]))
}

# exponetial decy for trial
expdec <- function(v, d) {
  w <- length(v)
  sum(v[1:w] * d^((w - 1):0))
}

# 3 failed ghosts RPFA success function
propdec2 <- function(v, d) {
  w <- length(v)
  sum((v[1:w] * d^((w - 1):0)) / sum(d^((w + 2):0)))
}

# 2 failed and 1 success ghost RPFA success function bug fixed 10/17/23 upload to github
propdec <- function(v, d) {
  w <- length(v)
  #  (cat(v,d,w,"\n"))
  corv <- sum(c(1, v[1:w]) * d^(w:0))
  incorv <- sum(c(1, abs(v[1:w] - 1)) * d^(w:0))
  corv / (corv+incorv)
}

logitdec <- function(v, d) {
  w <- length(v)
  #  (cat(v,d,w,"\n"))
  corv <- sum(c(1, v[1:w]) * d^(w:0))
  incorv <- sum(c(1, abs(v[1:w] - 1)) * d^(w:0))
  log(corv / incorv)
}


logitdec4 <- function(v, d) {
  w <- length(v)
  #  (cat(v,d,w,"\n"))
  corv <- sum(c(1,1,1,1, v[1:w]) * d^((w+3):0))
  incorv <- sum(c(1,1,1,1, abs(v[1:w] - 1)) * d^((w+3):0))
  log(corv / incorv)
}

slidelogitdecfree <- function(x, d) {
  v <- c(rep(0, length(x)))
  for (i in 1:length(x)) {
    v[i] <- logitdec(x[1:i], d)
  }
  return(c(0, v[1:length(x) - 1]))
}

slidelogitdec <- function(x, d) {
  v <- c(rep(0, length(x)))
  for (i in 1:length(x)) {
    v[i] <- logitdec(x[max(1, i - 59):i], d)
  }
  return(c(0, v[1:length(x) - 1]))
}

baseratepropdec <- function(v, d) {
  w <- length(v)
  targetvalue <- v[w]
  v <- v==targetvalue
  corv <- sum(c(1, v[1:w]) * d^(w:0))
  incorv <- sum(c(1, abs(v[1:w] - 1)) * d^(w:0))
  log(corv / incorv)
}

baseratepropdec <- function(v, d) {
  w <- length(v)
  targetvalue <- v[w]
  #print(v)
  v <- v==targetvalue
 #print(v)
  corv <- sum((v[1:w-1]) * d^((w-1):1))
  incorv <- sum(d^((w + 2):1))
#  print(corv/incorv)
  (corv / incorv)
}

baserateslidedec <- function(x, d) {
  v <- c(rep(0, length(x)))
  for (i in 1:length(x)) {
    v[i] <- baseratepropdec(x[1:i], d)
  }
  return(v[1:length(x) ])
}

# exponential decay for sequence
slideexpdec <- function(x, d) {
  v <- c(rep(0, length(x)))
  for (i in 1:length(x)) {
    v[i] <- expdec(x[1:i], d)
  }
  return(c(0, v[1:length(x) - 1]))
}

# proportion exponential decay for sequence
slidepropdec <- function(x, d) {
  v <- c(rep(0, length(x)))
  for (i in 1:length(x)) {
    v[i] <- propdec(x[1:i], d)
  }
  return(c(.5, v[1:length(x) - 1]))
}

slidepropdec2 <- function(x, d) {
  v <- c(rep(0, length(x)))
  for (i in 1:length(x)) {
    v[i] <- propdec2(x[1:i], d)
  }
  return(c(0, v[1:length(x) - 1]))
}



# PPE weights
ppew <- function(times, wpar) {
  times^-wpar *
    (1 / sum(times^-wpar))
}

# PPE time since practice
ppet <- function(times) {
  times[length(times)] - times
}

# ppe adjusted time for each trial in sequence
ppetw <- function(x, d) {
  v <- length(x)
  ppetv <- ppet(x)[1:(v - 1)]
  ppewv <- ppew(ppetv, d)
  ifelse(is.nan(crossprod(ppewv[1:(v - 1)], ppetv[1:(v - 1)])),
         1,
         crossprod(ppewv[1:(v - 1)], ppetv[1:(v - 1)])
  )
}

# PPE adjusted times for entire sequence
slideppetw <- function(x, d) {
  v <- c(rep(0, length(x)))
  for (i in 1:length(x)) {
    v[i] <- ppetw(x[1:i], d)
  }
  return(c(v[1:length(x)]))
}

# tkt main function
baselevel <- function(x, d) {
  l <- length(x)
  return(c(0, x[2:l]^-d)[1:l])
}

# find the time that corresponds to the longest break in the sequence
splittimes <- function(times) {
  (match(max(rank(diff(times))), rank(diff(times))))
}

#' @title smallSet
#' @export
#' @param data Dataframe of student data
#' @param nSub Number of students
smallSet <- function(data, nSub) {
  totsub <- length(unique(data$Anon.Student.Id))
  datasub <- unique(data$Anon.Student.Id)
  smallSub <- datasub[sample(1:totsub)[1:nSub]]

  smallIdx <- which(data$Anon.Student.Id %in% smallSub)
  smalldata <- data[smallIdx, ]
  smalldata <- droplevels(smalldata)
  return(smalldata)
}

texteval <- function(stringv) {
  eval(parse(text = stringv))
}

#' @title ViewExcel
#' @export
#' @param df Dataframe
#' @param file name of the Excel file
ViewExcel <-function(df = .Last.value, file = tempfile(fileext = ".csv")) {
  df <- try(as.data.frame(df))
  stopifnot(is.data.frame(df))
  utils::write.csv(df, file = file)
  shell.exec(file)
}

#' @title LKT_HDI
#' @description Bootstrap credibility intervals to aid in interpreting coefficients.
#' @import HDInterval
#' @param dat Dataframe
#' @param n_boot Number of subsamples to fit
#' @param n_students Number of students per subsample
#' @param comps Components in model
#' @param feats Features in model
#' @param ints Interacts in model
#' @param fixeds Fixed parameters in model
#' @param conns R notation for linear equation connectors in model
#' @param get_hdi Boolean to decide if generating HDI per coefficient
#' @param cred_mass Credibility mass parameter to decide width of HDI
#' @export
#' @return List of values "par_reps", "mod_full", "coef_hdi"
LKT_HDI <- function(dat, n_boot, n_students, comps, feats,conns = rep("+",max(1,length(comps)-1)), ints = NA, fixeds, get_hdi = TRUE, cred_mass = .95) {

  # First fit full to get all features to get all predictor names
  mod_full = LKT(setDT(dat), interc = TRUE,
                 interacts = ints, connectors = conns,
                 components = comps,
                 features = feats,
                 fixedpars = fixeds,
                 seedpars = c(NA), verbose = FALSE)

  par_reps = matrix(nrow = n_boot, ncol = length(mod_full$coefs))
  colnames(par_reps) <- rownames(mod_full$coefs)

  for(i in 1:n_boot) {
    # First trial, return the names and make the matrix
    temp = boot_fn(dat, n_students, comps, feats, ints, fixeds, conns)
    idx = match(rownames(temp), colnames(par_reps))
    par_reps[i, idx] = as.numeric(temp)
    if(i == 1) {
      cat("0%")
    } else {
      cat(paste("...", round((i / n_boot) * 100), "%", sep = ""))
    }
    if(i == n_boot) {
      cat("\n")
    }
  }
  return(list("par_reps" = par_reps, "mod_full" = mod_full, coef_hdi = get_hdi(par_reps, cred_mass = .99)))
}


LKTStartupMessage <- function()
{
  # > figlet -f doom LKT
  msg <- c(paste0(
    "  LL      KK  KK TTTTTTT
  LL      KK KK    TTT
  LL      KKKK     TTT
  LL      KK KK    TTT
  LLLLLLL KK  KK   TTT

  Join the mailing list: lkt@freelists.org
  Version ",
    packageVersion("LKT")),
    "\nType 'citation(\"LKT\")' for citing this R package in publications.")
  return(msg)
}

.onAttach <- function(lib, pkg)
{
  # unlock .LKT variable allowing its modification
  #unlockBinding(".LKT", asNamespace("LKT"))
  # startup message
  msg <- LKTStartupMessage()
  if(!interactive())
    msg[1] <- paste("Package 'LKT' version", packageVersion("LKT"))
  packageStartupMessage(msg)
  invisible()
}

#' @title buildLKTModel
#' @import pROC
#' @import crayon
#' @description Forward and backwards stepwise search for a set of features and components
#' @description with tracking of nonlinear parameters.
#' @param data is a dataset with Anon.Student.Id and CF..ansbin.
#' @param allcomponents is search space for LKT components
#' @param allfeatures is search space for LKT features
#' @param currentcomponents components to start search from
#' @param specialcomponents add special components (not crossed with features, only paired with special features 1 for 1)
#' @param specialfeatures features for each special component (not crossed during search)
#' @param forv the minimuum amount of improvement needed for the addition of a new term
#' @param bacv the maximuum amount of loss for a term to be removed
#' @param preset One of "static","AFM","PFA","advanced","AFMLLTM","PFALLTM","advancedLLTM"
#' @param presetint should the intercepts be included for preset components
#' @param currentfeatures features to start search from
#' @param verbose passed to LKT
#' @param currentfixedpars used for current features as an option to start
#' @param maxitv passed to LKT
#' @param interc passed to LKT
#' @param forward TRUE or FALSE
#' @param backward TRUE or FALSE
#' @param metric One of "BIC","AUC","AIC", and "RMSE"
#' @param usefolds Numeric Vector | Specifies the folds for model fitting in LKT; the features are still calculated across all folds to compute test fold fit externally
#' @param removefeat Character Vector | Excludes specified features from the test list.
#' @param removecomp Character Vector | Excludes specified components from the test list.
#' @return list of values "tracetable" and "currentfit"
#' @export
buildLKTModel <- function(data,usefolds = NA,
                          allcomponents,allfeatures,
                          currentcomponents=c(),specialcomponents=c(),specialfeatures=c()
                          ,forv,bacv,preset=NA,presetint=T,
                          currentfeatures=c(),verbose=FALSE,
                          currentfixedpars =c(),maxitv=10,interc = FALSE,
                          forward= TRUE, backward=TRUE, metric="BIC",removefeat=c(), removecomp=c()){


  if(is.na(usefolds)[1])
  {data$fold<-1
  usefolds=1}

  if(is.null(data$fold))
  {data$fold<-1
    usefolds=1}


  #allowable features in search space
  allfeatlist<-c("numer","intercept","lineafm","logafm","logsuc","logfail","linesuc","linefail","propdec",
                 "recency","expdecafm","recencysuc","recencyfail","logitdec","base2","ppe","base","powafm")

  featpars<-c(0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,4,1,1)

  if(!is.na(preset)){if(preset=="static"){allfeatures<-c("intercept")}


    if(preset=="AFM"){allfeatures<-c("intercept","lineafm","logafm","lineafm")}

    if(preset=="AFMLLTM"){allfeatures<-c("intercept","lineafm","logafm","lineafm","lineafm$","logafm$","lineafm$")}

    if(preset=="PFA"){allfeatures<-c("intercept","lineafm","logafm","lineafm", "logsuc","logfail",  "linesuc","linefail")}

    if(preset=="PFALLTM"){allfeatures<-c("intercept","lineafm","logafm","lineafm", "logsuc","logfail",  "linesuc","linefail"
                                         ,"lineafm$","logafm$","lineafm$", "logsuc$","logfail$",  "linesuc$","linefail$")}

    if(preset=="advanced"){allfeatures<-c("intercept","lineafm","logafm","lineafm", "logsuc","logfail",
                                          "linesuc","linefail", "logitdec","propdec","recency","base")}

    if(preset=="advancedLLTM"){allfeatures<-c("intercept","lineafm","logafm","lineafm", "logsuc","logfail",
                                              "linesuc","linefail", "logitdec","propdec","recency","base","lineafm$","logafm$","lineafm$", "logsuc$","logfail$",
                                              "linesuc$","linefail$")}
    if(presetint==F){allfeatures<-allfeatures[allfeatures!="intercept"]}
  }
  currentfit<-list()
  startfitscor <- Inf
  currentfitscore<- Inf
  k<-0
  paramvec<-currentfixedpars
  compstat<- c()

  tracetable<- as.data.frame(matrix(data=NA,nrow=0,ncol=10))
  x<-c("comp","feat","r2","ind","params","BIC","AUC","AIC","RMSE","action")
  colnames(tracetable)<-x

  if(length(currentcomponents)>0){
    fixedparct<-0
    for(ct in currentfeatures){

      if(match(gsub("[$]","",ct),gsub("[$]","",allfeatlist))>0){
        fixedparct<-fixedparct+featpars[match(gsub("[$]","",ct),gsub("[$]","",allfeatlist))]}}
    currentfit<-LKT(data = data, usefolds=usefolds,interc=interc,maxitv=maxitv,verbose=verbose,
                    components = currentcomponents,
                    features = currentfeatures,fixedpars = ifelse(is.na(currentfixedpars),rep(NA,fixedparct),currentfixedpars)
                    )

    BICis<- (length(currentfit$coefs)+fixedparct)*log(length(currentfit$prediction))-2*currentfit$loglik
    AUCis<- suppressMessages(pROC::auc(data$CF..ansbin., currentfit$prediction)[1])
    AICis<- (length(currentfit$coefs)+fixedparct)*2-2*currentfit$loglik
    RMSEis<- sqrt(mean((data$CF..ansbin.[data$fold %in% usefolds]-currentfit$prediction[data$fold %in% usefolds])^2))
  cat("\nStep",k,"results - pars ",length(currentfit$coefs)+fixedparct," current BIC",BICis,"current AIC",AICis,"current AUC",AUCis,
                         "current RMSE",RMSEis," McFadden's R2",currentfit$r2,"\n")
    cat(currentfeatures,"\n",currentcomponents,"\n")
    if(!is.atomic(currentfit$optimizedpars)){
      cat("pars",currentfit$optimizedpars$par,"\n")
      paramvec<-currentfit$optimizedpars$par}
    tracetable[nrow(tracetable) + 1,] =
      list(comp=paste(currentcomponents,collapse=" "),feat=paste(currentfeatures,collapse=" "),r2=currentfit$r2,ind=0,params=length(currentfit$coefs)+fixedparct,
           BIC=BICis,AUC=AUCis,AIC=AICis,RMSE=RMSEis,action=paste("starting model"))

    switch(metric,
           "AUC" = {
             currentfitscore<- -AUCis},
           "AIC" = {
             currentfitscore<-AICis},
           "BIC" = {
             currentfitscore<-BICis},
           "RMSE" = {
             currentfitscore<-RMSEis},
           "R2" = {
             currentfitscore<- -currentfit$r2})
  } else {
    meancor<-mean(data$CF..ansbin.)
    ll<- sum(log(ifelse(data$CF..ansbin.[data$fold %in% usefolds]==1,meancor,1-meancor)))
    BICis<- log(length(data$CF..ansbin.[data$fold %in% usefolds]))-2*ll
    AUCis<- .5
    AICis<- 2-2*ll
    RMSEis<- sqrt(mean((data$CF..ansbin.[data$fold %in% usefolds]-mean(data$CF..ansbin.[data$fold %in% usefolds]))^2))
    tracetable[nrow(tracetable) + 1,] =
      list(comp="none",feat="none",r2=0,ind=0,params=1,
           BIC=BICis,AUC=AUCis,AIC=AICis,RMSE=RMSEis,action=paste("null model"))

    switch(metric,
           "AUC" = {
             currentfitscore<- -AUCis},
           "AIC" = {
             currentfitscore<-AICis},
           "BIC" = {
             currentfitscore<-BICis},
           "RMSE" = {
             currentfitscore<-RMSEis},
           "R2" = {
             currentfitscore<- 0})
  }

  # create null model also and put that on graph

  while (is.infinite(startfitscor) | currentfitscore!=startfitscor){
    startfitscor<-currentfitscore

    k<-k+1
    cat(white$bgBlack$bold("\nStep ",k,"start\n"))
    bestmod<-NULL
    if(forward){
      cat("\ntrying to add\n")
      testtable<- as.data.frame(matrix(data=NA,nrow=0,ncol=10))
      x<-c("comp","feat","r2","ind","params","BIC","AUC","AIC","RMSE","action")
      colnames(testtable)<-x
      ij<-0
      complist<-c()
      featlist<-c()
      for(i in allcomponents){
        for(j in allfeatures){
          complist<-c(complist,i)
          featlist<-c(featlist,j)
        }}

      complist<-c(specialcomponents, complist)
      featlist<-c(specialfeatures, featlist)
      combined_list <- paste(complist, featlist, sep = "_")
      remove_list <- paste(removecomp, removefeat, sep = "_")
      indices_to_keep <- !combined_list %in% remove_list
      complist <- complist[indices_to_keep]
      featlist <- featlist[indices_to_keep]
      for(w in 1:length(complist)){
        i<-complist[w]
        j<-featlist[w]


        if(sum(paste(i,j) == data.frame(paste(currentcomponents,currentfeatures)))==1) next
        ij<-ij+1
        testfeatures <- c(currentfeatures,j)
        testcomponents <- c(currentcomponents,i)
        fixedparct<-0
        for(ct in testfeatures){
          if(match(gsub("[$]","",ct),gsub("[$]","",allfeatlist))>0){fixedparct<-fixedparct+featpars[match(gsub("[$]","",ct),gsub("[$]","",allfeatlist))]}}
        fittest<-LKT(data = data,usefolds=usefolds, interc=interc,maxitv=maxitv,verbose=verbose,
                     components = testcomponents,
                     features = testfeatures,fixedpars = c(paramvec,rep(NA,featpars[match(gsub("[$]","",j),gsub("[$]","",allfeatlist))])))

        BICis<- (length(fittest$coefs)+fixedparct)*log(length(fittest$prediction))-2*fittest$loglik
        AUCis<- suppressMessages(pROC::auc(data$CF..ansbin., fittest$prediction)[1])
        AICis<- (length(fittest$coefs)+fixedparct)*2-2*fittest$loglik
        RMSEis<- sqrt(mean((data$CF..ansbin.[data$fold %in% usefolds]-fittest$prediction[data$fold %in% usefolds])^2))
        testtable[nrow(testtable) + 1,] =
          list(comp=i,feat=j,r2=fittest$r2,ind=ij,params=length(fittest$coefs)+fixedparct,
               BIC=BICis,AUC=AUCis,AIC=AICis,RMSE=RMSEis,action=paste("add\n" ,paste(j,i,sep="-")))

        switch(metric,
               "AUC" = {compstat<- -testtable$AUC
               currentcompstat<- -AUCis},
               "AIC" = {compstat<- testtable$AIC
               currentcompstat<-AICis},
               "BIC" = {compstat<- testtable$BIC
               currentcompstat<-BICis},
               "RMSE" = {compstat<- testtable$RMSE
               currentcompstat<-RMSEis},
               "R2" = {compstat<- -testtable$r2
               currentcompstat<- -fittest$r2})
        cat(paste(j,i,sep="-"),length(fittest$coefs)+fixedparct,currentcompstat,"\n")

        if(min(compstat)==currentcompstat)(bestmod<-fittest)
      }

      if(min(compstat)+forv<currentfitscore){cat("added","\n")
        tracetable<-rbind(tracetable,testtable[which.min(compstat),])
        currentfitscore<-min(compstat)
        currentfeatures<-c(currentfeatures,testtable[which.min(compstat),]$feat)
        currentcomponents<-c(currentcomponents,testtable[which.min(compstat),]$comp)
        cat(testtable[which.min(compstat),]$feat,testtable[which.min(compstat),]$comp,"\n")
      }}

    if(!is.atomic(bestmod$optimizedpars)){
      paramvec<-c(paramvec ,NA)}

    # retain the best model from forward
    # then assume that model was selected and use its parameters as a basis

    #make sure backwards tests until there is no change in feature length for one iteration

    if(length(currentfeatures)>1 & backward)
    {
      cat("\ntrying to remove\n")
      testtable<- as.data.frame(matrix(data=NA,nrow=0,ncol=10))
      x<-c("comp","feat","r2","ind","params","BIC","AUC","AIC","RMSE","action")
      colnames(testtable)<-x

      for(i in 1:length(currentcomponents)){
        testfeatures <- currentfeatures[-i]
        testcomponents <- currentcomponents[-i]
        testpars<-c()


        fixedparct<-0
        pc<-1
        featct<-1
        for(ct in currentfeatures){
          if(ct==currentfeatures[i] & currentcomponents[featct]==currentcomponents[i]){
          }else{
            if(featpars[match(gsub("[$]","",ct),gsub("[$]","",allfeatlist))]>0 ){
              fixedparct<-fixedparct+featpars[match(gsub("[$]","",ct),gsub("[$]","",allfeatlist))]
              testpars<-c(testpars,paramvec[pc:pc+(featpars[match(gsub("[$]","",ct),gsub("[$]","",allfeatlist))]-1)])
            }}
          pc<-pc+featpars[match(gsub("[$]","",ct),gsub("[$]","",allfeatlist))]
          featct<-featct+1
        }
        fittest<-LKT(data = data, usefolds=usefolds,interc=interc,maxitv=maxitv,verbose=verbose,
                     components = testcomponents,
                     features = testfeatures,fixedpars = testpars)
        BICis<- (length(fittest$coefs)+fixedparct)*log(length(fittest$prediction))-2*fittest$loglik
        AUCis<- suppressMessages(pROC::auc(data$CF..ansbin., fittest$prediction)[1])
        AICis<- (length(fittest$coefs)+fixedparct)*2-2*fittest$loglik
        RMSEis<- sqrt(mean((data$CF..ansbin.[data$fold %in% usefolds]-fittest$prediction[data$fold %in% usefolds])^2))


        testtable[nrow(testtable) + 1,] =
          list(comp=i,feat=i,r2=fittest$r2,ind=i,params=length(fittest$coefs)+fixedparct,
               BIC=BICis,AUC=AUCis,AIC=AICis,RMSE=RMSEis,action=paste("drop\n" ,paste(currentfeatures[i],currentcomponents[i],sep="-")))

        switch(metric,
               "AUC" = {compstat<- -testtable$AUC
               currentcompstat<- -AUCis},
               "AIC" = {compstat<- testtable$AIC
               currentcompstat<-AICis},
               "BIC" = {compstat<- testtable$BIC
               currentcompstat<-BICis},
               "RMSE" = {compstat<- testtable$RMSE
               currentcompstat<-RMSEis},
               "R2" = {compstat<- -testtable$r2
               currentcompstat<- -fittest$r2})

        cat(paste(currentfeatures[i],currentcomponents[i],sep="-"),length(fittest$coefs)+fixedparct,currentcompstat,"\n")
        if(min(compstat)==currentcompstat)(bestmod<-fittest)

      }
      if(min(compstat)-bacv<currentfitscore){cat("removed","\n")
        tracetable<-rbind(tracetable,testtable[which.min(compstat),])
        currentfitscore<-min(compstat)
        cat(currentfeatures[testtable[which.min(compstat),]$feat],currentcomponents[testtable[which.min(compstat),]$comp],"\n")
        currentfeatures<-currentfeatures[-testtable[which.min(compstat),]$feat]
        currentcomponents<-currentcomponents[-testtable[which.min(compstat),]$comp]
      }}

    if(length(currentcomponents)>0){
      fixedparct<-0
      for(ct in currentfeatures){
        if(match(gsub("[$]","",ct),gsub("[$]","",allfeatlist))>0){fixedparct<-fixedparct+featpars[match(gsub("[$]","",ct),gsub("[$]","",allfeatlist))]}}
      currentfit<-LKT(data = data, usefolds=usefolds, interc=interc,maxitv=maxitv,verbose=verbose,
                      components = currentcomponents,
                      features = currentfeatures,fixedpars = rep(NA,fixedparct))

      BICis<- (length(currentfit$coefs)+fixedparct)*log(length(currentfit$prediction))-2*currentfit$loglik
      AUCis<- suppressMessages(pROC::auc(data$CF..ansbin., currentfit$prediction)[1])
      AICis<- (length(currentfit$coefs)+fixedparct)*2-2*currentfit$loglik
      RMSEis<- sqrt(mean((data$CF..ansbin.[data$fold %in% usefolds]-currentfit$prediction[data$fold %in% usefolds])^2))
      cat("\nStep",k,"results - pars ",length(currentfit$coefs)+fixedparct," current BIC",BICis,"current AIC",AICis,"current AUC",AUCis,
                           "current RMSE",RMSEis," McFadden's R2",currentfit$r2,"\n")

      cat(currentfeatures,"\n",currentcomponents,"\n")
      if(!is.atomic(currentfit$optimizedpars)){
        cat("pars",currentfit$optimizedpars$par,"\n")
        paramvec<-currentfit$optimizedpars$par}
    }}

  # repeat until no more above threshold
  # report final
  tryCatch({
    par(mar=c(16, 5, 1, 1))
    matplot(cbind(-scale(tracetable$r2),scale(tracetable$BIC),-scale(tracetable$AUC),
                  scale(tracetable$AIC),scale(tracetable$RMSE)), type="l", xaxt = "n",
            ylab = "Scaled Score", lwd=2, cex=1.5)

    axis(1, at = 1:nrow(tracetable), labels = paste(tracetable$action), cex.axis = 1, las=2)
    legend("topright", c("R2", "BIC", "AUC", "AIC", "RMSE"), col=1:5, cex=1, lty=1:5, lwd=2)
    mtext(side=1, text="Step action", line=14)
  }, error = function(e) {
    print("Problem creating figure.")
  })


  return(list(tracetable,currentfit))
}



#' @title LASSOLKTData
#' @import crayon
#' @description Forward and backwards stepwise search for a set of features and components
#' @description with tracking of nonlinear parameters.
#' @param data is a dataset with Anon.Student.Id and CF..ansbin.
#' @param allcomponents is search space for LKT components
#' @param allfeatures is search space for LKT features
#' @param specialcomponents add special components (not crossed with features, only paired with special features 1 for 1)
#' @param specialfeatures features for each special component (not crossed during search)
#' @param specialpars parameters for the special features (if needed)
#' @param gridpars a vector of parameters to create each feature at
#' @param preset One of "static","AFM","PFA","advanced","AFMLLTM","PFALLTM","advancedLLTM"
#' @param presetint should the intercepts be included for preset components
#' @param removefeat Character Vector | Excludes specified features from the test list.
#' @param removecomp Character Vector | Excludes specified components from the test list.
#' @return data which is the same frame with the added spacing relevant columns.
#' @return list of values "tracetable" and "currentfit"
#' @export
LASSOLKTData <- function(data,gridpars,
                          allcomponents,allfeatures,preset=NA,presetint=T,
                          specialcomponents=c(),specialfeatures=c(),specialpars=c(),removefeat=c(), removecomp=c()){

  #allowable features in search space
  allfeatlist<-c("numer","intercept","lineafm","logafm","logsuc","logfail","linesuc","linefail","propdec",
                 "recency","expdecafm","recencysuc","recencyfail","logitdec","base2","ppe","base")

  featpars<-c(0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,4,1)

  if(!is.na(preset)){if(preset=="static"){allfeatures<-c("intercept")}


    if(preset=="AFM"){allfeatures<-c("intercept","lineafm","logafm","lineafm")}

    if(preset=="AFMLLTM"){allfeatures<-c("intercept","lineafm","logafm","lineafm","lineafm$","logafm$","lineafm$")}

    if(preset=="PFA"){allfeatures<-c("intercept","lineafm","logafm","lineafm", "logsuc","logfail",  "linesuc","linefail")}

    if(preset=="PFALLTM"){allfeatures<-c("intercept","lineafm","logafm","lineafm", "logsuc","logfail",  "linesuc","linefail"
                                         ,"lineafm$","logafm$","lineafm$", "logsuc$","logfail$",  "linesuc$","linefail$")}

    if(preset=="advanced"){allfeatures<-c("intercept","lineafm","logafm","lineafm", "logsuc","logfail",
                                          "linesuc","linefail", "logitdec","propdec","recency","base")}

    if(preset=="advancedLLTM"){allfeatures<-c("intercept","lineafm","logafm","lineafm", "logsuc","logfail",
                                              "linesuc","linefail", "logitdec","propdec","recency","base","lineafm$","logafm$","lineafm$", "logsuc$","logfail$",
                                              "linesuc$","linefail$")}
    if(presetint==F){allfeatures<-allfeatures[allfeatures!="intercept"]}
  }

  cat(white$bgBlack$bold("\nStart making data\n"))

  complist<-c()
  featlist<-c()
  allpars<-c()
  for(i in allcomponents){
    for(j in allfeatures){
      if(featpars[match(gsub("[$]","",j),gsub("[$]","",allfeatlist))]==0){
        complist<-c(complist,i)
        featlist<-c(featlist,j)} else {
          #if it has parameters, add for each value in grid
          complist<-c(complist,rep(i,length(gridpars)))
          featlist<-c(featlist,rep(j,length(gridpars)))
          allpars<-c(allpars,gridpars)}
    }}

  complist<-c(specialcomponents, complist)
  featlist<-c(specialfeatures, featlist)

  combined_list <- paste(complist, featlist, sep = "_")
  remove_list <- paste(removecomp, removefeat, sep = "_")
  indices_to_keep <- !combined_list %in% remove_list
  complist <- complist[indices_to_keep]
  featlist <- featlist[indices_to_keep]


  allpars<-c(specialpars, allpars)
  # retain the best model data
  return(
    LKT(data = data,   components = complist,
        features = featlist,fixedpars = allpars, nosolve=TRUE)
  )
}


#' @title LASSOLKTModel
#' @import crayon
#' @description runs LASSO search on the data
#' @param data is a dataset with Anon.Student.Id and CF..ansbin.
#' @param allcomponents is search space for LKT components
#' @param allfeatures is search space for LKT features
#' @param specialcomponents add special components (not crossed with features, only paired with special features 1 for 1)
#' @param specialfeatures features for each special component (not crossed during search)
#' @param specialpars parameters for the special features (if needed)
#' @param gridpars a vector of parameters to create each feature at
#' @param target_n chosen number of features in model
#' @param removefeat Character Vector | Excludes specified features from the test list.
#' @param removecomp Character Vector | Excludes specified components from the test list.
#' @param preset One of "static","AFM","PFA","advanced","AFMLLTM","PFALLTM","advancedLLTM"
#' @param presetint should the intercepts be included for preset components
#' @param test_fold the fold that the chosen LASSO model will be tested on
#' @return list of matrices and values "train_x","train_y","test_x","test_y","fit","target_auc","target_rmse","n_features","auc_lambda","rmse_lambda","BIC_lambda","target_idx", "preds"
#' @export
LASSOLKTModel <- function(data,gridpars,allcomponents,preset=NA,presetint=T,allfeatures,specialcomponents=c(),
                          specialfeatures=c(),specialpars=c(), target_n,removefeat=c(), removecomp=c(),test_fold = 1){

  datmat = LASSOLKTData(setDT(data),gridpars,
                        allcomponents,allfeatures,preset=preset,presetint=presetint,
                        specialcomponents=specialcomponents,specialfeatures=specialfeatures,
                        specialpars=specialpars,removefeat=removefeat, removecomp=removecomp)

  m1 = as.matrix(datmat$lassodata[[2]])
  colnames(m1) = datmat$lassodata[[1]]

  train_x <- m1
  train_y <- data$CF..ansbin.


  allfold = unique(data$fold)
  all_x = m1
  all_y = data$CF..ansbin.

  train_fold = allfold[which(allfold!=test_fold)]
  train_x = all_x[which(data$fold %in% train_fold),]
  train_y = all_y[which(data$fold %in% train_fold)]
  test_x = all_x[which(data$fold %in% test_fold),]
  test_y = all_y[which(data$fold %in% test_fold)]
  #Test on remaining fold

  start=Sys.time()
  fit=glmnet(x = train_x, y = train_y, family = "binomial")
  end=Sys.time()
  end-start
  print(end-start)

  preds = predict(fit, newx = test_x, s = fit$lambda,type="response")#runs fast


  n_features=rep(NA,length(fit$lambda))
  for(j in 1:length(fit$lambda)){
    coefs=coef(fit, s = fit$lambda[j])
    n_features[j] = length(which(!(coefs==0)))
  }

  auc_lambda <- apply(preds, 2, function(col) {
   roc(test_y, col)$auc
    })

  rmse_lambda <- apply(preds, 2, function(col) {
    rmse_obj <- sqrt(mean((test_y-col)^2))
  })

  target_idx = which.min(abs(n_features - target_n))
  target_auc = auc_lambda[which.min(abs(n_features - target_n))]
  target_rmse = rmse_lambda[which.min(abs(n_features - target_n))]

  #save(preds,target25,target100,cloze_test_results,file=paste0("cloze_testFold_",testf,".RData"))
  BIC_lambda = rep(NA,length(fit$lambda))

  for(i in 1:length(fit$lambda)){
    tLL <- -deviance(fit)[i]
    k <- fit$df[i]
    n <- nobs(fit)
    BIC_lambda[i] = log(n)*k - tLL
    print(i)
  }

  #Returning features retained in lasso model with target lambda along with coefficients
  target_coefs = coef(fit, s = fit$lambda[target_idx])
  kept_features = rownames(target_coefs)[which(!(target_coefs==0))]
  kept_coefs = target_coefs[which(!(target_coefs==0))]
  model_features = data.frame(kept_features = kept_features,kept_coefs = kept_coefs)

  return_list = list(train_x,train_y,test_x,test_y,fit,target_auc,target_rmse,n_features,auc_lambda,rmse_lambda,BIC_lambda,target_idx,preds,target_coefs,model_features)#,fit)
  names(return_list) = c("train_x","train_y","test_x","test_y","fit","target_auc","target_rmse","n_features","auc_lambda","rmse_lambda","BIC_lambda","target_idx","preds","target_coefs","model_features")


  return(return_list)
}






