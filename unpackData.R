library(readxl)
library(dplyr)
library(reshape2)

extractRow <- function(x){
	x %>%
		c() %>%
		unlist() %>%
		unname()
}

combineNames <- function(x){
	if(length(x) > 1){
		return(ifelse(is.na(x[[1]]), x[[2]], x[[1]]))
	}
	return(unlist(x))
}

cleanNames <- function(tkn){
	gsub("-|'|&'", "", tkn) %>%
		gsub(pattern=" +", replacement=" ")
}


## First pass through the data, find where the data starts and right headers to import
findIndex <- function(x){
	tmp <- read_xls(x, sheet=1,) %>%
		data.frame()
	j = grep("Bennet, d", tmp[,1])

	rownames <- lapply(1:(j-1), function(x){
		extractRow(tmp[x,])
	}) %>%
		combineNames()

	list(
		file_path = x,
		data_start = j,
		county =  tmp[,1][j-1],
		headers = sapply(rownames, cleanNames)
	)
}

## Second pass, read data then process
parseResults <- function(x){
	repeat_col <- grep(substr(x$headers[1], 1,6), x$headers)[2]
	if(length(repeat_col) > 0){
		x$headers[repeat_col] = "remove"
	}
	read_xls(x$file_path, sheet=1, skip=x$data_start, col_names=FALSE) %>%
		setNames(x$headers) %>%
		select(-starts_with("remove")) %>%
		melt(id.vars=c(x$headers[1])) %>%
		setNames(c("candidate", "township", "count")) %>%
		subset(township != "TOTALS") %>%
		mutate(
			county = x$county,
			count = as.integer(count),
			count = ifelse(is.na(count), 0, count)
		)
}

##
raw_results <- list.files("raw", full.names=TRUE) %>%
	lapply(findIndex) %>%
	lapply(parseResults) %>%
	bind_rows()

write.csv(raw, "clean/all_results.csv", row.names=FALSE)

## Create a data entry file for machine counting 
data.frame(township=unique(raw_results$township), machine = "") %>%
	arrange(township) %>%
	write.csv("clean/all_townships.csv", row.names=FALSE)
