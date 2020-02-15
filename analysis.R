## Analyze Resutls
library(dplyr)

candidates <- c("Biden, d", "Buttigieg, d", "Klobuchar, d", "Sanders, d", "Warren, d")

results <- read.csv("clean/all_results.csv")
townships <- read.csv("clean/all_townships.csv")

township_totals <- results %>%
	group_by(township) %>%
	summarise(total = sum(count))

results %>%
	subset(candidate %in% candidates) %>%
	merge(township_totals, by="township") %>%
	subset(total > 0) %>%
	group_by(candidate, township, county) %>%
	summarise(
		count = count,
		percent = count/total
	) %>%
	merge(townships, by="township") %>%
	mutate(
		machine = ifelse(is.na(machine), 0, machine)
	)

## Overview
results %>%
	subset(candidate %in% candidates) %>%
	merge(township_totals, by="township") %>%
	subset(total > 0) %>%
	merge(townships, by="township")  %>%
	mutate(
		machine = ifelse(is.na(machine), 0, machine)
	) %>%
	group_by(candidate, machine) %>%
	summarise(
		votes = sum(count),
		total = sum(total)
	) %>%
	mutate(
		percent = sprintf("%0.1f%%", 100*votes/total)
	) %>%
	as.data.frame() %>%
	knitr::kable()

 # county,
