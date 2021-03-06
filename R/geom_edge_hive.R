#' Draw edges in hive plots
#'
#' This geom is only intended for use together with the hive layout. It draws
#' edges between nodes as bezier curves, with the control points positioned at
#' the same radi as the start or end point, and at a distance defined by the
#' curvature argument.
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
#' geom_edge_hive and geom_edge_hive0 understand the following
#' aesthetics. Bold aesthetics are automatically set, but can be overridden.
#' \itemize{
#'  \item{\strong{x}}
#'  \item{\strong{y}}
#'  \item{\strong{xend}}
#'  \item{\strong{yend}}
#'  \item{edge_colour}
#'  \item{edge_width}
#'  \item{edge_linetype}
#'  \item{edge_alpha}
#'  \item{filter}
#' }
#' geom_edge_hive2 understand the following aesthetics. Bold aesthetics are
#' automatically set, but can be overridden.
#' \itemize{
#'  \item{\strong{x}}
#'  \item{\strong{y}}
#'  \item{\strong{group}}
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
#' are mapped to x, y, xend, yend, and edge.id in the edge data.
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
#' @param curvature The curvature of the bezier. Defines the distance from the
#' control points to the midpoint between the start and end node. 1 means the
#' control points are positioned midway between the nodes, while 0 means it
#' coincide with the nodes (resulting in straight lines)
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
#' # Plot the flare import graph as a hive plot
#' library(igraph)
#' flareGr <- graph_from_data_frame(flare$imports)
#'
#' # Add some metadata to divide nodes by
#' V(flareGr)$type <- 'Both'
#' V(flareGr)$type[degree(flareGr, mode = 'in') == 0] <- 'Source'
#' V(flareGr)$type[degree(flareGr, mode = 'out') == 0] <- 'Sink'
#'
#' analyticsNodes <- grep('flare.analytics', V(flareGr)$name)
#' E(flareGr)$type <- 'Other'
#' E(flareGr)[inc(analyticsNodes)]$type <- 'Analytics'
#'
#' ggraph(flareGr, 'hive', axis = 'type') +
#'   geom_edge_hive(aes(colour = type), edge_alpha = 0.1) +
#'   coord_fixed()
#'
#' @rdname geom_edge_hive
#' @name geom_edge_hive
#'
NULL

#' @rdname ggraph-extensions
#' @format NULL
#' @usage NULL
#' @importFrom ggplot2 ggproto
#' @importFrom ggforce StatBezier
#' @export
StatEdgeHive <- ggproto('StatEdgeHive', StatBezier,
    setup_data = function(data, params) {
        if (any(names(data) == 'filter')) {
            if (!is.logical(data$filter)) {
                stop('filter must be logical')
            }
            data <- data[data$filter, names(data) != 'filter']
        }
        data$group <- seq_len(nrow(data))
        data2 <- data
        data2$x <- data2$xend
        data2$y <- data2$yend
        data$xend <- NULL
        data$yend <- NULL
        data2$xend <- NULL
        data2$yend <- NULL
        keep <- atan2(data$y, data$x) != atan2(data2$y, data2$x)
        createHiveBezier(data[keep, ], data2[keep, ], params)
    },
    required_aes = c('x', 'y', 'xend', 'yend'),
    default_aes = aes(filter = TRUE),
    extra_params = c('na.rm', 'n', 'curvature')
)
#' @rdname geom_edge_hive
#'
#' @importFrom ggplot2 layer aes_
#' @export
geom_edge_hive <- function(mapping = NULL, data = gEdges(),
                           position = "identity", arrow = NULL, curvature = 0.5,
                           lineend = "butt", show.legend = NA, n = 100, ...) {
    mapping <- completeEdgeAes(mapping)
    mapping <- aesIntersect(mapping, aes_(x=~x, y=~y, xend=~xend, yend=~yend))
    layer(data = data, mapping = mapping, stat = StatEdgeHive,
          geom = GeomEdgePath, position = position, show.legend = show.legend,
          inherit.aes = FALSE,
          params = list(arrow = arrow, lineend = lineend, na.rm = FALSE, n = n,
                        interpolate = FALSE, curvature = curvature, ...)
    )
}
#' @rdname ggraph-extensions
#' @format NULL
#' @usage NULL
#' @importFrom ggplot2 ggproto Stat
#' @importFrom ggforce StatBezier2
#' @export
StatEdgeHive2 <- ggproto('StatEdgeHive2', StatBezier2,
    setup_data = function(data, params) {
        if (any(names(data) == 'filter')) {
            if (!is.logical(data$filter)) {
                stop('filter must be logical')
            }
            data <- data[data$filter, names(data) != 'filter']
        }
        data <- data[order(data$group),]
        data2 <- data[c(FALSE, TRUE), ]
        data <- data[c(TRUE, FALSE), ]
        keep <- atan2(data$y, data$x) != atan2(data2$y, data2$x)
        createHiveBezier(data[keep, ], data2[keep, ], params)
    },
    required_aes = c('x', 'y', 'group'),
    default_aes = aes(filter = TRUE),
    extra_params = c('na.rm', 'n', 'curvature')
)
#' @rdname geom_edge_hive
#'
#' @importFrom ggplot2 layer aes_
#' @export
geom_edge_hive2 <- function(mapping = NULL, data = gEdges('long'),
                            position = "identity", arrow = NULL, curvature = 0.5,
                            lineend = "butt", show.legend = NA, n = 100, ...) {
    mapping <- completeEdgeAes(mapping)
    mapping <- aesIntersect(mapping, aes_(x=~x, y=~y, group=~edge.id))
    layer(data = data, mapping = mapping, stat = StatEdgeHive2,
          geom = GeomEdgePath, position = position, show.legend = show.legend,
          inherit.aes = FALSE,
          params = list(arrow = arrow, lineend = lineend, na.rm = FALSE, n = n,
                        interpolate = TRUE, curvature = curvature, ...)
    )
}
#' @rdname ggraph-extensions
#' @format NULL
#' @usage NULL
#' @importFrom ggplot2 ggproto
#' @importFrom ggforce StatBezier0
#' @export
StatEdgeHive0 <- ggproto('StatEdgeHive0', StatBezier0,
    setup_data = function(data, params) {
        StatEdgeHive$setup_data(data, params)
    },
    required_aes = c('x', 'y', 'xend', 'yend'),
    default_aes = aes(filter = TRUE),
    extra_params = c('na.rm', 'curvature')
)
#' @rdname geom_edge_hive
#'
#' @importFrom ggplot2 layer aes_
#' @export
geom_edge_hive0 <- function(mapping = NULL, data = gEdges(),
                           position = "identity", arrow = NULL, curvature = 0.5,
                           lineend = "butt", show.legend = NA, ...) {
    mapping <- completeEdgeAes(mapping)
    mapping <- aesIntersect(mapping, aes_(x=~x, y=~y, xend=~xend, yend=~yend))
    layer(data = data, mapping = mapping, stat = StatEdgeHive0,
          geom = GeomEdgeBezier, position = position, show.legend = show.legend,
          inherit.aes = FALSE,
          params = list(arrow = arrow, lineend = lineend, na.rm = FALSE,
                        curvature = curvature, ...)
    )
}
createHiveBezier <- function(from, to, params) {
    bezierStart <- seq(1, by=4, length.out = nrow(from))
    from$index <- bezierStart
    to$index <- bezierStart + 3
    data2 <- from
    data3 <- to
    data2$index <- bezierStart + 1
    data3$index <- bezierStart + 2
    fromAxis <- atan2(from$y, from$x)
    fromAxis[fromAxis < 0] <- fromAxis[fromAxis < 0] + 2 * pi
    toAxis <- atan2(to$y, to$x)
    toAxis[toAxis < 0] <- toAxis[toAxis < 0] + 2 * pi
    fromFirst <- ifelse(fromAxis < toAxis,
                        toAxis - fromAxis < pi,
                        toAxis - fromAxis < -pi)
    middleAxis1 <- ifelse(fromFirst, fromAxis, toAxis)
    middleAxis2 <- ifelse(fromFirst, toAxis, fromAxis)
    middleAxis2 <- ifelse(middleAxis2 < middleAxis1, middleAxis2 + 2*pi, middleAxis2)
    meanAxis <- (middleAxis2 - middleAxis1)/2
    middleAxis1 <- middleAxis1 + meanAxis * params$curvature
    middleAxis2 <- middleAxis2 - meanAxis * params$curvature
    nodeR2 <- sqrt(data2$x^2 + data2$y^2)
    nodeR3 <- sqrt(data3$x^2 + data3$y^2)
    data2$x <- nodeR2 * cos(ifelse(fromFirst, middleAxis1, middleAxis2))
    data2$y <- nodeR2 * sin(ifelse(fromFirst, middleAxis1, middleAxis2))
    data3$x <- nodeR3 * cos(ifelse(fromFirst, middleAxis2, middleAxis1))
    data3$y <- nodeR3 * sin(ifelse(fromFirst, middleAxis2, middleAxis1))
    data <- rbind(from, data2, data3, to)
    data[order(data$index), names(data) != 'index']
}
