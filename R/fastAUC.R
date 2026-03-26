#' Fast AUC Calculation Using Ranks
#'
#' Computes the Area Under the ROC Curve using a rank-based approach.
#' This avoids pairwise comparisons and runs in O(n log n) time.
#'
#' @param p Numeric vector of predicted probabilities.
#' @param y Binary (0/1) vector of true outcomes. Must be the same length
#'   as `p`.
#'
#' @return A single numeric AUC value between 0 and 1.
#'
#' @examples
#' # Perfect separation
#' fastAUC(c(0.1, 0.2, 0.8, 0.9), c(0, 0, 1, 1))
#'
#' @export
fastAUC <- function(p, y) {
  x1 <- p[y == 1]
  n1 <- length(x1)
  x2 <- p[y == 0]
  n2 <- length(x2)
  r <- rank(c(x1, x2))
  auc <- (sum(r[1:n1]) - n1 * (n1 + 1) / 2) / n1 / n2
  auc
}
