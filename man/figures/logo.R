library(rjd3x13)
library(rjd3toolkit)
library(ggplot2)
plot(ABS[[1]])
plot(ABS[[10]])
y <- ABS[[10]]
mod <- x13(y)
sa <- ggdemetra3::seasonaladj(mod)
seasonal <- ggdemetra3::seasonal(mod)
trend <- ggdemetra3::trendcycle(mod)
irr <- ggdemetra3::irregular(mod)
general_colors <- c(y = "#F0B400", t = "#7B7B7B", sa = "#155692",
                    cal = "#F0B400", s = "#1E6C0B", i = "#155692")
data <- data.frame(
    time = as.numeric(time(y)),
    y = as.numeric(y),
    sa = as.numeric(sa),
    s = as.numeric(seasonal),
    tc = as.numeric(trend),
    irr = as.numeric(irr)
)
data <- data[data$time>=2004,]
p_tc <- ggplot(mapping = aes(x = time)) +
    geom_line(data = data[data$time <= 2009, ],
              mapping = aes(y = y), color = general_colors["y"], linewidth = 1) +
    geom_line(data = data[data$time >= 2009, ],
              mapping = aes(y = tc), color = general_colors["t"], linewidth = 1) +
    scale_x_continuous(expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0)) +
    # 2. Désactive l'expansion automatique dans les coordonnées
    coord_cartesian(expand = FALSE) +
    # 3. Supprime les éléments de thème ET supprime explicitement plot.margin
    theme_void() +
    theme(
        panel.background = element_blank(),
        plot.background = element_blank(),
        plot.margin = margin(0, 0, 0, 0, "pt")
    )
p_irr <- ggplot(mapping = aes(x = time)) +
    geom_line(data = data[data$time >= 2009, ],
              mapping = aes(y = irr), color = general_colors["i"], linewidth = 1) +
    scale_x_continuous(expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0)) +
    # 2. Désactive l'expansion automatique dans les coordonnées
    coord_cartesian(expand = FALSE) +
    # 3. Supprime les éléments de thème ET supprime explicitement plot.margin
    theme_void() +
    theme(
        panel.background = element_blank(),
        plot.background = element_blank(),
        plot.margin = margin(0, 0, 0, 0, "pt")
    )
p_s <- ggplot(mapping = aes(x = time)) +
    geom_line(data = data[data$time >= 2009, ],
              mapping = aes(y = s), color = general_colors["s"], linewidth = 1.3) +
    scale_x_continuous(expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0)) +
    # 2. Désactive l'expansion automatique dans les coordonnées
    coord_cartesian(expand = FALSE) +
    # 3. Supprime les éléments de thème ET supprime explicitement plot.margin
    theme_void() +
    theme(
        panel.background = element_blank(),
        plot.background = element_blank(),
        plot.margin = margin(0, 0, 0, 0, "pt")
    )
p_tc
p_irr
p_s

ggsave("man/figures/tc_comp.svg", p_tc,
       width = 1200,
       height = 600,
       units = "px",
       bg = "transparent")
ggsave("man/figures/irr_comp.svg", p_irr,
       width = 1200,
       height = 600,
       units = "px",
       bg = "transparent")
ggsave("man/figures/s_comp.svg", p_s,
       width = 1200,
       height = 600,
       units = "px",
       bg = "transparent")
