#' Draw edges as elbows
#'
#' This geom draws edges as an angle in the same manner as known from classic
#' dendrogram plots of hierarchical clustering results. In case a circular
#' transformation has been applied the first line segment will be drawn as an
#' arc as expected. This geom is only applicable to layouts that return a
#' direction for the edges (currently \code{\link{layout_dendrogram_dendrogram}}
#' and \code{\link{layout_dendrogram_dendrogram}}).
#'
#' @details
#' Many geom_edge_* layers comes in 3 flavors depending on the level of control
#' needed over the drawing. The default (no numeric postfix) generate a number
#' of points (\code{n}) along the edge and draws it as a path. Each point along
#' the line has a numeric value associated with it giving the position along the
#' path, and it is therefore possible to show the direction of the edge by
#' mapping to this e.g. \code{colour = ..index..}. The version postfixed with a
#' "2" uses the "long" edge format (see \code{\link{gEdges}}) and makes it
#' possible to interpolate node parameter between the start and end node along
#' the edge. It is considerable less performant so should only be used if this
#' is needed. The version postfixed with a "0" draws the edge in the most
#' performant way, often directly using an appropriate grob from the grid
#' package, but does not allow for gradients along the edge.
#'
#' @note In order to avoid excessive typing edge aesthetic names are
#' automatically expanded. Because of this it is not necessary to write
#' \code{edge_colour} within the \code{aes()} call as \code{colour} will
#' automatically be renamed appropriately.
#'
#' @section Aesthetics:
#' geom_edge_elbow and geom_edge_elbow0 understand the following
#' aesthetics. Bold aesthetics are automatically set, but can be overridden.
#' \itemize{
#'  \item{\strong{x}}
#'  \item{\strong{y}}
#'  \item{\strong{xend}}
#'  \item{\strong{yend}}
#'  \item{\strong{circular}}
#'  \item{\strong{direction}}
#'  \item{edge_colour}
#'  \item{edge_width}
#'  \item{edge_linetype}
#'  \item{edge_alpha}
#'  \item{filter}
#' }
#' geom_edge_elbow2 understand the following aesthetics. Bold aesthetics are
#' automatically set, but can be overridden.
#' \itemize{
#'  \item{\strong{x}}
#'  \item{\strong{y}}
#'  \item{\strong{group}}
#'  \item{\strong{circular}}
#'  \item{\strong{direction}}
#'  \item{edge_colour}
#'  \item{edge_width}
#'  \item{edge_linetype}
#'  \item{edge_alpha}
#'  \item{filter}
#' }
#'
#' @section Computed variables:
#'
#' \describe{
#'  \item{index}{The position along the path (not computed for the *0 version)}
#' }
#'
#' @param mapping Set of aesthetic mappings created by \code{\link[ggplot2]{aes}}
#' or \code{\link[ggplot2]{aes_}}. By default x, y, xend, yend, group and
#' circular are mapped to x, y, xend, yend, edge.id and circular in the edge
#' data.
#'
#' @param data The return of a call to \code{gEdges()} or a data.frame
#' giving edges in corrent format (see details for for guidance on the format).
#' See \code{\link{gEdges}} for more details on edge extraction.
#'
#' @param position Position adjustment, either as a string, or the result of a
#' call to a position adjustment function. Currently no meaningful position
#' adjustment exists for edges.
#'
#' @param n The number of points to create along the path.
#'
#' @param flipped Logical, Has the layout been flipped by reassigning the
#' mapping of x, y etc?
#'
#' @param arrow Arrow specification, as created by \code{\link[grid]{arrow}}
#'
#' @param lineend Line end style (round, butt, square)
#'
#' @param ... other arguments passed on to \code{\link[ggplot2]{layer}}. There
#' are three types of arguments you can use here:
#' \itemize{
#'  \item{Aesthetics: to set an aesthetic to a fixed value, like
#'  \code{color = "red"} or \code{size = 3.}}
#'  \item{Other arguments to the layer, for example you override the default
#'  \code{stat} associated with the layer.}
#'  \item{Other arguments passed on to the stat.}
#' }
#'
#' @param show.legend logical. Should this layer be included in the legends?
#' \code{NA}, the default, includes if any aesthetics are mapped. \code{FALSE}
#' never includes, and \code{TRUE} always includes.
#'
#' @author Thomas Lin Pedersen
#'
#' @family geom_edge_*
#'
#' @examples
#' irisDen <- as.dendrogram(
#'   hclust(dist(iris[1:4],
#'               method='euclidean', ),
#'          method='ward.D2')
#' )
#' irisDen <- dendrapply(irisDen, function(x) {
#'   attr(x, 'nodePar') <- list(class = sample(letters[1:3], 1))
#'   attr(x, 'edgePar') <- list(class = sample(letters[1:3], 1))
#'   x
#' })
#'
#' ggraph(irisDen, 'even', circular = TRUE) +
#'   geom_edge_elbow(aes(alpha = ..index..))
#'
#' ggraph(irisDen, 'even') +
#'   geom_edge_elbow2(aes(colour = node.class),
#'                       gEdges('long', nodePar = 'class'))
#'
#' ggraph(irisDen, 'dendrogram') +
#'   geom_edge_elbow0(aes(colour = class))
#'
#' @rdname geom_edge_elbow
#' @name geom_edge_elbow
#'
NULL

#' @rdname ggraph-extensions
#' @format NULL
#' @usage NULL
#' @importFrom ggplot2 ggproto Stat
#' @importFrom ggforce radial_trans
#' @export
StatEdgeElbow <- ggproto('StatEdgeElbow', Stat,
    compute_panel = function(data, scales, flipped = FALSE, n = 100) {
        if (n %% 2) n <- n + 1
        index <- seq(0, 1, length.out = n)
        if (any(data$circular)) {
            circId <- which(data$circular)
            dataCirc <- data[circId, ]
            radial <- radial_trans(c(0, 1), c(2*pi, 0), pad = 0, offset = 0)
            start <- atan2(dataCirc$y, dataCirc$x)
            radiiStart <- sqrt(dataCirc$x^2 + dataCirc$y^2)
            radiiEnd <- sqrt(dataCirc$xend^2 + dataCirc$yend^2)
            angelDiff <- (dataCirc$x*dataCirc$xend + dataCirc$y*dataCirc$yend) /
             (radiiStart*radiiEnd)
            angelDiff[is.nan(angelDiff)] <- 0
            angelDiff <- suppressWarnings(acos(angelDiff))
            angelDiff[is.nan(angelDiff)] <- 0
            end <- start + ifelse(dataCirc$direction == 'left',
                                  -angelDiff, angelDiff)
            angles <- unlist(Map(seq, from = start, to = end, length.out = n/2))
            radii <- rep(sqrt(data$y[circId]^2 + data$x[circId]^2), each = n/2)
            pathCirc <- radial$transform(r = radii, a = angles)
            pathCirc$group <- rep(circId, each = n/2)
            pathCirc$index <- rep(index[seq_len(n/2)], length(circId))
            radiiRel <- radiiStart / radiiEnd
            elbowX <- dataCirc$xend * radiiRel
            elbowY <- dataCirc$yend * radiiRel
            elbowX <- unlist(Map(seq, from = elbowX, to = dataCirc$xend,
                                 length.out = n/2))
            elbowY <- unlist(Map(seq, from = elbowY, to = dataCirc$yend,
                                 length.out = n/2))
            pathCirc <- rbind(pathCirc,
                              data.frame(x = elbowX,
                                         y = elbowY,
                                         group = pathCirc$group,
                                         index = rep(index[seq_len(n/2) + n/2],
                                                     length(circId))))
            pathCirc <- cbind(pathCirc, data[pathCirc$group, !names(data) %in%
                                                 c('x', 'y', 'xend', 'yend')])
        }
        if (any(!data$circular)) {
            pathLin <- lapply(which(!data$circular), function(i) {
                if (flipped) {
                    path <- data.frame(
                        x = approx(c(data$x[i], data$x[i], data$xend[i]),
                                   n = n)$y,
                        y = approx(c(data$y[i], data$yend[i], data$yend[i]),
                                   n = n)$y,
                        group = i,
                        index = index
                    )
                } else {
                    path <- data.frame(
                        x = approx(c(data$x[i], data$xend[i], data$xend[i]),
                                   n = n)$y,
                        y = approx(c(data$y[i], data$y[i], data$yend[i]),
                                   n = n)$y,
                        group = i,
                        index = index
                    )
                }
                cbind(path, data[rep(i, nrow(path)), !names(data) %in%
                                     c('x', 'y', 'xend', 'yend')])
            })
            pathLin <- do.call(rbind, pathLin)

            if (any(data$circular)) {
                paths <- rbind(pathLin, pathCirc)
            } else {
                paths <- pathLin
            }
        } else {
            paths <- pathCirc
        }
        paths[order(paths$group), ]
    },
    setup_data = function(data, params) {
        if (any(names(data) == 'filter')) {
            if (!is.logical(data$filter)) {
                stop('filter must be logical')
            }
            data <- data[data$filter, names(data) != 'filter']
        }
        data
    },
    default_aes = aes(filter = TRUE),
    required_aes = c('x', 'y', 'xend', 'yend', 'circular', 'direction')
)
#' @rdname geom_edge_elbow
#'
#' @importFrom ggplot2 layer aes_
#' @export
geom_edge_elbow <- function(mapping = NULL, data = gEdges(),
                            position = "identity", arrow = NULL, flipped = FALSE,
                            lineend = "butt", show.legend = NA, n = 100, ...) {
    mapping <- completeEdgeAes(mapping)
    mapping <- aesIntersect(mapping, aes_(x=~x, y=~y, xend=~xend, yend=~yend,
                                          circular=~circular,
                                          direction=~direction))
    layer(data = data, mapping = mapping, stat = StatEdgeElbow,
          geom = GeomEdgePath, position = position, show.legend = show.legend,
          inherit.aes = FALSE,
          params = list(arrow = arrow, lineend = lineend, na.rm = FALSE, n = n,
                        interpolate = FALSE, flipped = flipped, ...)
    )
}
#' @rdname ggraph-extensions
#' @format NULL
#' @usage NULL
#' @importFrom ggplot2 ggproto Stat
#' @export
StatEdgeElbow2 <- ggproto('StatEdgeElbow2', Stat,
    compute_panel = function(data, scales, flipped = FALSE, n = 100) {
        posCols <- c('x', 'y', 'group', 'circular', 'direction', 'PANEL')
        data <- data[order(data$group), ]
        posData <- cbind(data[c(TRUE, FALSE), posCols], data[c(FALSE, TRUE),
                                                             c('x', 'y')])
        names(posData) <- c(posCols, 'xend', 'yend')
        newData <- StatEdgeElbow$compute_panel(posData, scales, flipped, n)
        extraCols <- !names(data) %in% posCols
        index <- match(seq_len(nrow(posData)), newData$group)
        index <- as.vector(rbind(index, index + 1))
        newData$.interp <- TRUE
        newData$.interp[index] <- FALSE
        if (sum(extraCols) != 0) {
            for (i in names(data)[extraCols]) {
                newData[[i]] <- NA
                newData[[i]][index] <- data[[i]]
            }
        }
        newData
    },
    setup_data = function(data, params) {
        if (any(names(data) == 'filter')) {
            if (!is.logical(data$filter)) {
                stop('filter must be logical')
            }
            data <- data[data$filter, names(data) != 'filter']
        }
        data
    },
    default_aes = aes(filter = TRUE),
    required_aes = c('x', 'y', 'group', 'circular', 'direction')
)
#' @rdname geom_edge_elbow
#'
#' @importFrom ggplot2 layer aes_
#' @export
geom_edge_elbow2 <- function(mapping = NULL, data = gEdges('long'),
                            position = "identity", arrow = NULL, flipped = FALSE,
                            lineend = "butt", show.legend = NA, n = 100, ...) {
    mapping <- completeEdgeAes(mapping)
    mapping <- aesIntersect(mapping, aes_(x=~x, y=~y, group=~edge.id,
                                          circular=~circular,
                                          direction=~direction))
    layer(data = data, mapping = mapping, stat = StatEdgeElbow2,
          geom = GeomEdgePath, position = position, show.legend = show.legend,
          inherit.aes = FALSE,
          params = list(arrow = arrow, lineend = lineend, na.rm = FALSE, n = n,
                        interpolate = TRUE, flipped = flipped, ...)
    )
}
#' @rdname ggraph-extensions
#' @format NULL
#' @usage NULL
#' @importFrom ggplot2 ggproto Stat
#' @export
StatEdgeElbow0 <- ggproto('StatEdgeElbow0', Stat,
    compute_panel = function(data, scales, flipped = FALSE) {
        if (any(data$circular)) {
            circId <- which(data$circular)
            dataCirc <- data[circId, ]
            radial <- radial_trans(c(0, 1), c(2*pi, 0), pad = 0, offset = 0)
            start <- atan2(dataCirc$y, dataCirc$x)
            angelDiff <- (dataCirc$x*dataCirc$xend + dataCirc$y*dataCirc$yend) /
                (sqrt(dataCirc$x^2 + dataCirc$y^2) *
                     sqrt(dataCirc$xend^2 + dataCirc$yend^2))
            angelDiff[is.nan(angelDiff)] <- 0
            angelDiff <- suppressWarnings(acos(angelDiff))
            angelDiff[is.nan(angelDiff)] <- 0
            end <- start + ifelse(dataCirc$direction == 'left',
                                  -angelDiff, angelDiff)
            angles <- unlist(Map(seq, from = start, to = end, length.out = 50))
            radii <- rep(sqrt(data$y[circId]^2 + data$x[circId]^2), each = 50)
            pathCirc <- radial$transform(r = radii, a = angles)
            pathCirc$group <- rep(circId, each = 50)
            pathCirc <- rbind(pathCirc,
                              data.frame(x = data$xend[circId],
                                         y = data$yend[circId],
                                         group = circId))
            pathCirc <- cbind(pathCirc, data[pathCirc$group, !names(data) %in%
                                                 c('x', 'y', 'xend', 'yend')])
        }
        if (any(!data$circular)) {
            pathLin <- lapply(which(!data$circular), function(i) {
                if (flipped) {
                    path <- data.frame(
                        x = c(data$x[i], data$x[i], data$xend[i]),
                        y = c(data$y[i], data$yend[i], data$yend[i]),
                        group = i
                    )
                } else {
                    path <- data.frame(
                        x = c(data$x[i], data$xend[i], data$xend[i]),
                        y = c(data$y[i], data$y[i], data$yend[i]),
                        group = i
                    )
                }
                cbind(path, data[rep(i, nrow(path)), !names(data) %in%
                                     c('x', 'y', 'xend', 'yend')])
            })
            pathLin <- do.call(rbind, pathLin)

            if (any(data$circular)) {
                paths <- rbind(pathLin, pathCirc)
            } else {
                paths <- pathLin
            }
        } else {
            paths <- pathCirc
        }
        paths[order(paths$group), ]
    },
    setup_data = function(data, params) {
        if (any(names(data) == 'filter')) {
            if (!is.logical(data$filter)) {
                stop('filter must be logical')
            }
            data <- data[data$filter, names(data) != 'filter']
        }
        data
    },
    default_aes = aes(filter = TRUE),
    required_aes = c('x', 'y', 'xend', 'yend', 'circular', 'direction')
)
#' @rdname geom_edge_elbow
#'
#' @importFrom ggplot2 layer aes_
#' @export
geom_edge_elbow0 <- function(mapping = NULL, data = gEdges(),
                            position = "identity", arrow = NULL, flipped = FALSE,
                            lineend = "butt", show.legend = NA, ...) {
    mapping <- completeEdgeAes(mapping)
    mapping <- aesIntersect(mapping, aes_(x=~x, y=~y, xend=~xend, yend=~yend,
                                          circular=~circular,
                                          direction=~direction))
    layer(data = data, mapping = mapping, stat = StatEdgeElbow0,
          geom = GeomEdgePath, position = position, show.legend = show.legend,
          inherit.aes = FALSE,
          params = list(arrow = arrow, lineend = lineend, na.rm = FALSE,
                        interpolate = FALSE, flipped = flipped, ...)
    )
}
