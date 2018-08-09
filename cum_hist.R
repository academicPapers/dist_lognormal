panel.cumul.histogram <- function (x, breaks, equal.widths = TRUE, 
                                   type = "density", 
                                   nint = round(log2(length(x)) + 1), 
                                   alpha = plot.polygon$alpha, 
                                   col = plot.polygon$col, 
                                   border = plot.polygon$border, 
                                   lty = plot.polygon$lty, 
                                   lwd = plot.polygon$lwd,
                                   ...) 
{ 
  plot.polygon <- trellis.par.get("plot.polygon") 
  xscale <- current.panel.limits()$xlim 
  panel.lines(x = xscale[1] + diff(xscale) * c(0.05, 0.95), 
              y = c(0, 0), col = border, lty = lty, lwd = lwd, alpha = alpha) 
  if (length(x) > 0) { 
    if (is.null(breaks)) { 
      breaks <- if (is.factor(x)) 
        seq_len(1 + nlevels(x)) - 0.5 
      else if (equal.widths) 
        do.breaks(range(x, finite = TRUE), nint) 
      else quantile(x, 0:nint/nint, na.rm = TRUE) 
    } 
    h <- lattice:::hist.constructor(x, breaks = breaks, ...) 
    
    h$counts<- cumsum(h$counts) 
    
    y <- if (type == "count") 
      h$counts 
    else if (type == "percent") 
      100 * h$counts/length(x) 
    else h$intensities 
    breaks <- h$breaks 
    nb <- length(breaks) 
    if (length(y) != nb - 1) 
      warning("problem with 'hist' computations") 
    if (nb > 1) { 
      panel.rect(x = breaks[-nb], y = 0, height = y, width = 
                   diff(breaks), 
                 col = col, alpha = alpha, border = border, lty = lty, 
                 lwd = lwd, just = c("left", "bottom")) 
    } 
  } 
} 
