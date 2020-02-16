library(dplyr)
library(rgdal)
library(leaflet)

# library(tomkit)


## manual map
name_fix <- c("FITZILLIAM"="FITZWILLIAM",
	"AT AND GIL AC GRANT"="ATKINSON AND GILMANTON ACADEMY GRANT",
	"SECOND COLL GRANT"="SECOND COLLEGE GRANT",
	"THOMPSON AND MESS PURCHASE"="THOMPSON AND MESERVES PURCHASE",
	"WENTWORTHS LOCATION"= "WENTWORTH LOCATION",
	"BERLIN"="BERLIN WARDS 1-3",
	"DERRY"="DERRY WARDS 1-4"
)

## messy regex
precincts <- readOGR(dsn= "gis", verbose=FALSE)
townships <- read.csv("clean/all_townships.csv") %>%
	mutate(
		township = toupper(township),
		township = gsub(" LOC.$| LOC$", " LOCATION", township),
		township = gsub(" GT.$| GT$", " GRANT", township),
		township = gsub(" PUR.$| PUR$", " PURCHASE", township),
		township = gsub("&", "AND", township),
		township = gsub("\\.", "", township),
		township = ifelse(township %in% names(name_fix), name_fix[township], township),
		machine = ifelse(is.na(machine), 0, machine)
	)

ts <- data.frame(township=precincts$NAME) %>%
	merge(townships, by.x="township", all.x=TRUE) %>%
	mutate(
		color = "",
		color = ifelse(machine == 1, "#40DFBD", color),
		color = ifelse(machine == 0, "#FFFFFF", color),
		color = ifelse(is.na(color), "#333333", color)
	)

color_map <- ts$color %>% setNames(ts$township)

par(mar=c(0,0,2,0))
plot(precincts, col=ts$color, lwd=0.25, border=1, main="Machine Counted Districts (Pres Primary 2020)")

leaflet(precincts) %>%
	addTiles() %>%
	addPolygons(color = "#444444", weight = 1, smoothFactor = 0.5,
	opacity = 1.0, fillOpacity = 0.5,
	fillColor = precincts$COLOR,
	label = precincts$NAME,
	highlightOptions = highlightOptions(color = "white", weight = 2,
		bringToFront = TRUE))
