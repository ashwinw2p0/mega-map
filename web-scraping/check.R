# Check sites.
# crontab:
# 0 * * * * cd dir; Rscript check.R > log 2>&1
            #  ^ change this

# Author: Bill Behrman
# Version: 2020-05-07

# Libraries
suppressMessages(library(dplyr))
library(purrr)
suppressMessages(library(rvest))
library(stringr)
library(xml2)
library(yaml)

# Parameters
  # Site data
file_sites <- here::here("web-scraping/sites.yml")
  # Exclude sites
exclude_sites <- NULL
  # Hash algorithm
hash_alg <- "md5"
  # Email read error message
email_read_error <- 
  'mail -s "{site$url} read error" email_1,email_2 < /dev/null'
                                #  ^ change this
  # Email to check site
email_check_site <- 
  'mail -s "{site$url} check site" email_1,email_2 < /dev/null'
                                #  ^ change this

#===============================================================================

scrape_site <- function(site) {
  tryCatch(
    site$url %>% 
      read_html() %>% 
      html_nodes(css = site$css) %>% 
      digest::digest(., algo = hash_alg),
    error = function(e) {
      system(str_glue(email_read_error))
    }
  )
}

check_site <- function(site) {
  hash <- NULL
  hash <- scrape_site(site)
  if (is_null(hash) || is_empty(hash) || is.na(hash)) {
    system(str_glue(email_read_error))
  } else if (hash != site$hash) {
    system(str_glue(email_check_site))
    site$hash <- hash
  }
  site
}

read_yaml(file_sites) %>% 
  .[setdiff(names(.), exclude_sites)] %>%
  map(check_site) %>% 
  write_yaml(file_sites)

Sys.time()