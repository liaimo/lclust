#' lclust
#' 
#' This function is an implementation of Louvain method --- a fast clustering algorithm.
#' It is designed in the way that one can manually define the number of steps and use the output
#' after any arbitrary number of steps.
#' 
#' The main properties of the algorithm:
#'\itemize{
#' \item Initially each node is assigned to a distinct cluster
#' \item On each pass it tries to move the node from its' own cluster to another one, calculates
#' change in modularity and choose one for which the gain is the most significant if it's positive
#' \item If no move of a single node can improve modularity the algorithm aggregates each cluster
#' and represents it as one node
#' \item Theese two steps repeats \code{n} times
#' }
#' @return list of groups
#' @param A symmetric adjacency matrix
#' @param n number of steps 
#' @export
#' @examples
#' lclust(A, n = 2)
#' lclust(A)
#' @references Blondel, V. D., Guillaume, J. L., Lambiotte, R., & Lefebvre, E. (2008). 
#' Fast unfolding of communities in large networks. Journal of Statistical Mechanics: 
#' Theory and Experiment, 2008(10), P10008.
lclust <- function(A = matrix(), n = 5) {
  global <- list()
  
  if (n == 1) { 
    return(firstPass(A)) 
  } else {
    for (i in 1:n) {
      global[[i]] <- firstPass(A)  
      if (i < n) {
        A <- aggregate(firstPass(A), A)
      }
    }
    
    levels <- length(global)
    for(j in levels:2) {
      res <- list()
      upper <- global[[j]]
      lower <- global[[j-1]]
      for (k in 1:length(upper)) {
        id <- upper[[k]]
        add <- combine(lower, id)
        res <- append(res, list(add))
      }
      global[[j - 1]] <- res
      global[[j]] <- NULL
    }
    
    for (i in 1:length(global[[1]])) {
      global[[1]][[i]] <- sort(global[[1]][[i]])
    }
    return(global[[1]])
  }
  
}
# helper functions --------------------------------------------------

# matching vector with list elements
listMatch <- function(x = list(), k = с()) {
  for (i in 1:length(x)) {
    if ( length(x[[i]]) == length(k)) {
      if ( sum(x[[i]] == k) == length(k) ) {
        return(i)
        break
      }
    }
  }
  return(0)
}

# merging several elements of a list together
combine <- function(list = list(), id = c()) {
  res <- c()
  for (i in 1:length(id)) {
  res <- c(res, list[[id[i]]])
  }
  return(res)
}

# one pass of a matrix
firstPass <- function(A = matrix()) {
  
  g <- graph.adjacency(A)
  M <- A - diag( diag(A) )
  m <- sum( diag(A) ) + sum( as.vector(M) ) / 2
  groups <- as.list( 1:ncol(A) )
  # mod <- modularity(g, groups)
  
  repeat {
  controls <- c()
  for (i in 1:nrow(A)) {
    
    if (listMatch(groups, i) > 0) {
    Q <- c()
    
    for (j in 1:length(groups)) {
      
      if ( sum( M[ i, groups[[j]] ] ) > 0) { # if node i has at least one neighbor in this group
       id <- groups[[j]]
       if (length(id) > 1) {
         Sin <- sum(diag(A[id, id])) + sum( as.vector(M[id, id]) ) / 2 
       } else { 
         Sin <- sum( as.vector(A[id, id]) ) 
       }
        kin <- sum( A[i, id] )                  
        kall <- sum( A[i, ])  
        Stot <- Sin + sum( as.vector(A[id, -id]) )
        dQ <- kin/2/m - Stot*kall/2/m^2
       
        if (dQ > 0)  {
          Q <- c(Q, dQ)
        } else {
          Q <- c(Q, 0)
        }
      } else {
        Q <- c(Q, 0)
      }
      
    }
    
    if (sum(Q) > 0) {
      res <- which.max(Q)
      groups[[res]] <- c(groups[[res]], i)
      del <- listMatch(groups, i)
      groups <- groups[-del]
     # mod <- mod + Q[which.max(Q)]
    } 
    
    cond <- sapply(groups, function(x) length(x))
    if (min(cond) > 1) break
    
    controls <- c(controls, Q[which.max(Q)])
     }
    
  }
  
   res <- sapply(groups, function(x) length(x))
   if( min(res) > 1 | sum(controls) == 0) break
}
# print(mod)
  return(groups)
}

# aggregation function
aggregate <- function(groups = list(), A = matrix()) {
  n <- length(groups)
  S <- matrix(rep(0, n*n), n, n)
  for (i in 1:n) {
    for (j in 1:n) {
       L <- A[ groups[[i]], groups[[j]] ]
     if (i == j) {
       M <- L - diag(diag(L))
       S[i,j] <- sum(diag(L)) + sum( as.vector( M )) / 2
     } else {
       S[i,j] <- sum( as.vector( L ))
     }
    }
  }
  return(S) 
}